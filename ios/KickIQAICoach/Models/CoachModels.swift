import Foundation

enum GameMoment: String, Codable, CaseIterable, Identifiable {
    case highPress = "High Press"
    case lowBlock = "Low Block"
    case compactAndCover = "Compact and Cover"
    case defensiveTransition = "Defensive Transition"
    case immediatePress = "Immediate Press"
    case buildUpPlay = "Build Up Play"
    case combinationPlay = "Combination Play"
    case switchOfPlay = "Switch of Play"
    case counterAttack = "Counter Attack"
    case overloadPlay = "Overload Play"
    case defendTheBox = "Defend the Box"
    case highPercentageFinishing = "High Percentage Finishing"

    var id: String { rawValue }

    var subObjectives: [String] {
        switch self {
        case .highPress: return ["Delay and Force", "Ball Recovery", "Defensive Trap", "Force Wide", "Force Central"]
        case .lowBlock: return ["Compact and Cover", "Deny Central Entry", "Win Second Ball", "Recover Shape"]
        case .compactAndCover: return ["Close Space", "Track Runners", "Apply Pressure", "Cover Behind"]
        case .defensiveTransition: return ["Recover Shape", "Delay the Counter", "Recover Goal-Side", "Compact Quickly"]
        case .immediatePress: return ["Counter-Press", "Cut Passing Lanes", "Win Ball Back", "Hunt in Pairs"]
        case .buildUpPlay: return ["Support Movement", "Width and Depth", "Line Breaking Pass", "GK as Player"]
        case .combinationPlay: return ["Wall Pass", "Third Man Run", "Overlap", "Underlap", "Draw and Release"]
        case .switchOfPlay: return ["Exploit Weak Side", "Switch to Overload", "Quick Transition Wide"]
        case .counterAttack: return ["Quick Transition", "Run in Behind", "Exploit Numbers", "Early Shot"]
        case .overloadPlay: return ["Create Overload", "Exploit Overload", "Switch to Find Overload"]
        case .defendTheBox: return ["Zonal Defense", "Man Marking", "Win Aerial Duels", "GK Command"]
        case .highPercentageFinishing: return ["Placement Shot", "First Time Finish", "Attack the Cross", "Rebound"]
        }
    }

    var category: String {
        switch self {
        case .highPress, .lowBlock, .compactAndCover, .defendTheBox: return "Defending"
        case .buildUpPlay, .combinationPlay, .switchOfPlay, .overloadPlay: return "Attacking"
        case .counterAttack, .highPercentageFinishing: return "Attacking Transition"
        case .defensiveTransition, .immediatePress: return "Defensive Transition"
        }
    }

    var icon: String {
        switch self {
        case .highPress: return "arrow.up.circle.fill"
        case .lowBlock: return "shield.fill"
        case .compactAndCover: return "square.3.stack.3d.fill"
        case .defensiveTransition: return "arrow.uturn.backward.circle.fill"
        case .immediatePress: return "bolt.fill"
        case .buildUpPlay: return "arrow.up.forward.circle.fill"
        case .combinationPlay: return "arrow.triangle.2.circlepath"
        case .switchOfPlay: return "arrow.left.arrow.right"
        case .counterAttack: return "hare.fill"
        case .overloadPlay: return "person.3.fill"
        case .defendTheBox: return "rectangle.and.hand.point.up.left.fill"
        case .highPercentageFinishing: return "scope"
        }
    }
}

nonisolated enum TrainingPhase: String, Codable, CaseIterable, Identifiable, Sendable {
    case warmUp = "Warm-Up"
    case technical = "Technical"
    case tactical = "Tactical"
    case game = "Game"
    case coolDown = "Cool-Down"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .warmUp: return "flame"
        case .technical: return "figure.soccer"
        case .tactical: return "rectangle.3.group"
        case .game: return "soccerball"
        case .coolDown: return "leaf"
        }
    }

    var shortLabel: String {
        switch self {
        case .warmUp: return "WU"
        case .technical: return "TEC"
        case .tactical: return "TAC"
        case .game: return "GAM"
        case .coolDown: return "CD"
        }
    }
}

nonisolated struct SessionActivity: Codable, Identifiable {
    var id: UUID = UUID()
    var order: Int
    var title: String
    var customTitle: String?
    var duration: Int
    var fieldSize: String
    var playerNumbers: String
    var setupDescription: String
    var instructions: String
    var phases: [String]
    var coachingPoints: [String]
    var trainingPhase: TrainingPhase?

    var displayTitle: String {
        customTitle ?? title
    }

    var resolvedPhase: TrainingPhase {
        if let trainingPhase { return trainingPhase }
        switch order {
        case 1: return .warmUp
        case 2: return .technical
        case 3: return .tactical
        default: return .game
        }
    }
}

nonisolated struct CoachSession: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var customTitle: String?
    var gameMoment: GameMoment
    var customGameMoment: String?
    var objective: String
    var duration: Int
    var intensity: Int
    var ageGroup: String
    var playerCount: Int
    var activities: [SessionActivity]
    var notes: String
    var createdAt: Date = Date()

    var displayTitle: String {
        customTitle ?? title
    }

    var displayGameMoment: String {
        customGameMoment ?? gameMoment.rawValue
    }
}

nonisolated struct TrainingBlock: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var weeks: Int
    var sessions: [CoachSession]
    var startDate: Date
}

nonisolated struct PlayerEvaluation: Codable, Identifiable {
    var id: UUID = UUID()
    var playerName: String
    var evaluationDate: Date
    var technical: Int
    var tactical: Int
    var physical: Int
    var character: Int
    var notes: String

    var averageScore: Double {
        Double(technical + tactical + physical + character) / 4.0
    }
}
