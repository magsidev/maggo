import SwiftUI
import MaggoCore

@main
struct MaggoApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup("Maggo") {
            MainView(appState: appState)
                .frame(minWidth: 800, minHeight: 500)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            // File Menu Commands
            CommandGroup(replacing: .newItem) {
                Button("New Tab") {
                    appState.openNewTab()
                }
                .keyboardShortcut("t", modifiers: .command)

                Button("New Folder…") {
                    appState.newFolderPromptLocation = appState.activePane.currentURL
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])

                Button("Close Tab") {
                    appState.closeActiveTab()
                }
                .keyboardShortcut("w", modifiers: .command)
            }

            // Edit Menu Commands
            CommandGroup(replacing: .undoRedo) {
                Button("Undo File Operation") {
                    appState.triggerUndo()
                }
                .keyboardShortcut("z", modifiers: .command)
                .disabled(!FileOperationEngine.shared.canUndo)
            }

            CommandGroup(replacing: .pasteboard) {
                Button("Cut") {
                    appState.cutSelected()
                }
                .keyboardShortcut("x", modifiers: .command)
                .disabled(appState.activePane.selectedURLs.isEmpty)

                Button("Copy") {
                    appState.copySelected()
                }
                .keyboardShortcut("c", modifiers: .command)
                .disabled(appState.activePane.selectedURLs.isEmpty)

                Button("Paste") {
                    appState.paste()
                }
                .keyboardShortcut("v", modifiers: .command)
                .disabled(!PasteboardService.shared.hasFileURLs())

                Divider()

                Button("Select All") {
                    appState.activePane.selectAll()
                }
                .keyboardShortcut("a", modifiers: .command)
            }

            // Custom File Operations Commands
            CommandMenu("Actions") {
                Button("Move To…") {
                    appState.triggerMoveTo()
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])
                .disabled(appState.activePane.selectedURLs.isEmpty)

                Button("Copy To…") {
                    appState.triggerCopyTo()
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .disabled(appState.activePane.selectedURLs.isEmpty)

                Button("Duplicate") {
                    appState.duplicateSelected()
                }
                .keyboardShortcut("d", modifiers: .command)
                .disabled(appState.activePane.selectedURLs.isEmpty)

                Divider()

                Button("Move to Trash") {
                    appState.deleteSelected()
                }
                .keyboardShortcut(.delete, modifiers: .command)
                .disabled(appState.activePane.selectedURLs.isEmpty)
            }

            // View Menu Commands
            CommandGroup(after: .toolbar) {
                Button("Toggle Split View") {
                    appState.activeTab.toggleSplitView()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])

                Button("Refresh") {
                    appState.activePane.refresh()
                    if appState.activeTab.isSplitView {
                        appState.activeTab.inactivePane.refresh()
                    }
                }
                .keyboardShortcut("r", modifiers: .command)

                Toggle("Show Hidden Files", isOn: Binding(
                    get: { appState.activePane.showHiddenFiles },
                    set: { newValue in
                        appState.activePane.showHiddenFiles = newValue
                        appState.activePane.refresh()
                    }
                ))
                .keyboardShortcut(".", modifiers: [.command, .shift])
            }
        }
    }
}
