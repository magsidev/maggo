import Foundation

public enum ViewMode: String, CaseIterable, Identifiable, Sendable {
    case detailsList = "List"
    case grid = "Grid"

    public var id: String { rawValue }
    
    public var systemImage: String {
        switch self {
        case .detailsList:
            return "list.bullet"
        case .grid:
            return "square.grid.2x2"
        }
    }
}

public enum SortField: String, CaseIterable, Identifiable, Sendable {
    case name = "Name"
    case dateModified = "Date Modified"
    case dateCreated = "Date Created"
    case size = "Size"
    case kind = "Kind"

    public var id: String { rawValue }
}

public struct FileSortOption: Sendable {
    public var field: SortField
    public var ascending: Bool

    public init(field: SortField = .name, ascending: Bool = true) {
        self.field = field
        self.ascending = ascending
    }

    public func sort(_ items: [FileItem]) -> [FileItem] {
        items.sorted { item1, item2 in
            // Folders always pinned to top (like Windows File Explorer / professional file managers)
            let isDir1 = item1.isDirectory && !item1.isPackage
            let isDir2 = item2.isDirectory && !item2.isPackage

            if isDir1 != isDir2 {
                return isDir1 && !isDir2
            }

            let comparison: Bool
            switch field {
            case .name:
                comparison = item1.name.localizedStandardCompare(item2.name) == .orderedAscending
            case .dateModified:
                comparison = item1.dateModified < item2.dateModified
            case .dateCreated:
                comparison = item1.dateCreated < item2.dateCreated
            case .size:
                comparison = item1.fileSize < item2.fileSize
            case .kind:
                comparison = item1.kindDescription.localizedStandardCompare(item2.kindDescription) == .orderedAscending
            }

            return ascending ? comparison : !comparison
        }
    }
}
