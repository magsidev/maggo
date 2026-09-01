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
        let count = activePane.items.count
        let selected = activePane.selectedItems

        if selected.isEmpty {
            return "\(count) item\(count == 1 ? "" : "s")"
        }

        let totalBytes = selected.reduce(0) { $0 + $1.fileSize }
        let formatted = ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
        return "\(count) items · \(selected.count) selected (\(formatted))"
    }

    public var body: some View {
        HStack(spacing: 12) {
            // Left Status
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 7, height: 7)

                Text(selectedSummary + " · Swift 6 Native Engine")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if !appState.statusMessage.isEmpty && appState.statusMessage != "Ready" {
                    Text("·  " + appState.statusMessage)
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
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

            // Right Volume Available Capacity
            if let mainVol = appState.volumes.first {
                Text("\(mainVol.name): \(mainVol.formattedAvailable)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
