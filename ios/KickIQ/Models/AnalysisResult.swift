import Foundation

nonisolated enum InsightType: String, Codable, CaseIterable, Sendable, Identifiable {
    case strength = "Strength"
    case weakness = "Weakness"
    case coachingPoint = "Coaching Point"
    case observation = "Observation"
    case recommendation = "Recommendation"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .strength: "checkmark.seal.fill"
        case .weakness: "exclamationmark.triangle.fill"
        case .coachingPoint: "lightbulb.fill"
        case .observation: "eye.fill"
        case .recommendation: "arrow.up.right.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .strength: "green"
        case .weakness: "red"
        case .coachingPoint: "orange"
        case .observation: "blue"
        case .recommendation: "purple"
        }
    }
}

nonisolated struct AnalysisInsight: Codable, Sendable, Identifiable {
    let id: String
    let type: InsightType
    let title: String
    let detail: String
    let relatedSkill: SkillCategory?
    let confidence: ConfidenceLevel
    let frameReference: String?
    let actionable: Bool

    init(
        id: String = UUID().uuidString,
        type: InsightType,
        title: String,
        detail: String,
        relatedSkill: SkillCategory? = nil,
        confidence: ConfidenceLevel = .medium,
        frameReference: String? = nil,
        actionable: Bool = false
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.detail = detail
        self.relatedSkill = relatedSkill
        self.confidence = confidence
        self.frameReference = frameReference
        self.actionable = actionable
    }
}

nonisolated struct AnalysisResult: Codable, Sendable, Identifiable {
    let id: String
    let sessionID: String
    let date: Date
    let position: PlayerPosition
    let skillLevel: SkillLevel
    let skillScores: [SkillScore]
    let overallScore: Int
    let insights: [AnalysisInsight]
    let structuredFeedback: StructuredFeedback
    let videoQuality: VideoQualityAssessment?
    let recommendedDrills: [Drill]
    let nextSessionFocus: String
    let clipDurationSeconds: Double
    let framesAnalyzed: Int

    init(
        id: String = UUID().uuidString,
        sessionID: String = UUID().uuidString,
        date: Date = .now,
        position: PlayerPosition,
        skillLevel: SkillLevel = .intermediate,
        skillScores: [SkillScore],
        overallScore: Int = 0,
        insights: [AnalysisInsight] = [],
        structuredFeedback: StructuredFeedback = StructuredFeedback(),
        videoQuality: VideoQualityAssessment? = nil,
        recommendedDrills: [Drill] = [],
        nextSessionFocus: String = "",
        clipDurationSeconds: Double = 0,
        framesAnalyzed: Int = 0
    ) {
        self.id = id
        self.sessionID = sessionID
        self.date = date
        self.position = position
        self.skillLevel = skillLevel
        self.skillScores = skillScores
        self.overallScore = overallScore > 0 ? overallScore : (skillScores.isEmpty ? 0 : Int(Double(skillScores.reduce(0) { $0 + $1.score }) / Double(skillScores.count) * 10))
        self.insights = insights
        self.structuredFeedback = structuredFeedback
        self.videoQuality = videoQuality
        self.recommendedDrills = recommendedDrills
        self.nextSessionFocus = nextSessionFocus
        self.clipDurationSeconds = clipDurationSeconds
        self.framesAnalyzed = framesAnalyzed
    }

    var strengths: [AnalysisInsight] {
        insights.filter { $0.type == .strength }
    }

    var weaknesses: [AnalysisInsight] {
        insights.filter { $0.type == .weakness }
    }

    var coachingPoints: [AnalysisInsight] {
        insights.filter { $0.type == .coachingPoint }
    }

    var highConfidenceScores: [SkillScore] {
        skillScores.filter { $0.confidence == .high }
    }

    var topSkill: SkillScore? {
        skillScores.max(by: { $0.score < $1.score })
    }

    var weakestSkill: SkillScore? {
        skillScores.min(by: { $0.score < $1.score })
    }

    static func from(session: TrainingSession, skillLevel: SkillLevel = .intermediate) -> AnalysisResult {
        var insights: [AnalysisInsight] = []

        if let feedback = session.structuredFeedback {
            for strength in feedback.strengths {
                insights.append(AnalysisInsight(type: .strength, title: "Strength", detail: strength))
            }
            for area in feedback.needsImprovement {
                insights.append(AnalysisInsight(type: .weakness, title: "Needs Work", detail: area))
            }
            for point in feedback.coachingPoints {
                insights.append(AnalysisInsight(type: .coachingPoint, title: "Coaching Point", detail: point, actionable: true))
            }
        }

        return AnalysisResult(
            sessionID: session.id,
            date: session.date,
            position: session.position,
            skillLevel: skillLevel,
            skillScores: session.skillScores,
            overallScore: session.overallScore,
            insights: insights,
            structuredFeedback: session.structuredFeedback ?? StructuredFeedback(),
            videoQuality: session.videoQuality,
            recommendedDrills: session.drills,
            nextSessionFocus: session.structuredFeedback?.nextSessionFocus ?? session.topImprovement
        )
    }
}
