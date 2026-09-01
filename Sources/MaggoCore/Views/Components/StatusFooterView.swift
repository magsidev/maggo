import SwiftUI

public struct StatusFooterView: View {
    @Bindable var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    private var activePane: PaneModel {
        appState.activePane
    }

    private var selectedSummary: String {
        let selected = activePane.selectedItems
        if selected.isEmpty {
            return "\(activePane.items.count) item\(activePane.items.count == 1 ? "" : "s")"
        }
        let totalBytes = selected.reduce(0) { $0 + $1.fileSize }
        let formatted = ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
        return "\(selected.count) selected (\(formatted))"
    }

    public var body: some View {
        HStack(spacing: 16) {
            // Status message
            if !appState.statusMessage.isEmpty {
                Text(appState.statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Undo indicator if available
            if FileOperationEngine.shared.canUndo {
                Button {
                    appState.triggerUndo()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.caption2)
                        Text("Undo (⌘Z)")
                            .font(.caption)
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            }

            Divider()
                .frame(height: 12)

            // Items count & selection summary
            Text(selectedSummary)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
