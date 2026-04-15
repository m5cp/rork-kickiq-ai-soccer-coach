import Foundation

nonisolated struct TrainingAnnotation: Codable, Sendable, Identifiable {
    let id: String
    let date: Date
    var notes: String
    var duration: Int?
    var effort: Int?
    var drillsCompleted: [String]

    init(id: String = UUID().uuidString, date: Date, notes: String = "", duration: Int? = nil, effort: Int? = nil, drillsCompleted: [String] = []) {
        self.id = id
        self.date = date
        self.notes = notes
        self.duration = duration
        self.effort = effort
        self.drillsCompleted = drillsCompleted
    }
}
