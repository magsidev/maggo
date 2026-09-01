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
            ("Pictures", "photo.stack.fill", homeURL.appendingPathComponent("Pictures")),
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
                    appState.showSmartPictures = false
                    appState.selectedVolumeForOverview = nil
                    appState.activePane.navigate(to: homeURL)
                } label: {
                    Label("Home", systemImage: "house.fill")
                        .foregroundColor(!appState.showSmartPictures && appState.selectedVolumeForOverview == nil && appState.activePane.currentURL == homeURL ? .accentColor : .primary)
                }
                .buttonStyle(.plain)
            }

            // Favorites
            Section("Favorites") {
                ForEach(appState.favorites) { fav in
                    Button {
                        appState.showSmartPictures = false
                        appState.selectedVolumeForOverview = nil
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

            // Standard & Smart Locations
            Section("Locations") {
                ForEach(standardLocations, id: \.name) { loc in
                    Button {
                        if loc.name == "Pictures" {
                            appState.selectedVolumeForOverview = nil
                            appState.showSmartPictures = true
                        } else {
                            appState.showSmartPictures = false
                            appState.selectedVolumeForOverview = nil
                            appState.activePane.navigate(to: loc.url)
                        }
                    } label: {
                        HStack {
                            let isActive = (loc.name == "Pictures" && appState.showSmartPictures) ||
                                           (!appState.showSmartPictures && appState.selectedVolumeForOverview == nil && appState.activePane.currentURL.path == loc.url.path)
                            Label(loc.name, systemImage: loc.icon)
                                .foregroundColor(isActive ? .accentColor : .primary)
                            Spacer()
                            if loc.name == "Pictures" {
                                Text("Smart")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.accentColor)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color.accentColor.opacity(0.12))
                                    .cornerRadius(3)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            // This Mac / Storage Drives
            Section("This Mac") {
                ForEach(appState.volumes) { volume in
                    Button {
                        appState.showSmartPictures = false
                        appState.selectedVolumeForOverview = volume
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Image(systemName: volume.isRemovable ? "externaldrive.fill" : "internaldrive.fill")
                                    .foregroundColor(volume.isRemovable ? .orange : .blue)
                                Text(volume.name)
                                    .fontWeight(.medium)
                            }
                            Text(volume.formattedAvailable)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Storage Overview") {
                            appState.showSmartPictures = false
                            appState.selectedVolumeForOverview = volume
                        }
                        Button("Browse Files Directly") {
                            appState.showSmartPictures = false
                            appState.selectedVolumeForOverview = nil
                            appState.activePane.navigate(to: volume.url)
                        }
                        Button("Reveal in Finder") {
                            appState.revealInFinder(url: volume.url)
                        }
                    }
                }
            }

            // Recent Locations
            if !appState.recentLocations.isEmpty {
                Section("Recent Locations") {
                    ForEach(appState.recentLocations.prefix(5), id: \.path) { url in
                        Button {
                            appState.showSmartPictures = false
                            appState.selectedVolumeForOverview = nil
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
        .frame(minWidth: 200, idealWidth: 220, maxWidth: 280)
    }
}
