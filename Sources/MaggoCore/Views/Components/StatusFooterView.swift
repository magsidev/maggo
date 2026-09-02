import SwiftUI

public struct StatusFooterView: View {
    @Bindable var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    private var activePane: PaneModel {
        appState.activePane
    }

    private var selectionText: String {
        let selected = activePane.selectedItems
        if selected.isEmpty {
            return "\(activePane.filteredItems.count) items"
        }
        let totalBytes = selected.reduce(0) { $0 + $1.fileSize }
        let formatted = ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
        return "\(selected.count) selected (\(formatted))"
    }

    private var volumeCapacityText: String {
        if let vol = appState.volumes.first {
            let freeStr = ByteCountFormatter.string(fromByteCount: vol.availableCapacity, countStyle: .file)
            return "\(vol.name): \(freeStr) free"
        }
        return ""
    }

    public var body: some View {
        HStack(spacing: 12) {
            // Left: Green checkmark + Status
            HStack(spacing: 5) {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.maggoGreenText)

                Text(appState.statusMessage.isEmpty ? "Ready" : appState.statusMessage)
                    .font(.system(size: 12))
                    .foregroundColor(Color.secondary)
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
                            .font(.system(size: 11))
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(Color.maggoBlue)
            }

            // Right: Selection summary | Volume capacity
            HStack(spacing: 8) {
                Text(selectionText)
                    .font(.system(size: 12))
                    .foregroundColor(Color.secondary)

                if !volumeCapacityText.isEmpty {
                    Text("|")
                        .font(.system(size: 12))
                        .foregroundColor(Color.secondary.opacity(0.4))

                    Text(volumeCapacityText)
                        .font(.system(size: 12))
                        .foregroundColor(Color.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color.maggoFooterBg)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.maggoBorder),
            alignment: .top
        )
    }
}
