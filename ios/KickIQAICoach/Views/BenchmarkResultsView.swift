import SwiftUI

struct BenchmarkResultsView: View {
    let storage: StorageService
    @State private var benchmarkService = BenchmarkService()
    @State private var appeared = false
    @State private var selectedFilter: BenchmarkResultFilter = .all
    @State private var selectedTestHistory: BenchmarkDrill?
    @State private var expandedSessions: Set<String> = []

    private var playerGender: PlayerGender {
        storage.profile?.gender ?? .male
    }

    private var playerRank: BenchmarkPlayerRank {
        BenchmarkPlayerRank.rank(for: benchmarkService.overallScore(results: storage.benchmarkResults, gender: playerGender))
    }

    private var sortedResults: [BenchmarkResult] {
        let filtered: [BenchmarkResult]
        switch selectedFilter {
        case .all:
            filtered = storage.benchmarkResults.filter { !$0.isSkipped && $0.latestScore != nil }
        case .improving:
            filtered = storage.benchmarkResults.filter { $0.trend == .improving }
        case .needsWork:
            filtered = storage.benchmarkResults.filter { $0.trend == .declining || (!$0.isSkipped && $0.latestScore != nil && scorePct(for: $0) < 50) }
        case .untested:
            filtered = storage.benchmarkResults.filter { $0.isSkipped || $0.latestScore == nil }
        }
        return filtered.sorted { ($0.attempts.last?.date ?? .distantPast) > ($1.attempts.last?.date ?? .distantPast) }
    }

    private var testingSessions: [BenchmarkTestSession] {
        var sessionMap: [String: [BenchmarkAttemptEntry]] = [:]
        for result in storage.benchmarkResults {
            for attempt in result.attempts {
                let key = Self.dateKey(attempt.date)
                let entry = BenchmarkAttemptEntry(
                    drillID: result.benchmarkDrillID,
                    drillName: result.drillName,
                    category: result.category,
                    score: attempt.score,
                    date: attempt.date
                )
                sessionMap[key, default: []].append(entry)
            }
        }
        return sessionMap.map { key, entries in
            BenchmarkTestSession(dateKey: key, date: entries.first?.date ?? .now, entries: entries.sorted { $0.date < $1.date })
        }.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQAICoachTheme.Spacing.md) {
                    summaryHeader
                    filterChips
                    if selectedFilter == .all {
                        timelineSection
                    } else {
                        filteredResultsList
                    }
                }
                .padding(.bottom, KickIQAICoachTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Results")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedTestHistory) { drill in
                BenchmarkTestHistoryView(
                    drill: drill,
                    storage: storage,
                    benchmarkService: benchmarkService
                )
            }
        }
        .onAppear {
            let age = storage.profile?.ageRange ?? .fifteen18
            benchmarkService.loadDrills(for: age, gender: playerGender)
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
        }
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.md) {
            HStack(spacing: KickIQAICoachTheme.Spacing.md) {
                rankBadge
                VStack(alignment: .leading, spacing: 6) {
                    Text(storage.profile?.name ?? "Athlete")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)

                    HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                        statPill(value: "\(totalAttempts)", label: "Tests")
                        statPill(value: "\(testingDays)", label: "Days")
                        statPill(value: "\(totalXPFromBenchmarks)", label: "XP")
                    }
                }
                Spacer()
            }

            categoryMiniScores
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.xl))
        .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
        .padding(.top, KickIQAICoachTheme.Spacing.sm)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
    }

    private var rankBadge: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [KickIQAICoachTheme.accent.opacity(0.25), KickIQAICoachTheme.accent.opacity(0.05)],
                        center: .center,
                        startRadius: 5,
                        endRadius: 35
                    )
                )
                .frame(width: 70, height: 70)

            VStack(spacing: 2) {
                Image(systemName: playerRank.icon)
                    .font(.title2)
                    .foregroundStyle(KickIQAICoachTheme.accent)
                Text(playerRank.rawValue)
                    .font(.system(size: 9, weight: .black))
                    .tracking(0.5)
                    .foregroundStyle(KickIQAICoachTheme.accent)
            }
        }
    }

    private func statPill(value: String, label: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.caption.weight(.black))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
        }
        .frame(minWidth: 44)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(KickIQAICoachTheme.surface, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.sm))
    }

    private var categoryMiniScores: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
            ForEach(BenchmarkCategory.allCases) { cat in
                let score = benchmarkService.categoryScore(results: storage.benchmarkResults, category: cat, gender: playerGender)
                VStack(spacing: 3) {
                    Image(systemName: cat.icon)
                        .font(.system(size: 11))
                        .foregroundStyle(score != nil ? KickIQAICoachTheme.accent : KickIQAICoachTheme.textSecondary.opacity(0.3))
                    Text(score != nil ? "\(Int(score!))" : "—")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(score != nil ? KickIQAICoachTheme.textPrimary : KickIQAICoachTheme.textSecondary.opacity(0.3))
                    Text(cat.rawValue)
                        .font(.system(size: 7, weight: .semibold))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(
                    score != nil ? KickIQAICoachTheme.accent.opacity(0.06) : KickIQAICoachTheme.surface,
                    in: .rect(cornerRadius: KickIQAICoachTheme.Radius.sm)
                )
            }
        }
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                ForEach(BenchmarkResultFilter.allCases) { filter in
                    Button {
                        withAnimation(.spring(response: 0.3)) { selectedFilter = filter }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: filter.icon)
                                .font(.system(size: 10))
                            Text(filter.label)
                                .font(.caption.weight(.semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            selectedFilter == filter ? KickIQAICoachTheme.accent : KickIQAICoachTheme.card,
                            in: Capsule()
                        )
                        .foregroundStyle(selectedFilter == filter ? KickIQAICoachTheme.onAccent : KickIQAICoachTheme.textSecondary)
                    }
                }
            }
        }
        .contentMargins(.horizontal, 16)
        .scrollIndicators(.hidden)
    }

    // MARK: - Timeline Section

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if testingSessions.isEmpty {
                emptyTimelineState
            } else {
                ForEach(Array(testingSessions.enumerated()), id: \.element.dateKey) { index, session in
                    timelineSessionCard(session, index: index)
                }
            }
        }
        .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
    }

    private func timelineSessionCard(_ session: BenchmarkTestSession, index: Int) -> some View {
        let isExpanded = expandedSessions.contains(session.dateKey)

        return VStack(spacing: 0) {
            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(KickIQAICoachTheme.accent)
                        .frame(width: 10, height: 10)
                    if index < testingSessions.count - 1 {
                        Rectangle()
                            .fill(KickIQAICoachTheme.divider)
                            .frame(width: 2)
                            .offset(y: 30)
                    }
                }
                .frame(width: 20)

                Button {
                    withAnimation(.spring(response: 0.3)) {
                        if isExpanded {
                            expandedSessions.remove(session.dateKey)
                        } else {
                            expandedSessions.insert(session.dateKey)
                        }
                    }
                } label: {
                    VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(session.date, style: .date)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                                Text("\(session.entries.count) test\(session.entries.count == 1 ? "" : "s") recorded")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                            }

                            Spacer()

                            HStack(spacing: 4) {
                                Text("+\(session.entries.count * 15) XP")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(KickIQAICoachTheme.accent)

                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.4))
                            }
                        }

                        if !isExpanded {
                            HStack(spacing: 4) {
                                ForEach(uniqueCategories(session.entries), id: \.self) { cat in
                                    Image(systemName: cat.icon)
                                        .font(.system(size: 9))
                                        .foregroundStyle(KickIQAICoachTheme.accent.opacity(0.6))
                                }
                            }
                        }

                        if isExpanded {
                            VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                                ForEach(session.entries, id: \.id) { entry in
                                    timelineEntryRow(entry)
                                }
                            }
                        }
                    }
                    .padding(KickIQAICoachTheme.Spacing.md)
                    .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
                }
            }
            .padding(.bottom, KickIQAICoachTheme.Spacing.sm)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.4).delay(Double(min(index, 8)) * 0.04), value: appeared)
    }

    private func timelineEntryRow(_ entry: BenchmarkAttemptEntry) -> some View {
        let drill = benchmarkService.benchmarkDrills.first(where: { $0.id == entry.drillID })
        let pct = drill.map { BenchmarkService.scorePercentage(score: entry.score, drill: $0, gender: playerGender) }

        return Button {
            if let d = drill {
                selectedTestHistory = d
            }
        } label: {
            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                Image(systemName: entry.category.icon)
                    .font(.system(size: 11))
                    .foregroundStyle(KickIQAICoachTheme.accent)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.drillName)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    Text(entry.date, format: .dateTime.hour().minute())
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.6))
                }

                Spacer()

                Text(BenchmarkView.formatScore(entry.score))
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)

                if let drill {
                    Text(drill.unit)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }

                if let p = pct {
                    Text("\(Int(p))%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(p >= 70 ? .green : p >= 40 ? .orange : KickIQAICoachTheme.textSecondary)
                        .frame(width: 30, alignment: .trailing)
                }
            }
            .padding(KickIQAICoachTheme.Spacing.sm)
            .background(KickIQAICoachTheme.surface, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.sm))
        }
    }

    // MARK: - Filtered Results List

    private var filteredResultsList: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            if sortedResults.isEmpty {
                emptyFilterState
            } else {
                ForEach(Array(sortedResults.enumerated()), id: \.element.id) { index, result in
                    filteredResultRow(result, index: index)
                }
            }
        }
        .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
    }

    private func filteredResultRow(_ result: BenchmarkResult, index: Int) -> some View {
        let drill = benchmarkService.benchmarkDrills.first(where: { $0.id == result.benchmarkDrillID })
        let pct = scorePct(for: result)
        let trend = result.trend

        return Button {
            if let d = drill {
                selectedTestHistory = d
            }
        } label: {
            HStack(spacing: KickIQAICoachTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(categoryColor(result.category).opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: result.category.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(categoryColor(result.category))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(result.drillName)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)

                    HStack(spacing: 6) {
                        if let score = result.latestScore {
                            Text("\(BenchmarkView.formatScore(score)) \(drill?.unit ?? "")")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(KickIQAICoachTheme.accent)
                        }

                        if result.attempts.count >= 2 {
                            HStack(spacing: 2) {
                                Image(systemName: trend.icon)
                                    .font(.system(size: 9, weight: .bold))
                                Text(trend.label)
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .foregroundStyle(trend == .improving ? .green : trend == .declining ? .orange : KickIQAICoachTheme.textSecondary)
                        }
                    }

                    if let lastDate = result.attempts.last?.date {
                        Text("Last: \(lastDate, style: .relative) ago")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.6))
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(Int(pct))%")
                        .font(.headline.weight(.black))
                        .foregroundStyle(pct >= 70 ? .green : pct >= 40 ? .orange : KickIQAICoachTheme.textSecondary)

                    Text("\(result.attempts.count) attempt\(result.attempts.count == 1 ? "" : "s")")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.3))
            }
            .padding(KickIQAICoachTheme.Spacing.md)
            .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.4).delay(Double(min(index, 10)) * 0.04), value: appeared)
    }

    // MARK: - Empty States

    private var emptyTimelineState: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.md) {
            Spacer().frame(height: 40)
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 44))
                .foregroundStyle(KickIQAICoachTheme.accent.opacity(0.4))
            Text("No Results Yet")
                .font(.title3.weight(.bold))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
            Text("Complete benchmark tests to see\nyour results timeline here.")
                .font(.subheadline)
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyFilterState: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.title2)
                .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.4))
            Text("No matching results")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, KickIQAICoachTheme.Spacing.xl)
    }

    // MARK: - Helpers

    private func scorePct(for result: BenchmarkResult) -> Double {
        guard let latest = result.latestScore,
              let drill = benchmarkService.benchmarkDrills.first(where: { $0.id == result.benchmarkDrillID }) else { return 0 }
        return BenchmarkService.scorePercentage(score: latest, drill: drill, gender: playerGender)
    }

    private func categoryColor(_ category: BenchmarkCategory) -> Color {
        KickIQAICoachTheme.accent
    }

    private func uniqueCategories(_ entries: [BenchmarkAttemptEntry]) -> [BenchmarkCategory] {
        var seen = Set<String>()
        return entries.compactMap { entry in
            guard seen.insert(entry.category.rawValue).inserted else { return nil }
            return entry.category
        }
    }

    private var totalAttempts: Int {
        storage.benchmarkResults.reduce(0) { $0 + $1.attempts.count }
    }

    private var testingDays: Int {
        let dates = Set(storage.benchmarkResults.flatMap { $0.attempts.map { Self.dateKey($0.date) } })
        return dates.count
    }

    private var totalXPFromBenchmarks: Int {
        totalAttempts * 15
    }

    private static func dateKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}

// MARK: - Supporting Types

private enum BenchmarkResultFilter: String, CaseIterable, Identifiable {
    case all = "Timeline"
    case improving = "Improving"
    case needsWork = "Needs Work"
    case untested = "Untested"

    var id: String { rawValue }

    var label: String { rawValue }

    var icon: String {
        switch self {
        case .all: "clock.fill"
        case .improving: "arrow.up.right"
        case .needsWork: "exclamationmark.triangle.fill"
        case .untested: "circle.dashed"
        }
    }
}

private struct BenchmarkTestSession {
    let dateKey: String
    let date: Date
    let entries: [BenchmarkAttemptEntry]
}

private struct BenchmarkAttemptEntry: Identifiable {
    let drillID: String
    let drillName: String
    let category: BenchmarkCategory
    let score: Double
    let date: Date

    var id: String { "\(drillID)_\(date.timeIntervalSince1970)" }
}
