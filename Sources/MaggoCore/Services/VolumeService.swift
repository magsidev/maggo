import Foundation
import AppKit

public struct VolumeItem: Identifiable, Hashable, Sendable {
    public var id: URL { url }
    public let url: URL
    public let name: String
    public let isRemovable: Bool
    public let isInternal: Bool
    public let totalCapacity: Int64
    public let availableCapacity: Int64
    
    public var formattedCapacity: String {
        let freeStr = ByteCountFormatter.string(fromByteCount: availableCapacity, countStyle: .file)
        let totalStr = ByteCountFormatter.string(fromByteCount: totalCapacity, countStyle: .file)
        return "\(freeStr) free of \(totalStr)"
    }
}

public final class VolumeService: @unchecked Sendable {
    public static let shared = VolumeService()

    private init() {}

    public func getMountedVolumes() -> [VolumeItem] {
        let keys: [URLResourceKey] = [
            .volumeNameKey,
            .volumeIsRemovableKey,
            .volumeIsInternalKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey
        ]

        let paths = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: keys,
            options: [.skipHiddenVolumes]
        ) ?? []

        var volumes: [VolumeItem] = []

        for url in paths {
            let values = try? url.resourceValues(forKeys: Set(keys))
            let name = values?.volumeName ?? url.lastPathComponent
            let isRemovable = values?.volumeIsRemovable ?? false
            let isInternal = values?.volumeIsInternal ?? true
            let total = Int64(values?.volumeTotalCapacity ?? 0)
            let free = values?.volumeAvailableCapacityForImportantUsage ?? 0

            volumes.append(
                VolumeItem(
                    url: url,
                    name: name,
                    isRemovable: isRemovable,
                    isInternal: isInternal,
                    totalCapacity: total,
                    availableCapacity: free
                )
            )
        }

        return volumes.sorted { v1, v2 in
            // Internal drives first, then alphabetical
            if v1.isInternal != v2.isInternal {
                return v1.isInternal && !v2.isInternal
            }
            return v1.name.localizedStandardCompare(v2.name) == .orderedAscending
        }
    }
}
