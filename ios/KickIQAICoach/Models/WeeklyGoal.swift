import Foundation

nonisolated struct WeeklyGoal: Codable, Sendable {
    var sessionsPerWeek: Int
    var startDate: Date

    init(sessionsPerWeek: Int = 3, startDate: Date = .now) {
        self.sessionsPerWeek = sessionsPerWeek
        self.startDate = startDate
    }
}

nonisolated struct SessionNote: Codable, Sendable, Identifiable {
    let id: String
    let sessionID: String
    let text: String
    let date: Date

    init(id: String = UUID().uuidString, sessionID: String, text: String, date: Date = .now) {
        self.id = id
        self.sessionID = sessionID
        self.text = text
        self.date = date
    }
}

nonisolated struct TrainingPlanDay: Codable, Sendable, Identifiable {
    let id: String
    let dayLabel: String
    let focus: String
    let drills: [Drill]
    let restDay: Bool

    init(id: String = UUID().uuidString, dayLabel: String, focus: String, drills: [Drill] = [], restDay: Bool = false) {
        self.id = id
        self.dayLabel = dayLabel
        self.focus = focus
        self.drills = drills
        self.restDay = restDay
    }
}

nonisolated struct TrainingPlan: Codable, Sendable, Identifiable {
    let id: String
    let createdAt: Date
    let days: [TrainingPlanDay]
    let summary: String

    init(id: String = UUID().uuidString, createdAt: Date = .now, days: [TrainingPlanDay], summary: String) {
        self.id = id
        self.createdAt = createdAt
        self.days = days
        self.summary = summary
    }
}

nonisolated enum GeneratedPlanType: String, Codable, Sendable {
    case skills = "Skills"
    case conditioning = "Conditioning"
}

nonisolated struct PlanConfig: Codable, Sendable {
    let planType: GeneratedPlanType
    let weeks: Int
    let daysPerWeek: Int
    let minutesPerSession: Int
    let focusAreas: [String]

    init(planType: GeneratedPlanType, weeks: Int = 4, daysPerWeek: Int = 5, minutesPerSession: Int = 45, focusAreas: [String] = []) {
        self.planType = planType
        self.weeks = weeks
        self.daysPerWeek = daysPerWeek
        self.minutesPerSession = minutesPerSession
        self.focusAreas = focusAreas
    }
}

nonisolated struct GeneratedPlanWeek: Codable, Sendable, Identifiable {
    let id: String
    let weekNumber: Int
    let days: [TrainingPlanDay]

    init(id: String = UUID().uuidString, weekNumber: Int, days: [TrainingPlanDay]) {
        self.id = id
        self.weekNumber = weekNumber
        self.days = days
    }
}

nonisolated struct GeneratedPlan: Codable, Sendable, Identifiable {
    let id: String
    let createdAt: Date
    let config: PlanConfig
    let weeks: [GeneratedPlanWeek]
    let summary: String
    var isSynced: Bool

    init(id: String = UUID().uuidString, createdAt: Date = .now, config: PlanConfig, weeks: [GeneratedPlanWeek], summary: String, isSynced: Bool = false) {
        self.id = id
        self.createdAt = createdAt
        self.config = config
        self.weeks = weeks
        self.summary = summary
        self.isSynced = isSynced
    }

    var totalDrills: Int {
        weeks.flatMap(\.days).filter { !$0.restDay }.flatMap(\.drills).count
    }

    var totalTrainingDays: Int {
        weeks.flatMap(\.days).filter { !$0.restDay }.count
    }
}
