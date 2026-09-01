import Foundation
import Observation
import AppKit

public struct DestinationPickerConfig: Identifiable, Sendable {
    public let id = UUID()
    public let operation: FileOperationType // .move or .copy
    public let sourceURLs: [URL]
}

@MainActor
@Observable
public final class AppState {
    public var tabs: [TabModel] = []
    public var activeTabIndex: Int = 0

    public var favorites: [FavoriteLocation] = []
    public var volumes: [VolumeItem] = []
    public var recentLocations: [URL] = []

    public var destinationPickerConfig: DestinationPickerConfig?
    public var quickLookURL: URL?
    public var statusMessage: String = "Ready"

    public var newFolderPromptLocation: URL?
    public var renameItemPromptURL: URL?

    public init() {
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        let initialTab = TabModel(initialURL: homeURL)
        self.tabs = [initialTab]
        self.activeTabIndex = 0
        reloadSidebarData()
    }

    public var activeTab: TabModel {
        guard activeTabIndex >= 0 && activeTabIndex < tabs.count else {
            if tabs.isEmpty {
                let tab = TabModel(initialURL: FileManager.default.homeDirectoryForCurrentUser)
                tabs.append(tab)
                return tab
            }
            return tabs[0]
        }
        return tabs[activeTabIndex]
    }

    public var activePane: PaneModel {
        activeTab.activePane
    }

    // MARK: - Tab Management

    public func openNewTab(url: URL? = nil) {
        let target = url ?? activePane.currentURL
        let tab = TabModel(initialURL: target)
        tabs.append(tab)
        activeTabIndex = tabs.count - 1
    }

    public func closeTab(at index: Int) {
        guard tabs.count > 1 else { return }
        tabs.remove(at: index)
        if activeTabIndex >= tabs.count {
            activeTabIndex = tabs.count - 1
        }
    }

    public func closeActiveTab() {
        closeTab(at: activeTabIndex)
    }

    // MARK: - Sidebar & Locations

    public func reloadSidebarData() {
        self.favorites = RecentLocationsManager.shared.getFavorites()
        self.volumes = VolumeService.shared.getMountedVolumes()
        self.recentLocations = RecentLocationsManager.shared.getRecentLocations()
    }

    public func addFavorite(url: URL) {
        RecentLocationsManager.shared.addFavorite(url: url)
        favorites = RecentLocationsManager.shared.getFavorites()
    }

    public func removeFavorite(path: String) {
        RecentLocationsManager.shared.removeFavorite(path: path)
        favorites = RecentLocationsManager.shared.getFavorites()
    }

    // MARK: - Actions

    public func openItem(_ item: FileItem) {
        if item.isDirectory && !item.isPackage {
            activePane.navigate(to: item.url)
        } else {
            NSWorkspace.shared.open(item.url)
        }
    }

    public func revealInFinder(url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    public func copyPathToClipboard(url: URL) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url.path, forType: .string)
        statusMessage = "Copied path: \(url.lastPathComponent)"
    }

    public func triggerMoveTo() {
        let selected = activePane.selectedURLs
        guard !selected.isEmpty else { return }
        destinationPickerConfig = DestinationPickerConfig(
            operation: .move,
            sourceURLs: Array(selected)
        )
    }

    public func triggerCopyTo() {
        let selected = activePane.selectedURLs
        guard !selected.isEmpty else { return }
        destinationPickerConfig = DestinationPickerConfig(
            operation: .copy,
            sourceURLs: Array(selected)
        )
    }

    public func deleteSelected() {
        let selected = Array(activePane.selectedURLs)
        guard !selected.isEmpty else { return }

        do {
            _ = try FileOperationEngine.shared.moveToTrash(urls: selected)
            statusMessage = "Moved \(selected.count) item(s) to Trash"
            activePane.refresh()
            if activeTab.isSplitView {
                activeTab.inactivePane.refresh()
            }
        } catch {
            statusMessage = "Trash error: \(error.localizedDescription)"
        }
    }

    public func duplicateSelected() {
        let selected = Array(activePane.selectedURLs)
        guard !selected.isEmpty else { return }

        for url in selected {
            _ = try? FileOperationEngine.shared.duplicateItem(at: url)
        }
        activePane.refresh()
        statusMessage = "Duplicated \(selected.count) item(s)"
    }

    public func triggerUndo() {
        guard FileOperationEngine.shared.canUndo else { return }
        do {
            try FileOperationEngine.shared.undo()
            statusMessage = "Undid last file operation"
            activePane.refresh()
            if activeTab.isSplitView {
                activeTab.inactivePane.refresh()
            }
        } catch {
            statusMessage = "Undo error: \(error.localizedDescription)"
        }
    }
}
