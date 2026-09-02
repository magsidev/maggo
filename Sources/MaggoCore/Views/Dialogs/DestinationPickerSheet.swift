import SwiftUI
import AppKit

public struct DestinationPickerSheet: View {
    let config: DestinationPickerConfig
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var currentBrowseURL: URL
    @State private var subfolders: [URL] = []
    @State private var selectedDestination: URL?
    @State private var searchText: String = ""
    @State private var isCreatingFolder: Bool = false
    @State private var newFolderName: String = ""
    @State private var searchResults: [URL] = []

    public init(config: DestinationPickerConfig, appState: AppState) {
        self.config = config
        self.appState = appState
        let initialURL = FileManager.default.homeDirectoryForCurrentUser
        _currentBrowseURL = State(initialValue: initialURL)
        _selectedDestination = State(initialValue: initialURL)
    }

    private var homeURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
    }

    private var quickLocations: [(name: String, icon: String, url: URL)] {
        [
            ("Home", "house.fill", homeURL),
            ("Applications", "app.badge", URL(fileURLWithPath: "/Applications")),
            ("Documents", "doc.text", homeURL.appendingPathComponent("Documents")),
            ("Downloads", "arrow.down.circle", homeURL.appendingPathComponent("Downloads")),
            ("Desktop", "display", homeURL.appendingPathComponent("Desktop")),
            ("Projects", "folder", homeURL.appendingPathComponent("Projects")),
            ("Pictures", "photo", homeURL.appendingPathComponent("Pictures"))
        ]
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(config.operation.rawValue) To…")
                        .font(.headline)
                        .foregroundColor(Color(hex: "0F172A"))
                    Text("\(config.sourceURLs.count) item(s) selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    isCreatingFolder.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "folder.badge.plus")
                        Text("New Folder")
                    }
                    .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search folder name…", text: $searchText)
                    .textFieldStyle(.plain)
                    .onChange(of: searchText) { _, newValue in
                        performSearch(query: newValue)
                    }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(7)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(7)
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.secondary.opacity(0.2)))
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            // Inline New Folder Input
            if isCreatingFolder {
                HStack(spacing: 8) {
                    Image(systemName: "folder.fill")
                        .foregroundColor(.maggoBlue)
                    TextField("Folder name", text: $newFolderName)
                        .textFieldStyle(.roundedBorder)
                    Button("Create") {
                        createNewFolder()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button("Cancel") {
                        isCreatingFolder = false
                        newFolderName = ""
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }

            Divider()

            // Main Two-Column Deep Browser
            HStack(spacing: 0) {
                // Left Column: Quick Favorites & Volumes
                VStack(alignment: .leading, spacing: 4) {
                    Text("PLACES")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "94A3B8"))
                        .padding(.horizontal, 8)
                        .padding(.top, 8)

                    ForEach(quickLocations, id: \.name) { loc in
                        let isSelected = currentBrowseURL.path == loc.url.path
                        Button {
                            browseTo(url: loc.url)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: loc.icon)
                                    .font(.system(size: 12))
                                    .foregroundColor(isSelected ? .white : .maggoBlue)
                                Text(loc.name)
                                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                                    .foregroundColor(isSelected ? .white : Color(hex: "334155"))
                                Spacer()
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(isSelected ? Color.maggoBlue : Color.clear)
                            .cornerRadius(5)
                        }
                        .buttonStyle(.plain)
                    }

                    if !appState.volumes.isEmpty {
                        Text("VOLUMES")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(hex: "94A3B8"))
                            .padding(.horizontal, 8)
                            .padding(.top, 6)

                        ForEach(appState.volumes) { vol in
                            let isSelected = currentBrowseURL.path == vol.url.path
                            Button {
                                browseTo(url: vol.url)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "internaldrive.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(isSelected ? .white : Color(hex: "64748B"))
                                    Text(vol.name)
                                        .font(.system(size: 12))
                                        .foregroundColor(isSelected ? .white : Color(hex: "334155"))
                                        .lineLimit(1)
                                    Spacer()
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(isSelected ? Color.maggoBlue : Color.clear)
                                .cornerRadius(5)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer()
                }
                .frame(width: 140)
                .padding(6)
                .background(Color(hex: "F8FAFC"))

                Divider()

                // Right Column: Deep Directory Browser & Subfolders
                VStack(spacing: 0) {
                    if !searchText.isEmpty {
                        // Search Results List
                        List(selection: $selectedDestination) {
                            if searchResults.isEmpty {
                                Text("No matching folders found")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(searchResults, id: \.path) { url in
                                    HStack {
                                        Image(systemName: "folder.fill")
                                            .foregroundColor(.maggoBlue)
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(url.lastPathComponent)
                                                .font(.system(size: 12, weight: .medium))
                                            Text(url.path)
                                                .font(.system(size: 9))
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                    }
                                    .tag(url)
                                }
                            }
                        }
                        .listStyle(.inset)
                    } else {
                        // Breadcrumbs Path Header
                        HStack(spacing: 6) {
                            Button {
                                let parent = currentBrowseURL.deletingLastPathComponent()
                                if parent.path != currentBrowseURL.path {
                                    browseTo(url: parent)
                                }
                            } label: {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 11, weight: .bold))
                                    .frame(width: 20, height: 20)
                            }
                            .buttonStyle(.plain)
                            .disabled(currentBrowseURL.path == "/")

                            Text(currentBrowseURL.path.replacingOccurrences(of: homeURL.path, with: "~"))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(hex: "475569"))
                                .lineLimit(1)

                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(hex: "F1F5F9"))

                        Divider()

                        // Subfolders List
                        List(selection: $selectedDestination) {
                            // Option to pick current browse directory itself
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("This folder (\(currentBrowseURL.lastPathComponent))")
                                    .font(.system(size: 12, weight: .semibold))
                                Spacer()
                            }
                            .tag(currentBrowseURL)

                            if subfolders.isEmpty {
                                Text("No subfolders in this directory")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 8)
                            } else {
                                ForEach(subfolders, id: \.path) { folder in
                                    HStack {
                                        Image(systemName: "folder.fill")
                                            .foregroundColor(.maggoBlue)
                                        Text(folder.lastPathComponent)
                                            .font(.system(size: 12))
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 10))
                                            .foregroundColor(Color(hex: "94A3B8"))
                                    }
                                    .contentShape(Rectangle())
                                    .tag(folder)
                                    .simultaneousGesture(
                                        TapGesture(count: 2).onEnded {
                                            browseTo(url: folder)
                                        }
                                    )
                                }
                            }
                        }
                        .listStyle(.inset)
                    }
                }
            }
            .frame(height: 240)

            Divider()

            // Footer with Selected Path Confirmation & Actions
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Destination:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text((selectedDestination ?? currentBrowseURL).path.replacingOccurrences(of: homeURL.path, with: "~"))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "0F172A"))
                        .lineLimit(1)
                }

                Spacer()

                Button("Browse Other…") {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = false
                    panel.prompt = "Select Destination"
                    if panel.runModal() == .OK, let url = panel.url {
                        browseTo(url: url)
                        selectedDestination = url
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button(config.operation.rawValue) {
                    performOperation()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(hex: "F8FAFC"))
        }
        .frame(width: 540, height: 390)
        .onAppear {
            loadSubfolders(for: currentBrowseURL)
        }
    }

    private func browseTo(url: URL) {
        currentBrowseURL = url
        selectedDestination = url
        loadSubfolders(for: url)
    }

    private func loadSubfolders(for url: URL) {
        let fm = FileManager.default
        do {
            let contents = try fm.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .isPackageKey],
                options: [.skipsHiddenFiles]
            )
            self.subfolders = contents.filter { itemURL in
                var isDir: ObjCBool = false
                return fm.fileExists(atPath: itemURL.path, isDirectory: &isDir) && isDir.boolValue && !itemURL.pathExtension.elementsEqual("app")
            }.sorted { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }
        } catch {
            self.subfolders = []
        }
    }

    private func createNewFolder() {
        let trimmed = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let target = currentBrowseURL.appendingPathComponent(trimmed)
        do {
            try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
            newFolderName = ""
            isCreatingFolder = false
            loadSubfolders(for: currentBrowseURL)
            selectedDestination = target
        } catch {
            appState.statusMessage = "Could not create folder: \(error.localizedDescription)"
        }
    }

    private func performSearch(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else {
            searchResults = []
            return
        }

        var results: [URL] = []
        let quick = quickLocations.map(\.url)
        for base in quick {
            if let enumerator = FileManager.default.enumerator(
                at: base,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) {
                var depth = 0
                while let item = enumerator.nextObject() as? URL {
                    depth += 1
                    if depth > 100 { break }
                    var isDir: ObjCBool = false
                    if FileManager.default.fileExists(atPath: item.path, isDirectory: &isDir) && isDir.boolValue {
                        if item.lastPathComponent.lowercased().contains(trimmed) {
                            results.append(item)
                        }
                    }
                }
            }
        }
        self.searchResults = results
    }

    private func performOperation() {
        let dest = selectedDestination ?? currentBrowseURL

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
            appState.refreshAllViews()
            dismiss()
        } catch {
            appState.statusMessage = "Operation failed: \(error.localizedDescription)"
            dismiss()
        }
    }
}
