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
                    FileTypeBadge(item: item)

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
            .width(min: 200, ideal: 280)

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
        .contextMenu {
            Button("New Folder (⌘⇧N)") {
                appState.newFolderPromptLocation = pane.currentURL
            }
            Divider()
            Button("Paste (⌘V)") {
                appState.paste()
            }
            .disabled(!PasteboardService.shared.hasFileURLs())
            Divider()
            Button("Select All (⌘A)") {
                pane.selectAll()
            }
            Button("Refresh (⌘R)") {
                pane.refresh()
            }
        }
    }

    @ViewBuilder
    private func contextMenu(for item: FileItem) -> some View {
        Button("Open") {
            appState.openItem(item)
        }

        Button("Copy (⌘C)") {
            pane.selectedURLs = [item.url]
            appState.copySelected()
        }

        Button("Cut (⌘X)") {
            pane.selectedURLs = [item.url]
            appState.cutSelected()
        }

        Button("Paste (⌘V)") {
            appState.paste()
        }
        .disabled(!PasteboardService.shared.hasFileURLs())

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

public struct FileTypeBadge: View {
    public let item: FileItem

    public init(item: FileItem) {
        self.item = item
    }

    public var body: some View {
        let text = item.typeBadgeText
        let colors = badgeColors(for: item)

        Text(text)
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundColor(colors.fg)
            .padding(.horizontal, 4)
            .padding(.vertical, 1.5)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(colors.bg)
            )
    }

    private func badgeColors(for item: FileItem) -> (bg: Color, fg: Color) {
        if item.isDirectory && !item.isPackage {
            return (Color.blue.opacity(0.14), Color.blue)
        }
        let ext = item.url.pathExtension.lowercased()
        switch ext {
        case "pdf":
            return (Color.red.opacity(0.14), Color.red)
        case "zip", "tar", "gz", "dmg", "pkg":
            return (Color.orange.opacity(0.14), Color.orange)
        case "sh", "bash", "zsh", "command":
            return (Color.gray.opacity(0.18), Color.primary)
        case "xls", "xlsx", "csv":
            return (Color.green.opacity(0.14), Color.green)
        case "doc", "docx", "txt", "md":
            return (Color.indigo.opacity(0.14), Color.indigo)
        case "jpg", "jpeg", "png", "heic", "gif", "webp":
            return (Color.purple.opacity(0.14), Color.purple)
        default:
            return (Color.secondary.opacity(0.12), Color.secondary)
        }
    }
}
