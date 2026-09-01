import Foundation
import Observation

public enum ActivePaneSide: String, Sendable {
    case left
    case right
}

@MainActor
@Observable
public final class TabModel: Identifiable {
    public let id = UUID()
    public var leftPane: PaneModel
    public var rightPane: PaneModel
    public var activePaneSide: ActivePaneSide = .left
    public var isSplitView: Bool = false

    public init(initialURL: URL) {
        self.leftPane = PaneModel(url: initialURL)
        self.rightPane = PaneModel(url: initialURL)
    }

    public var activePane: PaneModel {
        get {
            if isSplitView && activePaneSide == .right {
                return rightPane
            }
            return leftPane
        }
        set {
            if isSplitView && activePaneSide == .right {
                rightPane = newValue
            } else {
                leftPane = newValue
            }
        }
    }

    public var inactivePane: PaneModel {
        if isSplitView && activePaneSide == .right {
            return leftPane
        }
        return rightPane
    }

    public var title: String {
        let name = activePane.currentURL.lastPathComponent
        return name.isEmpty ? "/" : name
    }

    public func toggleSplitView() {
        isSplitView.toggle()
        if isSplitView {
            // Synchronize right pane initially to parent or same location
            rightPane.navigate(to: leftPane.currentURL)
        } else {
            activePaneSide = .left
        }
    }
}
