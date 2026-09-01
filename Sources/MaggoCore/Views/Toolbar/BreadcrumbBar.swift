import SwiftUI

public struct BreadcrumbSegment: Identifiable, Hashable {
    public var id: String { url.path }
    public let name: String
    public let url: URL
    public let isLast: Bool
}

public struct BreadcrumbBar: View {
    @Bindable var pane: PaneModel

    public init(pane: PaneModel) {
        self.pane = pane
    }

    private var segments: [BreadcrumbSegment] {
        var result: [BreadcrumbSegment] = []
        var current = pane.currentURL

        var stack: [URL] = []
        while true {
            stack.append(current)
            let parent = current.deletingLastPathComponent()
            if parent.path == current.path || current.path == "/" {
                break
            }
            current = parent
        }

        stack.reverse()

        for (index, url) in stack.enumerated() {
            let isLast = index == stack.count - 1
            var name = url.lastPathComponent
            if url.path == "/" {
                name = "Macintosh HD"
            }
            result.append(BreadcrumbSegment(name: name, url: url, isLast: isLast))
        }

        return result
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(segments) { segment in
                    Button {
                        pane.navigate(to: segment.url)
                    } label: {
                        HStack(spacing: 4) {
                            if segment.name == "Macintosh HD" {
                                Image(systemName: "internaldrive.fill")
                                    .font(.caption2)
                            } else if segment.url.path == FileManager.default.homeDirectoryForCurrentUser.path {
                                Image(systemName: "house.fill")
                                    .font(.caption2)
                            }
                            Text(segment.name)
                                .fontWeight(segment.isLast ? .semibold : .regular)
                                .foregroundColor(segment.isLast ? .primary : .secondary)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(segment.isLast ? Color.accentColor.opacity(0.12) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                    .help(segment.url.path)

                    if !segment.isLast {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(height: 28)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}
