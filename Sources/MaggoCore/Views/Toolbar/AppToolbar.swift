import SwiftUI

public struct AppToolbar: View {
    @Bindable var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        HStack(spacing: 12) {
            // New Tab Button
            Button {
                appState.openNewTab()
            } label: {
                Image(systemName: "plus")
            }
            .help("New Tab (⌘T)")
            .keyboardShortcut("t", modifiers: .command)

            // Split View Toggle
            Button {
                appState.activeTab.toggleSplitView()
            } label: {
                Image(systemName: appState.activeTab.isSplitView ? "square.split.2x1.fill" : "square.split.2x1")
            }
            .help("Toggle Split View (⌘⇧S)")
            .keyboardShortcut("s", modifiers: [.command, .shift])

            Divider()
                .frame(height: 18)

            // File Actions
            Button {
                appState.newFolderPromptLocation = appState.activePane.currentURL
            } label: {
                Image(systemName: "folder.badge.plus")
            }
            .help("New Folder (⌘⇧N)")
            .keyboardShortcut("n", modifiers: [.command, .shift])

            Button {
                appState.triggerMoveTo()
            } label: {
                Image(systemName: "arrow.right.doc.on.clipboard")
            }
            .help("Move To… (⌘⇧M)")
            .disabled(appState.activePane.selectedURLs.isEmpty)
            .keyboardShortcut("m", modifiers: [.command, .shift])

            Button {
                appState.triggerCopyTo()
            } label: {
                Image(systemName: "doc.on.doc")
            }
            .help("Copy To… (⌘⇧C)")
            .disabled(appState.activePane.selectedURLs.isEmpty)
            .keyboardShortcut("c", modifiers: [.command, .shift])

            Button {
                appState.deleteSelected()
            } label: {
                Image(systemName: "trash")
            }
            .help("Move to Trash (⌘⌫)")
            .disabled(appState.activePane.selectedURLs.isEmpty)
            .keyboardShortcut(.delete, modifiers: .command)

            Spacer()

            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.caption)
                TextField("Search current folder…", text: Binding(
                    get: { appState.activePane.searchQuery },
                    set: { appState.activePane.searchQuery = $0 }
                ))
                    .textFieldStyle(.plain)
                    .frame(width: 150)
                if !appState.activePane.searchQuery.isEmpty {
                    Button {
                        appState.activePane.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
    }
}
