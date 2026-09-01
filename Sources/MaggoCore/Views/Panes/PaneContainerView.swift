import SwiftUI

public struct PaneContainerView: View {
    @Bindable var tab: TabModel
    @Bindable var appState: AppState

    public init(tab: TabModel, appState: AppState) {
        self.tab = tab
        self.appState = appState
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Global Breadcrumb Bar above panes
            HStack(spacing: 8) {
                // Navigation history buttons
                HStack(spacing: 2) {
                    Button {
                        tab.activePane.goBack()
                    } label: {
                        Image(systemName: "chevron.backward")
                    }
                    .disabled(!tab.activePane.canGoBack)
                    .buttonStyle(.plain)

                    Button {
                        tab.activePane.goForward()
                    } label: {
                        Image(systemName: "chevron.forward")
                    }
                    .disabled(!tab.activePane.canGoForward)
                    .buttonStyle(.plain)

                    Button {
                        tab.activePane.goUp()
                    } label: {
                        Image(systemName: "arrow.up")
                    }
                    .disabled(!tab.activePane.canGoUp)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 4)

                // Interactive Breadcrumb
                BreadcrumbBar(pane: tab.activePane)

                Spacer()

                // List vs Grid Segmented Switcher
                Picker("View", selection: Binding(
                    get: { tab.activePane.viewMode },
                    set: { tab.activePane.viewMode = $0 }
                )) {
                    Image(systemName: "list.bullet").tag(ViewMode.detailsList)
                    Image(systemName: "square.grid.2x2").tag(ViewMode.grid)
                }
                .pickerStyle(.segmented)
                .frame(width: 68)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // Panes
            if tab.isSplitView {
                HSplitView {
                    paneColumn(pane: tab.leftPane, side: .left)
                        .frame(minWidth: 280)

                    paneColumn(pane: tab.rightPane, side: .right)
                        .frame(minWidth: 280)
                }
            } else {
                paneColumn(pane: tab.leftPane, side: .left)
            }
        }
    }

    @ViewBuilder
    private func paneColumn(pane: PaneModel, side: ActivePaneSide) -> some View {
        let isFocused = (tab.activePaneSide == side)
        let isRightPane = (side == .right)

        VStack(spacing: 0) {
            // Pane Sub-Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: paneHeaderIcon(for: pane.currentURL))
                        .foregroundColor(isRightPane ? .green : .accentColor)
                        .font(.system(size: 13, weight: .semibold))

                    Text(pane.currentURL.lastPathComponent.isEmpty ? "Macintosh HD" : pane.currentURL.lastPathComponent)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(isRightPane ? .green : .primary)
                }

                Spacer()

                Text("\(pane.filteredItems.count) item\(pane.filteredItems.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(isFocused ? Color.accentColor.opacity(0.04) : Color.clear)

            Divider()

            // Main Content Area
            ZStack {
                if pane.isLoading && pane.items.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if pane.filteredItems.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: pane.searchQuery.isEmpty ? "folder" : "magnifyingglass")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary)
                        Text(pane.searchQuery.isEmpty ? "Folder is empty" : "No matches for \"\(pane.searchQuery)\"")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    switch pane.viewMode {
                    case .detailsList:
                        FileListView(pane: pane, appState: appState)
                    case .grid:
                        FileGridView(pane: pane, appState: appState)
                    }
                }
            }

            // Split View Helper Footer Banner
            if tab.isSplitView {
                Divider()

                if isRightPane {
                    // Right pane drop target banner
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.down.doc")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("Drop files here to move directly")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.green)
                        Spacer()
                    }
                    .padding(.vertical, 7)
                    .background(Color.green.opacity(0.08))
                    .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                        handleDrop(providers: providers, destination: pane.currentURL)
                    }
                } else {
                    // Left pane guide banner
                    HStack {
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("Drag and drop to right pane or use Move To (⌘⇧M)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.secondary.opacity(0.04))
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(tab.isSplitView && isFocused ? Color.accentColor.opacity(0.35) : Color.clear, lineWidth: 1.5)
        )
        .onTapGesture {
            tab.activePaneSide = side
        }
    }

    private func paneHeaderIcon(for url: URL) -> String {
        let name = url.lastPathComponent.lowercased()
        if name == "downloads" {
            return "arrow.down.circle.fill"
        } else if name == "desktop" {
            return "desktopcomputer"
        } else if name == "documents" {
            return "doc.text.fill"
        } else {
            return "folder.fill"
        }
    }

    private func handleDrop(providers: [NSItemProvider], destination: URL) -> Bool {
        for provider in providers {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let sourceURL = url else { return }
                Task { @MainActor in
                    _ = try? FileOperationEngine.shared.moveItems(urls: [sourceURL], to: destination)
                    tab.leftPane.refresh()
                    tab.rightPane.refresh()
                    appState.statusMessage = "Moved \(sourceURL.lastPathComponent) to \(destination.lastPathComponent)"
                }
            }
        }
        return true
    }
}
