import Foundation
import Observation
import AppKit

@MainActor
@Observable
public final class PaneModel: Identifiable {
    public let id = UUID()
    public var currentURL: URL {
        didSet {
            loadItems()
        }
    }

    public var history: [URL] = []
    public var historyIndex: Int = 0

    public var items: [FileItem] = []
    public var selectedURLs: Set<URL> = []
    public var viewMode: ViewMode = .detailsList
    public var sortOption: FileSortOption = FileSortOption(field: .name, ascending: true)
    public var searchQuery: String = ""
    public var isLoading: Bool = false
    public var showHiddenFiles: Bool = false

    public init(url: URL) {
        self.currentURL = url
        self.history = [url]
        self.historyIndex = 0
        loadItems()
    }

    public var canGoBack: Bool {
        historyIndex > 0
    }

    public var canGoForward: Bool {
        historyIndex < history.count - 1
    }

    public var canGoUp: Bool {
        currentURL.path != "/" && currentURL.deletingLastPathComponent().path != currentURL.path
    }

    public var filteredItems: [FileItem] {
        let sorted = sortOption.sort(items)
        if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return sorted
        }
        let query = searchQuery.lowercased()
        return sorted.filter { $0.name.lowercased().contains(query) }
    }

    public var selectedItems: [FileItem] {
        items.filter { selectedURLs.contains($0.url) }
    }

    // MARK: - Navigation

    public func navigate(to url: URL) {
        guard url != currentURL else { return }

        // Truncate forward history
        if historyIndex < history.count - 1 {
            history = Array(history.prefix(historyIndex + 1))
        }

        history.append(url)
        historyIndex = history.count - 1
        currentURL = url
        selectedURLs.removeAll()
        searchQuery = ""

        RecentLocationsManager.shared.recordLocation(url)
    }

    public func goBack() {
        guard canGoBack else { return }
        historyIndex -= 1
        currentURL = history[historyIndex]
        selectedURLs.removeAll()
    }

    public func goForward() {
        guard canGoForward else { return }
        historyIndex += 1
        currentURL = history[historyIndex]
        selectedURLs.removeAll()
    }

    public func goUp() {
        guard canGoUp else { return }
        let parent = currentURL.deletingLastPathComponent()
        navigate(to: parent)
    }

    // MARK: - Loading

    public func loadItems() {
        isLoading = true
        let targetURL = currentURL
        let showHidden = showHiddenFiles

        Task {
            do {
                let fetched = try await FileSystemService.shared.fetchDirectoryContents(
                    at: targetURL,
                    showHidden: showHidden
                )
                guard self.currentURL == targetURL else { return }
                self.items = fetched
                self.isLoading = false
            } catch {
                guard self.currentURL == targetURL else { return }
                self.items = []
                self.isLoading = false
            }
        }
    }

    public func refresh() {
        loadItems()
    }

    public func selectAll() {
        selectedURLs = Set(items.map(\.url))
    }

    public func deselectAll() {
        selectedURLs.removeAll()
    }
}
