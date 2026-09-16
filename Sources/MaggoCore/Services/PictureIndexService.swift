import Foundation
import AppKit
import QuickLookThumbnailing
import UniformTypeIdentifiers

public struct PictureItem: Identifiable, Hashable, Sendable {
    public var id: URL { url }
    public let url: URL
    public let name: String
    public let fileSize: Int64
    public let dateModified: Date
    public let dateCreated: Date
    public let formatExtension: String
    public let parentDirectoryName: String
    public let relativeDisplayPath: String
    public let isPhotoBooth: Bool

    public init(
        url: URL,
        name: String,
        fileSize: Int64,
        dateModified: Date,
        dateCreated: Date,
        formatExtension: String,
        parentDirectoryName: String,
        relativeDisplayPath: String,
        isPhotoBooth: Bool = false
    ) {
        self.url = url
        self.name = name
        self.fileSize = fileSize
        self.dateModified = dateModified
        self.dateCreated = dateCreated
        self.formatExtension = formatExtension
        self.parentDirectoryName = parentDirectoryName
        self.relativeDisplayPath = relativeDisplayPath
        self.isPhotoBooth = isPhotoBooth
    }

    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: dateModified)
    }
}

public actor PictureIndexService {
    public static let shared = PictureIndexService()

    public static let supportedExtensions: Set<String> = [
        "jpg", "jpeg", "png", "heic", "heif", "gif", "tiff", "tif", "bmp", "webp"
    ]

    public static let excludedDirectoryNames: Set<String> = [
        ".git", "node_modules", "build", "dist", ".next", "DerivedData",
        "vendor", "Pods", ".venv", "venv", ".cargo", "target", ".cache"
    ]

    private var cachedPictures: [PictureItem] = []
    private var isIndexing = false
    private var lastIndexedDate: Date?

    private init() {}

    public nonisolated func isSupportedImage(url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return Self.supportedExtensions.contains(ext)
    }

    /// Returns currently cached pictures or triggers an initial index
    public func getIndexedPictures() async -> [PictureItem] {
        if !cachedPictures.isEmpty {
            return cachedPictures
        }
        return await indexPictures()
    }

    /// Scans primary user media directories (Pictures, Photo Booth Library, Downloads, Desktop, Documents)
    public func indexPictures() async -> [PictureItem] {
        guard !isIndexing else { return cachedPictures }
        isIndexing = true
        defer { isIndexing = false }

        let fm = FileManager()
        let home = fm.homeDirectoryForCurrentUser
        let picturesURL = home.appendingPathComponent("Pictures")

        let searchDirs: [URL] = [
            picturesURL,
            picturesURL.appendingPathComponent("Photo Booth Library/Pictures"),
            picturesURL.appendingPathComponent("Photo Booth Library"),
            home.appendingPathComponent("Downloads"),
            home.appendingPathComponent("Desktop"),
            home.appendingPathComponent("Documents")
        ]

        var foundItems: [PictureItem] = []
        var seenURLs: Set<String> = []
        let resourceKeys: Set<URLResourceKey> = [
            .fileSizeKey,
            .contentModificationDateKey,
            .creationDateKey,
            .isDirectoryKey,
            .isPackageKey
        ]

        for dir in searchDirs {
            guard fm.fileExists(atPath: dir.path) else { continue }

            let isPhotoBoothDir = dir.path.contains("Photo Booth Library")
            let options: FileManager.DirectoryEnumerationOptions = isPhotoBoothDir
                ? [.skipsHiddenFiles]
                : [.skipsHiddenFiles, .skipsPackageDescendants]

            guard let enumerator = fm.enumerator(
                at: dir,
                includingPropertiesForKeys: Array(resourceKeys),
                options: options
            ) else {
                continue
            }

            var scannedInDir = 0
            while let fileURL = enumerator.nextObject() as? URL {
                scannedInDir += 1
                if scannedInDir % 150 == 0 {
                    await Task.yield()
                }

                // Avoid duplicate index entries
                if seenURLs.contains(fileURL.path) {
                    continue
                }

                // Skip developer, package, and build directories
                let pathComponents = Set(fileURL.pathComponents)
                if !pathComponents.isDisjoint(with: Self.excludedDirectoryNames) {
                    continue
                }

                let ext = fileURL.pathExtension.lowercased()
                guard Self.supportedExtensions.contains(ext) else { continue }

                guard let values = try? fileURL.resourceValues(forKeys: resourceKeys),
                      values.isDirectory == false else { continue }

                seenURLs.insert(fileURL.path)

                let size = Int64(values.fileSize ?? 0)
                let dateMod = values.contentModificationDate ?? Date()
                let dateCreated = values.creationDate ?? dateMod

                let isPB = fileURL.path.contains("Photo Booth Library") || fileURL.path.contains("Photo Booth")
                let parentName = isPB ? "Photo Booth" : fileURL.deletingLastPathComponent().lastPathComponent
                let relativePath = fileURL.path.replacingOccurrences(of: home.path, with: "~")

                let item = PictureItem(
                    url: fileURL,
                    name: fileURL.lastPathComponent,
                    fileSize: size,
                    dateModified: dateMod,
                    dateCreated: dateCreated,
                    formatExtension: ext.uppercased(),
                    parentDirectoryName: parentName,
                    relativeDisplayPath: relativePath,
                    isPhotoBooth: isPB
                )
                foundItems.append(item)
            }
        }

        // Sort by most recently modified
        foundItems.sort { $0.dateModified > $1.dateModified }
        self.cachedPictures = foundItems
        self.lastIndexedDate = Date()

        return foundItems
    }
}
