import Foundation

struct AlgorithmicPlanBuilder {
    static func buildPlan(config: PlanConfig, position: PlayerPosition, skillLevel: SkillLevel) -> GeneratedPlan {
        let dayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        let focuses = config.focusAreas

        let drillPool: [Drill]
        if config.planType == .skills {
            let service = DrillsService()
            service.loadDrills(for: position, weakness: .firstTouch, skillLevel: skillLevel)
            drillPool = service.allDrills
        } else {
            let service = ConditioningDrillsService()
            service.loadDrills(for: skillLevel)
            drillPool = service.conditioningDrills
        }

        let focusDrillMap = buildFocusDrillMap(drills: drillPool, focuses: focuses, planType: config.planType)

        var planWeeks: [GeneratedPlanWeek] = []

        for weekNum in 1...config.weeks {
            let days: [TrainingPlanDay] = dayNames.enumerated().map { index, name in
                let isTraining = index < config.daysPerWeek
                guard isTraining else {
                    return TrainingPlanDay(dayLabel: name, focus: "Rest & Recovery", drills: [], restDay: true)
                }

                let focusArea = focuses.isEmpty ? "General" : focuses[index % focuses.count]
                let sessionDrills = selectDrillsForSession(
                    focus: focusArea,
                    focusDrillMap: focusDrillMap,
                    allDrills: drillPool,
                    minutesPerSession: config.minutesPerSession,
                    weekNumber: weekNum,
                    dayIndex: index,
                    skillLevel: skillLevel,
                    planType: config.planType
                )

                return TrainingPlanDay(dayLabel: name, focus: focusArea, drills: sessionDrills, restDay: false)
            }
            planWeeks.append(GeneratedPlanWeek(weekNumber: weekNum, days: days))
        }

        let focusNames = focuses.joined(separator: ", ")
        let totalDrills = planWeeks.flatMap(\.days).flatMap(\.drills).count
        let summary = "A \(config.weeks)-week \(config.planType.rawValue.lowercased()) program with \(config.daysPerWeek) training days per week, \(config.minutesPerSession) minutes per session. \(totalDrills) drills across \(focuses.count) focus areas: \(focusNames). Intensity increases each week with progressive overload."

        return GeneratedPlan(config: config, weeks: planWeeks, summary: summary)
    }

    private static func buildFocusDrillMap(drills: [Drill], focuses: [String], planType: GeneratedPlanType) -> [String: [Drill]] {
        var map: [String: [Drill]] = [:]
        for focus in focuses {
            if planType == .skills {
                if let skill = SkillCategory.allCases.first(where: { $0.rawValue == focus }) {
                    map[focus] = drills.filter { $0.targetSkill == skill.rawValue }
                }
            } else {
                if let cond = ConditioningFocus.allCases.first(where: { $0.rawValue == focus }) {
                    map[focus] = drills.filter { $0.targetSkill == cond.rawValue }
                }
            }
            if map[focus]?.isEmpty ?? true {
                map[focus] = drills.filter { $0.targetSkill.localizedStandardContains(focus) }
            }
        }
        return map
    }

    private static func selectDrillsForSession(
        focus: String,
        focusDrillMap: [String: [Drill]],
        allDrills: [Drill],
        minutesPerSession: Int,
        weekNumber: Int,
        dayIndex: Int,
        skillLevel: SkillLevel,
        planType: GeneratedPlanType
    ) -> [Drill] {
        let targetDrillCount = max(2, minutesPerSession / 15)
        let seed = weekNumber * 100 + dayIndex
        var rng = SeededRNG(seed: UInt64(seed))

        var candidates = focusDrillMap[focus] ?? []
        if candidates.isEmpty {
            candidates = allDrills
        }

        var shuffled = candidates
        shuffled.shuffle(using: &rng)

        let primaryCount = min(max(1, targetDrillCount - 1), shuffled.count)
        var selected = Array(shuffled.prefix(primaryCount))

        let remainingCount = targetDrillCount - selected.count
        if remainingCount > 0 {
            let otherDrills = allDrills.filter { drill in !selected.contains(where: { $0.name == drill.name }) }
            var otherShuffled = otherDrills
            otherShuffled.shuffle(using: &rng)
            selected.append(contentsOf: otherShuffled.prefix(remainingCount))
        }

        let perDrillTime = minutesPerSession / max(selected.count, 1)
        return selected.enumerated().map { idx, drill in
            let progressionMultiplier = 1.0 + Double(weekNumber - 1) * 0.15
            let adjustedReps = progressReps(baseReps: drill.reps, multiplier: progressionMultiplier, weekNumber: weekNumber)

            return Drill(
                name: drill.name,
                description: drill.description,
                duration: "\(perDrillTime) min",
                difficulty: drill.difficulty,
                targetSkill: drill.targetSkill,
                coachingCues: drill.coachingCues,
                reps: adjustedReps
            )
        }
    }

    private static func progressReps(baseReps: String, multiplier: Double, weekNumber: Int) -> String {
        guard !baseReps.isEmpty else {
            return "\(2 + weekNumber) sets of \(8 + weekNumber)"
        }

        let setsPattern = /(\d+)\s*sets?\s*(of|x|×)\s*(\d+)/
        if let match = baseReps.firstMatch(of: setsPattern) {
            let baseSets = Int(match.output.1) ?? 3
            let baseCount = Int(match.output.3) ?? 10
            let newSets = min(baseSets + (weekNumber - 1) / 2, baseSets + 2)
            let newCount = min(Int(Double(baseCount) * multiplier), baseCount + 6)
            return "\(newSets) sets of \(newCount)"
        }

        let repsOnlyPattern = /(\d+)\s*reps?/
        if let match = baseReps.firstMatch(of: repsOnlyPattern) {
            let base = Int(match.output.1) ?? 10
            let newCount = min(Int(Double(base) * multiplier), base + 6)
            return "\(newCount) reps"
        }

        if weekNumber > 1 {
            return "\(baseReps) (Week \(weekNumber): +intensity)"
        }
        return baseReps
    }
}

struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}
