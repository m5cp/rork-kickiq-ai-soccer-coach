import Foundation

nonisolated struct AssessmentChallenge: Identifiable, Sendable {
    let id: String
    let skill: SkillCategory
    let name: String
    let instruction: String
    let duration: Int
    let unit: String
    let icon: String

    init(
        id: String = UUID().uuidString,
        skill: SkillCategory,
        name: String,
        instruction: String,
        duration: Int = 20,
        unit: String = "reps",
        icon: String = "figure.soccer"
    ) {
        self.id = id
        self.skill = skill
        self.name = name
        self.instruction = instruction
        self.duration = duration
        self.unit = unit
        self.icon = icon
    }
}

nonisolated struct AssessmentResult: Codable, Sendable, Identifiable {
    let id: String
    let skill: String
    let challengeName: String
    let score: Int
    let date: Date

    init(
        id: String = UUID().uuidString,
        skill: String,
        challengeName: String,
        score: Int,
        date: Date = .now
    ) {
        self.id = id
        self.skill = skill
        self.challengeName = challengeName
        self.score = score
        self.date = date
    }
}

nonisolated struct SkillAssessmentSession: Codable, Sendable, Identifiable {
    let id: String
    let date: Date
    let results: [AssessmentResult]
    let overallScore: Int

    init(
        id: String = UUID().uuidString,
        date: Date = .now,
        results: [AssessmentResult]
    ) {
        self.id = id
        self.date = date
        self.results = results
        self.overallScore = results.isEmpty ? 0 : results.reduce(0) { $0 + $1.score } / results.count
    }
}

struct AssessmentChallengeLibrary {
    static func challenges(for position: PlayerPosition) -> [AssessmentChallenge] {
        let positionSkills = position.skills.prefix(5)
        return positionSkills.map { skill in
            challengeFor(skill)
        }
    }

    static func challengeFor(_ skill: SkillCategory) -> AssessmentChallenge {
        switch skill {
        case .firstTouch:
            return AssessmentChallenge(
                skill: skill,
                name: "Wall Touch Test",
                instruction: "Pass the ball against a wall and control the return. Count each clean first touch.",
                duration: 20,
                unit: "touches",
                icon: "hand.point.up.fill"
            )
        case .ballControl:
            return AssessmentChallenge(
                skill: skill,
                name: "Close Control Box",
                instruction: "Dribble inside a small area. Count each direction change without losing the ball.",
                duration: 30,
                unit: "changes",
                icon: "circle.dashed"
            )
        case .dribbling:
            return AssessmentChallenge(
                skill: skill,
                name: "Cone Weave Speed",
                instruction: "Weave through 6 cones and back. Count complete runs.",
                duration: 30,
                unit: "runs",
                icon: "figure.soccer"
            )
        case .passing:
            return AssessmentChallenge(
                skill: skill,
                name: "Target Passing",
                instruction: "Pass to a target from 10 yards. Count accurate passes that hit the target.",
                duration: 20,
                unit: "passes",
                icon: "arrow.right.arrow.left"
            )
        case .shooting:
            return AssessmentChallenge(
                skill: skill,
                name: "Target Finishing",
                instruction: "Shoot at corners of the goal from 12 yards. Count goals scored.",
                duration: 30,
                unit: "goals",
                icon: "scope"
            )
        case .finishing:
            return AssessmentChallenge(
                skill: skill,
                name: "Quick Fire Finishing",
                instruction: "One-touch finish from a set position. Count clean finishes on target.",
                duration: 20,
                unit: "goals",
                icon: "soccerball"
            )
        case .movement:
            return AssessmentChallenge(
                skill: skill,
                name: "Agility Shuttle",
                instruction: "Sprint between two cones 5 yards apart. Count complete shuttles.",
                duration: 20,
                unit: "shuttles",
                icon: "figure.run"
            )
        case .bodyPosition:
            return AssessmentChallenge(
                skill: skill,
                name: "Receive & Turn",
                instruction: "Receive a pass, check shoulder, turn and play forward. Count clean turns.",
                duration: 20,
                unit: "turns",
                icon: "figure.stand"
            )
        case .positioning:
            return AssessmentChallenge(
                skill: skill,
                name: "Angle Adjustment",
                instruction: "Start in goal. Adjust position for shots from 5 different angles. Self-rate 1-10.",
                duration: 30,
                unit: "rating",
                icon: "mappin.and.ellipse"
            )
        case .handling:
            return AssessmentChallenge(
                skill: skill,
                name: "Catch & Release",
                instruction: "Have someone throw balls at you. Count clean catches.",
                duration: 20,
                unit: "catches",
                icon: "hand.raised.fill"
            )
        case .distribution:
            return AssessmentChallenge(
                skill: skill,
                name: "Distribution Accuracy",
                instruction: "Distribute to targets at different distances. Count accurate deliveries.",
                duration: 30,
                unit: "deliveries",
                icon: "arrow.up.forward"
            )
        case .reflexes:
            return AssessmentChallenge(
                skill: skill,
                name: "Reaction Saves",
                instruction: "React to close-range shots. Count successful saves.",
                duration: 20,
                unit: "saves",
                icon: "bolt.fill"
            )
        case .scanning:
            return AssessmentChallenge(
                skill: skill,
                name: "Awareness Check",
                instruction: "While dribbling, call out objects held up by a partner. Count correct calls.",
                duration: 20,
                unit: "calls",
                icon: "eye.fill"
            )
        case .changeOfDirection:
            return AssessmentChallenge(
                skill: skill,
                name: "Direction Change Test",
                instruction: "Sprint and change direction at each cone in a zigzag. Count sharp changes.",
                duration: 20,
                unit: "changes",
                icon: "arrow.triangle.turn.up.right.diamond.fill"
            )
        case .acceleration:
            return AssessmentChallenge(
                skill: skill,
                name: "Sprint Burst Test",
                instruction: "From standing, sprint 10 yards. Walk back. Count complete sprints.",
                duration: 30,
                unit: "sprints",
                icon: "gauge.with.dots.needle.67percent"
            )
        case .defensiveFootwork:
            return AssessmentChallenge(
                skill: skill,
                name: "Defensive Shuffle",
                instruction: "Lateral shuffle between cones 3 yards apart. Count complete shuffles.",
                duration: 20,
                unit: "shuffles",
                icon: "shield.lefthalf.filled"
            )
        case .weakFoot:
            return AssessmentChallenge(
                skill: skill,
                name: "Weak Foot Passing",
                instruction: "Pass to a wall target using only your weak foot. Count accurate passes.",
                duration: 20,
                unit: "passes",
                icon: "shoe.fill"
            )
        case .communication:
            return AssessmentChallenge(
                skill: skill,
                name: "Communication Drill",
                instruction: "Direct teammates while organizing defense. Self-rate your clarity 1-10.",
                duration: 30,
                unit: "rating",
                icon: "megaphone.fill"
            )
        default:
            return AssessmentChallenge(
                skill: skill,
                name: "\(skill.rawValue) Test",
                instruction: "Perform your best for this skill. Count completed reps.",
                duration: 20,
                unit: "reps",
                icon: skill.icon
            )
        }
    }
}
