import SwiftUI

public struct MainView: View {
    @Bindable var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        NavigationSplitView {
            SidebarView(appState: appState)
        } detail: {
            VStack(spacing: 0) {
                // Tab Strip
                tabStripView

                Divider()

                // Active Content: Smart Pictures, Storage Overview, or File Panes
                if appState.showSmartPictures {
                    PicturesSmartView(appState: appState)
                } else if let volume = appState.selectedVolumeForOverview {
                    StorageOverviewView(volume: volume) {
                        appState.selectedVolumeForOverview = nil
                        appState.activePane.navigate(to: volume.url)
                    }
                } else if !appState.tabs.isEmpty {
                    PaneContainerView(tab: appState.activeTab, appState: appState)
                }

                Divider()

                // Status Footer
                StatusFooterView(appState: appState)
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                AppToolbar(appState: appState)
            }
        }
        // Sheets & Dialogs
        .sheet(item: $appState.destinationPickerConfig) { config in
            DestinationPickerSheet(config: config, appState: appState)
        }
        .sheet(item: Binding(
            get: { appState.newFolderPromptLocation.map { IdentifiableURL(url: $0) } },
            set: { appState.newFolderPromptLocation = $0?.url }
        )) { item in
            NewFolderSheet(parentURL: item.url, appState: appState)
        }
        .sheet(item: Binding(
            get: { appState.renameItemPromptURL.map { IdentifiableURL(url: $0) } },
            set: { appState.renameItemPromptURL = $0?.url }
        )) { item in
            RenameSheet(targetURL: item.url, appState: appState)
        }
        .onChange(of: appState.quickLookURL) { _, newURL in
            if let newURL {
                QuickLookCoordinator.shared.toggleQuickLook(for: newURL)
                appState.quickLookURL = nil
            }
        }
        // Window-level keyboard fallback shortcuts
        .background(
            HStack {
                Button("") { appState.copySelected() }.keyboardShortcut("c", modifiers: .command)
                Button("") { appState.cutSelected() }.keyboardShortcut("x", modifiers: .command)
                Button("") { appState.paste() }.keyboardShortcut("v", modifiers: .command)
            }
            .opacity(0.001)
        )
    }

    // MARK: - Tab Strip
    private var tabStripView: some View {
        HStack(spacing: 6) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(appState.tabs.enumerated()), id: \.element.id) { index, tab in
                        let isSelected = (index == appState.activeTabIndex)
                        let count = tab.activePane.filteredItems.count

                        HStack(spacing: 6) {
                            Image(systemName: tabIcon(for: tab.activePane.currentURL))
                                .foregroundColor(isSelected ? .accentColor : .secondary)
                                .font(.system(size: 11))

                            Text(tab.title)
                                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                                .foregroundColor(isSelected ? .primary : .secondary)
                                .lineLimit(1)

                            if count > 0 {
                                Text("\(count)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(isSelected ? .accentColor : .secondary)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(
                                        Capsule()
                                            .fill(isSelected ? Color.accentColor.opacity(0.14) : Color.secondary.opacity(0.12))
                                    )
                            }

                            if appState.tabs.count > 1 {
                                Button {
                                    appState.closeTab(at: index)
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                                .padding(2)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isSelected ? Color(nsColor: .controlBackgroundColor) : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isSelected ? Color.secondary.opacity(0.2) : Color.clear, lineWidth: 1)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            appState.activeTabIndex = index
                        }
                    }
                }
                .padding(.horizontal, 8)
            }

            // Plus button for new tab
            Button {
                appState.openNewTab()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(6)
            }
            .buttonStyle(.plain)
            .help("New Tab (⌘T)")
        }
        .padding(.vertical, 4)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func tabIcon(for url: URL) -> String {
        let name = url.lastPathComponent.lowercased()
        if name == "downloads" {
            return "arrow.down.circle"
        } else if name == "documents" {
            return "doc.text"
        } else if name == "desktop" {
            return "desktopcomputer"
        } else {
            return "folder"
        }
    }
}

public struct IdentifiableURL: Identifiable {
    public var id: String { url.path }
    public let url: URL
}
