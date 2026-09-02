import SwiftUI
import AppKit

public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Dynamic Light / Dark mode adaptive color using macOS NSColor dynamicProvider
    static func dynamic(light: String, dark: String) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(hexString: dark)
                : NSColor(hexString: light)
        })
    }

    // App Design Tokens (Adaptive Light & Dark)
    static let maggoBlue = Color.accentColor
    static let maggoFocusedBlue = dynamic(light: "3B82F6", dark: "60A5FA")

    // Backgrounds
    static let maggoSidebarBg = dynamic(light: "F5F6F7", dark: "18181B")
    static let maggoSidebarActive = dynamic(light: "E0EFFE", dark: "1E3A5F")
    static let maggoSidebarHeader = dynamic(light: "8A8F98", dark: "71717A")
    static let maggoSidebarText = dynamic(light: "334155", dark: "E2E8F0")

    static let maggoToolbarBg = dynamic(light: "ECEEEF", dark: "202024")
    static let maggoPaneBg = dynamic(light: "FFFFFF", dark: "121214")
    static let maggoSubBarBg = dynamic(light: "F8FAFC", dark: "1C1C20")
    static let maggoFooterBg = dynamic(light: "F8FAFC", dark: "18181B")
    static let maggoModalBg = dynamic(light: "FFFFFF", dark: "1C1C20")
    static let maggoModalSubBg = dynamic(light: "F8FAFC", dark: "18181B")

    // Buttons & Pills
    static let maggoButtonBg = dynamic(light: "FFFFFF", dark: "27272A")
    static let maggoPillBg = dynamic(light: "FFFFFF", dark: "27272A")
    static let maggoBorder = dynamic(light: "E2E8F0", dark: "2E2E36")
    static let maggoSubBorder = dynamic(light: "F1F5F9", dark: "27272A")

    // Tabs
    static let maggoTabStripBg = dynamic(light: "ECEEEF", dark: "202024")
    static let maggoTabActiveBg = dynamic(light: "FFFFFF", dark: "27272A")
    static let maggoTabInactiveBg = dynamic(light: "E4E6E8", dark: "18181B")

    // Move To Button
    static let maggoGreenBg = dynamic(light: "F0FDF4", dark: "064E3B")
    static let maggoGreenBorder = dynamic(light: "86EFAC", dark: "059669")
    static let maggoGreenText = dynamic(light: "15803D", dark: "34D399")

    // File Type Icons
    static let iconPdf = Color(hex: "EF4444")
    static let iconFolder = Color(hex: "0A84FF")
    static let iconZip = Color(hex: "F97316")
    static let iconSheet = Color(hex: "16A34A")
    static let iconScript = dynamic(light: "64748B", dark: "94A3B8")
}

public extension NSColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            srgbRed: CGFloat(r) / 255.0,
            green: CGFloat(g) / 255.0,
            blue: CGFloat(b) / 255.0,
            alpha: CGFloat(a) / 255.0
        )
    }
}
