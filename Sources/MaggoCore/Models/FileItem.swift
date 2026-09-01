import Foundation
import AppKit
import UniformTypeIdentifiers

public struct FileItem: Identifiable, Hashable, @unchecked Sendable {
    public var id: URL { url }
    public let url: URL
    public let name: String
    public let isDirectory: Bool
    public let isPackage: Bool
    public let fileSize: Int64
    public let dateModified: Date
    public let dateCreated: Date
    public let kindDescription: String
    public let isHidden: Bool
    public let isSymlink: Bool
    
    // Cached icon for performance
    private let _customIcon: NSImage?

    public init(
        url: URL,
        name: String? = nil,
        isDirectory: Bool,
        isPackage: Bool = false,
        fileSize: Int64 = 0,
        dateModified: Date = Date(),
        dateCreated: Date = Date(),
        kindDescription: String? = nil,
        isHidden: Bool = false,
        isSymlink: Bool = false,
        icon: NSImage? = nil
    ) {
        self.url = url
        self.name = name ?? url.lastPathComponent
        self.isDirectory = isDirectory
        self.isPackage = isPackage
        self.fileSize = fileSize
        self.dateModified = dateModified
        self.dateCreated = dateCreated
        self.isHidden = isHidden
        self.isSymlink = isSymlink
        self._customIcon = icon
        
        if let kindDescription {
            self.kindDescription = kindDescription
        } else if isDirectory && !isPackage {
            self.kindDescription = "Folder"
        } else {
            let ext = url.pathExtension.lowercased()
            if let utType = UTType(filenameExtension: ext) {
                self.kindDescription = utType.localizedDescription ?? ext.uppercased()
            } else {
                self.kindDescription = ext.isEmpty ? "Document" : "\(ext.uppercased()) File"
            }
        }
    }

    public var icon: NSImage {
        if let _customIcon {
            return _customIcon
        }
        return NSWorkspace.shared.icon(forFile: url.path)
    }

    public var typeBadgeText: String {
        if isDirectory && !isPackage {
            return "DIR"
        }
        let ext = url.pathExtension.uppercased()
        if ext.isEmpty { return "FILE" }
        if ext == "JPEG" { return "JPG" }
        return String(ext.prefix(4))
    }

    public var formattedSize: String {
        if isDirectory && !isPackage {
            return "--"
        }
        return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    public var formattedDateModified: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: dateModified)
    }

    public static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        lhs.url == rhs.url && lhs.dateModified == rhs.dateModified && lhs.fileSize == rhs.fileSize
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}
