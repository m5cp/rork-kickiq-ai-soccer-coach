import Foundation

nonisolated struct ThemeProfile: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let appearanceMode: AppearanceMode
    let presetID: String?
    let customPrimaryHex: UInt?
    let customAccentHex: UInt?
    let isUsingCustomColors: Bool
    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        appearanceMode: AppearanceMode = .dark,
        presetID: String? = nil,
        customPrimaryHex: UInt? = nil,
        customAccentHex: UInt? = nil,
        isUsingCustomColors: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.appearanceMode = appearanceMode
        self.presetID = presetID
        self.customPrimaryHex = customPrimaryHex
        self.customAccentHex = customAccentHex
        self.isUsingCustomColors = isUsingCustomColors
        self.createdAt = createdAt
    }

    @MainActor
    static func capture(name: String, from manager: ThemeManager) -> ThemeProfile {
        ThemeProfile(
            name: name,
            appearanceMode: manager.appearanceMode,
            presetID: manager.selectedPresetID,
            customPrimaryHex: manager.isUsingCustomColors ? manager.customPrimaryHex : nil,
            customAccentHex: manager.isUsingCustomColors ? manager.customAccentHex : nil,
            isUsingCustomColors: manager.isUsingCustomColors
        )
    }

    @MainActor
    func apply(to manager: ThemeManager) {
        manager.appearanceMode = appearanceMode
        if isUsingCustomColors, let primary = customPrimaryHex, let accent = customAccentHex {
            manager.setCustomColors(primary: primary, accent: accent)
        } else if let presetID {
            if let preset = ThemePreset.allPresets.first(where: { $0.id == presetID }) {
                manager.selectPreset(preset)
            }
        }
    }
}
