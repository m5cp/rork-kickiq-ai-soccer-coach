import SwiftUI

nonisolated enum AppearanceMode: String, CaseIterable, Codable, Sendable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"

    var icon: String {
        switch self {
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        case .system: "circle.lefthalf.filled"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light: .light
        case .dark: .dark
        case .system: nil
        }
    }
}

nonisolated struct ThemePreset: Identifiable, Codable, Sendable {
    let id: String
    let name: String
    let primaryHex: UInt
    let accentHex: UInt
    let icon: String

    static let allPresets: [ThemePreset] = [
        ThemePreset(id: "unc", name: "Carolina", primaryHex: 0x7BAFD4, accentHex: 0x13294B, icon: "star.fill"),
        ThemePreset(id: "classic", name: "Classic", primaryHex: 0xFF6D00, accentHex: 0xE65100, icon: "flame.fill"),
        ThemePreset(id: "arsenal", name: "Arsenal", primaryHex: 0xEF0107, accentHex: 0x063672, icon: "shield.fill"),
        ThemePreset(id: "barcelona", name: "Barcelona", primaryHex: 0xA50044, accentHex: 0x004D98, icon: "shield.lefthalf.filled"),
        ThemePreset(id: "liverpool", name: "Liverpool", primaryHex: 0xC8102E, accentHex: 0xF6EB61, icon: "bird.fill"),
        ThemePreset(id: "chelsea", name: "Chelsea", primaryHex: 0x034694, accentHex: 0xDBA111, icon: "crown.fill"),
        ThemePreset(id: "madrid", name: "Real Madrid", primaryHex: 0xFEBE10, accentHex: 0x00529F, icon: "crown"),
        ThemePreset(id: "psg", name: "PSG", primaryHex: 0x004170, accentHex: 0xDA291C, icon: "building.columns.fill"),
        ThemePreset(id: "juventus", name: "Juventus", primaryHex: 0x000000, accentHex: 0xFFFFFF, icon: "j.circle.fill"),
        ThemePreset(id: "dortmund", name: "Dortmund", primaryHex: 0xFDE100, accentHex: 0x000000, icon: "bolt.fill"),
    ]
}

@Observable
@MainActor
class ThemeManager {
    static let shared = ThemeManager()

    var appearanceMode: AppearanceMode {
        didSet { save() }
    }
    var selectedPresetID: String? {
        didSet { save() }
    }
    var customPrimaryHex: UInt {
        didSet { save() }
    }
    var customAccentHex: UInt {
        didSet { save() }
    }
    var isUsingCustomColors: Bool {
        didSet { save() }
    }

    var primaryColor: Color {
        if isUsingCustomColors {
            return Color(hex: customPrimaryHex)
        }
        if let preset = currentPreset {
            return Color(hex: preset.primaryHex)
        }
        return Color(hex: ThemePreset.allPresets[0].primaryHex)
    }

    var accentColor: Color {
        if isUsingCustomColors {
            return Color(hex: customAccentHex)
        }
        if let preset = currentPreset {
            return Color(hex: preset.accentHex)
        }
        return Color(hex: ThemePreset.allPresets[0].accentHex)
    }

    var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [primaryColor, primaryColor.opacity(0.75)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var colorScheme: ColorScheme? {
        appearanceMode.colorScheme
    }

    var currentPreset: ThemePreset? {
        guard let id = selectedPresetID else { return ThemePreset.allPresets[0] }
        return ThemePreset.allPresets.first { $0.id == id }
    }

    var isDarkEffective: Bool {
        switch appearanceMode {
        case .dark: true
        case .light: false
        case .system: UITraitCollection.current.userInterfaceStyle == .dark
        }
    }

    private let modeKey = "kickiq_theme_mode"
    private let presetKey = "kickiq_theme_preset"
    private let customPrimaryKey = "kickiq_theme_custom_primary"
    private let customAccentKey = "kickiq_theme_custom_accent"
    private let isCustomKey = "kickiq_theme_is_custom"

    private init() {
        let defaults = UserDefaults.standard
        let modeRaw = defaults.string(forKey: modeKey) ?? AppearanceMode.dark.rawValue
        appearanceMode = AppearanceMode(rawValue: modeRaw) ?? .dark
        selectedPresetID = defaults.string(forKey: presetKey) ?? "unc"
        customPrimaryHex = UInt(defaults.integer(forKey: customPrimaryKey))
        customAccentHex = UInt(defaults.integer(forKey: customAccentKey))
        isUsingCustomColors = defaults.bool(forKey: isCustomKey)

        if customPrimaryHex == 0 { customPrimaryHex = 0x7BAFD4 }
        if customAccentHex == 0 { customAccentHex = 0x13294B }
    }

    func selectPreset(_ preset: ThemePreset) {
        selectedPresetID = preset.id
        isUsingCustomColors = false
    }

    func setCustomColors(primary: UInt, accent: UInt) {
        customPrimaryHex = primary
        customAccentHex = accent
        isUsingCustomColors = true
        selectedPresetID = nil
    }

    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(appearanceMode.rawValue, forKey: modeKey)
        defaults.set(selectedPresetID, forKey: presetKey)
        defaults.set(Int(customPrimaryHex), forKey: customPrimaryKey)
        defaults.set(Int(customAccentHex), forKey: customAccentKey)
        defaults.set(isUsingCustomColors, forKey: isCustomKey)
    }
}
