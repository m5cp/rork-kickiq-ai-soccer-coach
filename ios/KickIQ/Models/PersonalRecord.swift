import Foundation

nonisolated struct PersonalRecord: Codable, Sendable, Identifiable {
    let id: String
    let drillID: String
    let value: Double
    let unit: String
    let date: Date

    init(
        id: String = UUID().uuidString,
        drillID: String,
        value: Double,
        unit: String = "reps",
        date: Date = .now
    ) {
        self.id = id
        self.drillID = drillID
        self.value = value
        self.unit = unit
        self.date = date
    }

    var formattedValue: String {
        if value == value.rounded() {
            return "\(Int(value))"
        }
        return String(format: "%.1f", value)
    }
}
