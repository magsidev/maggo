import Foundation
import AppKit

public final class PasteboardService: @unchecked Sendable {
    public static let shared = PasteboardService()

    private let cutMarkerKey = NSPasteboard.PasteboardType("com.maggo.app.isCut")

    private init() {}

    /// Writes file URLs to the system pasteboard for Copy or Cut
    public func copy(urls: [URL], isCut: Bool = false) {
        guard !urls.isEmpty else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        // Write as file promises and standard file URLs so Finder and other Mac apps understand it
        pasteboard.writeObjects(urls as [NSURL])

        if isCut {
            pasteboard.setString("true", forType: cutMarkerKey)
        }
    }

    /// Checks if the macOS pasteboard currently contains file URLs
    public func hasFileURLs() -> Bool {
        let pasteboard = NSPasteboard.general
        guard let types = pasteboard.types else { return false }
        return types.contains(.fileURL) || pasteboard.canReadObject(forClasses: [NSURL.self], options: nil)
    }

    /// Reads file URLs from the pasteboard and determines if it was a Cut operation
    public func getFileURLs() -> (urls: [URL], isCut: Bool) {
        let pasteboard = NSPasteboard.general
        guard let objects = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !objects.isEmpty else {
            return ([], false)
        }

        let isCut = pasteboard.string(forType: cutMarkerKey) == "true"
        return (objects, isCut)
    }

    /// Clears the cut flag after a successful paste
    public func clearCutFlag() {
        NSPasteboard.general.setString("false", forType: cutMarkerKey)
    }
}
