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
                        .frame(minWidth: 320)

                    singlePaneView(pane: tab.rightPane, side: .right)
                        .frame(minWidth: 320)
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
            // Pane Top Bar: < > ↑ + Breadcrumbs + [ ≡ ⊞ ]
            HStack(spacing: 8) {
                // Navigation buttons
                HStack(spacing: 2) {
                    Button {
                        pane.goBack()
                    } label: {
                        Text("‹")
                            .font(.system(size: 16, weight: .bold))
                            .frame(width: 20, height: 22)
                    }
                    .disabled(!pane.canGoBack)
                    .buttonStyle(.plain)

                    Button {
                        pane.goForward()
                    } label: {
                        Text("›")
                            .font(.system(size: 16, weight: .bold))
                            .frame(width: 20, height: 22)
                    }
                    .disabled(!pane.canGoForward)
                    .buttonStyle(.plain)

                    Button {
                        pane.goUp()
                    } label: {
                        Text("↑")
                            .font(.system(size: 13, weight: .bold))
                            .frame(width: 20, height: 22)
                    }
                    .disabled(!pane.canGoUp)
                    .buttonStyle(.plain)
                }
                .foregroundColor(.secondary)

                // Breadcrumb capsule
                BreadcrumbBar(pane: pane)

                // View Mode Picker [ ≡ ⊞ ]
                Picker("View", selection: $boundPane.viewMode) {
                    Image(systemName: "list.bullet").tag(ViewMode.detailsList)
                    Image(systemName: "square.grid.2x2").tag(ViewMode.grid)
                }
                .pickerStyle(.segmented)
                .frame(width: 62)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.maggoSubBarBg)

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
                            .foregroundColor(.secondary.opacity(0.5))
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
        .background(Color.maggoPaneBg)
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(
                    tab.isSplitView && isFocused ? Color.maggoFocusedBlue : Color.maggoBorder,
                    lineWidth: tab.isSplitView && isFocused ? 2 : 1
                )
        )
        .onTapGesture {
            tab.activePaneSide = side
        }
    }
}
