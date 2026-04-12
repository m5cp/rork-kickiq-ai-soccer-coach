import Foundation

nonisolated struct PersonalRecord: Codable, Sendable, Identifiable {
    let id: String
    let category: String
    let value: Int
    let date: Date
    let label: String

    init(id: String = UUID().uuidString, category: String, value: Int, date: Date = .now, label: String) {
        self.id = id
        self.category = category
        self.value = value
        self.date = date
        self.label = label
    }
}

nonisolated struct DrillCompletion: Codable, Sendable, Identifiable {
    let id: String
    let drillID: String
    let drillName: String
    let date: Date
    let durationSeconds: Int

    init(id: String = UUID().uuidString, drillID: String, drillName: String, date: Date = .now, durationSeconds: Int) {
        self.id = id
        self.drillID = drillID
        self.drillName = drillName
        self.date = date
        self.durationSeconds = durationSeconds
    }
}
