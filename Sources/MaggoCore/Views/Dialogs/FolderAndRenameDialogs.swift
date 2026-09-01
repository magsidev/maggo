import SwiftUI

public struct NewFolderSheet: View {
    let parentURL: URL
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var folderName: String = "New Folder"

    public init(parentURL: URL, appState: AppState) {
        self.parentURL = parentURL
        self.appState = appState
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Folder")
                .font(.headline)

            TextField("Folder Name", text: $folderName)
                .textFieldStyle(.roundedBorder)

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Create") {
                    createFolder()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(folderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 320)
    }

    private func createFolder() {
        let name = folderName.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            let newURL = try FileOperationEngine.shared.createFolder(at: parentURL, name: name)
            appState.statusMessage = "Created folder: \(newURL.lastPathComponent)"
            appState.activePane.refresh()
            if appState.activeTab.isSplitView {
                appState.activeTab.inactivePane.refresh()
            }
            dismiss()
        } catch {
            appState.statusMessage = "Failed to create folder: \(error.localizedDescription)"
            dismiss()
        }
    }
}

public struct RenameSheet: View {
    let targetURL: URL
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var newName: String = ""

    public init(targetURL: URL, appState: AppState) {
        self.targetURL = targetURL
        self.appState = appState
        _newName = State(initialValue: targetURL.lastPathComponent)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rename Item")
                .font(.headline)

            TextField("Item Name", text: $newName)
                .textFieldStyle(.roundedBorder)

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Rename") {
                    renameItem()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || newName == targetURL.lastPathComponent)
            }
        }
        .padding(20)
        .frame(width: 340)
    }

    private func renameItem() {
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            let resultingURL = try FileOperationEngine.shared.renameItem(at: targetURL, newName: name)
            appState.statusMessage = "Renamed to \(resultingURL.lastPathComponent)"
            appState.activePane.refresh()
            if appState.activeTab.isSplitView {
                appState.activeTab.inactivePane.refresh()
            }
            dismiss()
        } catch {
            appState.statusMessage = "Rename failed: \(error.localizedDescription)"
            dismiss()
        }
    }
}
