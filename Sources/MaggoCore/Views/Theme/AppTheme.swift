import SwiftUI

public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    // Colors matching the HeroDemo landing page design
    static let maggoBlue = Color(hex: "0066D6")
    static let maggoFocusedBlue = Color(hex: "3B82F6")
    static let maggoSidebarBg = Color(hex: "F5F6F7")
    static let maggoSidebarActive = Color(hex: "E0EFFE")
    static let maggoSidebarHeader = Color(hex: "8A8F98")
    static let maggoBorder = Color(hex: "E2E8F0")
    static let maggoTabStripBg = Color(hex: "ECEEEF")
    static let maggoTabInactiveBg = Color(hex: "E4E6E8")

    // Button green highlight (Move To)
    static let maggoGreenBg = Color(hex: "F0FDF4")
    static let maggoGreenBorder = Color(hex: "86EFAC")
    static let maggoGreenText = Color(hex: "15803D")

    // File icons colors
    static let iconPdf = Color(hex: "EF4444")
    static let iconFolder = Color(hex: "0A84FF")
    static let iconZip = Color(hex: "F97316")
    static let iconSheet = Color(hex: "16A34A")
    static let iconScript = Color(hex: "64748B")
}
