import Foundation
import AppKit
import UniformTypeIdentifiers

public actor FileSystemService {
    public static let shared = FileSystemService()

    private let fileManager = FileManager()

    private let resourceKeys: Set<URLResourceKey> = [
        .localizedNameKey,
        .isDirectoryKey,
        .isPackageKey,
        .fileSizeKey,
        .contentModificationDateKey,
        .creationDateKey,
        .contentTypeKey,
        .isHiddenKey,
        .isSymbolicLinkKey
    ]

    public init() {}

    /// Fetches directory contents asynchronously off the main thread with optimized resource key prefetching
    public func fetchDirectoryContents(at url: URL, showHidden: Bool = false) async throws -> [FileItem] {
        guard url.hasDirectoryPath || (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true else {
            return []
        }

        let options: FileManager.DirectoryEnumerationOptions = showHidden ? [] : [.skipsHiddenFiles]

        let fileURLs = try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: Array(resourceKeys),
            options: options
        )

        var items: [FileItem] = []
        items.reserveCapacity(fileURLs.count)

        for fileURL in fileURLs {
            // Fetch cached resource values
            let values = try? fileURL.resourceValues(forKeys: resourceKeys)

            let isHidden = values?.isHidden ?? false
            if !showHidden && isHidden {
                continue
            }

            let name = values?.localizedName ?? fileURL.lastPathComponent
            let isDir = values?.isDirectory ?? false
            let isPackage = values?.isPackage ?? false
            let size = Int64(values?.fileSize ?? 0)
            let dateMod = values?.contentModificationDate ?? Date()
            let dateCreated = values?.creationDate ?? Date()
            let isSymlink = values?.isSymbolicLink ?? false
            
            var kindDesc: String? = nil
            if let contentType = values?.contentType {
                kindDesc = contentType.localizedDescription
            }

            let item = FileItem(
                url: fileURL,
                name: name,
                isDirectory: isDir,
                isPackage: isPackage,
                fileSize: size,
                dateModified: dateMod,
                dateCreated: dateCreated,
                kindDescription: kindDesc,
                isHidden: isHidden,
                isSymlink: isSymlink
            )
            items.append(item)
        }

        return items
    }

    /// Checks if a file or folder exists at a given path
    public func exists(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
    }

    /// Gets available free space for a URL's volume
    public func volumeFreeSpace(for url: URL) -> (free: Int64, total: Int64)? {
        guard let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeTotalCapacityKey]) else {
            return nil
        }
        let free = values.volumeAvailableCapacityForImportantUsage ?? 0
        let total = Int64(values.volumeTotalCapacity ?? 0)
        return (free, total)
    }
}
