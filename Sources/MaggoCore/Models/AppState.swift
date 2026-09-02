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

    public var showSmartPictures: Bool = false
    public var selectedVolumeForOverview: VolumeItem?
    public var selectedPictureURL: URL?
    public var smartPicturesRefreshTrigger: Int = 0

    public var hasSelection: Bool {
        if showSmartPictures {
            return selectedPictureURL != nil
        }
        return !activePane.selectedURLs.isEmpty
    }

    public var selectedCount: Int {
        if showSmartPictures {
            return selectedPictureURL != nil ? 1 : 0
        }
        return activePane.selectedURLs.count
    }

    public func refreshAllViews() {
        activePane.refresh()
        if activeTab.isSplitView {
            activeTab.inactivePane.refresh()
        }
        smartPicturesRefreshTrigger += 1
    }

    public init() {
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        let initialTab = TabModel(initialURL: homeURL)
        self.tabs = [initialTab]
        self.activeTabIndex = 0
        reloadSidebarData()

        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.reloadSidebarData()
            }
        }
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

    public func copySelected() {
        let selected = Array(activePane.selectedURLs)
        guard !selected.isEmpty else { return }
        PasteboardService.shared.copy(urls: selected, isCut: false)
        statusMessage = "Copied \(selected.count) item(s)"
    }

    public func cutSelected() {
        let selected = Array(activePane.selectedURLs)
        guard !selected.isEmpty else { return }
        PasteboardService.shared.copy(urls: selected, isCut: true)
        statusMessage = "Cut \(selected.count) item(s)"
    }

    public func paste() {
        let (urls, isCut) = PasteboardService.shared.getFileURLs()
        guard !urls.isEmpty else {
            statusMessage = "Clipboard is empty"
            return
        }

        let target = activePane.currentURL
        do {
            if isCut {
                _ = try FileOperationEngine.shared.moveItems(urls: urls, to: target)
                PasteboardService.shared.clearCutFlag()
                statusMessage = "Moved \(urls.count) item(s) to \(target.lastPathComponent)"
            } else {
                _ = try FileOperationEngine.shared.copyItems(urls: urls, to: target)
                statusMessage = "Pasted \(urls.count) item(s) into \(target.lastPathComponent)"
            }
            activePane.refresh()
            if activeTab.isSplitView {
                activeTab.inactivePane.refresh()
            }
        } catch {
            statusMessage = "Paste error: \(error.localizedDescription)"
        }
    }

    public func triggerMoveTo() {
        let selected: [URL]
        if showSmartPictures, let pic = selectedPictureURL {
            selected = [pic]
        } else {
            selected = Array(activePane.selectedURLs)
        }
        guard !selected.isEmpty else { return }
        destinationPickerConfig = DestinationPickerConfig(
            operation: .move,
            sourceURLs: selected
        )
    }

    public func triggerCopyTo() {
        let selected: [URL]
        if showSmartPictures, let pic = selectedPictureURL {
            selected = [pic]
        } else {
            selected = Array(activePane.selectedURLs)
        }
        guard !selected.isEmpty else { return }
        destinationPickerConfig = DestinationPickerConfig(
            operation: .copy,
            sourceURLs: selected
        )
    }

    public func deleteSelected() {
        let selected: [URL]
        if showSmartPictures, let pic = selectedPictureURL {
            selected = [pic]
        } else {
            selected = Array(activePane.selectedURLs)
        }
        guard !selected.isEmpty else { return }

        do {
            _ = try FileOperationEngine.shared.moveToTrash(urls: selected)
            statusMessage = "Moved \(selected.count) item(s) to Trash"
            refreshAllViews()
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
