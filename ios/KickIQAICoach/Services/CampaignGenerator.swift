import Foundation

nonisolated enum CampaignGenerator {
    static func phaseSequence(for style: PeriodizationStyle, weeks: Int) -> [CampaignPhaseLabel] {
        switch style {
        case .tacticalMorphocycle:
            let cycle: [CampaignPhaseLabel] = [.recovery, .strength, .endurance, .speed, .activation]
            return (0..<weeks).map { cycle[$0 % cycle.count] }
        case .classic:
            return (0..<weeks).map { i in
                let r = Double(i) / Double(max(1, weeks - 1))
                if r < 0.25 { return .preseason }
                if r < 0.7 { return .inSeason }
                if r < 0.9 { return .peaking }
                return .taper
            }
        }
    }

    static func preferredMoments(for phase: CampaignPhaseLabel) -> [GameMoment] {
        switch phase {
        case .recovery, .taper:
            return [.combinationPlay, .buildUpPlay, .switchOfPlay]
        case .strength, .preseason:
            return [.lowBlock, .defendTheBox, .compactAndCover]
        case .endurance, .inSeason:
            return [.highPress, .immediatePress, .defensiveTransition]
        case .speed, .peaking:
            return [.counterAttack, .highPercentageFinishing, .overloadPlay]
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
        let phases = phaseSequence(for: style, weeks: weeks)
        var campaignWeeks: [CampaignWeek] = []
        var embedded: [CoachSession] = []

        for (i, phase) in phases.enumerated() {
            let moments = preferredMoments(for: phase)
            let available = library.filter { moments.contains($0.gameMoment) }
            let pool = available.isEmpty ? library : available

            var picked: [UUID] = []
            for s in 0..<sessionsPerWeek {
                guard !pool.isEmpty else { break }
                let src = pool[(i * sessionsPerWeek + s) % pool.count]
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
            sessionsPerWeek: sessionsPerWeek,
            ageGroup: ageGroup,
            level: level,
            startDate: startDate,
            embeddedSessions: embedded
        )
    }
}
