import Foundation

nonisolated enum PeriodizationStyle: String, Codable, CaseIterable, Identifiable, Sendable {
    case tacticalMorphocycle = "Tactical Morphocycle"
    case classic = "Classic"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .tacticalMorphocycle:
            return "Recovery → Strength → Endurance → Speed → Activation"
        case .classic:
            return "Preseason → In-Season → Peaking → Taper"
        }
    }
}

nonisolated enum CampaignPhaseLabel: String, Codable, Sendable {
    case recovery = "Recovery"
    case strength = "Strength"
    case endurance = "Endurance"
    case speed = "Speed"
    case activation = "Activation"
    case preseason = "Preseason"
    case inSeason = "In-Season"
    case peaking = "Peaking"
    case taper = "Taper"

    var shortCode: String {
        switch self {
        case .recovery: return "REC"
        case .strength: return "STR"
        case .endurance: return "END"
        case .speed: return "SPD"
        case .activation: return "ACT"
        case .preseason: return "PRE"
        case .inSeason: return "IN"
        case .peaking: return "PEAK"
        case .taper: return "TAP"
        }
    }
}

nonisolated struct CampaignWeek: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    var weekNumber: Int
    var phaseLabel: CampaignPhaseLabel
    var sessionIDs: [UUID]
    var notes: String = ""
}

nonisolated struct Campaign: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    var title: String
    var style: PeriodizationStyle
    var weeks: [CampaignWeek]
    var sessionsPerWeek: Int
    var ageGroup: String
    var level: String
    var startDate: Date
    var createdAt: Date = Date()
    var embeddedSessions: [CoachSession] = []
}
