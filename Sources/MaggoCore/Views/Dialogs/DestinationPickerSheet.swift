import SwiftUI

public struct DestinationPickerSheet: View {
    let config: DestinationPickerConfig
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var searchText: String = ""
    @State private var selectedDestination: URL?

    public init(config: DestinationPickerConfig, appState: AppState) {
        self.config = config
        self.appState = appState
    }

    private var recentDestinations: [URL] {
        RecentLocationsManager.shared.getRecentDestinations()
    }

    private var favoriteDestinations: [FavoriteLocation] {
        appState.favorites
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Text("\(config.operation.rawValue) To…")
                    .font(.headline)
                Spacer()
                Text("\(config.sourceURLs.count) item(s) selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search recent or favorite folders…", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))

            // Destinations List
            List(selection: $selectedDestination) {
                // Favorites
                Section("Favorites") {
                    ForEach(filteredFavorites) { fav in
                        HStack {
                            Image(systemName: fav.iconName)
                                .foregroundColor(.accentColor)
                            Text(fav.name)
                            Spacer()
                            Text(fav.path)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .tag(fav.url)
                    }
                }

                // Recent Destinations
                if !recentDestinations.isEmpty {
                    Section("Recent Destinations") {
                        ForEach(filteredRecents, id: \.path) { url in
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.secondary)
                                Text(url.lastPathComponent)
                                Spacer()
                                Text(url.path)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .tag(url)
                        }
                    }
                }
            }
            .listStyle(.inset)
            .frame(height: 220)

            // Bottom Buttons: Browse / Cancel / Action
            HStack {
                Button("Browse Other…") {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = false
                    panel.prompt = "Select Destination"
                    if panel.runModal() == .OK, let url = panel.url {
                        selectedDestination = url
                    }
                }

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button(config.operation.rawValue) {
                    performOperation()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(selectedDestination == nil)
            }
        }
        .padding(18)
        .frame(width: 480)
    }

    private var filteredFavorites: [FavoriteLocation] {
        if searchText.isEmpty { return favoriteDestinations }
        return favoriteDestinations.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.path.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredRecents: [URL] {
        if searchText.isEmpty { return recentDestinations }
        return recentDestinations.filter {
            $0.lastPathComponent.localizedCaseInsensitiveContains(searchText) ||
            $0.path.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func performOperation() {
        guard let dest = selectedDestination else { return }

        do {
            switch config.operation {
            case .move:
                _ = try FileOperationEngine.shared.moveItems(urls: config.sourceURLs, to: dest)
                appState.statusMessage = "Moved \(config.sourceURLs.count) item(s) to \(dest.lastPathComponent)"
            case .copy:
                _ = try FileOperationEngine.shared.copyItems(urls: config.sourceURLs, to: dest)
                appState.statusMessage = "Copied \(config.sourceURLs.count) item(s) to \(dest.lastPathComponent)"
            default:
                break
            }

            RecentLocationsManager.shared.recordDestination(dest)
            appState.activePane.refresh()
            if appState.activeTab.isSplitView {
                appState.activeTab.inactivePane.refresh()
            }
            dismiss()
        } catch {
            appState.statusMessage = "Operation failed: \(error.localizedDescription)"
            dismiss()
        }
    }
}
