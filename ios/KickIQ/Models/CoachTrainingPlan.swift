import Foundation

nonisolated struct CoachTrainingPlanDTO: Codable, Sendable, Identifiable {
    let id: String
    let team_id: String
    let coach_id: String
    let coach_name: String?
    let title: String
    let description: String?
    let age_group: String?
    let difficulty: String?
    let duration_minutes: Int?
    let focus_areas: [String]
    let drills: [CoachPlanDrillDTO]
    let created_at: String
    let updated_at: String?

    nonisolated enum CodingKeys: String, CodingKey {
        case id, team_id, coach_id, coach_name, title, description
        case age_group, difficulty, duration_minutes, focus_areas, drills
        case created_at, updated_at
    }
}

nonisolated struct CoachPlanDrillDTO: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let duration: String?
    let reps: String?
    let coaching_cues: [String]
    let order: Int

    nonisolated enum CodingKeys: String, CodingKey {
        case id, name, description, duration, reps, coaching_cues, order
    }
}
