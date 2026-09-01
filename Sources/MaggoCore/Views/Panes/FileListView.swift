import SwiftUI
import AppKit

public struct FileListView: View {
    @Bindable var pane: PaneModel
    @Bindable var appState: AppState

    public init(pane: PaneModel, appState: AppState) {
        self.pane = pane
        self.appState = appState
    }

    public var body: some View {
        Table(
            of: FileItem.self,
            selection: $pane.selectedURLs,
            sortOrder: Binding(
                get: {
                    let order: SortOrder = pane.sortOption.ascending ? .forward : .reverse
                    switch pane.sortOption.field {
                    case .dateModified:
                        return [KeyPathComparator(\FileItem.dateModified, order: order)]
                    case .size:
                        return [KeyPathComparator(\FileItem.fileSize, order: order)]
                    case .kind:
                        return [KeyPathComparator(\FileItem.kindDescription, order: order)]
                    default:
                        return [KeyPathComparator(\FileItem.name, order: order)]
                    }
                },
                set: { order in
                    if let first = order.first {
                        pane.sortOption.ascending = (first.order == .forward)
                        if first.keyPath == \FileItem.dateModified {
                            pane.sortOption.field = .dateModified
                        } else if first.keyPath == \FileItem.fileSize {
                            pane.sortOption.field = .size
                        } else if first.keyPath == \FileItem.kindDescription {
                            pane.sortOption.field = .kind
                        } else {
                            pane.sortOption.field = .name
                        }
                    }
                }
            )
        ) {
            TableColumn("Name", value: \.name) { item in
                HStack(spacing: 8) {
                    Image(nsImage: item.icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 18, height: 18)

                    Text(item.name)
                        .lineLimit(1)
                        .foregroundColor(item.isHidden ? .secondary : .primary)
                }
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    appState.openItem(item)
                }
                .contextMenu {
                    contextMenu(for: item)
                }
            }
            .width(min: 180, ideal: 260)

            TableColumn("Date Modified", value: \.dateModified) { item in
                Text(item.formattedDateModified)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .width(min: 120, ideal: 140, max: 180)

            TableColumn("Size") { item in
                let sizeStr = pane.displaySize(for: item)
                Text(sizeStr)
                    .font(.caption)
                    .foregroundColor(sizeStr == "Calculating…" ? .secondary.opacity(0.7) : .secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(min: 80, ideal: 95, max: 120)

            TableColumn("Kind", value: \.kindDescription) { item in
                Text(item.kindDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .width(min: 100, ideal: 130, max: 200)
        } rows: {
            ForEach(pane.filteredItems) { item in
                TableRow(item)
            }
        }
    }

    @ViewBuilder
    private func contextMenu(for item: FileItem) -> some View {
        Button("Open") {
            appState.openItem(item)
        }

        Divider()

        Button("Move To… (⌘⇧M)") {
            pane.selectedURLs = [item.url]
            appState.triggerMoveTo()
        }

        Button("Copy To… (⌘⇧C)") {
            pane.selectedURLs = [item.url]
            appState.triggerCopyTo()
        }

        Button("Duplicate (⌘D)") {
            pane.selectedURLs = [item.url]
            appState.duplicateSelected()
        }

        Button("Rename…") {
            appState.renameItemPromptURL = item.url
        }

        Divider()

        if item.isDirectory && !item.isPackage {
            Button("Add to Favorites") {
                appState.addFavorite(url: item.url)
            }
        }

        Button("Quick Look (Space)") {
            appState.quickLookURL = item.url
        }

        Button("Copy Path (⌘⌥C)") {
            appState.copyPathToClipboard(url: item.url)
        }

        Button("Reveal in Finder (⌘⌥R)") {
            appState.revealInFinder(url: item.url)
        }

        Divider()

        Button("Move to Trash (⌘⌫)", role: .destructive) {
            pane.selectedURLs = [item.url]
            appState.deleteSelected()
        }
    }
}
