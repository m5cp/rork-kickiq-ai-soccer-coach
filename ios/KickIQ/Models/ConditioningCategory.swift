import Foundation

nonisolated enum ConditioningType: String, Codable, CaseIterable, Sendable, Identifiable {
    case sprints = "Sprints & Speed"
    case hiit = "HIIT & Intervals"
    case endurance = "Endurance"
    case strength = "Strength & Power"
    case agility = "Agility & Footwork"
    case flexibility = "Flexibility & Recovery"
    case plyometrics = "Plyometrics"
    case crossTraining = "Cross Training"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .sprints: "bolt.fill"
        case .hiit: "flame.fill"
        case .endurance: "heart.fill"
        case .strength: "dumbbell.fill"
        case .agility: "figure.run"
        case .flexibility: "figure.cooldown"
        case .plyometrics: "arrow.up.circle.fill"
        case .crossTraining: "figure.pool.swim"
        }
    }

    var color: String {
        switch self {
        case .sprints: "red"
        case .hiit: "orange"
        case .endurance: "blue"
        case .strength: "purple"
        case .agility: "green"
        case .flexibility: "teal"
        case .plyometrics: "pink"
        case .crossTraining: "cyan"
        }
    }

    static func classify(_ drill: Drill) -> ConditioningType {
        let tags = Set(drill.tags.map { $0.lowercased() })
        let name = drill.name.lowercased()
        let desc = drill.description.lowercased()

        if tags.contains("recovery") || tags.contains("flexibility") || name.contains("cooldown") || name.contains("stretch") || name.contains("warm-up") || name.contains("warmup") || name.contains("dynamic warm") {
            return .flexibility
        }
        if tags.contains("low-impact") || name.contains("water workout") || name.contains("bike") || name.contains("stairmaster") {
            return .crossTraining
        }
        if tags.contains("plyometrics") || name.contains("box jump") || name.contains("broad jump") || name.contains("bounding") {
            return .plyometrics
        }
        if tags.contains("strength") || name.contains("strength") || name.contains("bodyweight") || name.contains("circuit") && (name.contains("core") || name.contains("push") || name.contains("pull") || name.contains("lower body") || name.contains("upper body")) || name.contains("nordic") || name.contains("resistance band") {
            return .strength
        }
        if tags.contains("hiit") || name.contains("tabata") || name.contains("interval") || name.contains("30/30") || name.contains("burst interval") || name.contains("10-second burst") {
            return .hiit
        }
        if tags.contains("agility") || name.contains("agility") || name.contains("cone agility") || name.contains("t-drill") || name.contains("5-10-5") || name.contains("shuttle") || name.contains("balance") {
            return .agility
        }
        if tags.contains("endurance") || name.contains("tempo run") || name.contains("fartlek") || name.contains("yo-yo") || name.contains("track workout") || name.contains("pyramid") || name.contains("90-second") || name.contains("two-minute") || name.contains("one-minute") || name.contains("speed play") {
            return .endurance
        }
        if tags.contains("speed") || name.contains("sprint") || name.contains("flying") || name.contains("hill sprint") || name.contains("acceleration") || name.contains("repeat 100") || name.contains("progressive sprint") {
            return .sprints
        }

        if drill.intensity == .maximum || drill.intensity == .high {
            return .sprints
        }
        return .endurance
    }

    static func isConditioningDrill(_ drill: Drill) -> Bool {
        let conditioningTags: Set<String> = ["conditioning", "speed", "endurance", "hiit", "strength", "plyometrics", "agility", "recovery", "flexibility", "injury-prevention", "low-impact", "warmup", "balance", "core"]
        let tags = Set(drill.tags.map { $0.lowercased() })
        if !tags.isDisjoint(with: conditioningTags) { return true }

        let conditioningSkills: Set<String> = ["Movement", "Acceleration & Deceleration"]
        if conditioningSkills.contains(drill.targetSkill) { return true }

        let name = drill.name.lowercased()
        let conditioningNames = ["sprint", "interval", "tabata", "tempo run", "fartlek", "cooldown", "warm-up", "warmup", "stretch", "bodyweight", "plyometric", "box jump", "broad jump", "balance", "nordic", "resistance band", "agility", "shuttle", "stairmaster", "bike", "water workout", "track workout", "pyramid", "yo-yo"]
        return conditioningNames.contains(where: { name.contains($0) })
    }
}
