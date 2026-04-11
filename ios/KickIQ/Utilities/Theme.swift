import SwiftUI

enum KickIQTheme {
    static let background = Color(hex: 0x0A0A0A)
    static let card = Color(hex: 0x1A1A1A)
    static let accent = Color(hex: 0xFF6D00)
    static let accentGradient = LinearGradient(
        colors: [Color(hex: 0xFF6D00), Color(hex: 0xE65100)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: 0x888888)
    static let surface = Color(white: 0.14)
    static let divider = Color(white: 0.18)

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 40
    }

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
    }
}

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
