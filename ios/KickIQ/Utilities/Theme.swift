import SwiftUI

enum KickIQTheme {
    static var accent: Color {
        ThemeManager.shared.primaryColor
    }

    static var accentSecondary: Color {
        ThemeManager.shared.accentColor
    }

    static var accentGradient: LinearGradient {
        ThemeManager.shared.primaryGradient
    }

    static var background: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.04, green: 0.04, blue: 0.04, alpha: 1)
                : UIColor.systemBackground
        })
    }

    static var card: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1)
                : UIColor.secondarySystemGroupedBackground
        })
    }

    static var textPrimary: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? .white : .label
        })
    }

    static var textSecondary: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 0.53, alpha: 1)
                : UIColor.secondaryLabel
        })
    }

    static var surface: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 0.14, alpha: 1)
                : UIColor.tertiarySystemGroupedBackground
        })
    }

    static var divider: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 0.18, alpha: 1)
                : UIColor.separator
        })
    }

    static var buttonLabel: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? .black : .white
        })
    }

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

    var hexUInt: UInt {
        let components = UIColor(self).cgColor.components ?? [0, 0, 0]
        let r = components.count > 0 ? components[0] : 0
        let g = components.count > 1 ? components[1] : 0
        let b = components.count > 2 ? components[2] : 0
        return (UInt(r * 255) << 16) | (UInt(g * 255) << 8) | UInt(b * 255)
    }
}
