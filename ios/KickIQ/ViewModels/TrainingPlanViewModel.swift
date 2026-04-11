import Foundation

@Observable
@MainActor
class TrainingPlanViewModel {
    let storage: StorageService
    private let drillsService = DrillsService()

    var isGenerating = false
    var selectedDay: DailyPlan?
    var showDrillSwap = false
    var swappingDrillIndex: Int?
    var showPreferences = false

    init(storage: StorageService) {
        self.storage = storage
        if let profile = storage.profile {
            drillsService.loadDrills(for: profile.position, weakness: profile.weakness, skillLevel: profile.skillLevel)
        }
    }

    var smartPlan: SmartTrainingPlan? {
        storage.smartTrainingPlan
    }

    var todaysPlan: DailyPlan? {
        smartPlan?.todaysPlan
    }

    var weakestSkillNames: [String] {
        storage.weakestSkills.map(\.rawValue)
    }

    var recentScoreTrend: [(String, Int)] {
        let recent = Array(storage.sessions.prefix(5).reversed())
        return recent.map { session in
            let label = session.date.formatted(.dateTime.month(.abbreviated).day())
            return (label, session.overallScore)
        }
    }

    func generatePlan() {
        isGenerating = true

        let position = storage.profile?.position ?? .midfielder
        let weakness = storage.profile?.weakness ?? .firstTouch
        let skillLevel = storage.profile?.skillLevel ?? .intermediate
        let weakSkills = storage.weakestSkills
        let prefs = smartPlan?.preferences ?? PlanPreferences()

        let intensityPattern: [TrainingIntensity] = [
            .medium, .heavy, .light, .medium, .heavy, .light, .medium,
            .heavy, .light, .medium, .heavy, .medium, .light, .medium,
            .heavy, .light, .medium, .heavy, .light, .medium, .medium,
            .light, .heavy, .medium, .light, .heavy, .medium, .light,
            .medium, .heavy
        ]

        let focusAreas = buildFocusRotation(position: position, weakness: weakness, weakSkills: weakSkills, prefs: prefs)

        var days: [DailyPlan] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        for dayIndex in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: dayIndex, to: today) else { continue }
            let intensity = intensityPattern[dayIndex % intensityPattern.count]
            let focusIndex = dayIndex % focusAreas.count
            let focus = focusAreas[focusIndex]
            let duration = durationForIntensity(intensity, preferred: prefs.preferredDuration)
            let mode = prefs.preferredMode

            let effectiveMode: TrainingMode = prefs.soloOnly ? .solo : mode

            let drills = buildDrills(
                focus: focus,
                intensity: intensity,
                duration: duration,
                mode: effectiveMode,
                position: position,
                weakness: weakness,
                skillLevel: skillLevel,
                weakSkills: weakSkills,
                dayIndex: dayIndex,
                prefs: prefs
            )

            let weakPriority = weakSkills.isEmpty
                ? [weakness.rawValue]
                : weakSkills.map(\.rawValue)

            let plan = DailyPlan(
                date: date,
                dayNumber: dayIndex + 1,
                focus: focus,
                intensity: intensity,
                duration: duration,
                mode: prefs.soloOnly ? .solo : mode,
                weaknessPriority: weakPriority,
                drills: drills
            )
            days.append(plan)
        }

        let summary = "30-day plan targeting \(weakSkills.isEmpty ? weakness.rawValue.lowercased() : weakSkills.map(\.rawValue).joined(separator: " & ").lowercased()) for a \(position.rawValue.lowercased()). Intensity alternates daily — no rest days, just smart recovery sessions."

        let plan = SmartTrainingPlan(
            days: days,
            summary: summary,
            preferences: prefs
        )

        storage.saveSmartTrainingPlan(plan)
        isGenerating = false
    }

    func completeDrill(dayID: String, drillID: String) {
        guard var plan = storage.smartTrainingPlan,
              let dayIdx = plan.days.firstIndex(where: { $0.id == dayID }),
              let drillIdx = plan.days[dayIdx].drills.firstIndex(where: { $0.id == drillID }) else { return }

        plan.days[dayIdx].drills[drillIdx].isCompleted = true
        storage.saveSmartTrainingPlan(plan)

        let drill = plan.days[dayIdx].drills[drillIdx]
        storage.completeDrill(drill.asDrill)
    }

    func swapDrill(dayID: String, drillIndex: Int, with newDrill: SmartDrill) {
        guard var plan = storage.smartTrainingPlan,
              let dayIdx = plan.days.firstIndex(where: { $0.id == dayID }),
              drillIndex < plan.days[dayIdx].drills.count else { return }

        plan.days[dayIdx].drills[drillIndex] = newDrill
        storage.saveSmartTrainingPlan(plan)
    }

    func updatePreferences(_ prefs: PlanPreferences) {
        guard var plan = storage.smartTrainingPlan else { return }
        plan.preferences = prefs
        storage.saveSmartTrainingPlan(plan)
    }

    func availableDrillsForSwap(excluding currentSkill: String) -> [SmartDrill] {
        let allDrills = drillsService.allDrills
        return allDrills.map { drill in
            SmartDrill(
                name: drill.name,
                description: drill.description,
                duration: drill.duration,
                difficulty: drill.difficulty,
                targetSkill: drill.targetSkill,
                coachingCues: drill.coachingCues,
                reps: drill.reps,
                reason: "Added from \(drill.targetSkill) drill library"
            )
        }
    }

    func drillsByCategory() -> [(category: String, drills: [SmartDrill])] {
        let allDrills = drillsService.allDrills
        var groups: [String: [SmartDrill]] = [:]
        for drill in allDrills {
            let smart = SmartDrill(
                name: drill.name,
                description: drill.description,
                duration: drill.duration,
                difficulty: drill.difficulty,
                targetSkill: drill.targetSkill,
                coachingCues: drill.coachingCues,
                reps: drill.reps,
                reason: "Added from \(drill.targetSkill) drill library"
            )
            groups[drill.targetSkill, default: []].append(smart)
        }
        return groups.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }

    private func buildFocusRotation(position: PlayerPosition, weakness: WeaknessArea, weakSkills: [SkillCategory], prefs: PlanPreferences) -> [String] {
        var focuses: [String] = []
        let weakWeight = prefs.weaknessPriorityWeight

        if weakSkills.isEmpty {
            let positionSkills = position.skills
            focuses.append(weakness.rawValue)
            for skill in positionSkills.prefix(4) {
                focuses.append(skill.rawValue)
            }
            focuses.append(weakness.rawValue)
        } else {
            let weakRepeat = max(Int(ceil(Double(weakSkills.count) * weakWeight * 2)), weakSkills.count)
            for i in 0..<weakRepeat {
                focuses.append(weakSkills[i % weakSkills.count].rawValue)
            }

            if prefs.mixCategories {
                let otherSkills = position.skills.filter { !weakSkills.contains($0) }
                let otherCount = max(Int(ceil(Double(weakRepeat) * (1.0 - weakWeight) / max(weakWeight, 0.1))), 1)
                for i in 0..<otherCount {
                    focuses.append(otherSkills[i % max(otherSkills.count, 1)].rawValue)
                }
            }

            for skill in weakSkills {
                focuses.append(skill.rawValue)
            }
        }

        return focuses
    }

    private func durationForIntensity(_ intensity: TrainingIntensity, preferred: SessionDuration) -> SessionDuration {
        switch intensity {
        case .light:
            switch preferred {
            case .twenty: return .twenty
            case .thirty: return .twenty
            case .fortyFive: return .thirty
            case .sixty: return .fortyFive
            case .ninety: return .sixty
            }
        case .medium:
            return preferred
        case .heavy:
            switch preferred {
            case .twenty: return .thirty
            case .thirty: return .fortyFive
            case .fortyFive: return .sixty
            case .sixty: return .ninety
            case .ninety: return .ninety
            }
        }
    }

    private func buildDrills(
        focus: String,
        intensity: TrainingIntensity,
        duration: SessionDuration,
        mode: TrainingMode,
        position: PlayerPosition,
        weakness: WeaknessArea,
        skillLevel: SkillLevel,
        weakSkills: [SkillCategory],
        dayIndex: Int,
        prefs: PlanPreferences
    ) -> [SmartDrill] {
        let targetCount: Int
        switch duration {
        case .twenty: targetCount = 2
        case .thirty: targetCount = 3
        case .fortyFive: targetCount = 4
        case .sixty: targetCount = 5
        case .ninety: targetCount = 6
        }

        var pool = drillsService.allDrills

        if prefs.soloOnly {
            pool = pool.filter { $0.trainingMode == .solo }
        }

        if let maxMin = prefs.maxDrillMinutes {
            pool = pool.filter { $0.durationMinutes <= maxMin }
        }

        guard !pool.isEmpty else { return [] }

        var selected: [SmartDrill] = []
        var usedNames: Set<String> = []

        let weakWeight = prefs.weaknessPriorityWeight
        let weakSlots = max(Int(ceil(Double(targetCount) * weakWeight)), 1)
        let focusSlots = max(targetCount - weakSlots, 0)

        let weakPool = pool.filter { drill in
            weakSkills.contains(where: { $0.rawValue == drill.targetSkill })
        }
        let _ = pool.filter { $0.targetSkill == focus && !weakSkills.contains(where: { cat in cat.rawValue == focus }) }

        for drill in weakPool.shuffled().prefix(weakSlots) {
            guard !usedNames.contains(drill.name) else { continue }
            usedNames.insert(drill.name)
            selected.append(SmartDrill(
                name: drill.name,
                description: drill.description,
                duration: drill.duration,
                difficulty: drill.difficulty,
                targetSkill: drill.targetSkill,
                coachingCues: drill.coachingCues,
                reps: drill.reps,
                reason: "Prioritized — \(drill.targetSkill) identified as a weak area"
            ))
        }

        if selected.count < weakSlots {
            let focusFallback = pool.filter { $0.targetSkill == focus && !usedNames.contains($0.name) }
            for drill in focusFallback.shuffled().prefix(weakSlots - selected.count) {
                usedNames.insert(drill.name)
                selected.append(SmartDrill(
                    name: drill.name,
                    description: drill.description,
                    duration: drill.duration,
                    difficulty: drill.difficulty,
                    targetSkill: drill.targetSkill,
                    coachingCues: drill.coachingCues,
                    reps: drill.reps,
                    reason: "Targets \(drill.targetSkill) — today's focus area"
                ))
            }
        }

        if prefs.mixCategories {
            let mixPool = pool.filter { drill in
                !usedNames.contains(drill.name)
                && !weakSkills.contains(where: { $0.rawValue == drill.targetSkill })
            }
            let categorized = Dictionary(grouping: mixPool, by: \.targetSkill)
            var mixCandidates: [Drill] = []
            for (_, drills) in categorized {
                if let pick = drills.randomElement() {
                    mixCandidates.append(pick)
                }
            }
            for drill in mixCandidates.shuffled().prefix(focusSlots) {
                guard !usedNames.contains(drill.name) else { continue }
                usedNames.insert(drill.name)
                let reason: String
                switch intensity {
                case .light:
                    reason = "Light session — technique refinement for \(drill.targetSkill)"
                case .medium:
                    reason = "Balanced session — developing well-rounded \(drill.targetSkill)"
                case .heavy:
                    reason = "High intensity — pushing \(drill.targetSkill) under pressure"
                }
                selected.append(SmartDrill(
                    name: drill.name,
                    description: drill.description,
                    duration: drill.duration,
                    difficulty: drill.difficulty,
                    targetSkill: drill.targetSkill,
                    coachingCues: drill.coachingCues,
                    reps: drill.reps,
                    reason: reason
                ))
            }
        } else {
            let focusOnly = pool.filter { $0.targetSkill == focus && !usedNames.contains($0.name) }
            for drill in focusOnly.shuffled().prefix(focusSlots) {
                usedNames.insert(drill.name)
                selected.append(SmartDrill(
                    name: drill.name,
                    description: drill.description,
                    duration: drill.duration,
                    difficulty: drill.difficulty,
                    targetSkill: drill.targetSkill,
                    coachingCues: drill.coachingCues,
                    reps: drill.reps,
                    reason: "Builds \(drill.targetSkill) — key skill for \(position.rawValue.lowercased())s"
                ))
            }
        }

        let remaining = targetCount - selected.count
        if remaining > 0 {
            let leftover = pool.filter { !usedNames.contains($0.name) }
            for drill in leftover.shuffled().prefix(remaining) {
                usedNames.insert(drill.name)
                selected.append(SmartDrill(
                    name: drill.name,
                    description: drill.description,
                    duration: drill.duration,
                    difficulty: drill.difficulty,
                    targetSkill: drill.targetSkill,
                    coachingCues: drill.coachingCues,
                    reps: drill.reps,
                    reason: "Supplemental — well-rounded \(drill.targetSkill) development"
                ))
            }
        }

        return selected
    }
}
