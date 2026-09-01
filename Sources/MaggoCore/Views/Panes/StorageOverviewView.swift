import SwiftUI

public struct StorageOverviewView: View {
    let volume: VolumeItem
    let onBrowse: () -> Void

    public init(volume: VolumeItem, onBrowse: @escaping () -> Void) {
        self.volume = volume
        self.onBrowse = onBrowse
    }

    public var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack(spacing: 16) {
                Image(systemName: volume.isRemovable ? "externaldrive.fill" : "internaldrive.fill")
                    .font(.system(size: 48))
                    .foregroundColor(volume.isRemovable ? .orange : .blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text(volume.name)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(volume.url.path)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Browse Files") {
                    onBrowse()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.bottom, 8)

            Divider()

            // Storage Meter
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Storage Usage")
                        .font(.headline)
                    Spacer()
                    Text(String(format: "%.1f%% used", volume.usedPercentage * 100))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(0.15))
                            .frame(height: 18)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: volume.usedPercentage > 0.9 ? [.orange, .red] : [.blue, .accentColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(volume.usedPercentage), height: 18)
                    }
                }
                .frame(height: 18)

                // Stats breakdown
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Used")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(volume.formattedUsed)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    VStack(alignment: .center, spacing: 2) {
                        Text("Available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(volume.formattedAvailable)
                            .font(.headline)
                            .foregroundColor(volume.usedPercentage > 0.9 ? .orange : .green)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Capacity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(volume.formattedTotal)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 6)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
            )

            Spacer()
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
