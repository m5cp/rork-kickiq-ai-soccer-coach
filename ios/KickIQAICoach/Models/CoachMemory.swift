import Foundation

nonisolated enum CoachMemoryType: String, Codable, Sendable {
    case benchmarkScore = "Benchmark"
    case drillCompleted = "Drill"
    case goalSet = "Goal"
    case weakness = "Weakness"
    case improvement = "Improvement"
    case userPreference = "Preference"
    case sessionNote = "Note"
}

nonisolated struct CoachMemoryEntry: Codable, Sendable, Identifiable {
    let id: String
    let date: Date
    let type: CoachMemoryType
    let content: String

    init(id: String = UUID().uuidString, date: Date = .now, type: CoachMemoryType, content: String) {
        self.id = id
        self.date = date
        self.type = type
        self.content = content
    }
}
