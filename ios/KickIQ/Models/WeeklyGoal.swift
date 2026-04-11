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
