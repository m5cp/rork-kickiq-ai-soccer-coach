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

nonisolated enum CampaignPhaseLabel: String, Codable, Sendable, CaseIterable, Identifiable {
    case preseason = "Preseason"
    case earlySeason = "Early Season"
    case midSeason = "Mid Season"
    case lateSeason = "Late Season"
    case playoffs = "Playoffs"
    case offSeason = "Off-Season"
    case recovery = "Recovery"
    case strength = "Strength"
    case endurance = "Endurance"
    case speed = "Speed"
    case activation = "Activation"
    case inSeason = "In-Season"
    case peaking = "Peaking"
    case taper = "Taper"

    var id: String { rawValue }

    var shortCode: String {
        switch self {
        case .preseason: return "PRE"
        case .earlySeason: return "EARLY"
        case .midSeason: return "MID"
        case .lateSeason: return "LATE"
        case .playoffs: return "PLAY"
        case .offSeason: return "OFF"
        case .recovery: return "REC"
        case .strength: return "STR"
        case .endurance: return "END"
        case .speed: return "SPD"
        case .activation: return "ACT"
        case .inSeason: return "IN"
        case .peaking: return "PEAK"
        case .taper: return "TAP"
        }
    }

    var focusDescription: String {
        switch self {
        case .preseason: return "Fitness base, build-up play, team shape"
        case .earlySeason: return "Defensive organization, pressing triggers"
        case .midSeason: return "Tactical variety, transitions, combination play"
        case .lateSeason: return "Sharpness, attacking patterns, set pieces"
        case .playoffs: return "Finishing, decision-making, match scenarios"
        case .offSeason: return "Recovery, individual skill, light touch work"
        case .recovery: return "Light intensity, mobility, technical refinement"
        case .strength: return "Power, duels, physical robustness"
        case .endurance: return "High volume, pressing, repeat sprints"
        case .speed: return "Explosiveness, counters, finishing"
        case .activation: return "Pre-match sharpness, set pieces"
        case .inSeason: return "Match preparation, weekly rhythm"
        case .peaking: return "Top form, finishing quality"
        case .taper: return "Reduced load, quality over quantity"
        }
    }

    static var seasonPhases: [CampaignPhaseLabel] {
        [.preseason, .earlySeason, .midSeason, .lateSeason, .playoffs, .offSeason]
    }
}

nonisolated enum GeneratorScope: Codable, Sendable, Hashable {
    case fullSeason
    case singlePhase(CampaignPhaseLabel)
    case singleMonth(Int)       // 1-indexed month within season
    case singleWeek(Int)        // 1-indexed week number within season
    case singleSession(Date)
    case customDateRange(Date, Date)

    var displayName: String {
        switch self {
        case .fullSeason: return "Full Season"
        case .singlePhase(let p): return p.rawValue
        case .singleMonth: return "Month"
        case .singleWeek: return "Week"
        case .singleSession: return "Single Session"
        case .customDateRange: return "Date Range"
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
