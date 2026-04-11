import Foundation

nonisolated enum TrainingIntensity: String, Codable, CaseIterable, Sendable {
    case light = "Light"
    case medium = "Medium"
    case heavy = "Heavy"

    var icon: String {
        switch self {
        case .light: "leaf.fill"
        case .medium: "flame.fill"
        case .heavy: "bolt.fill"
        }
    }

    var color: String {
        switch self {
        case .light: "green"
        case .medium: "orange"
        case .heavy: "red"
        }
    }

    var description: String {
        switch self {
        case .light: "Recovery & technique focus"
        case .medium: "Balanced intensity"
        case .heavy: "High intensity & game simulation"
        }
    }
}

nonisolated enum SessionDuration: Int, Codable, CaseIterable, Sendable, Identifiable {
    case twenty = 20
    case thirty = 30
    case fortyFive = 45
    case sixty = 60
    case ninety = 90

    var id: Int { rawValue }

    var label: String { "\(rawValue) min" }
}

nonisolated enum TrainingMode: String, Codable, CaseIterable, Sendable, Identifiable {
    case solo = "Solo"
    case partner = "Partner"
    case team = "Team"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .solo: "person.fill"
        case .partner: "person.2.fill"
        case .team: "person.3.fill"
        }
    }
}

nonisolated struct SmartDrill: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let description: String
    let duration: String
    let difficulty: DrillDifficulty
    let targetSkill: String
    let coachingCues: [String]
    let reps: String
    let reason: String
    var isCompleted: Bool

    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        duration: String,
        difficulty: DrillDifficulty = .intermediate,
        targetSkill: String,
        coachingCues: [String] = [],
        reps: String = "",
        reason: String = "",
        isCompleted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.duration = duration
        self.difficulty = difficulty
        self.targetSkill = targetSkill
        self.coachingCues = coachingCues
        self.reps = reps
        self.reason = reason
        self.isCompleted = isCompleted
    }

    var asDrill: Drill {
        Drill(
            id: id,
            name: name,
            description: description,
            duration: duration,
            difficulty: difficulty,
            targetSkill: targetSkill,
            coachingCues: coachingCues,
            reps: reps,
            isCompleted: isCompleted
        )
    }
}

nonisolated struct DailyPlan: Codable, Sendable, Identifiable {
    let id: String
    let date: Date
    let dayNumber: Int
    let focus: String
    let intensity: TrainingIntensity
    let duration: SessionDuration
    let mode: TrainingMode
    let weaknessPriority: [String]
    var drills: [SmartDrill]

    init(
        id: String = UUID().uuidString,
        date: Date,
        dayNumber: Int,
        focus: String,
        intensity: TrainingIntensity,
        duration: SessionDuration,
        mode: TrainingMode,
        weaknessPriority: [String] = [],
        drills: [SmartDrill] = []
    ) {
        self.id = id
        self.date = date
        self.dayNumber = dayNumber
        self.focus = focus
        self.intensity = intensity
        self.duration = duration
        self.mode = mode
        self.weaknessPriority = weaknessPriority
        self.drills = drills
    }

    var completedCount: Int {
        drills.filter(\.isCompleted).count
    }

    var isFullyCompleted: Bool {
        !drills.isEmpty && drills.allSatisfy(\.isCompleted)
    }

    var progressPercent: Double {
        guard !drills.isEmpty else { return 0 }
        return Double(completedCount) / Double(drills.count)
    }
}

nonisolated struct PlanPreferences: Codable, Sendable {
    var preferredDuration: SessionDuration
    var preferredMode: TrainingMode
    var soloOnly: Bool
    var maxDrillMinutes: Int?
    var mixCategories: Bool
    var weaknessPriorityWeight: Double

    init(
        preferredDuration: SessionDuration = .thirty,
        preferredMode: TrainingMode = .solo,
        soloOnly: Bool = false,
        maxDrillMinutes: Int? = nil,
        mixCategories: Bool = true,
        weaknessPriorityWeight: Double = 0.6
    ) {
        self.preferredDuration = preferredDuration
        self.preferredMode = preferredMode
        self.soloOnly = soloOnly
        self.maxDrillMinutes = maxDrillMinutes
        self.mixCategories = mixCategories
        self.weaknessPriorityWeight = min(max(weaknessPriorityWeight, 0), 1)
    }
}

nonisolated struct SmartTrainingPlan: Codable, Sendable, Identifiable {
    let id: String
    let createdAt: Date
    var days: [DailyPlan]
    let summary: String
    var preferences: PlanPreferences

    init(
        id: String = UUID().uuidString,
        createdAt: Date = .now,
        days: [DailyPlan],
        summary: String,
        preferences: PlanPreferences = PlanPreferences()
    ) {
        self.id = id
        self.createdAt = createdAt
        self.days = days
        self.summary = summary
        self.preferences = preferences
    }

    var todaysPlan: DailyPlan? {
        let calendar = Calendar.current
        return days.first { calendar.isDate($0.date, inSameDayAs: .now) }
    }

    var completedDaysCount: Int {
        days.filter(\.isFullyCompleted).count
    }

    var totalDrillsCompleted: Int {
        days.reduce(0) { $0 + $1.completedCount }
    }

    var totalDrills: Int {
        days.reduce(0) { $0 + $1.drills.count }
    }
}
