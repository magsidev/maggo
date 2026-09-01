import Foundation

public struct FavoriteLocation: Identifiable, Codable, Hashable, Sendable {
    public var id: String { path }
    public let path: String
    public let name: String
    public let iconName: String

    public var url: URL {
        URL(fileURLWithPath: path)
    }

    public init(path: String, name: String? = nil, iconName: String = "folder.fill") {
        self.path = path
        self.name = name ?? URL(fileURLWithPath: path).lastPathComponent
        self.iconName = iconName
    }
}

public final class RecentLocationsManager: @unchecked Sendable {
    public static let shared = RecentLocationsManager()

    private let recentLocationsKey = "Maggo.RecentLocations"
    private let recentDestinationsKey = "Maggo.RecentDestinations"
    private let favoritesKey = "Maggo.Favorites"
    private let maxHistory = 15

    private init() {}

    // MARK: - Recent Locations
    public func getRecentLocations() -> [URL] {
        let paths = UserDefaults.standard.stringArray(forKey: recentLocationsKey) ?? []
        return paths.compactMap { path in
            let url = URL(fileURLWithPath: path)
            return FileManager.default.fileExists(atPath: url.path) ? url : nil
        }
    }

    public func recordLocation(_ url: URL) {
        guard url.hasDirectoryPath || (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true else {
            return
        }
        var recents = getRecentLocations().map(\.path)
        recents.removeAll { $0 == url.path }
        recents.insert(url.path, at: 0)
        if recents.count > maxHistory {
            recents = Array(recents.prefix(maxHistory))
        }
        UserDefaults.standard.set(recents, forKey: recentLocationsKey)
    }

    // MARK: - Recent Destinations (For Move To / Copy To)
    public func getRecentDestinations() -> [URL] {
        let paths = UserDefaults.standard.stringArray(forKey: recentDestinationsKey) ?? []
        return paths.compactMap { path in
            let url = URL(fileURLWithPath: path)
            return FileManager.default.fileExists(atPath: url.path) ? url : nil
        }
    }

    public func recordDestination(_ url: URL) {
        var recents = getRecentDestinations().map(\.path)
        recents.removeAll { $0 == url.path }
        recents.insert(url.path, at: 0)
        if recents.count > maxHistory {
            recents = Array(recents.prefix(maxHistory))
        }
        UserDefaults.standard.set(recents, forKey: recentDestinationsKey)
    }

    // MARK: - Favorites
    public func getFavorites() -> [FavoriteLocation] {
        if let data = UserDefaults.standard.data(forKey: favoritesKey),
           let list = try? JSONDecoder().decode([FavoriteLocation].self, from: data) {
            return list
        }
        // Default favorites: Home, Documents, Downloads, Desktop
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        let defaults: [FavoriteLocation] = [
            FavoriteLocation(path: home.path, name: "Home", iconName: "house.fill"),
            FavoriteLocation(path: home.appendingPathComponent("Desktop").path, name: "Desktop", iconName: "desktopcomputer"),
            FavoriteLocation(path: home.appendingPathComponent("Documents").path, name: "Documents", iconName: "doc.text.fill"),
            FavoriteLocation(path: home.appendingPathComponent("Downloads").path, name: "Downloads", iconName: "arrow.down.circle.fill"),
            FavoriteLocation(path: home.appendingPathComponent("Pictures").path, name: "Pictures", iconName: "photo.fill")
        ]
        return defaults
    }

    public func saveFavorites(_ favorites: [FavoriteLocation]) {
        if let data = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(data, forKey: favoritesKey)
        }
    }

    public func addFavorite(url: URL) {
        var current = getFavorites()
        if !current.contains(where: { $0.path == url.path }) {
            current.append(FavoriteLocation(path: url.path, name: url.lastPathComponent))
            saveFavorites(current)
        }
    }

    public func removeFavorite(path: String) {
        var current = getFavorites()
        current.removeAll { $0.path == path }
        saveFavorites(current)
    }
}
