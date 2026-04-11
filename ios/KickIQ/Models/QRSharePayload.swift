import Foundation

nonisolated enum QRShareType: String, Codable, Sendable {
    case drill
    case session
    case analysis
    case dailyPlan
}

nonisolated struct QRDrillPayload: Codable, Sendable {
    let name: String
    let description: String
    let duration: String
    let difficulty: DrillDifficulty
    let targetSkill: String
    let coachingCues: [String]
    let reps: String
}

nonisolated struct QRSessionPayload: Codable, Sendable {
    let date: Date
    let position: PlayerPosition
    let overallScore: Int
    let feedback: String
    let skillScores: [QRSkillScorePayload]
    let drills: [QRDrillPayload]
    let strengths: [String]
    let needsImprovement: [String]
    let coachingPoints: [String]
    let nextSessionFocus: String
}

nonisolated struct QRSkillScorePayload: Codable, Sendable {
    let category: SkillCategory
    let score: Int
    let feedback: String
    let tip: String
}

nonisolated struct QRDailyPlanPayload: Codable, Sendable {
    let focus: String
    let intensity: TrainingIntensity
    let duration: SessionDuration
    let mode: TrainingMode
    let weaknessPriority: [String]
    let drills: [QRDrillPayload]
}

nonisolated struct QRSharePayload: Codable, Sendable {
    let v: Int
    let type: QRShareType
    let drill: QRDrillPayload?
    let session: QRSessionPayload?
    let dailyPlan: QRDailyPlanPayload?

    init(drill: QRDrillPayload) {
        self.v = 1
        self.type = .drill
        self.drill = drill
        self.session = nil
        self.dailyPlan = nil
    }

    init(session: QRSessionPayload) {
        self.v = 1
        self.type = .analysis
        self.session = session
        self.drill = nil
        self.dailyPlan = nil
    }

    init(dailyPlan: QRDailyPlanPayload) {
        self.v = 1
        self.type = .dailyPlan
        self.dailyPlan = dailyPlan
        self.drill = nil
        self.session = nil
    }
}
