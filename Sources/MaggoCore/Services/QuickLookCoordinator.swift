import Foundation
import AppKit
import QuickLookUI

@MainActor
public final class QuickLookCoordinator: NSObject, @preconcurrency QLPreviewPanelDataSource, @preconcurrency QLPreviewPanelDelegate {
    public static let shared = QuickLookCoordinator()

    public var previewURLs: [URL] = []

    private override init() {
        super.init()
    }

    public func showQuickLook(for url: URL) {
        previewURLs = [url]
        guard let panel = QLPreviewPanel.shared() else { return }
        panel.dataSource = self
        panel.delegate = self
        panel.makeKeyAndOrderFront(nil)
        panel.reloadData()
    }

    public func toggleQuickLook(for url: URL) {
        guard let panel = QLPreviewPanel.shared() else { return }
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            showQuickLook(for: url)
        }
    }

    // MARK: - QLPreviewPanelDataSource

    public func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        previewURLs.count
    }

    public func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        guard index >= 0 && index < previewURLs.count else { return nil }
        return previewURLs[index] as NSURL
    }
}
