import Foundation

nonisolated enum SavedPlanType: String, Codable, Sendable {
    case skillDrills
    case conditioning
}

nonisolated struct SavedPlanDrill: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let description: String
    let duration: String
    let reps: String
    let targetSkill: String
    let difficulty: DrillDifficulty
    let coachingCues: [String]
    var isCompleted: Bool

    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        duration: String,
        reps: String = "",
        targetSkill: String = "",
        difficulty: DrillDifficulty = .intermediate,
        coachingCues: [String] = [],
        isCompleted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.duration = duration
        self.reps = reps
        self.targetSkill = targetSkill
        self.difficulty = difficulty
        self.coachingCues = coachingCues
        self.isCompleted = isCompleted
    }
}

nonisolated struct SavedPlanDay: Codable, Sendable, Identifiable {
    let id: String
    let dayNumber: Int
    let weekNumber: Int
    let focus: String
    let intensity: TrainingIntensity
    let duration: SessionDuration
    var drills: [SavedPlanDrill]

    init(
        id: String = UUID().uuidString,
        dayNumber: Int,
        weekNumber: Int,
        focus: String,
        intensity: TrainingIntensity,
        duration: SessionDuration,
        drills: [SavedPlanDrill] = []
    ) {
        self.id = id
        self.dayNumber = dayNumber
        self.weekNumber = weekNumber
        self.focus = focus
        self.intensity = intensity
        self.duration = duration
        self.drills = drills
    }

    var completedCount: Int { drills.filter(\.isCompleted).count }
    var isFullyCompleted: Bool { !drills.isEmpty && drills.allSatisfy(\.isCompleted) }
}

nonisolated struct SavedPlan: Codable, Sendable, Identifiable {
    let id: String
    let createdAt: Date
    let planType: SavedPlanType
    let title: String
    let focusAreas: [String]
    let sessionDuration: SessionDuration
    let weekCount: Int
    var days: [SavedPlanDay]
    var isSyncedToCalendar: Bool

    init(
        id: String = UUID().uuidString,
        createdAt: Date = .now,
        planType: SavedPlanType,
        title: String,
        focusAreas: [String],
        sessionDuration: SessionDuration,
        weekCount: Int,
        days: [SavedPlanDay],
        isSyncedToCalendar: Bool = false
    ) {
        self.id = id
        self.createdAt = createdAt
        self.planType = planType
        self.title = title
        self.focusAreas = focusAreas
        self.sessionDuration = sessionDuration
        self.weekCount = weekCount
        self.days = days
        self.isSyncedToCalendar = isSyncedToCalendar
    }

    var totalDrills: Int { days.reduce(0) { $0 + $1.drills.count } }
    var completedDrills: Int { days.reduce(0) { $0 + $1.completedCount } }
    var completedDays: Int { days.filter(\.isFullyCompleted).count }
    var totalDays: Int { days.count }

    var summaryText: String {
        "\(weekCount)-week \(planType == .skillDrills ? "skill" : "conditioning") plan focusing on \(focusAreas.joined(separator: ", ")). \(sessionDuration.label) sessions, \(totalDays) training days."
    }
}
