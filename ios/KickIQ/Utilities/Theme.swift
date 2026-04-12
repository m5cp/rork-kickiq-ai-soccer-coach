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

    static let carolinaBlue = TeamColor(name: "Carolina Blue", primary: 0x7BAFD4, secondary: 0x13294B, accent: 0x7BAFD4)
    static let classic = TeamColor(name: "Classic Orange", primary: 0xFF6D00, secondary: 0xE65100, accent: 0xFF6D00)
    static let crimson = TeamColor(name: "Crimson", primary: 0xDC143C, secondary: 0x8B0000, accent: 0xDC143C)
    static let emerald = TeamColor(name: "Emerald", primary: 0x50C878, secondary: 0x2E8B57, accent: 0x50C878)
    static let royal = TeamColor(name: "Royal Blue", primary: 0x4169E1, secondary: 0x1E3A7A, accent: 0x4169E1)
    static let gold = TeamColor(name: "Gold", primary: 0xFFD700, secondary: 0xDAA520, accent: 0xFFD700)
    static let purple = TeamColor(name: "Purple", primary: 0x9B59B6, secondary: 0x6C3483, accent: 0x9B59B6)
    static let teal = TeamColor(name: "Teal", primary: 0x1ABC9C, secondary: 0x16A085, accent: 0x1ABC9C)

    static let allPresets: [TeamColor] = [.carolinaBlue, .classic, .crimson, .emerald, .royal, .gold, .purple, .teal]
}

@Observable
@MainActor
class ThemeManager {
    var appearanceMode: AppearanceMode = .dark
    var teamColor: TeamColor = .carolinaBlue

    private let appearanceKey = "kickiq_appearance_mode"
    private let teamColorKey = "kickiq_team_color"

    init() {
        if let raw = UserDefaults.standard.string(forKey: appearanceKey),
           let mode = AppearanceMode(rawValue: raw) {
            appearanceMode = mode
        }
        if let data = UserDefaults.standard.data(forKey: teamColorKey),
           let color = try? JSONDecoder().decode(TeamColor.self, from: data) {
            teamColor = color
        }
    }

    func setAppearanceMode(_ mode: AppearanceMode) {
        appearanceMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: appearanceKey)
    }

    func setTeamColor(_ color: TeamColor) {
        teamColor = color
        if let data = try? JSONEncoder().encode(color) {
            UserDefaults.standard.set(data, forKey: teamColorKey)
        }
    }
}

enum KickIQTheme {
    @MainActor static var shared: ThemeManager = ThemeManager()

    static let background = Color(hex: 0x0A0A0A)
    static let card = Color(hex: 0x1A1A1A)
    static let accent = Color(hex: 0x7BAFD4)
    static let accentGradient = LinearGradient(
        colors: [Color(hex: 0x7BAFD4), Color(hex: 0x13294B)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: 0x888888)
    static let surface = Color(white: 0.14)
    static let divider = Color(white: 0.18)

    static let carolinaBlue = Color(hex: 0x7BAFD4)
    static let navy = Color(hex: 0x13294B)

    @MainActor static var dynamicAccent: Color {
        Color(hex: shared.teamColor.accent)
    }

    @MainActor static var dynamicAccentGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: shared.teamColor.primary), Color(hex: shared.teamColor.secondary)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @MainActor static var dynamicBackground: Color {
        switch shared.appearanceMode {
        case .dark, .system: Color(hex: 0x0A0A0A)
        case .light: Color(hex: 0xF2F2F7)
        }
    }

    @MainActor static var dynamicCard: Color {
        switch shared.appearanceMode {
        case .dark, .system: Color(hex: 0x1A1A1A)
        case .light: Color.white
        }
    }

    @MainActor static var dynamicTextPrimary: Color {
        switch shared.appearanceMode {
        case .dark, .system: .white
        case .light: Color(hex: 0x1C1C1E)
        }
    }

    @MainActor static var dynamicTextSecondary: Color {
        switch shared.appearanceMode {
        case .dark, .system: Color(hex: 0x888888)
        case .light: Color(hex: 0x6C6C70)
        }
    }

    @MainActor static var dynamicSurface: Color {
        switch shared.appearanceMode {
        case .dark, .system: Color(white: 0.14)
        case .light: Color(hex: 0xE5E5EA)
        }
    }

    @MainActor static var dynamicDivider: Color {
        switch shared.appearanceMode {
        case .dark, .system: Color(white: 0.18)
        case .light: Color(hex: 0xD1D1D6)
        }
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
}
