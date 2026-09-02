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

    /// Asynchronously calculates the total size of a folder or application bundle in the background
    public func calculateSize(for url: URL, currentDateModified: Date) async -> Int64 {
        if let cached = getCachedSize(for: url, currentDateModified: currentDateModified) {
            return cached
        }

        // Deduplicate in-flight calculations for the same folder/app
        if let existingTask = inFlightTasks[url] {
            return await existingTask.value
        }

        let task = Task.detached(priority: .utility) { () -> Int64 in
            let fm = FileManager()
            let resourceKeys: Set<URLResourceKey> = [
                .fileSizeKey,
                .totalFileAllocatedSizeKey,
                .isDirectoryKey
            ]
            
            guard let enumerator = fm.enumerator(
                at: url,
                includingPropertiesForKeys: Array(resourceKeys),
                options: [.skipsHiddenFiles]
            ) else {
                return 0
            }

            var totalSize: Int64 = 0
            var count = 0

            while let fileURL = enumerator.nextObject() as? URL {
                count += 1
                if count % 250 == 0 {
                    await Task.yield()
                }

                if let values = try? fileURL.resourceValues(forKeys: resourceKeys) {
                    if values.isDirectory == false {
                        let bytes = Int64(values.fileSize ?? 0)
                        totalSize += bytes
                    }
                }
            }

            return totalSize
        }

        inFlightTasks[url] = task
        let finalSize = await task.value
        inFlightTasks.removeValue(forKey: url)
        cache[url] = CacheEntry(size: finalSize, dateModified: currentDateModified)
        return finalSize
    }

    public func invalidateCache(for url: URL) {
        cache.removeValue(forKey: url)
    }

    public func clearCache() {
        cache.removeAll()
    }
}
