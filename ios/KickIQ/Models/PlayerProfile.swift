import Foundation

nonisolated enum PlayerPosition: String, Codable, CaseIterable, Sendable, Identifiable {
    case goalkeeper = "Goalkeeper"
    case defender = "Defender"
    case midfielder = "Midfielder"
    case winger = "Winger"
    case striker = "Striker"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .goalkeeper: "hand.raised.fill"
        case .defender: "shield.fill"
        case .midfielder: "arrow.triangle.2.circlepath"
        case .winger: "bolt.horizontal.fill"
        case .striker: "scope"
        }
    }

    var skills: [SkillCategory] {
        switch self {
        case .goalkeeper:
            [.positioning, .handling, .distribution, .reflexes, .communication, .bodyPosition]
        case .defender:
            [.firstTouch, .bodyPosition, .defensiveFootwork, .passing, .ballControl, .acceleration, .scanning, .weakFoot]
        case .midfielder:
            [.firstTouch, .passing, .ballControl, .dribbling, .scanning, .bodyPosition, .changeOfDirection, .weakFoot]
        case .winger:
            [.firstTouch, .dribbling, .acceleration, .changeOfDirection, .passing, .finishing, .weakFoot, .scanning]
        case .striker:
            [.firstTouch, .finishing, .bodyPosition, .dribbling, .movement, .weakFoot, .shooting, .scanning]
        }
    }
}

nonisolated enum AgeRange: String, Codable, CaseIterable, Sendable, Identifiable {
    case under12 = "Under 12"
    case twelve15 = "12–15"
    case sixteen18 = "16–18"
    case eighteenPlus = "18+"

    var id: String { rawValue }
}

nonisolated enum SkillLevel: String, Codable, CaseIterable, Sendable, Identifiable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case competitive = "Competitive"
    case semiPro = "Semi-Pro"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .beginner: "Just getting started"
        case .intermediate: "Training regularly"
        case .competitive: "Playing in leagues"
        case .semiPro: "Competing at a high level"
        }
    }
}

nonisolated enum WeaknessArea: String, Codable, CaseIterable, Sendable, Identifiable {
    case firstTouch = "First Touch"
    case shooting = "Shooting"
    case dribbling = "Dribbling"
    case defending = "Defending"
    case fitness = "Fitness"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .firstTouch: "hand.point.up.fill"
        case .shooting: "scope"
        case .dribbling: "figure.soccer"
        case .defending: "shield.lefthalf.filled"
        case .fitness: "heart.fill"
        }
    }
}

nonisolated enum SkillCategory: String, Codable, CaseIterable, Sendable, Identifiable {
    case firstTouch = "First Touch"
    case bodyPosition = "Body Position"
    case ballControl = "Ball Control"
    case shooting = "Shooting Form"
    case movement = "Movement"
    case positioning = "Positioning"
    case handling = "Handling"
    case distribution = "Distribution"
    case reflexes = "Reflexes"
    case communication = "Communication"
    case passing = "Passing"
    case dribbling = "Dribbling"
    case finishing = "Finishing"
    case scanning = "Scanning & Awareness"
    case changeOfDirection = "Change of Direction"
    case acceleration = "Acceleration & Deceleration"
    case defensiveFootwork = "Defensive Footwork"
    case weakFoot = "Weak Foot Usage"
    case turning = "Turning"
    case striking = "Striking"
    case receiving = "Receiving"
    case juggling = "Juggling"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .firstTouch: "hand.point.up.fill"
        case .bodyPosition: "figure.stand"
        case .ballControl: "circle.dashed"
        case .shooting: "scope"
        case .movement: "figure.run"
        case .positioning: "mappin.and.ellipse"
        case .handling: "hand.raised.fill"
        case .distribution: "arrow.up.forward"
        case .reflexes: "bolt.fill"
        case .communication: "megaphone.fill"
        case .passing: "arrow.right.arrow.left"
        case .dribbling: "figure.soccer"
        case .finishing: "soccerball"
        case .scanning: "eye.fill"
        case .changeOfDirection: "arrow.triangle.turn.up.right.diamond.fill"
        case .acceleration: "gauge.with.dots.needle.67percent"
        case .defensiveFootwork: "shield.lefthalf.filled"
        case .weakFoot: "shoe.fill"
        case .turning: "arrow.uturn.right"
        case .striking: "shoe.2.fill"
        case .receiving: "arrow.down.to.line"
        case .juggling: "circle.grid.3x3"
        }
    }
}

nonisolated enum ProfileAvatar: Codable, Sendable, Equatable {
    case symbol(String)
    case imageData(Data)

    var symbolName: String? {
        if case .symbol(let name) = self { return name }
        return nil
    }

    var imageDataValue: Data? {
        if case .imageData(let data) = self { return data }
        return nil
    }
}

nonisolated struct PlayerProfile: Codable, Sendable {
    var name: String
    var position: PlayerPosition
    var ageRange: AgeRange
    var skillLevel: SkillLevel
    var weakness: WeaknessArea
    var createdAt: Date
    var avatar: ProfileAvatar?

    init(
        name: String = "",
        position: PlayerPosition = .midfielder,
        ageRange: AgeRange = .sixteen18,
        skillLevel: SkillLevel = .beginner,
        weakness: WeaknessArea = .firstTouch,
        createdAt: Date = .now,
        avatar: ProfileAvatar? = nil
    ) {
        self.name = name
        self.position = position
        self.ageRange = ageRange
        self.skillLevel = skillLevel
        self.weakness = weakness
        self.createdAt = createdAt
        self.avatar = avatar
    }
}
