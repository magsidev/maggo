import SwiftUI

public struct PaneContainerView: View {
    @Bindable var tab: TabModel
    @Bindable var appState: AppState

    public init(tab: TabModel, appState: AppState) {
        self.tab = tab
        self.appState = appState
    }

    public var body: some View {
        Group {
            if tab.isSplitView {
                HSplitView {
                    singlePaneView(pane: tab.leftPane, side: .left)
                        .frame(minWidth: 250)

                    singlePaneView(pane: tab.rightPane, side: .right)
                        .frame(minWidth: 250)
                }
            } else {
                singlePaneView(pane: tab.leftPane, side: .left)
            }
        }
    }

    @ViewBuilder
    private func singlePaneView(pane: PaneModel, side: ActivePaneSide) -> some View {
        @Bindable var boundPane = pane
        let isFocused = (tab.activePaneSide == side)

        VStack(spacing: 0) {
            // Pane Header: Breadcrumb & View Toggle
            HStack(spacing: 8) {
                // Navigation history buttons
                HStack(spacing: 2) {
                    Button {
                        pane.goBack()
                    } label: {
                        Image(systemName: "chevron.backward")
                    }
                    .disabled(!pane.canGoBack)
                    .buttonStyle(.plain)

                    Button {
                        pane.goForward()
                    } label: {
                        Image(systemName: "chevron.forward")
                    }
                    .disabled(!pane.canGoForward)
                    .buttonStyle(.plain)

                    Button {
                        pane.goUp()
                    } label: {
                        Image(systemName: "arrow.up")
                    }
                    .disabled(!pane.canGoUp)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 4)

                // Breadcrumbs
                BreadcrumbBar(pane: pane)

                // View Mode Picker (List vs Grid)
                Picker("View", selection: $boundPane.viewMode) {
                    Image(systemName: "list.bullet").tag(ViewMode.detailsList)
                    Image(systemName: "square.grid.2x2").tag(ViewMode.grid)
                }
                .pickerStyle(.segmented)
                .frame(width: 65)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(nsColor: .windowBackgroundColor))

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
        }
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(tab.isSplitView && isFocused ? Color.accentColor.opacity(0.4) : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            tab.activePaneSide = side
        }
    }
}
