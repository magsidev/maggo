import SwiftUI
import QuickLookThumbnailing

public struct PictureThumbnailView: View {
    let url: URL
    let size: CGFloat

    @State private var thumbnail: NSImage?
    @State private var isLoading = false

    public init(url: URL, size: CGFloat = 110) {
        self.url = url
        self.size = size
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.08))

            if let thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipped()
                    .cornerRadius(8)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 28))
                    .foregroundColor(.secondary.opacity(0.4))
            }
        }
        .frame(width: size, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
        )
        .task(id: url) {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        let scale = NSScreen.main?.backingScaleFactor ?? 2.0
        let targetSize = CGSize(width: size * scale, height: size * scale)
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: targetSize,
            scale: scale,
            representationTypes: .thumbnail
        )

        let generator = QLThumbnailGenerator.shared
        do {
            let representation = try await generator.generateBestRepresentation(for: request)
            await MainActor.run {
                self.thumbnail = representation.nsImage
            }
        } catch {
            // Fallback to workspace icon
            await MainActor.run {
                self.thumbnail = NSWorkspace.shared.icon(forFile: url.path)
            }
        }
    }
}
