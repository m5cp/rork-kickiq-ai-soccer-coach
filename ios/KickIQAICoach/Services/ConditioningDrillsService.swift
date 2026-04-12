import Foundation

nonisolated enum DrillCategory: String, Codable, CaseIterable, Sendable, Identifiable {
    case skills = "Skills"
    case conditioning = "Conditioning"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .skills: "figure.soccer"
        case .conditioning: "heart.circle.fill"
        }
    }
}

nonisolated enum ConditioningFocus: String, Codable, CaseIterable, Sendable, Identifiable {
    case speed = "Speed & Agility"
    case endurance = "Endurance"
    case strength = "Strength"
    case flexibility = "Flexibility & Recovery"
    case plyometrics = "Plyometrics"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .speed: "hare.fill"
        case .endurance: "heart.fill"
        case .strength: "dumbbell.fill"
        case .flexibility: "figure.flexibility"
        case .plyometrics: "arrow.up.circle.fill"
        }
    }
}

@Observable
@MainActor
class ConditioningDrillsService {
    var conditioningDrills: [Drill] = []

    func loadDrills(for level: SkillLevel) {
        conditioningDrills = generateConditioningDrills(level: level)
    }

    func drillsByFocus() -> [(focus: ConditioningFocus, drills: [Drill])] {
        var groups: [ConditioningFocus: [Drill]] = [:]
        for drill in conditioningDrills {
            if let focus = ConditioningFocus.allCases.first(where: { drill.targetSkill == $0.rawValue }) {
                groups[focus, default: []].append(drill)
            }
        }
        return ConditioningFocus.allCases.compactMap { focus in
            guard let drills = groups[focus], !drills.isEmpty else { return nil }
            return (focus: focus, drills: drills)
        }
    }

    private func generateConditioningDrills(level: SkillLevel) -> [Drill] {
        let diff = difficultyFor(level)
        var drills: [Drill] = []

        drills.append(contentsOf: [
            Drill(name: "T-Drill Sprint", description: "Set up cones in a T shape. Sprint forward, shuffle left, shuffle right, then backpedal to start. Focus on quick direction changes and low center of gravity.", duration: "10 min", difficulty: diff, targetSkill: ConditioningFocus.speed.rawValue, coachingCues: ["Stay low through direction changes", "Push off outside foot", "Pump arms for acceleration"], reps: "6 reps"),
            Drill(name: "5-10-5 Shuttle", description: "Start at the middle cone. Sprint 5 yards right, touch the line, sprint 10 yards left, touch the line, then sprint 5 yards back to center.", duration: "8 min", difficulty: diff, targetSkill: ConditioningFocus.speed.rawValue, coachingCues: ["Explode out of each turn", "Drop hips to decelerate", "Stay on the balls of your feet"], reps: "8 reps"),
            Drill(name: "Ladder Quick Feet", description: "Run through an agility ladder using various foot patterns: in-in-out-out, icky shuffle, lateral crossover. Maintain speed through the full ladder.", duration: "10 min", difficulty: .beginner, targetSkill: ConditioningFocus.speed.rawValue, coachingCues: ["Light feet, quick contact", "Eyes up, not on feet", "Arms drive the rhythm"], reps: "4 patterns x 3 reps"),
            Drill(name: "Cone Weave Sprints", description: "Set 8 cones in a line 2 yards apart. Weave through at max speed, then sprint 20 yards past the last cone. Jog back and repeat.", duration: "10 min", difficulty: diff, targetSkill: ConditioningFocus.speed.rawValue, coachingCues: ["Sharp cuts, not wide arcs", "Lean into each turn", "Accelerate out of the weave"], reps: "6 reps")
        ])

        drills.append(contentsOf: [
            Drill(name: "Fartlek Run", description: "Alternate between 30 seconds of hard running and 60 seconds of easy jogging for the full duration. Simulate the stop-start nature of a match.", duration: "20 min", difficulty: diff, targetSkill: ConditioningFocus.endurance.rawValue, coachingCues: ["Push hard during fast intervals", "Use jog phase to recover breathing", "Maintain good running form even when tired"], reps: "Continuous"),
            Drill(name: "120s Interval Runs", description: "Sprint 120 yards in under 20 seconds. Walk back in 40 seconds. This simulates match-intensity running with incomplete recovery.", duration: "15 min", difficulty: .advanced, targetSkill: ConditioningFocus.endurance.rawValue, coachingCues: ["Maintain pace across all reps", "Drive knees and pump arms", "Focus on breathing pattern"], reps: "8–10 reps"),
            Drill(name: "Ball-at-Feet Endurance", description: "Dribble continuously around a large area at moderate pace. Every 60 seconds increase speed for 15 seconds. Keep the ball within playing distance.", duration: "15 min", difficulty: diff, targetSkill: ConditioningFocus.endurance.rawValue, coachingCues: ["Close control even when fatigued", "Change direction frequently", "Simulate match movement patterns"], reps: "3 sets of 4 min"),
            Drill(name: "Yo-Yo Intermittent Recovery", description: "Run 20 meters to a cone, turn and run back, then rest 10 seconds. Each round the pace increases. Continue until you cannot maintain the pace.", duration: "15 min", difficulty: diff, targetSkill: ConditioningFocus.endurance.rawValue, coachingCues: ["Pace yourself early", "Use the 10-second rest fully", "Stay light on your feet during turns"], reps: "To exhaustion")
        ])

        drills.append(contentsOf: [
            Drill(name: "Bodyweight Circuit", description: "Perform 10 push-ups, 15 squats, 10 lunges per leg, and a 30-second plank. Rest 30 seconds between rounds.", duration: "15 min", difficulty: diff, targetSkill: ConditioningFocus.strength.rawValue, coachingCues: ["Full range of motion on each rep", "Engage core throughout", "Control the tempo, no rushing"], reps: "4 rounds"),
            Drill(name: "Single-Leg Squat Holds", description: "Stand on one leg, lower into a quarter squat, and hold for 20 seconds. This builds the leg strength needed for shooting, jumping, and change of direction.", duration: "10 min", difficulty: diff, targetSkill: ConditioningFocus.strength.rawValue, coachingCues: ["Keep knee aligned over toes", "Engage glutes for stability", "Build up hold time gradually"], reps: "3 sets of 20 sec per leg"),
            Drill(name: "Nordic Hamstring Curl", description: "Kneel on the ground with a partner or anchor holding your ankles. Slowly lower your body forward, using hamstrings to control the descent. Push back up with hands if needed.", duration: "10 min", difficulty: .advanced, targetSkill: ConditioningFocus.strength.rawValue, coachingCues: ["Control the lowering phase", "Keep hips extended", "Use hands to push back only as needed"], reps: "3 sets of 6"),
            Drill(name: "Core Stability Series", description: "Front plank (45 sec), side plank each side (30 sec), dead bugs (12 reps), bird dogs (10 per side). Builds the core strength critical for balance and shielding.", duration: "12 min", difficulty: diff, targetSkill: ConditioningFocus.strength.rawValue, coachingCues: ["No sagging hips in plank", "Breathe steadily throughout", "Slow controlled movements"], reps: "3 rounds")
        ])

        drills.append(contentsOf: [
            Drill(name: "Dynamic Warm-Up Flow", description: "Leg swings (front-back and side-to-side), walking lunges with twist, inchworms, high knees, and butt kicks. Prepare your body for training.", duration: "10 min", difficulty: .beginner, targetSkill: ConditioningFocus.flexibility.rawValue, coachingCues: ["Gradually increase range of motion", "Keep movements controlled", "Focus on areas that feel tight"], reps: "2 rounds"),
            Drill(name: "Hip Mobility Circuit", description: "90/90 hip switches (10 per side), hip circles on all fours (8 per direction), pigeon stretch (30 sec per side), and frog stretch (30 sec). Crucial for soccer players.", duration: "12 min", difficulty: diff, targetSkill: ConditioningFocus.flexibility.rawValue, coachingCues: ["Go to tension, not pain", "Breathe into the stretch", "Consistent daily practice yields results"], reps: "2 rounds"),
            Drill(name: "Post-Training Cooldown", description: "Slow jog for 2 minutes, then static stretches: quad stretch, hamstring stretch, calf stretch, hip flexor stretch, and seated groin stretch. Hold each 30 seconds.", duration: "10 min", difficulty: .beginner, targetSkill: ConditioningFocus.flexibility.rawValue, coachingCues: ["Never skip the cooldown", "Hold stretches, don't bounce", "Breathe deeply and relax into each stretch"], reps: "Full routine")
        ])

        drills.append(contentsOf: [
            Drill(name: "Box Jump Progression", description: "Start with a low box (12-18 inches). Jump up with both feet, land softly, step down. Progress height as form improves. Builds explosive power for headers and sprints.", duration: "10 min", difficulty: diff, targetSkill: ConditioningFocus.plyometrics.rawValue, coachingCues: ["Land softly with bent knees", "Swing arms for momentum", "Step down, don't jump down"], reps: "4 sets of 8"),
            Drill(name: "Lateral Bound Series", description: "Stand on one leg, explode laterally to land on the opposite foot. Hold the landing for 2 seconds. Builds lateral power for defending and change of direction.", duration: "10 min", difficulty: diff, targetSkill: ConditioningFocus.plyometrics.rawValue, coachingCues: ["Push off forcefully", "Stick each landing", "Keep hips and knees aligned"], reps: "3 sets of 8 per side"),
            Drill(name: "Tuck Jumps", description: "Jump as high as possible, bringing knees to chest at the peak. Land softly and immediately jump again. Builds the explosive power needed for aerial duels.", duration: "8 min", difficulty: .advanced, targetSkill: ConditioningFocus.plyometrics.rawValue, coachingCues: ["Maximum height each jump", "Quick ground contact time", "Absorb landing through full body"], reps: "4 sets of 6"),
            Drill(name: "Single-Leg Hops", description: "Hop forward on one leg for 10 yards, then switch. Focus on height and distance. Develops single-leg power critical for shooting and sprinting.", duration: "10 min", difficulty: diff, targetSkill: ConditioningFocus.plyometrics.rawValue, coachingCues: ["Drive knee up on each hop", "Use arms for balance and power", "Land on the ball of your foot"], reps: "3 sets per leg")
        ])

        return drills
    }

    private func difficultyFor(_ level: SkillLevel) -> DrillDifficulty {
        switch level {
        case .beginner: .beginner
        case .intermediate: .intermediate
        case .competitive, .semiPro: .advanced
        }
    }
}
