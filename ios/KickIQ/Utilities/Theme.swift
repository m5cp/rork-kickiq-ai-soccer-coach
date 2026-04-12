import SwiftUI

nonisolated enum AppearanceMode: String, Codable, CaseIterable, Sendable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    var icon: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        }
    }
}

nonisolated struct TeamColor: Codable, Sendable, Equatable {
    let name: String
    let primary: UInt
    let secondary: UInt
    let accent: UInt

    static let tarHeels = TeamColor(name: "Tar Heels", primary: 0x7BAFD4, secondary: 0x13294B, accent: 0x7BAFD4)
    static let classic = TeamColor(name: "Classic Orange", primary: 0xFF6D00, secondary: 0xE65100, accent: 0xFF6D00)
    static let crimson = TeamColor(name: "Crimson", primary: 0xDC143C, secondary: 0x8B0000, accent: 0xDC143C)
    static let emerald = TeamColor(name: "Emerald", primary: 0x50C878, secondary: 0x2E8B57, accent: 0x50C878)
    static let royal = TeamColor(name: "Royal Blue", primary: 0x4169E1, secondary: 0x1E3A7A, accent: 0x4169E1)
    static let gold = TeamColor(name: "Gold", primary: 0xFFD700, secondary: 0xDAA520, accent: 0xFFD700)
    static let purple = TeamColor(name: "Purple", primary: 0x9B59B6, secondary: 0x6C3483, accent: 0x9B59B6)
    static let teal = TeamColor(name: "Teal", primary: 0x1ABC9C, secondary: 0x16A085, accent: 0x1ABC9C)
    static let navy = TeamColor(name: "Navy", primary: 0x13294B, secondary: 0x0A1628, accent: 0x13294B)
    static let scarlet = TeamColor(name: "Scarlet", primary: 0xBB0000, secondary: 0x660000, accent: 0xBB0000)
    static let skyBlue = TeamColor(name: "Sky Blue", primary: 0x6CACE4, secondary: 0x3A7CC1, accent: 0x6CACE4)
    static let maroon = TeamColor(name: "Maroon", primary: 0x800000, secondary: 0x4B0000, accent: 0x800000)

    static let allPresets: [TeamColor] = [
        .tarHeels, .classic, .crimson, .emerald, .royal, .gold,
        .purple, .teal, .navy, .scarlet, .skyBlue, .maroon
    ]

    var primaryColor: Color { Color(hex: primary) }
    var secondaryColor: Color { Color(hex: secondary) }
    var accentColor: Color { Color(hex: accent) }

    var onPrimaryColor: Color {
        let r = Double((primary >> 16) & 0xFF) / 255
        let g = Double((primary >> 8) & 0xFF) / 255
        let b = Double(primary & 0xFF) / 255
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance > 0.55 ? .black : .white
    }
}

nonisolated struct CustomTeamColor: Codable, Sendable {
    let red: Double
    let green: Double
    let blue: Double

    func toTeamColor() -> TeamColor {
        let r = UInt(red * 255) & 0xFF
        let g = UInt(green * 255) & 0xFF
        let b = UInt(blue * 255) & 0xFF
        let hex = (r << 16) | (g << 8) | b

        let darkerR = UInt(max(red * 0.6, 0) * 255) & 0xFF
        let darkerG = UInt(max(green * 0.6, 0) * 255) & 0xFF
        let darkerB = UInt(max(blue * 0.6, 0) * 255) & 0xFF
        let darkerHex = (darkerR << 16) | (darkerG << 8) | darkerB

        return TeamColor(name: "Custom", primary: hex, secondary: darkerHex, accent: hex)
    }
}

@Observable
@MainActor
class ThemeManager {
    var appearanceMode: AppearanceMode = .system
    var teamColor: TeamColor = .tarHeels
    var useCustomColor: Bool = false
    var customColor: CustomTeamColor = CustomTeamColor(red: 0.48, green: 0.69, blue: 0.83)

    private let appearanceKey = "kickiq_appearance_mode"
    private let teamColorKey = "kickiq_team_color"
    private let customColorKey = "kickiq_custom_color"
    private let useCustomKey = "kickiq_use_custom_color"

    var activeTeamColor: TeamColor {
        useCustomColor ? customColor.toTeamColor() : teamColor
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: appearanceKey),
           let mode = AppearanceMode(rawValue: raw) {
            appearanceMode = mode
        }
        if let data = UserDefaults.standard.data(forKey: teamColorKey),
           let color = try? JSONDecoder().decode(TeamColor.self, from: data) {
            teamColor = color
        }
        useCustomColor = UserDefaults.standard.bool(forKey: useCustomKey)
        if let data = UserDefaults.standard.data(forKey: customColorKey),
           let custom = try? JSONDecoder().decode(CustomTeamColor.self, from: data) {
            customColor = custom
        }
    }

    func setAppearanceMode(_ mode: AppearanceMode) {
        appearanceMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: appearanceKey)
    }

    func setTeamColor(_ color: TeamColor) {
        teamColor = color
        useCustomColor = false
        UserDefaults.standard.set(false, forKey: useCustomKey)
        if let data = try? JSONEncoder().encode(color) {
            UserDefaults.standard.set(data, forKey: teamColorKey)
        }
    }

    func setCustomColor(red: Double, green: Double, blue: Double) {
        customColor = CustomTeamColor(red: red, green: green, blue: blue)
        useCustomColor = true
        UserDefaults.standard.set(true, forKey: useCustomKey)
        if let data = try? JSONEncoder().encode(customColor) {
            UserDefaults.standard.set(data, forKey: customColorKey)
        }
    }
}

enum KickIQTheme {
    @MainActor static var shared: ThemeManager = ThemeManager()

    static let background = Color(.systemBackground)
    static let card = Color(.secondarySystemGroupedBackground)
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let surface = Color(.tertiarySystemGroupedBackground)
    static let divider = Color(.separator)

    @MainActor static var accent: Color {
        shared.activeTeamColor.accentColor
    }

    @MainActor static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [shared.activeTeamColor.primaryColor, shared.activeTeamColor.secondaryColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @MainActor static var onAccent: Color {
        shared.activeTeamColor.onPrimaryColor
    }

    static let carolinaBlue = Color(hex: 0x7BAFD4)
    static let navy = Color(hex: 0x13294B)

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
