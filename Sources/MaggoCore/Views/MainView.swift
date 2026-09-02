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
                // Top App Toolbar (matching landing page demo)
                AppToolbar(appState: appState)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color(hex: "ECEEEF"))

                Divider()

                // Tab Strip (Only displayed when 2+ tabs are open, like Finder & Safari)
                if appState.tabs.count > 1 {
                    tabStripView
                    Divider()
                }

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

                // Status Footer
                StatusFooterView(appState: appState)
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
                Button("") { appState.triggerQuickLook() }.keyboardShortcut(.space, modifiers: [])
                Button("") { appState.deleteSelected() }.keyboardShortcut(.delete, modifiers: .command)
                Button("") { appState.triggerUndo() }.keyboardShortcut("z", modifiers: .command)
                Button("") { appState.copySelected() }.keyboardShortcut("c", modifiers: .command)
                Button("") { appState.cutSelected() }.keyboardShortcut("x", modifiers: .command)
                Button("") { appState.paste() }.keyboardShortcut("v", modifiers: .command)
                Button("") { appState.duplicateSelected() }.keyboardShortcut("d", modifiers: .command)
                Button("") { appState.triggerMoveTo() }.keyboardShortcut("m", modifiers: [.command, .shift])
                Button("") { appState.triggerCopyTo() }.keyboardShortcut("c", modifiers: [.command, .shift])
            }
            .opacity(0.0001)
        )
    }

    // MARK: - Tab Strip
    private var tabStripView: some View {
        HStack(spacing: 4) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(appState.tabs.enumerated()), id: \.element.id) { index, tab in
                        let isSelected = (index == appState.activeTabIndex)

                        HStack(spacing: 6) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 11))
                                .foregroundColor(Color.iconFolder)

                            Text(tab.title)
                                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                                .foregroundColor(isSelected ? Color(hex: "0F172A") : Color(hex: "475569"))
                                .lineLimit(1)

                            if appState.tabs.count > 1 {
                                Button {
                                    appState.closeTab(at: index)
                                } label: {
                                    Text("✕")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(Color.secondary.opacity(0.6))
                                }
                                .buttonStyle(.plain)
                                .padding(.leading, 2)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isSelected ? Color.white : Color.maggoTabInactiveBg)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isSelected ? Color.maggoBorder : Color.clear, lineWidth: 1)
                        )
                        .shadow(color: isSelected ? Color.black.opacity(0.04) : Color.clear, radius: 2, y: 1)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            appState.activeTabIndex = index
                        }
                    }
                }
                .padding(.horizontal, 10)
            }

            // Plus button for new tab
            Button {
                appState.openNewTab()
            } label: {
                Text("+")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: "64748B"))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .help("New Tab (⌘T)")
            .padding(.trailing, 8)
        }
        .padding(.vertical, 4)
        .background(Color.maggoTabStripBg)
    }
}

public struct IdentifiableURL: Identifiable {
    public var id: String { url.path }
    public let url: URL

    public init(url: URL) {
        self.url = url
    }
}

