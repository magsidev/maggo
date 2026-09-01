import SwiftUI

public struct SidebarView: View {
    @Bindable var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    private let homeURL = FileManager.default.homeDirectoryForCurrentUser

    private var standardLocations: [(name: String, icon: String, url: URL)] {
        [
            ("Desktop", "desktopcomputer", homeURL.appendingPathComponent("Desktop")),
            ("Documents", "doc.text", homeURL.appendingPathComponent("Documents")),
            ("Downloads", "arrow.down.circle", homeURL.appendingPathComponent("Downloads")),
            ("Pictures", "photo", homeURL.appendingPathComponent("Pictures")),
            ("Movies", "film", homeURL.appendingPathComponent("Movies")),
            ("Music", "music.note", homeURL.appendingPathComponent("Music")),
            ("Applications", "app.badge", URL(fileURLWithPath: "/Applications"))
        ]
    }

    public var body: some View {
        List {
            // Home / Quick Start
            Section {
                Button {
                    appState.activePane.navigate(to: homeURL)
                } label: {
                    Label("Home", systemImage: "house.fill")
                        .foregroundColor(appState.activePane.currentURL == homeURL ? .accentColor : .primary)
                }
                .buttonStyle(.plain)
            }

            // Favorites
            Section("Favorites") {
                ForEach(appState.favorites) { fav in
                    Button {
                        appState.activePane.navigate(to: fav.url)
                    } label: {
                        HStack {
                            Label(fav.name, systemImage: fav.iconName)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Remove from Favorites") {
                            appState.removeFavorite(path: fav.path)
                        }
                        Button("Reveal in Finder") {
                            appState.revealInFinder(url: fav.url)
                        }
                    }
                }
            }

            // Standard Locations
            Section("Locations") {
                ForEach(standardLocations, id: \.name) { loc in
                    Button {
                        appState.activePane.navigate(to: loc.url)
                    } label: {
                        HStack {
                            Label(loc.name, systemImage: loc.icon)
                                .foregroundColor(appState.activePane.currentURL.path == loc.url.path ? .accentColor : .primary)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            // This Mac / Storage Drives
            Section("This Mac") {
                ForEach(appState.volumes) { volume in
                    Button {
                        appState.activePane.navigate(to: volume.url)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Image(systemName: volume.isRemovable ? "externaldrive.fill" : "internaldrive.fill")
                                    .foregroundColor(volume.isRemovable ? .orange : .blue)
                                Text(volume.name)
                                    .fontWeight(.medium)
                            }
                            Text(volume.formattedCapacity)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Recent Locations
            if !appState.recentLocations.isEmpty {
                Section("Recent Locations") {
                    ForEach(appState.recentLocations.prefix(5), id: \.path) { url in
                        Button {
                            appState.activePane.navigate(to: url)
                        } label: {
                            Label(url.lastPathComponent, systemImage: "clock")
                                .font(.callout)
                                .lineLimit(1)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 190, idealWidth: 210, maxWidth: 260)
    }
}
