import Foundation
import AppKit

public enum FileOperationType: String, Sendable {
    case move = "Move"
    case copy = "Copy"
    case trash = "Move to Trash"
    case rename = "Rename"
    case newFolder = "New Folder"
    case duplicate = "Duplicate"
}

public struct UndoableAction: Sendable {
    public let type: FileOperationType
    public let originalURLs: [URL]
    public let destinationURLs: [URL]
    public let timestamp: Date

    public init(type: FileOperationType, originalURLs: [URL], destinationURLs: [URL]) {
        self.type = type
        self.originalURLs = originalURLs
        self.destinationURLs = destinationURLs
        self.timestamp = Date()
    }
}

public enum ConflictResolutionChoice {
    case replace
    case keepBoth
    case skip
}

public final class FileOperationEngine: @unchecked Sendable {
    public static let shared = FileOperationEngine()

    private let fileManager = FileManager.default
    private var undoStack: [UndoableAction] = []
    private let lock = NSLock()

    private init() {}

    public var canUndo: Bool {
        lock.lock()
        defer { lock.unlock() }
        return !undoStack.isEmpty
    }

    public var lastActionDescription: String? {
        lock.lock()
        defer { lock.unlock() }
        guard let last = undoStack.last else { return nil }
        return "\(last.type.rawValue) \(last.destinationURLs.count) item(s)"
    }

    // MARK: - Core Operations

    /// Creates a new folder inside parentURL
    @discardableResult
    public func createFolder(at parentURL: URL, name: String = "New Folder") throws -> URL {
        var targetURL = parentURL.appendingPathComponent(name)
        var counter = 2
        while fileManager.fileExists(atPath: targetURL.path) {
            targetURL = parentURL.appendingPathComponent("\(name) \(counter)")
            counter += 1
        }

        try fileManager.createDirectory(at: targetURL, withIntermediateDirectories: false)

        lock.lock()
        undoStack.append(UndoableAction(type: .newFolder, originalURLs: [], destinationURLs: [targetURL]))
        lock.unlock()

        return targetURL
    }

    /// Safely moves items to the macOS Trash
    public func moveToTrash(urls: [URL]) throws -> [URL] {
        var trashedURLs: [URL] = []
        for url in urls {
            var resultingURL: NSURL?
            try fileManager.trashItem(at: url, resultingItemURL: &resultingURL)
            if let resultingURL = resultingURL as URL? {
                trashedURLs.append(resultingURL)
            }
        }

        lock.lock()
        undoStack.append(UndoableAction(type: .trash, originalURLs: urls, destinationURLs: trashedURLs))
        lock.unlock()

        return trashedURLs
    }

    /// Renames a file or folder at url to newName
    @discardableResult
    public func renameItem(at url: URL, newName: String) throws -> URL {
        let parent = url.deletingLastPathComponent()
        let destinationURL = parent.appendingPathComponent(newName)

        if fileManager.fileExists(atPath: destinationURL.path) {
            throw NSError(
                domain: "MaggoErrorDomain",
                code: 409,
                userInfo: [NSLocalizedDescriptionKey: "An item named '\(newName)' already exists."]
            )
        }

        try fileManager.moveItem(at: url, to: destinationURL)

        lock.lock()
        undoStack.append(UndoableAction(type: .rename, originalURLs: [url], destinationURLs: [destinationURL]))
        lock.unlock()

        return destinationURL
    }

    /// Duplicates an item (like Finder ⌘D)
    @discardableResult
    public func duplicateItem(at url: URL) throws -> URL {
        let parent = url.deletingLastPathComponent()
        let baseName = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension

        var targetName = ext.isEmpty ? "\(baseName) copy" : "\(baseName) copy.\(ext)"
        var targetURL = parent.appendingPathComponent(targetName)
        var counter = 2

        while fileManager.fileExists(atPath: targetURL.path) {
            targetName = ext.isEmpty ? "\(baseName) copy \(counter)" : "\(baseName) copy \(counter).\(ext)"
            targetURL = parent.appendingPathComponent(targetName)
            counter += 1
        }

        try fileManager.copyItem(at: url, to: targetURL)

        lock.lock()
        undoStack.append(UndoableAction(type: .duplicate, originalURLs: [url], destinationURLs: [targetURL]))
        lock.unlock()

        return targetURL
    }

    /// Moves items to a target directory
    public func moveItems(
        urls: [URL],
        to destinationDirectory: URL,
        onConflict: (URL) -> ConflictResolutionChoice = { _ in .keepBoth }
    ) throws -> [URL] {
        var movedURLs: [URL] = []
        var originalURLs: [URL] = []

        for sourceURL in urls {
            let filename = sourceURL.lastPathComponent
            var targetURL = destinationDirectory.appendingPathComponent(filename)

            if fileManager.fileExists(atPath: targetURL.path) {
                let choice = onConflict(targetURL)
                switch choice {
                case .skip:
                    continue
                case .replace:
                    try fileManager.removeItem(at: targetURL)
                case .keepBoth:
                    targetURL = uniqueDestinationURL(for: targetURL)
                }
            }

            try fileManager.moveItem(at: sourceURL, to: targetURL)
            movedURLs.append(targetURL)
            originalURLs.append(sourceURL)
        }

        lock.lock()
        undoStack.append(UndoableAction(type: .move, originalURLs: originalURLs, destinationURLs: movedURLs))
        lock.unlock()

        return movedURLs
    }

    /// Copies items to a target directory
    public func copyItems(
        urls: [URL],
        to destinationDirectory: URL,
        onConflict: (URL) -> ConflictResolutionChoice = { _ in .keepBoth }
    ) throws -> [URL] {
        var copiedURLs: [URL] = []
        var originalURLs: [URL] = []

        for sourceURL in urls {
            let filename = sourceURL.lastPathComponent
            var targetURL = destinationDirectory.appendingPathComponent(filename)

            if fileManager.fileExists(atPath: targetURL.path) {
                let choice = onConflict(targetURL)
                switch choice {
                case .skip:
                    continue
                case .replace:
                    try fileManager.removeItem(at: targetURL)
                case .keepBoth:
                    targetURL = uniqueDestinationURL(for: targetURL)
                }
            }

            try fileManager.copyItem(at: sourceURL, to: targetURL)
            copiedURLs.append(targetURL)
            originalURLs.append(sourceURL)
        }

        lock.lock()
        undoStack.append(UndoableAction(type: .copy, originalURLs: originalURLs, destinationURLs: copiedURLs))
        lock.unlock()

        return copiedURLs
    }

    // MARK: - Undo

    /// Reverses the most recent file operation
    public func undo() throws {
        lock.lock()
        guard let action = undoStack.popLast() else {
            lock.unlock()
            return
        }
        lock.unlock()

        switch action.type {
        case .move:
            // Move back from destination to original
            for (original, dest) in zip(action.originalURLs, action.destinationURLs) {
                if fileManager.fileExists(atPath: dest.path) {
                    try fileManager.moveItem(at: dest, to: original)
                }
            }
        case .copy, .duplicate, .newFolder:
            // Delete the copies or created folder
            for dest in action.destinationURLs {
                if fileManager.fileExists(atPath: dest.path) {
                    try fileManager.removeItem(at: dest)
                }
            }
        case .rename:
            // Revert name back to original
            if let original = action.originalURLs.first, let dest = action.destinationURLs.first {
                if fileManager.fileExists(atPath: dest.path) {
                    try fileManager.moveItem(at: dest, to: original)
                }
            }
        case .trash:
            // Items in trash: Attempt to move back from resulting trash URL
            for (original, trashed) in zip(action.originalURLs, action.destinationURLs) {
                if fileManager.fileExists(atPath: trashed.path) {
                    try fileManager.moveItem(at: trashed, to: original)
                }
            }
        }
    }

    // MARK: - Helpers

    private func uniqueDestinationURL(for url: URL) -> URL {
        let parent = url.deletingLastPathComponent()
        let baseName = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension

        var counter = 2
        var targetURL = url

        while fileManager.fileExists(atPath: targetURL.path) {
            let newName = ext.isEmpty ? "\(baseName) \(counter)" : "\(baseName) \(counter).\(ext)"
            targetURL = parent.appendingPathComponent(newName)
            counter += 1
        }

        return targetURL
    }
}
