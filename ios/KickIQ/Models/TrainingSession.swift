import Foundation

nonisolated enum ConfidenceLevel: String, Codable, Sendable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"

    var icon: String {
        switch self {
        case .high: "checkmark.seal.fill"
        case .medium: "exclamationmark.circle.fill"
        case .low: "questionmark.circle.fill"
        }
    }
}

nonisolated struct SkillScore: Codable, Sendable, Identifiable {
    var id: String { category.rawValue }
    let category: SkillCategory
    let score: Int
    let feedback: String
    let tip: String
    let confidence: ConfidenceLevel?
    let observedAction: String?

    init(category: SkillCategory, score: Int, feedback: String = "", tip: String = "", confidence: ConfidenceLevel? = nil, observedAction: String? = nil) {
        self.category = category
        self.score = min(max(score, 0), 10)
        self.feedback = feedback
        self.tip = tip
        self.confidence = confidence
        self.observedAction = observedAction
    }

    var percentage: Double {
        Double(score) / 10.0
    }
}

nonisolated enum DrillDifficulty: String, Codable, CaseIterable, Sendable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    var color: String {
        switch self {
        case .beginner: "green"
        case .intermediate: "orange"
        case .advanced: "red"
        }
    }
}

nonisolated struct Drill: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let description: String
    let duration: String
    let difficulty: DrillDifficulty
    let targetSkill: String
    let coachingCues: [String]
    let reps: String
    var isCompleted: Bool

    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        duration: String,
        difficulty: DrillDifficulty = .intermediate,
        targetSkill: String,
        coachingCues: [String] = [],
        reps: String = "",
        isCompleted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.duration = duration
        self.difficulty = difficulty
        self.targetSkill = targetSkill
        self.coachingCues = coachingCues
        self.reps = reps
        self.isCompleted = isCompleted
    }
}

nonisolated struct StructuredFeedback: Codable, Sendable {
    let strengths: [String]
    let needsImprovement: [String]
    let coachingPoints: [String]
    let nextSessionFocus: String

    init(strengths: [String] = [], needsImprovement: [String] = [], coachingPoints: [String] = [], nextSessionFocus: String = "") {
        self.strengths = strengths
        self.needsImprovement = needsImprovement
        self.coachingPoints = coachingPoints
        self.nextSessionFocus = nextSessionFocus
    }
}

nonisolated struct VideoQualityAssessment: Codable, Sendable {
    let rating: String
    let issues: [String]
    let tips: [String]

    init(rating: String = "Good", issues: [String] = [], tips: [String] = []) {
        self.rating = rating
        self.issues = issues
        self.tips = tips
    }
}

nonisolated struct TrainingSession: Codable, Sendable, Identifiable {
    let id: String
    let date: Date
    let position: PlayerPosition
    let skillScores: [SkillScore]
    let overallScore: Int
    let feedback: String
    let drills: [Drill]
    let topImprovement: String
    let structuredFeedback: StructuredFeedback?
    let videoQuality: VideoQualityAssessment?

    init(
        id: String = UUID().uuidString,
        date: Date = .now,
        position: PlayerPosition,
        skillScores: [SkillScore],
        feedback: String,
        drills: [Drill],
        topImprovement: String = "",
        structuredFeedback: StructuredFeedback? = nil,
        videoQuality: VideoQualityAssessment? = nil
    ) {
        self.id = id
        self.date = date
        self.position = position
        self.skillScores = skillScores
        self.overallScore = skillScores.isEmpty ? 0 : Int(Double(skillScores.reduce(0) { $0 + $1.score }) / Double(skillScores.count) * 10)
        self.feedback = feedback
        self.drills = drills
        self.topImprovement = topImprovement.isEmpty ? (skillScores.min(by: { $0.score < $1.score })?.category.rawValue ?? "") : topImprovement
        self.structuredFeedback = structuredFeedback
        self.videoQuality = videoQuality
    }
}

nonisolated enum MilestoneBadge: String, Codable, CaseIterable, Sendable, Identifiable {
    case streak7 = "7-Day Streak"
    case streak30 = "30-Day Streak"
    case streak90 = "90-Day Streak"
    case firstAnalysis = "First Analysis"
    case fiveAnalyses = "5 Analyses"
    case tenAnalyses = "10 Analyses"
    case twentyFiveAnalyses = "25 Analyses"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .streak7: "flame.fill"
        case .streak30: "flame.circle.fill"
        case .streak90: "trophy.fill"
        case .firstAnalysis: "star.fill"
        case .fiveAnalyses: "star.leadinghalffilled"
        case .tenAnalyses: "star.circle.fill"
        case .twentyFiveAnalyses: "medal.fill"
        }
    }

    var requirement: String {
        switch self {
        case .streak7: "Train 7 days in a row"
        case .streak30: "Train 30 days in a row"
        case .streak90: "Train 90 days in a row"
        case .firstAnalysis: "Complete your first analysis"
        case .fiveAnalyses: "Complete 5 analyses"
        case .tenAnalyses: "Complete 10 analyses"
        case .twentyFiveAnalyses: "Complete 25 analyses"
        }
    }
}

nonisolated enum PlayerLevel: String, Codable, CaseIterable, Sendable {
    case rookie = "Rookie"
    case amateur = "Amateur"
    case clubPlayer = "Club Player"
    case semiPro = "Semi-Pro"
    case elite = "Elite"

    var icon: String {
        switch self {
        case .rookie: "figure.walk"
        case .amateur: "figure.run"
        case .clubPlayer: "figure.soccer"
        case .semiPro: "trophy"
        case .elite: "crown.fill"
        }
    }

    var xpThreshold: Int {
        switch self {
        case .rookie: 0
        case .amateur: 100
        case .clubPlayer: 300
        case .semiPro: 600
        case .elite: 1000
        }
    }

    var nextLevel: PlayerLevel? {
        switch self {
        case .rookie: .amateur
        case .amateur: .clubPlayer
        case .clubPlayer: .semiPro
        case .semiPro: .elite
        case .elite: nil
        }
    }

    static func level(for xp: Int) -> PlayerLevel {
        if xp >= PlayerLevel.elite.xpThreshold { return .elite }
        if xp >= PlayerLevel.semiPro.xpThreshold { return .semiPro }
        if xp >= PlayerLevel.clubPlayer.xpThreshold { return .clubPlayer }
        if xp >= PlayerLevel.amateur.xpThreshold { return .amateur }
        return .rookie
    }

    static func xpToNextLevel(currentXP: Int) -> (current: Int, needed: Int)? {
        let currentLevel = level(for: currentXP)
        guard let next = currentLevel.nextLevel else { return nil }
        let progress = currentXP - currentLevel.xpThreshold
        let total = next.xpThreshold - currentLevel.xpThreshold
        return (progress, total)
    }
}
