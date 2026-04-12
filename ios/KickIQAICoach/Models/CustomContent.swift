import Foundation

nonisolated enum CustomContentType: String, Codable, CaseIterable, Sendable, Identifiable {
    case drill = "Skill Drill"
    case conditioning = "Conditioning"
    case benchmark = "Benchmark"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .drill: "figure.soccer"
        case .conditioning: "heart.circle.fill"
        case .benchmark: "chart.bar.doc.horizontal.fill"
        }
    }
}

nonisolated struct CustomDrillItem: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let description: String
    let duration: String
    let difficulty: DrillDifficulty
    let targetSkill: String
    let coachingCues: [String]
    let reps: String
    var isCompleted: Bool
    let sourceFileName: String
    let dateAdded: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        duration: String = "10 min",
        difficulty: DrillDifficulty = .intermediate,
        targetSkill: String = "General",
        coachingCues: [String] = [],
        reps: String = "",
        isCompleted: Bool = false,
        sourceFileName: String = "",
        dateAdded: Date = .now
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
        self.sourceFileName = sourceFileName
        self.dateAdded = dateAdded
    }

    func toDrill() -> Drill {
        Drill(
            id: "custom_\(id)",
            name: name,
            description: description,
            duration: duration,
            difficulty: difficulty,
            targetSkill: targetSkill,
            coachingCues: coachingCues,
            reps: reps,
            isCompleted: isCompleted
        )
    }
}

nonisolated struct CustomConditioningItem: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let description: String
    let duration: String
    let difficulty: DrillDifficulty
    let focus: String
    let coachingCues: [String]
    let reps: String
    var isCompleted: Bool
    let sourceFileName: String
    let dateAdded: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        duration: String = "10 min",
        difficulty: DrillDifficulty = .intermediate,
        focus: String = "General",
        coachingCues: [String] = [],
        reps: String = "",
        isCompleted: Bool = false,
        sourceFileName: String = "",
        dateAdded: Date = .now
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.duration = duration
        self.difficulty = difficulty
        self.focus = focus
        self.coachingCues = coachingCues
        self.reps = reps
        self.isCompleted = isCompleted
        self.sourceFileName = sourceFileName
        self.dateAdded = dateAdded
    }

    func toDrill() -> Drill {
        Drill(
            id: "custom_cond_\(id)",
            name: name,
            description: description,
            duration: duration,
            difficulty: difficulty,
            targetSkill: focus,
            coachingCues: coachingCues,
            reps: reps,
            isCompleted: isCompleted
        )
    }
}

nonisolated struct CustomBenchmarkItem: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let category: String
    let instructions: String
    let howToRecord: String
    let unit: String
    let higherIsBetter: Bool
    let sourceFileName: String
    let dateAdded: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        category: String = "General",
        instructions: String,
        howToRecord: String,
        unit: String,
        higherIsBetter: Bool = true,
        sourceFileName: String = "",
        dateAdded: Date = .now
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.instructions = instructions
        self.howToRecord = howToRecord
        self.unit = unit
        self.higherIsBetter = higherIsBetter
        self.sourceFileName = sourceFileName
        self.dateAdded = dateAdded
    }

    func toBenchmarkDrill() -> BenchmarkDrill {
        BenchmarkDrill(
            id: "custom_bench_\(id)",
            category: matchCategory(),
            name: name,
            instructions: instructions,
            howToRecord: howToRecord,
            unit: unit,
            higherIsBetter: higherIsBetter,
            genderThresholds: nil
        )
    }

    private func matchCategory() -> BenchmarkCategory {
        let lower = category.lowercased()
        if lower.contains("ball control") || lower.contains("juggl") { return .ballControl }
        if lower.contains("first touch") || lower.contains("touch") || lower.contains("trapping") { return .firstTouch }
        if lower.contains("pass") { return .passing }
        if lower.contains("shoot") || lower.contains("finishing") { return .shooting }
        if lower.contains("dribbl") { return .dribbling }
        if lower.contains("agility") || lower.contains("speed") { return .agility }
        if lower.contains("endurance") || lower.contains("fitness") || lower.contains("cardio") { return .endurance }
        return .ballControl
    }
}

nonisolated struct CustomContentLibrary: Codable, Sendable {
    var drills: [CustomDrillItem]
    var conditioning: [CustomConditioningItem]
    var benchmarks: [CustomBenchmarkItem]

    init(drills: [CustomDrillItem] = [], conditioning: [CustomConditioningItem] = [], benchmarks: [CustomBenchmarkItem] = []) {
        self.drills = drills
        self.conditioning = conditioning
        self.benchmarks = benchmarks
    }
}

nonisolated struct PDFParseResult: Codable, Sendable {
    let drills: [ParsedDrill]
    let conditioning: [ParsedConditioning]
    let benchmarks: [ParsedBenchmark]
}

nonisolated struct ParsedDrill: Codable, Sendable {
    let name: String
    let description: String
    let duration: String?
    let difficulty: String?
    let targetSkill: String?
    let coachingCues: [String]?
    let reps: String?
}

nonisolated struct ParsedConditioning: Codable, Sendable {
    let name: String
    let description: String
    let duration: String?
    let difficulty: String?
    let focus: String?
    let coachingCues: [String]?
    let reps: String?
}

nonisolated struct ParsedBenchmark: Codable, Sendable {
    let name: String
    let category: String?
    let instructions: String
    let howToRecord: String
    let unit: String
    let higherIsBetter: Bool?
}
