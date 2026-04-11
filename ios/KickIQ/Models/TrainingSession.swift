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

nonisolated enum SpaceRequirement: String, Codable, CaseIterable, Sendable, Identifiable {
    case minimal = "Minimal"
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    case fullPitch = "Full Pitch"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .minimal: "square.dashed"
        case .small: "square.split.1x2"
        case .medium: "square.split.2x2"
        case .large: "rectangle.split.3x3"
        case .fullPitch: "sportscourt"
        }
    }

    var detail: String {
        switch self {
        case .minimal: "2x2 yards or less"
        case .small: "5x5 yards"
        case .medium: "10x10 yards"
        case .large: "20x20 yards or half pitch"
        case .fullPitch: "Full-size pitch required"
        }
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

nonisolated enum EquipmentType: String, Codable, CaseIterable, Sendable, Identifiable {
    case none = "No Equipment"
    case ball = "Ball"
    case cones = "Cones"
    case agilityLadder = "Agility Ladder"
    case wall = "Wall"
    case goal = "Goal"
    case resistanceBand = "Resistance Band"
    case reactionBall = "Reaction Ball"
    case tennisBalls = "Tennis Balls"
    case mannequin = "Mannequin"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .none: "hand.raised.slash"
        case .ball: "soccerball"
        case .cones: "triangle.fill"
        case .agilityLadder: "rectangle.split.3x1"
        case .wall: "square.fill"
        case .goal: "rectangle.open.lefthalf.inset.filled"
        case .resistanceBand: "circle.dotted"
        case .reactionBall: "circle.hexagongrid.fill"
        case .tennisBalls: "circle.fill"
        case .mannequin: "figure.stand"
        }
    }
}

nonisolated enum DrillIntensity: String, Codable, CaseIterable, Sendable, Identifiable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case maximum = "Maximum"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .low: "leaf.fill"
        case .moderate: "flame"
        case .high: "flame.fill"
        case .maximum: "bolt.fill"
        }
    }

    var color: String {
        switch self {
        case .low: "green"
        case .moderate: "yellow"
        case .high: "orange"
        case .maximum: "red"
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
    let category: SkillCategory?
    let intensity: DrillIntensity
    let trainingMode: TrainingMode
    let equipment: [EquipmentType]
    let durationMinutes: Int
    let variations: [DrillVariation]
    let tags: [String]
    let purpose: String
    let setup: String
    let space: SpaceRequirement
    let instructions: [String]
    let commonMistakes: [String]
    let restGuidance: RestGuidance?
    let recommendedSurfaces: [TrainingSurface]

    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        duration: String,
        difficulty: DrillDifficulty = .intermediate,
        targetSkill: String,
        coachingCues: [String] = [],
        reps: String = "",
        isCompleted: Bool = false,
        category: SkillCategory? = nil,
        intensity: DrillIntensity = .moderate,
        trainingMode: TrainingMode = .solo,
        equipment: [EquipmentType] = [.ball],
        durationMinutes: Int = 0,
        variations: [DrillVariation] = [],
        tags: [String] = [],
        purpose: String = "",
        setup: String = "",
        space: SpaceRequirement = .small,
        instructions: [String] = [],
        commonMistakes: [String] = [],
        restGuidance: RestGuidance? = nil,
        recommendedSurfaces: [TrainingSurface] = []
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
        self.category = category
        self.intensity = intensity
        self.trainingMode = trainingMode
        self.equipment = equipment
        self.durationMinutes = durationMinutes > 0 ? durationMinutes : Drill.parseDuration(duration)
        self.variations = variations
        self.tags = tags
        self.purpose = purpose
        self.setup = setup
        self.space = space
        self.instructions = instructions
        self.commonMistakes = commonMistakes
        self.restGuidance = restGuidance
        self.recommendedSurfaces = recommendedSurfaces
    }

    var resolvedCategory: SkillCategory? {
        if let category { return category }
        return SkillCategory.allCases.first { $0.rawValue == targetSkill }
    }

    private static func parseDuration(_ str: String) -> Int {
        let digits = str.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Int(digits) ?? 10
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
