import Foundation

nonisolated struct DrillVariation: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let description: String
    let adjustedDifficulty: DrillDifficulty
    let adjustedDuration: String
    let adjustedReps: String
    let requiredEquipment: [EquipmentType]
    let trainingMode: TrainingMode
    let notes: String

    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        adjustedDifficulty: DrillDifficulty = .intermediate,
        adjustedDuration: String = "",
        adjustedReps: String = "",
        requiredEquipment: [EquipmentType] = [],
        trainingMode: TrainingMode = .solo,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.adjustedDifficulty = adjustedDifficulty
        self.adjustedDuration = adjustedDuration
        self.adjustedReps = adjustedReps
        self.requiredEquipment = requiredEquipment
        self.trainingMode = trainingMode
        self.notes = notes
    }
}
