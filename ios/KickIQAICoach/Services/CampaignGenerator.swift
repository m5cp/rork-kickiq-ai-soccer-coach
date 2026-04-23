import Foundation

nonisolated enum CampaignGenerator {
    static func phaseSequence(for style: PeriodizationStyle, weeks: Int) -> [CampaignPhaseLabel] {
        switch style {
        case .tacticalMorphocycle:
            let cycle: [CampaignPhaseLabel] = [.recovery, .strength, .endurance, .speed, .activation]
            return (0..<weeks).map { cycle[$0 % cycle.count] }
        case .classic:
            return seasonPhaseSequence(weeks: weeks)
        }
    }

    static func seasonPhaseSequence(weeks: Int) -> [CampaignPhaseLabel] {
        guard weeks > 0 else { return [] }
        let phases = CampaignPhaseLabel.seasonPhases
        // Distribute 6 phases proportionally across the weeks.
        // Rough split: Preseason 15%, Early 20%, Mid 25%, Late 20%, Playoffs 12%, Off 8%.
        let weights: [Double] = [0.15, 0.20, 0.25, 0.20, 0.12, 0.08]
        var counts: [Int] = weights.map { max(1, Int(round(Double(weeks) * $0))) }
        // Adjust to exactly `weeks`
        var total = counts.reduce(0, +)
        var idx = 0
        while total != weeks {
            if total < weeks {
                counts[idx % counts.count] += 1
                total += 1
            } else {
                if counts[idx % counts.count] > 1 {
                    counts[idx % counts.count] -= 1
                    total -= 1
                }
            }
            idx += 1
            if idx > weeks * 4 { break }
        }
        var out: [CampaignPhaseLabel] = []
        for (i, c) in counts.enumerated() {
            out.append(contentsOf: Array(repeating: phases[i], count: c))
        }
        if out.count > weeks { out = Array(out.prefix(weeks)) }
        while out.count < weeks { out.append(phases.last!) }
        return out
    }

    static func preferredMoments(for phase: CampaignPhaseLabel) -> [GameMoment] {
        switch phase {
        case .recovery, .taper, .offSeason:
            return [.combinationPlay, .buildUpPlay, .switchOfPlay]
        case .strength, .preseason:
            return [.lowBlock, .defendTheBox, .compactAndCover, .buildUpPlay]
        case .earlySeason:
            return [.lowBlock, .compactAndCover, .defensiveTransition, .buildUpPlay]
        case .midSeason:
            return [.combinationPlay, .switchOfPlay, .overloadPlay, .immediatePress]
        case .lateSeason:
            return [.counterAttack, .highPercentageFinishing, .buildUpPlay, .immediatePress]
        case .playoffs, .peaking, .speed:
            return [.counterAttack, .highPercentageFinishing, .overloadPlay, .highPress]
        case .endurance, .inSeason:
            return [.highPress, .immediatePress, .defensiveTransition]
        case .activation:
            return [.highPress, .buildUpPlay, .counterAttack]
        }
    }

    static func generate(
        title: String,
        style: PeriodizationStyle,
        weeks: Int,
        sessionsPerWeek: Int,
        ageGroup: String,
        level: String,
        startDate: Date,
        library: [CoachSession]
    ) -> Campaign {
        generate(title: title, style: style, scope: .fullSeason, totalWeeks: weeks, sessionsPerWeek: sessionsPerWeek, ageGroup: ageGroup, level: level, startDate: startDate, library: library)
    }

    static func generate(
        title: String,
        style: PeriodizationStyle,
        scope: GeneratorScope,
        totalWeeks: Int,
        sessionsPerWeek: Int,
        ageGroup: String,
        level: String,
        startDate: Date,
        library: [CoachSession]
    ) -> Campaign {
        let fullPhases = phaseSequence(for: style, weeks: max(1, totalWeeks))
        let (phases, effectiveStart, sessionsThisWeek): ([CampaignPhaseLabel], Date, Int) = {
            switch scope {
            case .fullSeason:
                return (fullPhases, startDate, sessionsPerWeek)
            case .singlePhase(let label):
                let filtered = fullPhases.filter { $0 == label }
                let count = filtered.isEmpty ? max(1, totalWeeks / 6) : filtered.count
                return (Array(repeating: label, count: count), startDate, sessionsPerWeek)
            case .singleMonth(let month):
                let startWeek = max(0, (month - 1) * 4)
                let endWeek = min(fullPhases.count, startWeek + 4)
                let slice = Array(fullPhases[startWeek..<max(startWeek, endWeek)])
                let newStart = Calendar.current.date(byAdding: .weekOfYear, value: startWeek, to: startDate) ?? startDate
                return (slice.isEmpty ? [fullPhases.first ?? .preseason] : slice, newStart, sessionsPerWeek)
            case .singleWeek(let w):
                let idx = max(0, min(fullPhases.count - 1, w - 1))
                let phase = fullPhases.indices.contains(idx) ? fullPhases[idx] : .preseason
                let newStart = Calendar.current.date(byAdding: .weekOfYear, value: idx, to: startDate) ?? startDate
                return ([phase], newStart, sessionsPerWeek)
            case .singleSession(let date):
                let phase = fullPhases.first ?? .preseason
                return ([phase], date, 1)
            case .customDateRange(let from, let to):
                let weeks = max(1, Calendar.current.dateComponents([.weekOfYear], from: from, to: to).weekOfYear ?? 1)
                let startIdx = max(0, Calendar.current.dateComponents([.weekOfYear], from: startDate, to: from).weekOfYear ?? 0)
                let endIdx = min(fullPhases.count, startIdx + weeks)
                let slice = startIdx < endIdx ? Array(fullPhases[startIdx..<endIdx]) : []
                return (slice.isEmpty ? Array(repeating: fullPhases.first ?? .preseason, count: weeks) : slice, from, sessionsPerWeek)
            }
        }()
        var campaignWeeks: [CampaignWeek] = []
        var embedded: [CoachSession] = []

        for (i, phase) in phases.enumerated() {
            let moments = preferredMoments(for: phase)
            let available = library.filter { moments.contains($0.gameMoment) }
            let pool = available.isEmpty ? library : available

            var picked: [UUID] = []
            for s in 0..<sessionsThisWeek {
                guard !pool.isEmpty else { break }
                let src = pool[(i * sessionsThisWeek + s) % pool.count]
                var copy = src
                copy.id = UUID()
                copy.ageGroup = ageGroup
                copy.createdAt = Date()
                picked.append(copy.id)
                embedded.append(copy)
            }

            campaignWeeks.append(CampaignWeek(
                weekNumber: i + 1,
                phaseLabel: phase,
                sessionIDs: picked
            ))
        }

        return Campaign(
            title: title,
            style: style,
            weeks: campaignWeeks,
            sessionsPerWeek: sessionsThisWeek,
            ageGroup: ageGroup,
            level: level,
            startDate: effectiveStart,
            embeddedSessions: embedded
        )
    }
}
