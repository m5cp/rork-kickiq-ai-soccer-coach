import Foundation

nonisolated enum QRShareType: String, Codable, Sendable {
    case drill
    case session
    case analysis
    case dailyPlan
    case trainingPlan
    case themeProfile
}

nonisolated struct QRDrillPayload: Codable, Sendable {
    let name: String
    let description: String
    let duration: String
    let difficulty: DrillDifficulty
    let targetSkill: String
    let coachingCues: [String]
    let reps: String
    let intensity: DrillIntensity?
    let trainingMode: TrainingMode?
    let equipment: [EquipmentType]?

    init(
        name: String,
        description: String,
        duration: String,
        difficulty: DrillDifficulty,
        targetSkill: String,
        coachingCues: [String],
        reps: String,
        intensity: DrillIntensity? = nil,
        trainingMode: TrainingMode? = nil,
        equipment: [EquipmentType]? = nil
    ) {
        self.name = name
        self.description = description
        self.duration = duration
        self.difficulty = difficulty
        self.targetSkill = targetSkill
        self.coachingCues = coachingCues
        self.reps = reps
        self.intensity = intensity
        self.trainingMode = trainingMode
        self.equipment = equipment
    }
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

nonisolated struct QRTrainingPlanPayload: Codable, Sendable {
    let summary: String
    let days: [QRDailyPlanPayload]
    let preferences: PlanPreferences?

    init(summary: String, days: [QRDailyPlanPayload], preferences: PlanPreferences? = nil) {
        self.summary = summary
        self.days = days
        self.preferences = preferences
    }
}

nonisolated struct QRThemeProfilePayload: Codable, Sendable {
    let name: String
    let appearanceMode: AppearanceMode
    let presetID: String?
    let customPrimaryHex: UInt?
    let customAccentHex: UInt?
    let isUsingCustomColors: Bool

    init(from profile: ThemeProfile) {
        self.name = profile.name
        self.appearanceMode = profile.appearanceMode
        self.presetID = profile.presetID
        self.customPrimaryHex = profile.customPrimaryHex
        self.customAccentHex = profile.customAccentHex
        self.isUsingCustomColors = profile.isUsingCustomColors
    }
}

nonisolated struct QRSharePayload: Codable, Sendable {
    let v: Int
    let type: QRShareType
    let drill: QRDrillPayload?
    let session: QRSessionPayload?
    let dailyPlan: QRDailyPlanPayload?
    let trainingPlan: QRTrainingPlanPayload?
    let themeProfile: QRThemeProfilePayload?

    init(drill: QRDrillPayload) {
        self.v = 1
        self.type = .drill
        self.drill = drill
        self.session = nil
        self.dailyPlan = nil
        self.trainingPlan = nil
        self.themeProfile = nil
    }

    init(session: QRSessionPayload) {
        self.v = 1
        self.type = .analysis
        self.session = session
        self.drill = nil
        self.dailyPlan = nil
        self.trainingPlan = nil
        self.themeProfile = nil
    }

    init(dailyPlan: QRDailyPlanPayload) {
        self.v = 1
        self.type = .dailyPlan
        self.dailyPlan = dailyPlan
        self.drill = nil
        self.session = nil
        self.trainingPlan = nil
        self.themeProfile = nil
    }

    init(trainingPlan: QRTrainingPlanPayload) {
        self.v = 1
        self.type = .trainingPlan
        self.trainingPlan = trainingPlan
        self.drill = nil
        self.session = nil
        self.dailyPlan = nil
        self.themeProfile = nil
    }

    init(themeProfile: QRThemeProfilePayload) {
        self.v = 1
        self.type = .themeProfile
        self.themeProfile = themeProfile
        self.drill = nil
        self.session = nil
        self.dailyPlan = nil
        self.trainingPlan = nil
    }
}
