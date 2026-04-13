import Foundation

struct PlayerContext {
    let position: PlayerPosition
    let skillLevel: SkillLevel
    let ageRange: AgeRange
    let gender: PlayerGender
    let weakestSkills: [SkillCategory]
    let benchmarkWeakCategories: [BenchmarkCategory]
    let benchmarkResults: [BenchmarkResult]
    let recentDrillNames: Set<String>
    let completedDrillIDs: Set<String>
    let totalTrainingMinutes: Int
    let streakCount: Int

    init(
        position: PlayerPosition = .midfielder,
        skillLevel: SkillLevel = .intermediate,
        ageRange: AgeRange = .fifteen18,
        gender: PlayerGender = .male,
        weakestSkills: [SkillCategory] = [],
        benchmarkWeakCategories: [BenchmarkCategory] = [],
        benchmarkResults: [BenchmarkResult] = [],
        recentDrillNames: Set<String> = [],
        completedDrillIDs: Set<String> = [],
        totalTrainingMinutes: Int = 0,
        streakCount: Int = 0
    ) {
        self.position = position
        self.skillLevel = skillLevel
        self.ageRange = ageRange
        self.gender = gender
        self.weakestSkills = weakestSkills
        self.benchmarkWeakCategories = benchmarkWeakCategories
        self.benchmarkResults = benchmarkResults
        self.recentDrillNames = recentDrillNames
        self.completedDrillIDs = completedDrillIDs
        self.totalTrainingMinutes = totalTrainingMinutes
        self.streakCount = streakCount
    }

    static func from(storage: StorageService) -> PlayerContext {
        let recentCompletions = storage.drillCompletionHistory.prefix(30)
        let recentNames = Set(recentCompletions.map(\.drillName))

        return PlayerContext(
            position: storage.profile?.position ?? .midfielder,
            skillLevel: storage.profile?.skillLevel ?? .intermediate,
            ageRange: storage.profile?.ageRange ?? .fifteen18,
            gender: storage.profile?.gender ?? .male,
            weakestSkills: storage.weakestSkills,
            benchmarkWeakCategories: storage.benchmarkWeakestCategories,
            benchmarkResults: storage.benchmarkResults,
            recentDrillNames: recentNames,
            completedDrillIDs: storage.completedDrillIDs,
            totalTrainingMinutes: storage.totalDrillMinutes,
            streakCount: storage.streakCount
        )
    }
}

struct AlgorithmicPlanBuilder {

    // MARK: - Main Entry

    static func buildPlan(config: PlanConfig, context: PlayerContext) -> GeneratedPlan {
        let dayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

        let allSkillDrills = loadSkillDrills(context: context)
        let allConditioningDrills = loadConditioningDrills(context: context)

        let drillPool: [Drill]
        if config.planType == .skills {
            drillPool = allSkillDrills
        } else {
            drillPool = allConditioningDrills
        }

        let focusWeights = computeFocusWeights(
            focuses: config.focusAreas,
            context: context,
            planType: config.planType
        )

        let sortedFocuses = focusWeights.sorted { $0.value > $1.value }.map(\.key)

        var planWeeks: [GeneratedPlanWeek] = []

        for weekNum in 1...config.weeks {
            let weekIntensity = weekIntensityProfile(
                weekNumber: weekNum,
                totalWeeks: config.weeks,
                skillLevel: context.skillLevel
            )

            let trainingDayCount = min(config.daysPerWeek, 7)
            let restDayIndices = computeRestDays(daysPerWeek: trainingDayCount)

            var days: [TrainingPlanDay] = []
            var usedDrillNamesThisWeek: Set<String> = []
            var trainingDayIndex = 0

            for dayIndex in 0..<7 {
                let dayName = dayNames[dayIndex]

                if restDayIndices.contains(dayIndex) {
                    days.append(TrainingPlanDay(dayLabel: dayName, focus: "Rest & Recovery", drills: [], restDay: true))
                    continue
                }

                let focusForDay = assignFocusForDay(
                    trainingDayIndex: trainingDayIndex,
                    sortedFocuses: sortedFocuses,
                    weekNumber: weekNum
                )

                let sessionStructure = buildSessionStructure(
                    focus: focusForDay,
                    drillPool: drillPool,
                    supplementaryPool: config.planType == .skills ? allConditioningDrills : allSkillDrills,
                    minutesPerSession: config.minutesPerSession,
                    weekIntensity: weekIntensity,
                    weekNumber: weekNum,
                    dayIndex: trainingDayIndex,
                    context: context,
                    config: config,
                    usedThisWeek: usedDrillNamesThisWeek
                )

                for drill in sessionStructure {
                    usedDrillNamesThisWeek.insert(drill.name)
                }

                days.append(TrainingPlanDay(dayLabel: dayName, focus: focusForDay, drills: sessionStructure, restDay: false))
                trainingDayIndex += 1
            }

            planWeeks.append(GeneratedPlanWeek(weekNumber: weekNum, days: days))
        }

        let summary = buildSummary(config: config, context: context, weeks: planWeeks, focusWeights: focusWeights)

        return GeneratedPlan(config: config, weeks: planWeeks, summary: summary)
    }

    // MARK: - Backward Compatible Entry

    static func buildPlan(config: PlanConfig, position: PlayerPosition, skillLevel: SkillLevel) -> GeneratedPlan {
        let context = PlayerContext(position: position, skillLevel: skillLevel)
        return buildPlan(config: config, context: context)
    }

    // MARK: - Focus Weight Computation

    private static func computeFocusWeights(
        focuses: [String],
        context: PlayerContext,
        planType: GeneratedPlanType
    ) -> [String: Double] {
        var weights: [String: Double] = [:]
        let basePortion = 1.0 / max(Double(focuses.count), 1.0)

        for focus in focuses {
            weights[focus] = basePortion
        }

        if planType == .skills {
            for weakSkill in context.weakestSkills {
                if let w = weights[weakSkill.rawValue] {
                    weights[weakSkill.rawValue] = w * 1.5
                }
            }
        }

        for benchCat in context.benchmarkWeakCategories {
            let mapped = mapBenchmarkToFocus(benchCat, planType: planType)
            if let match = mapped, let w = weights[match] {
                weights[match] = w * 1.3
            }
        }

        let positionPriorities = positionFocusPriorities(context.position, planType: planType)
        for (focus, multiplier) in positionPriorities {
            if let w = weights[focus] {
                weights[focus] = w * multiplier
            }
        }

        let total = weights.values.reduce(0, +)
        if total > 0 {
            for key in weights.keys {
                weights[key] = (weights[key] ?? 0) / total
            }
        }

        return weights
    }

    private static func positionFocusPriorities(_ position: PlayerPosition, planType: GeneratedPlanType) -> [String: Double] {
        if planType == .conditioning {
            switch position {
            case .goalkeeper:
                return [
                    ConditioningFocus.plyometrics.rawValue: 1.3,
                    ConditioningFocus.flexibility.rawValue: 1.2,
                    ConditioningFocus.speed.rawValue: 1.1
                ]
            case .defender:
                return [
                    ConditioningFocus.strength.rawValue: 1.3,
                    ConditioningFocus.speed.rawValue: 1.2,
                    ConditioningFocus.endurance.rawValue: 1.1
                ]
            case .midfielder:
                return [
                    ConditioningFocus.endurance.rawValue: 1.4,
                    ConditioningFocus.speed.rawValue: 1.1
                ]
            case .winger:
                return [
                    ConditioningFocus.speed.rawValue: 1.4,
                    ConditioningFocus.plyometrics.rawValue: 1.2
                ]
            case .striker:
                return [
                    ConditioningFocus.plyometrics.rawValue: 1.3,
                    ConditioningFocus.speed.rawValue: 1.3
                ]
            case .coachTrainer:
                return [:]
            }
        }

        switch position {
        case .goalkeeper:
            return [
                SkillCategory.reflexes.rawValue: 1.4,
                SkillCategory.handling.rawValue: 1.3,
                SkillCategory.positioning.rawValue: 1.2,
                SkillCategory.distribution.rawValue: 1.1
            ]
        case .defender:
            return [
                SkillCategory.bodyPosition.rawValue: 1.3,
                SkillCategory.firstTouch.rawValue: 1.2,
                SkillCategory.movement.rawValue: 1.1
            ]
        case .midfielder:
            return [
                SkillCategory.ballControl.rawValue: 1.2,
                SkillCategory.firstTouch.rawValue: 1.3,
                SkillCategory.movement.rawValue: 1.1
            ]
        case .winger:
            return [
                SkillCategory.ballControl.rawValue: 1.3,
                SkillCategory.movement.rawValue: 1.3,
                SkillCategory.shooting.rawValue: 1.1
            ]
        case .striker:
            return [
                SkillCategory.shooting.rawValue: 1.4,
                SkillCategory.firstTouch.rawValue: 1.2,
                SkillCategory.movement.rawValue: 1.2
            ]
        case .coachTrainer:
            return [:]
        }
    }

    private static func mapBenchmarkToFocus(_ category: BenchmarkCategory, planType: GeneratedPlanType) -> String? {
        if planType == .skills {
            switch category {
            case .ballControl: return SkillCategory.ballControl.rawValue
            case .firstTouch: return SkillCategory.firstTouch.rawValue
            case .passing: return SkillCategory.bodyPosition.rawValue
            case .shooting: return SkillCategory.shooting.rawValue
            case .dribbling: return SkillCategory.ballControl.rawValue
            case .agility: return SkillCategory.movement.rawValue
            case .endurance: return SkillCategory.movement.rawValue
            }
        } else {
            switch category {
            case .agility: return ConditioningFocus.speed.rawValue
            case .endurance: return ConditioningFocus.endurance.rawValue
            case .ballControl, .dribbling: return ConditioningFocus.speed.rawValue
            case .shooting: return ConditioningFocus.strength.rawValue
            case .firstTouch, .passing: return ConditioningFocus.flexibility.rawValue
            }
        }
    }

    // MARK: - Rest Day Placement

    private static func computeRestDays(daysPerWeek: Int) -> Set<Int> {
        let totalRest = 7 - daysPerWeek
        guard totalRest > 0 else { return [] }

        switch totalRest {
        case 1: return [6]
        case 2: return [3, 6]
        case 3: return [2, 4, 6]
        case 4: return [1, 3, 5, 6]
        default: return Set(Array((7 - totalRest)..<7))
        }
    }

    // MARK: - Focus Assignment Per Day

    private static func assignFocusForDay(
        trainingDayIndex: Int,
        sortedFocuses: [String],
        weekNumber: Int
    ) -> String {
        guard !sortedFocuses.isEmpty else { return "General" }
        let rotationOffset = (weekNumber - 1) % sortedFocuses.count
        let index = (trainingDayIndex + rotationOffset) % sortedFocuses.count
        return sortedFocuses[index]
    }

    // MARK: - Session Structure

    private static func buildSessionStructure(
        focus: String,
        drillPool: [Drill],
        supplementaryPool: [Drill],
        minutesPerSession: Int,
        weekIntensity: WeekIntensity,
        weekNumber: Int,
        dayIndex: Int,
        context: PlayerContext,
        config: PlanConfig,
        usedThisWeek: Set<String>
    ) -> [Drill] {
        let seed = weekNumber * 1000 + dayIndex * 100 + config.planType.hashValue
        var rng = SeededRNG(seed: UInt64(seed))

        let warmupMinutes = warmupDuration(for: minutesPerSession, ageRange: context.ageRange)
        let cooldownMinutes = cooldownDuration(for: minutesPerSession, ageRange: context.ageRange)
        let mainWorkMinutes = minutesPerSession - warmupMinutes - cooldownMinutes

        var sessionDrills: [Drill] = []

        if warmupMinutes > 0 {
            let warmup = selectWarmup(
                from: supplementaryPool.isEmpty ? drillPool : supplementaryPool,
                minutes: warmupMinutes,
                rng: &rng,
                context: context
            )
            sessionDrills.append(contentsOf: warmup)
        }

        let focusDrills = drillPool.filter { $0.targetSkill == focus }
        let relatedDrills = drillPool.filter { $0.targetSkill != focus }

        let mainDrillCount = max(2, mainWorkMinutes / 12)
        let primaryCount = max(1, Int(ceil(Double(mainDrillCount) * 0.65)))
        let secondaryCount = mainDrillCount - primaryCount

        let scoredPrimary = scoreDrills(
            focusDrills.isEmpty ? drillPool : focusDrills,
            context: context,
            usedThisWeek: usedThisWeek,
            weekIntensity: weekIntensity,
            rng: &rng
        )

        let selectedPrimary = pickTopDrills(from: scoredPrimary, count: primaryCount, rng: &rng)

        let usedNames = usedThisWeek.union(Set(selectedPrimary.map(\.name)))
        let scoredSecondary = scoreDrills(
            relatedDrills.isEmpty ? drillPool : relatedDrills,
            context: context,
            usedThisWeek: usedNames,
            weekIntensity: weekIntensity,
            rng: &rng
        )
        let selectedSecondary = pickTopDrills(from: scoredSecondary, count: secondaryCount, rng: &rng)

        let perDrillTime = mainWorkMinutes / max(mainDrillCount, 1)
        let mainDrills = (selectedPrimary + selectedSecondary).map { drill in
            applyProgression(drill: drill, perDrillTime: perDrillTime, weekNumber: weekNumber, weekIntensity: weekIntensity, context: context)
        }
        sessionDrills.append(contentsOf: mainDrills)

        if cooldownMinutes > 0 {
            let cooldown = selectCooldown(from: supplementaryPool.isEmpty ? drillPool : supplementaryPool, minutes: cooldownMinutes, rng: &rng)
            sessionDrills.append(contentsOf: cooldown)
        }

        return sessionDrills
    }

    // MARK: - Drill Scoring

    private static func scoreDrills(
        _ drills: [Drill],
        context: PlayerContext,
        usedThisWeek: Set<String>,
        weekIntensity: WeekIntensity,
        rng: inout SeededRNG
    ) -> [(drill: Drill, score: Double)] {
        drills.map { drill in
            var score: Double = 50.0

            let diff = drill.difficulty
            let targetDiff = targetDifficulty(for: context.skillLevel)
            if diff == targetDiff {
                score += 20
            } else if diff == .intermediate {
                score += 10
            }

            if weekIntensity == .deload && diff == .advanced {
                score -= 15
            }
            if weekIntensity == .peak && diff == .beginner {
                score -= 10
            }

            let weakNames = Set(context.weakestSkills.map(\.rawValue))
            if weakNames.contains(drill.targetSkill) {
                score += 25
            }

            for benchCat in context.benchmarkWeakCategories {
                let mapped = mapBenchmarkToFocus(benchCat, planType: drill.targetSkill.contains("Speed") || drill.targetSkill.contains("Endurance") || drill.targetSkill.contains("Strength") || drill.targetSkill.contains("Flexibility") || drill.targetSkill.contains("Plyometrics") ? .conditioning : .skills)
                if mapped == drill.targetSkill {
                    score += 15
                }
            }

            if usedThisWeek.contains(drill.name) {
                score -= 30
            }
            if context.recentDrillNames.contains(drill.name) {
                score -= 10
            }

            if !context.completedDrillIDs.contains(drill.id) {
                score += 5
            }

            let randomBonus = Double(rng.next() % 20)
            score += randomBonus

            return (drill: drill, score: max(score, 0))
        }
    }

    private static func pickTopDrills(from scored: [(drill: Drill, score: Double)], count: Int, rng: inout SeededRNG) -> [Drill] {
        let sorted = scored.sorted { $0.score > $1.score }
        let topPoolSize = min(sorted.count, count * 3)
        guard topPoolSize > 0 else { return [] }
        var topPool = Array(sorted.prefix(topPoolSize))
        topPool.shuffle(using: &rng)

        var selected: [Drill] = []
        var usedNames: Set<String> = []
        for item in topPool {
            guard selected.count < count else { break }
            guard !usedNames.contains(item.drill.name) else { continue }
            selected.append(item.drill)
            usedNames.insert(item.drill.name)
        }

        if selected.count < count {
            for item in sorted {
                guard selected.count < count else { break }
                guard !usedNames.contains(item.drill.name) else { continue }
                selected.append(item.drill)
                usedNames.insert(item.drill.name)
            }
        }

        return selected
    }

    // MARK: - Warm-up & Cooldown

    private static func warmupDuration(for sessionMinutes: Int, ageRange: AgeRange) -> Int {
        if sessionMinutes <= 15 { return 0 }
        switch ageRange {
        case .under8, .nine12: return min(5, sessionMinutes / 6)
        default: return min(8, sessionMinutes / 5)
        }
    }

    private static func cooldownDuration(for sessionMinutes: Int, ageRange: AgeRange) -> Int {
        if sessionMinutes <= 15 { return 0 }
        if sessionMinutes <= 30 { return 3 }
        return 5
    }

    private static func selectWarmup(from pool: [Drill], minutes: Int, rng: inout SeededRNG, context: PlayerContext) -> [Drill] {
        let flexDrills = pool.filter {
            $0.targetSkill == ConditioningFocus.flexibility.rawValue || $0.difficulty == .beginner
        }
        let candidates = flexDrills.isEmpty ? pool.filter { $0.difficulty == .beginner } : flexDrills
        guard !candidates.isEmpty else {
            return [Drill(name: "Dynamic Warm-Up", description: "Leg swings, high knees, butt kicks, and light jogging to prepare your body for training.", duration: "\(minutes) min", difficulty: .beginner, targetSkill: "Warm-Up", coachingCues: ["Gradually increase range of motion", "Keep movements controlled", "Focus on areas that feel tight"], reps: "2 rounds")]
        }
        var shuffled = candidates
        shuffled.shuffle(using: &rng)
        let warmup = shuffled.first!
        return [Drill(name: warmup.name, description: warmup.description, duration: "\(minutes) min", difficulty: .beginner, targetSkill: warmup.targetSkill, coachingCues: warmup.coachingCues, reps: warmup.reps)]
    }

    private static func selectCooldown(from pool: [Drill], minutes: Int, rng: inout SeededRNG) -> [Drill] {
        let flexDrills = pool.filter { $0.targetSkill == ConditioningFocus.flexibility.rawValue }
        if let cooldown = flexDrills.last {
            return [Drill(name: cooldown.name, description: cooldown.description, duration: "\(minutes) min", difficulty: .beginner, targetSkill: cooldown.targetSkill, coachingCues: cooldown.coachingCues, reps: cooldown.reps)]
        }
        return [Drill(name: "Cooldown Stretch", description: "Slow jog, then static stretches: quads, hamstrings, calves, hip flexors, groin. Hold each for 30 seconds.", duration: "\(minutes) min", difficulty: .beginner, targetSkill: "Recovery", coachingCues: ["Never skip the cooldown", "Hold stretches, don't bounce", "Breathe deeply and relax"], reps: "Full routine")]
    }

    // MARK: - Progression

    private static func applyProgression(
        drill: Drill,
        perDrillTime: Int,
        weekNumber: Int,
        weekIntensity: WeekIntensity,
        context: PlayerContext
    ) -> Drill {
        let intensityMultiplier: Double
        switch weekIntensity {
        case .base: intensityMultiplier = 1.0
        case .build: intensityMultiplier = 1.0 + Double(weekNumber - 1) * 0.1
        case .peak: intensityMultiplier = 1.0 + Double(weekNumber - 1) * 0.15
        case .deload: intensityMultiplier = 0.75
        }

        let ageMultiplier: Double
        switch context.ageRange {
        case .under8: ageMultiplier = 0.6
        case .nine12: ageMultiplier = 0.75
        case .thirteen14: ageMultiplier = 0.85
        case .fifteen18: ageMultiplier = 1.0
        case .eighteenPlus: ageMultiplier = 1.1
        }

        let combined = intensityMultiplier * ageMultiplier
        let adjustedReps = progressReps(baseReps: drill.reps, multiplier: combined, weekNumber: weekNumber)

        return Drill(
            name: drill.name,
            description: drill.description,
            duration: "\(max(perDrillTime, 5)) min",
            difficulty: drill.difficulty,
            targetSkill: drill.targetSkill,
            coachingCues: drill.coachingCues,
            reps: adjustedReps
        )
    }

    // MARK: - Week Intensity Profile (Periodization)

    enum WeekIntensity {
        case base, build, peak, deload
    }

    private static func weekIntensityProfile(weekNumber: Int, totalWeeks: Int, skillLevel: SkillLevel) -> WeekIntensity {
        if totalWeeks <= 2 { return weekNumber == 1 ? .build : .peak }
        if totalWeeks == 3 { return [.build, .peak, .base][weekNumber - 1] }

        let cyclePosition = (weekNumber - 1) % 4
        switch cyclePosition {
        case 0: return .base
        case 1: return .build
        case 2: return .peak
        case 3: return .deload
        default: return .build
        }
    }

    // MARK: - Difficulty Mapping

    private static func targetDifficulty(for level: SkillLevel) -> DrillDifficulty {
        switch level {
        case .beginner: return .beginner
        case .intermediate: return .intermediate
        case .competitive, .semiPro: return .advanced
        }
    }

    // MARK: - Load Drills

    private static func loadSkillDrills(context: PlayerContext) -> [Drill] {
        let service = DrillsService()
        let weakness: WeaknessArea = context.weakestSkills.first.flatMap { skill in
            switch skill {
            case .firstTouch: return .firstTouch
            case .shooting: return .shooting
            case .ballControl: return .dribbling
            case .bodyPosition: return .defending
            case .movement: return .fitness
            default: return .firstTouch
            }
        } ?? .firstTouch
        service.loadDrills(for: context.position, weakness: weakness, skillLevel: context.skillLevel)
        return service.allDrills
    }

    private static func loadConditioningDrills(context: PlayerContext) -> [Drill] {
        let service = ConditioningDrillsService()
        service.loadDrills(for: context.skillLevel)
        return service.conditioningDrills
    }

    // MARK: - Rep Progression

    private static func progressReps(baseReps: String, multiplier: Double, weekNumber: Int) -> String {
        guard !baseReps.isEmpty else {
            let sets = min(2 + weekNumber, 5)
            let reps = min(Int(Double(8 + weekNumber) * multiplier), 20)
            return "\(sets) sets of \(reps)"
        }

        let setsPattern = /(\d+)\s*sets?\s*(of|x|×)\s*(\d+)/
        if let match = baseReps.firstMatch(of: setsPattern) {
            let baseSets = Int(match.output.1) ?? 3
            let baseCount = Int(match.output.3) ?? 10
            let newSets = min(baseSets + (weekNumber - 1) / 2, baseSets + 2)
            let newCount = min(Int(Double(baseCount) * multiplier), baseCount + 8)
            return "\(newSets) sets of \(newCount)"
        }

        let repsOnlyPattern = /(\d+)\s*reps?/
        if let match = baseReps.firstMatch(of: repsOnlyPattern) {
            let base = Int(match.output.1) ?? 10
            let newCount = min(Int(Double(base) * multiplier), base + 8)
            return "\(newCount) reps"
        }

        let roundsPattern = /(\d+)\s*rounds?/
        if let match = baseReps.firstMatch(of: roundsPattern) {
            let base = Int(match.output.1) ?? 3
            let newRounds = min(Int(Double(base) * multiplier), base + 3)
            return "\(newRounds) rounds"
        }

        if weekNumber > 1 && multiplier > 1.0 {
            return "\(baseReps) (+intensity)"
        }
        return baseReps
    }

    // MARK: - Summary

    private static func buildSummary(
        config: PlanConfig,
        context: PlayerContext,
        weeks: [GeneratedPlanWeek],
        focusWeights: [String: Double]
    ) -> String {
        let totalDrills = weeks.flatMap(\.days).flatMap(\.drills).count
        let topFocuses = focusWeights.sorted { $0.value > $1.value }.prefix(3).map(\.key)
        let focusStr = topFocuses.joined(separator: ", ")

        var parts: [String] = []
        parts.append("A \(config.weeks)-week \(config.planType.rawValue.lowercased()) program")
        parts.append("\(config.daysPerWeek) training days per week")
        parts.append("\(config.minutesPerSession) minutes per session")

        if !context.benchmarkWeakCategories.isEmpty {
            let weakStr = context.benchmarkWeakCategories.prefix(2).map(\.rawValue).joined(separator: " and ")
            parts.append("targeting \(weakStr) based on your benchmarks")
        } else if !context.weakestSkills.isEmpty {
            let weakStr = context.weakestSkills.prefix(2).map(\.rawValue).joined(separator: " and ")
            parts.append("prioritizing \(weakStr)")
        }

        parts.append("\(totalDrills) drills across \(focusStr)")
        parts.append("Built for a \(context.skillLevel.rawValue.lowercased()) \(context.position.rawValue.lowercased()) (\(context.ageRange.rawValue))")
        parts.append("Periodized with progressive overload each week")

        return parts.joined(separator: ". ") + "."
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
