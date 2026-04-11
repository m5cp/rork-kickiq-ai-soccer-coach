import Foundation

nonisolated struct FocusCategory: Codable, Sendable, Identifiable {
    let id: String
    let skill: SkillCategory
    let displayName: String
    let shortDescription: String
    let drillCount: Int
    let relevantPositions: [PlayerPosition]
    let priorityScore: Double
    let isWeakness: Bool

    init(
        id: String = UUID().uuidString,
        skill: SkillCategory,
        displayName: String = "",
        shortDescription: String = "",
        drillCount: Int = 0,
        relevantPositions: [PlayerPosition] = PlayerPosition.allCases,
        priorityScore: Double = 0,
        isWeakness: Bool = false
    ) {
        self.id = id
        self.skill = skill
        self.displayName = displayName.isEmpty ? skill.rawValue : displayName
        self.shortDescription = shortDescription.isEmpty ? FocusCategory.defaultDescription(for: skill) : shortDescription
        self.drillCount = drillCount
        self.relevantPositions = relevantPositions
        self.priorityScore = priorityScore
        self.isWeakness = isWeakness
    }

    var icon: String { skill.icon }

    private static func defaultDescription(for skill: SkillCategory) -> String {
        switch skill {
        case .firstTouch: "Control the ball cleanly on first contact"
        case .bodyPosition: "Optimize stance and orientation for play"
        case .ballControl: "Maintain possession under pressure"
        case .shooting: "Strike with accuracy and power"
        case .movement: "Create space with intelligent runs"
        case .positioning: "Read the game and find optimal positions"
        case .handling: "Secure the ball with clean catches"
        case .distribution: "Start attacks with precise delivery"
        case .reflexes: "React quickly to close-range shots"
        case .communication: "Organize teammates and command the box"
        case .passing: "Deliver accurate passes at all ranges"
        case .dribbling: "Beat defenders with close control and pace"
        case .finishing: "Convert chances with composure"
        case .scanning: "Build awareness through constant head movement"
        case .changeOfDirection: "Cut and turn explosively"
        case .acceleration: "Burst into top speed and brake sharply"
        case .defensiveFootwork: "Jockey and contain attackers"
        case .weakFoot: "Develop your non-dominant foot"
        }
    }

    static func fromSkillCategories(for position: PlayerPosition, weaknesses: [SkillCategory] = [], drillCounts: [SkillCategory: Int] = [:]) -> [FocusCategory] {
        let weakSet = Set(weaknesses)
        return position.skills.enumerated().map { index, skill in
            FocusCategory(
                skill: skill,
                drillCount: drillCounts[skill] ?? 0,
                relevantPositions: PlayerPosition.allCases.filter { $0.skills.contains(skill) },
                priorityScore: weakSet.contains(skill) ? 1.0 : max(0, 1.0 - Double(index) * 0.1),
                isWeakness: weakSet.contains(skill)
            )
        }.sorted { $0.priorityScore > $1.priorityScore }
    }
}
