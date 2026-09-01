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
                let isSelected = pane.selectedURLs.contains(item.url)

                HStack(spacing: 8) {
                    fileIconView(for: item)
                        .frame(width: 16, height: 16)

                    Text(item.name)
                        .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                        .lineLimit(1)
                        .foregroundColor(isSelected ? Color.maggoBlue : (item.isHidden ? .secondary : .primary))
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
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "64748B"))
            }
            .width(min: 120, ideal: 140, max: 180)

            TableColumn("Size") { item in
                let sizeStr = pane.displaySize(for: item)
                Text(sizeStr)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "64748B"))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(min: 75, ideal: 85, max: 110)

            TableColumn("Kind", value: \.kindDescription) { item in
                Text(item.kindDescription)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "64748B"))
            }
            .width(min: 90, ideal: 110, max: 160)
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
    private func fileIconView(for item: FileItem) -> some View {
        if item.isDirectory && !item.isPackage {
            Image(systemName: "folder.fill")
                .foregroundColor(Color.iconFolder)
        } else {
            let ext = item.url.pathExtension.lowercased()
            switch ext {
            case "pdf":
                Image(systemName: "doc.text.fill")
                    .foregroundColor(Color.iconPdf)
            case "zip", "tar", "gz", "dmg", "pkg":
                Image(systemName: "archivebox.fill")
                    .foregroundColor(Color.iconZip)
            case "xls", "xlsx", "csv":
                Image(systemName: "tablecells.fill")
                    .foregroundColor(Color.iconSheet)
            case "sh", "bash", "zsh", "command":
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.iconScript)
            default:
                Image(nsImage: item.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
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
