import Foundation

public actor FolderSizeService {
    public static let shared = FolderSizeService()

    private struct CacheEntry {
        let size: Int64
        let dateModified: Date
    }

    private var cache: [URL: CacheEntry] = [:]
    private var inFlightTasks: [URL: Task<Int64, Never>] = [:]

    private init() {}

    /// Returns cached size if valid and not modified since calculation
    public func getCachedSize(for url: URL, currentDateModified: Date) -> Int64? {
        guard let entry = cache[url] else { return nil }
        if entry.dateModified == currentDateModified {
            return entry.size
        }
        return nil
    }

    /// Asynchronously calculates the total size of a folder in the background
    public func calculateSize(for url: URL, currentDateModified: Date) async -> Int64 {
        if let cached = getCachedSize(for: url, currentDateModified: currentDateModified) {
            return cached
        }

        // Deduplicate in-flight calculations for the same folder
        if let existingTask = inFlightTasks[url] {
            return await existingTask.value
        }

        let task = Task.detached(priority: .utility) { () -> Int64 in
            let fm = FileManager()
            let resourceKeys: Set<URLResourceKey> = [.fileSizeKey, .isDirectoryKey, .isPackageKey]
            
            guard let enumerator = fm.enumerator(
                at: url,
                includingPropertiesForKeys: Array(resourceKeys),
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else {
                return 0
            }

            var totalSize: Int64 = 0
            var count = 0

            while let fileURL = enumerator.nextObject() as? URL {
                // Yield periodically so we don't hog cooperative task pools on massive folders
                count += 1
                if count % 200 == 0 {
                    await Task.yield()
                }

                if let values = try? fileURL.resourceValues(forKeys: resourceKeys) {
                    if values.isDirectory == false || values.isPackage == true {
                        totalSize += Int64(values.fileSize ?? 0)
                    }
                }
            }

            return totalSize
        }

        inFlightTasks[url] = task
        let size = await task.value
        inFlightTasks.removeValue(forKey: url)

        cache[url] = CacheEntry(size: size, dateModified: currentDateModified)
        return size
    }

    public func invalidateCache(for url: URL) {
        cache.removeValue(forKey: url)
    }

    public func clearCache() {
        cache.removeAll()
    }
}
