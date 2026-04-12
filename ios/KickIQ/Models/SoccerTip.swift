import Foundation

nonisolated struct SoccerTip: Sendable {
    let text: String
    let category: String
    let icon: String

    static let allTips: [SoccerTip] = [
        SoccerTip(text: "Keep your head up while dribbling — scanning the field opens up passing lanes.", category: "Dribbling", icon: "eye.fill"),
        SoccerTip(text: "Receive the ball with the foot furthest from your defender to shield possession.", category: "First Touch", icon: "hand.point.up.fill"),
        SoccerTip(text: "Practice weak foot passing for 10 minutes every session — consistency beats intensity.", category: "Weak Foot", icon: "shoe.fill"),
        SoccerTip(text: "Plant your standing foot next to the ball and point it at your target when shooting.", category: "Shooting", icon: "scope"),
        SoccerTip(text: "Use the inside of your foot for short passes — it gives you the most surface area and control.", category: "Passing", icon: "arrow.right.arrow.left"),
        SoccerTip(text: "Check your shoulder before receiving to know where space and pressure are.", category: "Awareness", icon: "eye.fill"),
        SoccerTip(text: "Stay on the balls of your feet when defending — it helps you react faster.", category: "Defending", icon: "shield.lefthalf.filled"),
        SoccerTip(text: "After a sprint, recover with light jogging — don't stop completely.", category: "Fitness", icon: "heart.fill"),
        SoccerTip(text: "Visualize your next move before the ball arrives — great players think two steps ahead.", category: "Mental", icon: "brain.head.profile.fill"),
        SoccerTip(text: "Warm up with dynamic stretches, not static ones — save static stretches for cooldown.", category: "Recovery", icon: "figure.cooldown"),
        SoccerTip(text: "Communication is a skill too — call for the ball loudly and early.", category: "Communication", icon: "megaphone.fill"),
        SoccerTip(text: "Use your body as a shield when protecting the ball — lean into the defender.", category: "Ball Control", icon: "circle.dashed"),
        SoccerTip(text: "Bend your knees slightly on first touch — a lower center of gravity gives better control.", category: "First Touch", icon: "hand.point.up.fill"),
        SoccerTip(text: "Film yourself from behind the goal to see your movement patterns during practice.", category: "Analysis", icon: "video.fill"),
        SoccerTip(text: "Quality reps beat quantity — 30 focused minutes outperform 90 unfocused ones.", category: "Training", icon: "star.fill"),
        SoccerTip(text: "Rest days are training days for your muscles — recovery builds strength.", category: "Recovery", icon: "bed.double.fill"),
        SoccerTip(text: "Use cones at home to practice tight turns and direction changes.", category: "Agility", icon: "arrow.triangle.turn.up.right.diamond.fill"),
        SoccerTip(text: "Follow through on your shot — your kicking foot should end up pointing at the target.", category: "Shooting", icon: "scope"),
        SoccerTip(text: "Play small-sided games whenever possible — more touches, more decisions, faster learning.", category: "Game Sense", icon: "sportscourt.fill"),
        SoccerTip(text: "Drink water before you feel thirsty — staying hydrated improves reaction time and focus.", category: "Health", icon: "drop.fill"),
    ]

    static func tipOfTheDay() -> SoccerTip {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 1
        return allTips[dayOfYear % allTips.count]
    }
}
