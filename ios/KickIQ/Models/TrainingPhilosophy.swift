import Foundation

nonisolated enum TrainingSurface: String, Codable, CaseIterable, Sendable, Identifiable {
    case grass = "Grass"
    case turf = "Artificial Turf"
    case indoor = "Indoor / Futsal"
    case concrete = "Concrete / Hard Court"
    case sand = "Sand"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .grass: "leaf.fill"
        case .turf: "square.grid.3x3.fill"
        case .indoor: "building.fill"
        case .concrete: "square.fill"
        case .sand: "sun.dust.fill"
        }
    }

    var performanceNote: String {
        switch self {
        case .grass:
            "Natural grass offers true ball behavior. Wet grass slows the ball and reduces bounce—adjust touch firmness accordingly."
        case .turf:
            "Artificial turf speeds up the ball and increases bounce. Use softer touches to compensate. Beware of friction on joints."
        case .indoor:
            "Fast surface with predictable bounce. Ideal for close control work. Ball skids more—keep touches tight."
        case .concrete:
            "Very fast with high bounce. Good for wall work and juggling. Avoid sliding or diving drills to prevent injury."
        case .sand:
            "High resistance builds strength and balance. Ball won't roll—focus on aerial control and body movement drills."
        }
    }
}

nonisolated struct RestGuidance: Codable, Sendable, Equatable {
    let workSeconds: Int
    let restSeconds: Int
    let restToWorkRatio: Double
    let note: String

    init(workSeconds: Int = 30, restSeconds: Int = 45, note: String = "") {
        self.workSeconds = workSeconds
        self.restSeconds = restSeconds
        self.restToWorkRatio = workSeconds > 0 ? Double(restSeconds) / Double(workSeconds) : 1.0
        self.note = note.isEmpty ? RestGuidance.defaultNote(ratio: restSeconds > 0 && workSeconds > 0 ? Double(restSeconds) / Double(workSeconds) : 1.0) : note
    }

    private static func defaultNote(ratio: Double) -> String {
        if ratio >= 2.0 {
            return "Full recovery between sets. Focus on quality over fatigue."
        } else if ratio >= 1.0 {
            return "Rest at least as long as you work. Technique degrades with fatigue."
        } else {
            return "Short rest to build stamina. Maintain form even when tired."
        }
    }

    static let techniqueDefault = RestGuidance(workSeconds: 30, restSeconds: 60, note: "Rest longer than work. Clean technique is the priority—never sacrifice form for speed.")
    static let fitnessDefault = RestGuidance(workSeconds: 45, restSeconds: 30, note: "Shorter rest to build game-like conditioning. Keep effort high.")
    static let recoveryDefault = RestGuidance(workSeconds: 20, restSeconds: 40, note: "Light effort with generous rest. Focus on feel and touch.")
}

nonisolated struct TrainingPrinciple: Codable, Sendable, Identifiable {
    let id: String
    let title: String
    let description: String
    let priority: Int

    init(id: String = UUID().uuidString, title: String, description: String, priority: Int = 0) {
        self.id = id
        self.title = title
        self.description = description
        self.priority = priority
    }
}

nonisolated struct TrainingPhilosophy: Codable, Sendable {

    let principles: [TrainingPrinciple]
    let defaultRestGuidance: RestGuidance
    let surfaceNotes: [TrainingSurface: String]

    static let shared = TrainingPhilosophy()

    init(
        principles: [TrainingPrinciple]? = nil,
        defaultRestGuidance: RestGuidance = .techniqueDefault,
        surfaceNotes: [TrainingSurface: String]? = nil
    ) {
        self.principles = principles ?? TrainingPhilosophy.corePrinciples
        self.defaultRestGuidance = defaultRestGuidance
        self.surfaceNotes = surfaceNotes ?? Dictionary(uniqueKeysWithValues: TrainingSurface.allCases.map { ($0, $0.performanceNote) })
    }

    static let corePrinciples: [TrainingPrinciple] = [
        TrainingPrinciple(
            title: "Technique Before Speed",
            description: "Always prioritize clean, correct technique over doing things fast. Speed is added only after the movement pattern is consistent and automatic.",
            priority: 1
        ),
        TrainingPrinciple(
            title: "Gradual Pace Increase",
            description: "Start every drill at walking or jogging pace. Increase speed only when you can perform the drill cleanly at the current tempo. If form breaks, slow back down.",
            priority: 2
        ),
        TrainingPrinciple(
            title: "Weak Area Focus",
            description: "Spend more time on skills you struggle with. It is tempting to repeat what you are good at, but real improvement comes from targeted work on weak areas.",
            priority: 3
        ),
        TrainingPrinciple(
            title: "Solo-Capable Training",
            description: "Most drills should be completable alone with minimal equipment. A ball, a wall, and a few cones unlock hundreds of high-quality training sessions.",
            priority: 4
        ),
        TrainingPrinciple(
            title: "Minimal Equipment",
            description: "Prefer drills that require only a ball and cones. Fancy equipment is not needed for elite-level technical development. A wall is the best training partner.",
            priority: 5
        ),
        TrainingPrinciple(
            title: "Rest Longer Than You Work",
            description: "For technique drills, rest periods should be equal to or longer than work periods. Fatigue kills form, and bad reps build bad habits.",
            priority: 6
        ),
        TrainingPrinciple(
            title: "Surface Awareness",
            description: "Your training surface affects ball speed, bounce, and body load. Adjust touch, intensity, and drill selection based on whether you are on grass, turf, concrete, or indoor courts.",
            priority: 7
        )
    ]

    func restGuidance(for intensity: DrillIntensity) -> RestGuidance {
        switch intensity {
        case .low:
            return .recoveryDefault
        case .moderate:
            return .techniqueDefault
        case .high:
            return RestGuidance(workSeconds: 40, restSeconds: 50, note: "Moderate rest to maintain quality. If technique slips, take extra time.")
        case .maximum:
            return .fitnessDefault
        }
    }

    func surfaceNote(for surface: TrainingSurface) -> String {
        surfaceNotes[surface] ?? surface.performanceNote
    }

    func principlesSorted() -> [TrainingPrinciple] {
        principles.sorted { $0.priority < $1.priority }
    }
}
