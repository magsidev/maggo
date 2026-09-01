import SwiftUI

public struct AppToolbar: View {
    @Bindable var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        HStack(spacing: 8) {
            // Split View Toggle
            ToolbarPillButton(
                title: "Split View",
                icon: "square.split.2x1",
                shortcut: "⌘⇧S",
                isActive: appState.activeTab.isSplitView
            ) {
                appState.activeTab.toggleSplitView()
            }
            .help("Toggle Split View (⌘⇧S)")

            Divider()
                .frame(height: 16)

            // Move To
            ToolbarPillButton(
                title: "Move To…",
                icon: "arrow.right.doc.on.clipboard",
                shortcut: "⌘⇧M",
                isDisabled: appState.activePane.selectedURLs.isEmpty
            ) {
                appState.triggerMoveTo()
            }
            .help("Move To… (⌘⇧M)")

            // Copy To
            ToolbarPillButton(
                title: "Copy To…",
                icon: "doc.on.doc",
                shortcut: "⌘⇧C",
                isDisabled: appState.activePane.selectedURLs.isEmpty
            ) {
                appState.triggerCopyTo()
            }
            .help("Copy To… (⌘⇧C)")

            // Copy
            ToolbarPillButton(
                title: "Copy",
                icon: "doc.on.clipboard",
                shortcut: "⌘C",
                isDisabled: appState.activePane.selectedURLs.isEmpty
            ) {
                appState.copySelected()
            }
            .help("Copy (⌘C)")

            // Paste
            ToolbarPillButton(
                title: "Paste",
                icon: "clipboard",
                shortcut: "⌘V",
                isDisabled: !PasteboardService.shared.hasFileURLs()
            ) {
                appState.paste()
            }
            .help("Paste (⌘V)")

            // New Folder icon button
            Button {
                appState.newFolderPromptLocation = appState.activePane.currentURL
            } label: {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 13))
                    .padding(5)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help("New Folder (⌘⇧N)")

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
                .frame(width: 155)

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

public struct ToolbarPillButton: View {
    public let title: String
    public let icon: String
    public let shortcut: String
    public var isActive: Bool = false
    public var isDisabled: Bool = false
    public let action: () -> Void

    public init(
        title: String,
        icon: String,
        shortcut: String,
        isActive: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.shortcut = shortcut
        self.isActive = isActive
        self.isDisabled = isDisabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                Text(shortcut)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(Color.secondary.opacity(0.12))
                    .cornerRadius(3)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isActive ? Color.accentColor.opacity(0.15) : Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isActive ? Color.accentColor.opacity(0.5) : Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.45 : 1.0)
    }
}
