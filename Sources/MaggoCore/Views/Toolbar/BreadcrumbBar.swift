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
                // Folder leading icon
                Image(systemName: "folder.fill")
                    .font(.system(size: 11))
                    .foregroundColor(Color.maggoBlue)
                    .padding(.leading, 6)

                ForEach(segments) { segment in
                    Button {
                        pane.navigate(to: segment.url)
                    } label: {
                        Text(segment.name)
                            .font(.system(size: 12, weight: segment.isLast ? .semibold : .regular))
                            .foregroundColor(segment.isLast ? Color.maggoBlue : Color(hex: "334155"))
                    }
                    .buttonStyle(.plain)
                    .help(segment.url.path)

                    if !segment.isLast {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Color(hex: "94A3B8"))
                            .padding(.horizontal, 2)
                    }
                }
            }
            .padding(.trailing, 8)
            .padding(.vertical, 3)
        }
        .frame(height: 26)
        .background(Color.white)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.maggoBorder, lineWidth: 1)
        )
    }
}
