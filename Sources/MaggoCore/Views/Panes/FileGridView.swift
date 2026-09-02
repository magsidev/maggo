import SwiftUI
import AppKit

public struct FileGridView: View {
    @Bindable var pane: PaneModel
    @Bindable var appState: AppState

    public init(pane: PaneModel, appState: AppState) {
        self.pane = pane
        self.appState = appState
    }

    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 16)
    ]

    public var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(pane.filteredItems) { item in
                    let isSelected = pane.selectedURLs.contains(item.url)

                    VStack(spacing: 6) {
                        Image(nsImage: item.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 48, height: 48)

                        Text(item.name)
                            .font(.system(size: 11))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .foregroundColor(isSelected ? .white : (item.isHidden ? .secondary : .primary))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(isSelected ? Color.accentColor : Color.clear)
                            )
                    }
                    .padding(6)
                    .contentShape(Rectangle())
                    .draggable(item.url)
                    .dropDestination(for: URL.self) { droppedURLs, _ in
                        if item.isDirectory && !item.isPackage {
                            handleDropIntoFolder(urls: droppedURLs, destinationFolder: item.url)
                            return true
                        }
                        return false
                    }
                    .simultaneousGesture(
                        TapGesture(count: 2).onEnded {
                            appState.openItem(item)
                        }
                    )
                    .simultaneousGesture(
                        TapGesture(count: 1).onEnded {
                            if NSEvent.modifierFlags.contains(.command) {
                                if isSelected {
                                    pane.selectedURLs.remove(item.url)
                                } else {
                                    pane.selectedURLs.insert(item.url)
                                }
                            } else {
                                pane.selectedURLs = [item.url]
                            }
                        }
                    )
                    .contextMenu {
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
                        Divider()
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
            }
            .padding(16)
        }
        .dropDestination(for: URL.self) { droppedURLs, _ in
            handleDropIntoCurrentDirectory(urls: droppedURLs)
            return true
        }
    }

    private func handleDropIntoCurrentDirectory(urls: [URL]) {
        guard !urls.isEmpty else { return }
        let destination = pane.currentURL
        Task { @MainActor in
            do {
                _ = try FileOperationEngine.shared.copyItems(urls: urls, to: destination)
                pane.refresh()
                appState.statusMessage = "Added \(urls.count) item(s) to \(destination.lastPathComponent)"
            } catch {
                appState.statusMessage = "Drop error: \(error.localizedDescription)"
            }
        }
    }

    private func handleDropIntoFolder(urls: [URL], destinationFolder: URL) {
        guard !urls.isEmpty else { return }
        Task { @MainActor in
            do {
                _ = try FileOperationEngine.shared.moveItems(urls: urls, to: destinationFolder)
                pane.refresh()
                appState.statusMessage = "Moved \(urls.count) item(s) into \(destinationFolder.lastPathComponent)"
            } catch {
                appState.statusMessage = "Drop error: \(error.localizedDescription)"
            }
        }
    }
}
