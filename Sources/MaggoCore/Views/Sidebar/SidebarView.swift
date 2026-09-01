import SwiftUI

public struct SidebarView: View {
    @Bindable var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    private let homeURL = FileManager.default.homeDirectoryForCurrentUser

    private var favoriteLocations: [(name: String, icon: String, url: URL)] {
        [
            ("Downloads", "arrow.down.circle", homeURL.appendingPathComponent("Downloads")),
            ("Documents", "doc.text", homeURL.appendingPathComponent("Documents")),
            ("Desktop", "desktopcomputer", homeURL.appendingPathComponent("Desktop")),
            ("Projects", "folder", homeURL.appendingPathComponent("Projects"))
        ]
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // Section: Home
                Button {
                    appState.showSmartPictures = false
                    appState.selectedVolumeForOverview = nil
                    appState.activePane.navigate(to: homeURL)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 13))
                        Text("Home")
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                    }
                    .foregroundColor(isHomeActive ? .maggoBlue : .primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(isHomeActive ? Color.maggoSidebarActive : Color.clear)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)

                // Section: FAVORITES
                VStack(alignment: .leading, spacing: 2) {
                    Text("FAVORITES")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.maggoSidebarHeader)
                        .padding(.horizontal, 10)
                        .padding(.bottom, 2)

                    ForEach(favoriteLocations, id: \.name) { loc in
                        let isActive = !appState.showSmartPictures && appState.selectedVolumeForOverview == nil && appState.activePane.currentURL.lastPathComponent == loc.name

                        Button {
                            appState.showSmartPictures = false
                            appState.selectedVolumeForOverview = nil
                            appState.activePane.navigate(to: loc.url)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: loc.icon)
                                    .font(.system(size: 13))
                                    .foregroundColor(isActive ? .maggoBlue : .primary)
                                Text(loc.name)
                                    .font(.system(size: 13, weight: isActive ? .semibold : .regular))
                                    .foregroundColor(isActive ? .maggoBlue : .primary)
                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(isActive ? Color.maggoSidebarActive : Color.clear)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }

                    // Pictures Smart Location
                    let isPicturesActive = appState.showSmartPictures
                    Button {
                        appState.selectedVolumeForOverview = nil
                        appState.showSmartPictures = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "photo.stack.fill")
                                .font(.system(size: 13))
                                .foregroundColor(isPicturesActive ? .maggoBlue : .primary)
                            Text("Pictures")
                                .font(.system(size: 13, weight: isPicturesActive ? .semibold : .regular))
                                .foregroundColor(isPicturesActive ? .maggoBlue : .primary)
                            Spacer()
                            Text("Smart")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.maggoBlue)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.maggoSidebarActive)
                                .cornerRadius(3)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(isPicturesActive ? Color.maggoSidebarActive : Color.clear)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }

                // Section: THIS MAC
                VStack(alignment: .leading, spacing: 3) {
                    Text("THIS MAC")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.maggoSidebarHeader)
                        .padding(.horizontal, 10)
                        .padding(.bottom, 2)

                    ForEach(appState.volumes) { volume in
                        let isSelected = (appState.selectedVolumeForOverview?.id == volume.id) ||
                                         (!appState.showSmartPictures && appState.activePane.currentURL.path == volume.url.path)

                        Button {
                            appState.showSmartPictures = false
                            appState.selectedVolumeForOverview = volume
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: volume.isRemovable ? "externaldrive.fill" : "internaldrive.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(volume.isRemovable ? Color.iconZip : Color.maggoBlue)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(volume.name)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(isSelected ? .maggoBlue : .primary)

                                    Text(volumeSubtitle(for: volume))
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(isSelected ? Color.maggoSidebarActive : Color.clear)
                            .cornerRadius(6)
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
                        }
                    }
                }

                // Section: RECENT LOCATIONS
                if !appState.recentLocations.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("RECENT LOCATIONS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.maggoSidebarHeader)
                            .padding(.horizontal, 10)
                            .padding(.bottom, 2)

                        ForEach(appState.recentLocations.prefix(4), id: \.path) { url in
                            Button {
                                appState.showSmartPictures = false
                                appState.selectedVolumeForOverview = nil
                                appState.activePane.navigate(to: url)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "clock")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                    Text(url.lastPathComponent)
                                        .font(.system(size: 12))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    Spacer()
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.clear)
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
        }
        .frame(minWidth: 190, idealWidth: 205, maxWidth: 230)
        .background(Color.maggoSidebarBg)
    }

    private var isHomeActive: Bool {
        !appState.showSmartPictures && appState.selectedVolumeForOverview == nil && appState.activePane.currentURL == homeURL
    }

    private func volumeSubtitle(for volume: VolumeItem) -> String {
        let total = ByteCountFormatter.string(fromByteCount: volume.totalCapacity, countStyle: .file)
        let free = ByteCountFormatter.string(fromByteCount: volume.availableCapacity, countStyle: .file)
        return "\(total) • \(free) free"
    }
}
