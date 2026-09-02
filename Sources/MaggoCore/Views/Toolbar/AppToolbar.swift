import SwiftUI

public struct AppToolbar: View {
    @Bindable var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        HStack(spacing: 8) {
            // New Tab button [+]
            Button {
                appState.openNewTab()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.primary)
                    .frame(width: 28, height: 26)
                    .background(Color.maggoButtonBg)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.maggoBorder, lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.03), radius: 1, y: 1)
            }
            .buttonStyle(.plain)
            .help("New Tab (⌘T)")

            // Split View Toggle [◫]
            Button {
                appState.activeTab.toggleSplitView()
            } label: {
                Image(systemName: "square.split.2x1")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(appState.activeTab.isSplitView ? .maggoBlue : .primary)
                    .frame(width: 32, height: 26)
                    .background(appState.activeTab.isSplitView ? Color.maggoSidebarActive : Color.maggoButtonBg)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(appState.activeTab.isSplitView ? Color.maggoBlue.opacity(0.6) : Color.maggoBorder, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.03), radius: 1, y: 1)
            }
            .buttonStyle(.plain)
            .help("Toggle Split View (⌘⇧S)")

            // New Folder button [📁]
            Button {
                appState.newFolderPromptLocation = appState.activePane.currentURL
            } label: {
                Image(systemName: "folder")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 30, height: 26)
                    .background(Color.maggoButtonBg)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.maggoBorder, lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.03), radius: 1, y: 1)
            }
            .buttonStyle(.plain)
            .help("New Folder (⌘⇧N)")

            // Move To… [📄↗ Move To…] (Green highlight button)
            Button {
                appState.triggerMoveTo()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.right.doc.on.clipboard")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Move To…")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(Color.maggoGreenText)
                .padding(.horizontal, 10)
                .frame(height: 26)
                .background(Color.maggoGreenBg)
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.maggoGreenBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(!appState.hasSelection)
            .opacity(appState.hasSelection ? 1.0 : 0.45)
            .help("Move To… (⌘⇧M)")

            // Copy To… [📄📄 Copy To…] (Adaptive button with border)
            Button {
                appState.triggerCopyTo()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 11, weight: .medium))
                    Text("Copy To…")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 10)
                .frame(height: 26)
                .background(Color.maggoButtonBg)
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.maggoBorder, lineWidth: 1))
                .shadow(color: Color.black.opacity(0.03), radius: 1, y: 1)
            }
            .buttonStyle(.plain)
            .disabled(!appState.hasSelection)
            .opacity(appState.hasSelection ? 1.0 : 0.45)
            .help("Copy To… (⌘⇧C)")

            // Trash button [🗑]
            Button {
                appState.deleteSelected()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(width: 28, height: 26)
                    .background(Color.maggoButtonBg)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.maggoBorder, lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.03), radius: 1, y: 1)
            }
            .buttonStyle(.plain)
            .disabled(!appState.hasSelection)
            .opacity(appState.hasSelection ? 1.0 : 0.45)
            .help("Move to Trash (⌘⌫)")

            Spacer()

            // Search folder...
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 11))
                TextField("Search folder…", text: Binding(
                    get: { appState.activePane.searchQuery },
                    set: { appState.activePane.searchQuery = $0 }
                ))
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .frame(width: 150)

                if !appState.activePane.searchQuery.isEmpty {
                    Button {
                        appState.activePane.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.caption2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Color.maggoButtonBg)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.maggoBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.02), radius: 1, y: 1)
        }
    }
}
