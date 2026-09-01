import SwiftUI

public enum PictureFilter: String, CaseIterable, Identifiable {
    case all = "All Pictures"
    case recent = "Recently Modified"
    case large = "Large (> 5 MB)"

    public var id: String { rawValue }
}

public struct PicturesSmartView: View {
    @Bindable var appState: AppState

    @State private var pictures: [PictureItem] = []
    @State private var isLoading = true
    @State private var activeFilter: PictureFilter = .all
    @State private var selectedExtension: String = "ALL"
    @State private var searchText: String = ""
    @State private var selectedURL: URL?

    public init(appState: AppState) {
        self.appState = appState
    }

    private var availableExtensions: [String] {
        let set = Set(pictures.map(\.formatExtension))
        var list = Array(set).sorted()
        list.insert("ALL", at: 0)
        return list
    }

    private var filteredPictures: [PictureItem] {
        var result = pictures

        // Filter by preset
        switch activeFilter {
        case .all:
            break
        case .recent:
            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            result = result.filter { $0.dateModified >= sevenDaysAgo }
        case .large:
            result = result.filter { $0.fileSize >= 5 * 1024 * 1024 }
        }

        // Filter by extension
        if selectedExtension != "ALL" {
            result = result.filter { $0.formatExtension == selectedExtension }
        }

        // Filter by search text
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                $0.parentDirectoryName.lowercased().contains(query) ||
                $0.relativeDisplayPath.lowercased().contains(query)
            }
        }

        return result
    }

    private let columns = [
        GridItem(.adaptive(minimum: 140, maximum: 170), spacing: 18)
    ]

    public var body: some View {
        VStack(spacing: 0) {
            // Filter Bar
            HStack(spacing: 12) {
                // Preset Picker
                Picker("Filter", selection: $activeFilter) {
                    ForEach(PictureFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 320)

                // Format Filter
                if availableExtensions.count > 2 {
                    Picker("Format", selection: $selectedExtension) {
                        ForEach(availableExtensions, id: \.self) { ext in
                            Text(ext).tag(ext)
                        }
                    }
                    .frame(width: 90)
                }

                Spacer()

                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    TextField("Search pictures…", text: $searchText)
                        .textFieldStyle(.plain)
                        .frame(width: 140)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
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
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2), lineWidth: 1))

                // Refresh button
                Button {
                    reloadPictures()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .help("Refresh Pictures Index")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // Header info
            HStack {
                Text("All Pictures")
                    .font(.headline)
                Text("·  \(filteredPictures.count) item\(filteredPictures.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text("Aggregated across Mac · Original files remain in place")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 4)

            // Content Grid
            if isLoading && pictures.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Indexing pictures across your Mac…")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredPictures.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 44))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No pictures found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Images in Downloads, Desktop, Documents, and Pictures will appear here.")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(filteredPictures) { pic in
                            let isSelected = selectedURL == pic.url

                            VStack(alignment: .leading, spacing: 6) {
                                PictureThumbnailView(url: pic.url, size: 140)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(pic.name)
                                        .font(.system(size: 11, weight: .medium))
                                        .lineLimit(1)
                                        .foregroundColor(isSelected ? .white : .primary)

                                    HStack(spacing: 4) {
                                        Text(pic.formattedSize)
                                            .font(.system(size: 9))
                                            .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)

                                        Text("·")
                                            .font(.system(size: 9))
                                            .foregroundColor(.secondary)

                                        Text(pic.parentDirectoryName)
                                            .font(.system(size: 9))
                                            .foregroundColor(isSelected ? .white.opacity(0.8) : .accentColor)
                                            .lineLimit(1)
                                    }
                                }
                                .padding(.horizontal, 4)
                                .padding(.vertical, 3)
                                .frame(maxWidth: 140, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(isSelected ? Color.accentColor : Color.clear)
                                    )
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedURL = pic.url
                            }
                            .onTapGesture(count: 2) {
                                NSWorkspace.shared.open(pic.url)
                            }
                            .contextMenu {
                                pictureContextMenu(for: pic)
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .task {
            await loadPictures()
        }
    }

    @ViewBuilder
    private func pictureContextMenu(for pic: PictureItem) -> some View {
        Button("Open") {
            NSWorkspace.shared.open(pic.url)
        }

        Button("Quick Look (Space)") {
            appState.quickLookURL = pic.url
        }

        Divider()

        Button("Open Containing Folder") {
            let parent = pic.url.deletingLastPathComponent()
            appState.activePane.navigate(to: parent)
            appState.showSmartPictures = false
        }

        Button("Reveal in Finder (⌘⌥R)") {
            appState.revealInFinder(url: pic.url)
        }

        Button("Copy Path (⌘⌥C)") {
            appState.copyPathToClipboard(url: pic.url)
        }

        Divider()

        Button("Move To… (⌘⇧M)") {
            appState.destinationPickerConfig = DestinationPickerConfig(operation: .move, sourceURLs: [pic.url])
        }

        Button("Copy To… (⌘⇧C)") {
            appState.destinationPickerConfig = DestinationPickerConfig(operation: .copy, sourceURLs: [pic.url])
        }

        Button("Move to Trash (⌘⌫)", role: .destructive) {
            _ = try? FileOperationEngine.shared.moveToTrash(urls: [pic.url])
            pictures.removeAll { $0.url == pic.url }
        }
    }

    private func loadPictures() async {
        isLoading = true
        let items = await PictureIndexService.shared.getIndexedPictures()
        await MainActor.run {
            self.pictures = items
            self.isLoading = false
        }
    }

    private func reloadPictures() {
        isLoading = true
        Task {
            let items = await PictureIndexService.shared.indexPictures()
            await MainActor.run {
                self.pictures = items
                self.isLoading = false
            }
        }
    }
}
