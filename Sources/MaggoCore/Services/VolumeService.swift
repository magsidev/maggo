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
    
    public var usedCapacity: Int64 {
        max(0, totalCapacity - availableCapacity)
    }

    public var usedPercentage: Double {
        guard totalCapacity > 0 else { return 0.0 }
        return min(1.0, max(0.0, Double(usedCapacity) / Double(totalCapacity)))
    }

    public var formattedAvailable: String {
        let size = ByteCountFormatter.string(fromByteCount: availableCapacity, countStyle: .file)
        return "\(size) available"
    }

    public var formattedUsed: String {
        let size = ByteCountFormatter.string(fromByteCount: usedCapacity, countStyle: .file)
        return "\(size) used"
    }

    public var formattedTotal: String {
        let size = ByteCountFormatter.string(fromByteCount: totalCapacity, countStyle: .file)
        return "\(size) total"
    }

    public var formattedCapacitySummary: String {
        "\(formattedAvailable) · \(formattedTotal)"
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
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityKey
        ]

        let paths = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: keys,
            options: [.skipHiddenVolumes]
        ) ?? []

        var volumes: [VolumeItem] = []

        for url in paths {
            guard let values = try? url.resourceValues(forKeys: Set(keys)) else { continue }
            let name = values.volumeName ?? url.lastPathComponent
            let isRemovable = values.volumeIsRemovable ?? false
            let isInternal = values.volumeIsInternal ?? true
            let total = Int64(values.volumeTotalCapacity ?? 0)
            
            let available: Int64
            if let important = values.volumeAvailableCapacityForImportantUsage {
                available = important
            } else if let general = values.volumeAvailableCapacity {
                available = Int64(general)
            } else {
                available = 0
            }

            guard total > 0 else { continue }

            volumes.append(
                VolumeItem(
                    url: url,
                    name: name,
                    isRemovable: isRemovable,
                    isInternal: isInternal,
                    totalCapacity: total,
                    availableCapacity: available
                )
            )
        }

        return volumes.sorted { v1, v2 in
            if v1.isInternal != v2.isInternal {
                return v1.isInternal && !v2.isInternal
            }
            return v1.name.localizedStandardCompare(v2.name) == .orderedAscending
        }
    }
}
