import Foundation

nonisolated enum BenchmarkCategory: String, Codable, CaseIterable, Sendable, Identifiable {
    case ballControl = "Ball Control"
    case firstTouch = "First Touch"
    case passing = "Passing"
    case shooting = "Shooting"
    case dribbling = "Dribbling"
    case agility = "Agility"
    case endurance = "Endurance"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .ballControl: "circle.dashed"
        case .firstTouch: "hand.point.up.fill"
        case .passing: "arrow.up.forward"
        case .shooting: "scope"
        case .dribbling: "figure.soccer"
        case .agility: "hare.fill"
        case .endurance: "lungs.fill"
        }
    }

    var color: String {
        switch self {
        case .ballControl: "purple"
        case .firstTouch: "blue"
        case .passing: "green"
        case .shooting: "red"
        case .dribbling: "orange"
        case .agility: "teal"
        case .endurance: "pink"
        }
    }
}

nonisolated struct GenderThresholds: Codable, Sendable {
    let maleElite: Double
    let maleAverage: Double
    let femaleElite: Double
    let femaleAverage: Double

    func elite(for gender: PlayerGender) -> Double {
        switch gender.benchmarkGender {
        case .male, .nonBinary: maleElite
        case .female: femaleElite
        }
    }

    func average(for gender: PlayerGender) -> Double {
        switch gender.benchmarkGender {
        case .male, .nonBinary: maleAverage
        case .female: femaleAverage
        }
    }
}

nonisolated struct BenchmarkDrill: Codable, Sendable, Identifiable {
    let id: String
    let category: BenchmarkCategory
    let name: String
    let instructions: String
    let howToRecord: String
    let unit: String
    let higherIsBetter: Bool
    let eliteThresholds: [String: Double]
    let genderThresholds: GenderThresholds?

    init(
        id: String = UUID().uuidString,
        category: BenchmarkCategory,
        name: String,
        instructions: String,
        howToRecord: String,
        unit: String,
        higherIsBetter: Bool = true,
        eliteThresholds: [String: Double] = [:],
        genderThresholds: GenderThresholds? = nil
    ) {
        self.id = id
        self.category = category
        self.name = name
        self.instructions = instructions
        self.howToRecord = howToRecord
        self.unit = unit
        self.higherIsBetter = higherIsBetter
        self.eliteThresholds = eliteThresholds
        self.genderThresholds = genderThresholds
    }
}

nonisolated struct BenchmarkAttempt: Codable, Sendable, Identifiable {
    let id: String
    let benchmarkDrillID: String
    let score: Double
    let date: Date

    init(id: String = UUID().uuidString, benchmarkDrillID: String, score: Double, date: Date = .now) {
        self.id = id
        self.benchmarkDrillID = benchmarkDrillID
        self.score = score
        self.date = date
    }
}

nonisolated struct BenchmarkResult: Codable, Sendable, Identifiable {
    let id: String
    let benchmarkDrillID: String
    let category: BenchmarkCategory
    var attempts: [BenchmarkAttempt]
    let drillName: String
    var isSkipped: Bool

    init(id: String = UUID().uuidString, benchmarkDrillID: String, category: BenchmarkCategory, attempts: [BenchmarkAttempt] = [], drillName: String, isSkipped: Bool = false) {
        self.id = id
        self.benchmarkDrillID = benchmarkDrillID
        self.category = category
        self.attempts = attempts
        self.drillName = drillName
        self.isSkipped = isSkipped
    }

    var latestScore: Double? {
        guard !isSkipped else { return nil }
        return attempts.last?.score
    }

    var bestScore: Double? {
        guard !isSkipped else { return nil }
        return attempts.map(\.score).max()
    }

    var trend: BenchmarkTrend {
        guard !isSkipped, attempts.count >= 2 else { return .neutral }
        let last = attempts[attempts.count - 1].score
        let prev = attempts[attempts.count - 2].score
        if last > prev { return .improving }
        if last < prev { return .declining }
        return .neutral
    }
}

nonisolated enum BenchmarkTier: String, Codable, CaseIterable, Sendable {
    case recreational = "Recreational"
    case competitive = "Competitive"
    case academy = "Academy"
    case elite = "Elite"

    var shortLabel: String { rawValue }

    var fullDescription: String {
        switch self {
        case .recreational: "Rec / House League"
        case .competitive: "Travel Team"
        case .academy: "High-Level / Academy"
        case .elite: "Elite / Pre-Pro"
        }
    }

    var color: String {
        switch self {
        case .recreational: "gray"
        case .competitive: "orange"
        case .academy: "cyan"
        case .elite: "purple"
        }
    }
}

nonisolated enum BenchmarkTrend: String, Codable, Sendable {
    case improving
    case declining
    case neutral

    var icon: String {
        switch self {
        case .improving: "arrow.up.right"
        case .declining: "arrow.down.right"
        case .neutral: "arrow.right"
        }
    }

    var label: String {
        switch self {
        case .improving: "Improving"
        case .declining: "Needs Work"
        case .neutral: "Steady"
        }
    }
}

nonisolated enum BenchmarkPlayerRank: String, Codable, CaseIterable, Sendable {
    case rookie = "Rookie"
    case developing = "Developing"
    case clubReady = "Club Ready"
    case competitive = "Competitive"
    case elite = "Elite"

    var icon: String {
        switch self {
        case .rookie: "figure.walk"
        case .developing: "figure.run"
        case .clubReady: "figure.soccer"
        case .competitive: "trophy"
        case .elite: "crown.fill"
        }
    }

    var threshold: Double {
        switch self {
        case .rookie: 0
        case .developing: 25
        case .clubReady: 50
        case .competitive: 70
        case .elite: 85
        }
    }

    static func rank(for overallScore: Double) -> BenchmarkPlayerRank {
        if overallScore >= BenchmarkPlayerRank.elite.threshold { return .elite }
        if overallScore >= BenchmarkPlayerRank.competitive.threshold { return .competitive }
        if overallScore >= BenchmarkPlayerRank.clubReady.threshold { return .clubReady }
        if overallScore >= BenchmarkPlayerRank.developing.threshold { return .developing }
        return .rookie
    }

    var nextRank: BenchmarkPlayerRank? {
        switch self {
        case .rookie: .developing
        case .developing: .clubReady
        case .clubReady: .competitive
        case .competitive: .elite
        case .elite: nil
        }
    }
}
