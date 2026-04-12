import SwiftUI

struct ProgressTabView: View {
    let storage: StorageService
    @State private var selectedSkill: SkillCategory?
    @State private var appeared = false
    @State private var selectedSession: TrainingSession?
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    @State private var showComparison = false

    private var position: PlayerPosition {
        storage.profile?.position ?? .midfielder
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQAICoachTheme.Spacing.md + 4) {
                    if storage.sessions.isEmpty && storage.benchmarkResults.isEmpty {
                        emptyState
                    } else {
                        levelOverviewCard
                        if !storage.benchmarkResults.isEmpty {
                            benchmarkProgressCard
                        }
                        personalRecordsCard
                        if !storage.sessions.isEmpty {
                            scoreOverTimeCard
                            if storage.sessions.count >= 2 {
                                compareSessionsButton
                            }
                            improvementTrendCard
                            skillBreakdownCard
                        }
                        trainingVolumeCard
                        streakHeatmapCard
                        badgesSection
                        if !storage.sessions.isEmpty {
                            sessionHistoryList
                        }
                        shareProgressButton
                    }
                }
                .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                .padding(.bottom, KickIQAICoachTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQAICoachTheme.background.ignoresSafeArea())
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedSession) { session in
                NavigationStack {
                    AnalysisResultView(session: session, storage: storage) {
                        selectedSession = nil
                    }
                }
                .presentationDragIndicator(.visible)
                .presentationBackground(.background)
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = shareImage {
                    ShareSheetView(image: image)
                }
            }
            .sheet(isPresented: $showComparison) {
                ComparisonView(storage: storage)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
    }

    private var emptyState: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.md) {
            Spacer().frame(height: 60)

            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(KickIQAICoachTheme.accent.opacity(0.5))

            Text("No Progress Yet")
                .font(.title3.weight(.bold))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)

            Text("Complete your first analysis session\nto start tracking your progress")
                .font(.subheadline)
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var levelOverviewCard: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.md) {
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(KickIQAICoachTheme.accent.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: storage.playerLevel.icon)
                            .font(.title3)
                            .foregroundStyle(KickIQAICoachTheme.accent)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(storage.playerLevel.rawValue)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(KickIQAICoachTheme.textPrimary)
                        Text("\(storage.xpPoints) XP earned")
                            .font(.caption)
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(storage.analysisCount)")
                        .font(.title3.weight(.black))
                        .foregroundStyle(KickIQAICoachTheme.accent)
                    Text("analyses")
                        .font(.caption2)
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }
            }

            if let progress = storage.xpProgress {
                VStack(spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(KickIQAICoachTheme.divider)
                                .frame(height: 8)
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [KickIQAICoachTheme.accent.opacity(0.7), KickIQAICoachTheme.accent],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, geo.size.width * Double(progress.current) / Double(max(1, progress.needed))), height: 8)
                        }
                    }
                    .frame(height: 8)

                    HStack {
                        Text(storage.playerLevel.rawValue)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.6))
                        Spacer()
                        if let next = storage.playerLevel.nextLevel {
                            Text(next.rawValue)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(KickIQAICoachTheme.accent.opacity(0.6))
                        }
                    }
                }
            }
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
    }

    private var benchmarkProgressCard: some View {
        let results = storage.benchmarkResults
        let rank = storage.benchmarkPlayerRank
        let overall = storage.benchmarkOverallScore

        return VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm + 2) {
            HStack {
                Text("BENCHMARK SCORES")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(KickIQAICoachTheme.accent)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: rank.icon)
                        .font(.system(size: 11))
                    Text(rank.rawValue)
                        .font(.caption.weight(.black))
                }
                .foregroundStyle(KickIQAICoachTheme.accent)
            }

            HStack(spacing: KickIQAICoachTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .stroke(KickIQAICoachTheme.divider, lineWidth: 5)
                        .frame(width: 56, height: 56)
                    Circle()
                        .trim(from: 0, to: overall / 100.0)
                        .stroke(KickIQAICoachTheme.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(overall))")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(BenchmarkCategory.allCases) { cat in
                        let catResults = results.filter { $0.category == cat && $0.latestScore != nil }
                        if !catResults.isEmpty {
                            let improving = catResults.filter { $0.trend == .improving }.count
                            let declining = catResults.filter { $0.trend == .declining }.count
                            HStack(spacing: 6) {
                                Image(systemName: cat.icon)
                                    .font(.system(size: 9))
                                    .foregroundStyle(KickIQAICoachTheme.accent)
                                    .frame(width: 14)
                                Text(cat.rawValue)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                                Spacer()
                                if improving > 0 {
                                    HStack(spacing: 2) {
                                        Image(systemName: "arrow.up")
                                            .font(.system(size: 8, weight: .bold))
                                        Text("\(improving)")
                                            .font(.system(size: 9, weight: .bold))
                                    }
                                    .foregroundStyle(.green)
                                }
                                if declining > 0 {
                                    HStack(spacing: 2) {
                                        Image(systemName: "arrow.down")
                                            .font(.system(size: 8, weight: .bold))
                                        Text("\(declining)")
                                            .font(.system(size: 9, weight: .bold))
                                    }
                                    .foregroundStyle(.orange)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.02), value: appeared)
    }

    private var personalRecordsCard: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm + 2) {
            Text("PERSONAL BESTS")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQAICoachTheme.accent)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: KickIQAICoachTheme.Spacing.sm), GridItem(.flexible(), spacing: KickIQAICoachTheme.Spacing.sm)], spacing: KickIQAICoachTheme.Spacing.sm) {
                recordTile(icon: "chart.bar.fill", value: "\(storage.sessions.map(\.overallScore).max() ?? 0)", label: "Best Score", highlight: true)
                recordTile(icon: "flame.fill", value: "\(storage.maxStreak)", label: "Longest Streak")
                if let best = storage.bestSkillScore {
                    recordTile(icon: best.category.icon, value: "\(best.score)/10", label: "Best: \(best.category.rawValue)")
                }
                recordTile(icon: "clock.fill", value: "\(storage.totalDrillMinutes)m", label: "Total Training")
            }
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.03), value: appeared)
    }

    private func recordTile(icon: String, value: String, label: String, highlight: Bool = false) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(highlight ? KickIQAICoachTheme.accent : KickIQAICoachTheme.textSecondary)
                Text(value)
                    .font(.title3.weight(.black))
                    .foregroundStyle(highlight ? KickIQAICoachTheme.accent : KickIQAICoachTheme.textPrimary)
            }
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, KickIQAICoachTheme.Spacing.sm + 2)
        .background(highlight ? KickIQAICoachTheme.accent.opacity(0.08) : KickIQAICoachTheme.surface, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
    }

    private var improvementTrendCard: some View {
        let rate = storage.improvementRate
        let avgScore = storage.averageSessionScore
        let totalSessions = storage.sessions.count

        return VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm + 2) {
            Text("IMPROVEMENT TREND")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQAICoachTheme.accent)

            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    if let rate {
                        HStack(spacing: 3) {
                            Image(systemName: rate >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 11, weight: .bold))
                            Text(rate >= 0 ? "+\(rate)" : "\(rate)")
                                .font(.headline.weight(.black))
                        }
                        .foregroundStyle(rate >= 0 ? .green : .red)
                    } else {
                        Text("—")
                            .font(.headline.weight(.black))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    }
                    Text("Recent vs. Earlier")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)

                Rectangle().fill(KickIQAICoachTheme.divider).frame(width: 1, height: 36)

                VStack(spacing: 4) {
                    Text("\(avgScore)")
                        .font(.headline.weight(.black))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    Text("Avg Score")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)

                Rectangle().fill(KickIQAICoachTheme.divider).frame(width: 1, height: 36)

                VStack(spacing: 4) {
                    Text("\(totalSessions)")
                        .font(.headline.weight(.black))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    Text("Sessions")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, KickIQAICoachTheme.Spacing.sm)
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.08), value: appeared)
    }

    private var trainingVolumeCard: some View {
        let calendar = Calendar.current
        let last4Weeks: [(label: String, minutes: Int)] = (0..<4).reversed().map { weekOffset in
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now))!)!
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
            let mins = storage.drillCompletionHistory.filter { $0.date >= weekStart && $0.date < weekEnd }.reduce(0) { $0 + $1.durationSeconds } / 60
            let label = weekOffset == 0 ? "This" : "\(weekOffset)w ago"
            return (label: label, minutes: mins)
        }

        let maxMins = max(last4Weeks.map(\.minutes).max() ?? 1, 1)

        return VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm + 2) {
            HStack {
                Text("TRAINING VOLUME")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(KickIQAICoachTheme.accent)
                Spacer()
                Text("\(storage.thisWeekDrillMinutes) min this week")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
            }

            HStack(alignment: .bottom, spacing: KickIQAICoachTheme.Spacing.sm) {
                ForEach(Array(last4Weeks.enumerated()), id: \.offset) { _, week in
                    VStack(spacing: 4) {
                        Text("\(week.minutes)m")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(week.label == "This" ? KickIQAICoachTheme.accent : KickIQAICoachTheme.accent.opacity(0.4))
                            .frame(height: max(8, CGFloat(week.minutes) / CGFloat(maxMins) * 60))

                        Text(week.label)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 90)
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.1), value: appeared)
    }

    // MARK: - Score Over Time Chart
    private var scoreOverTimeCard: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.md) {
            HStack {
                Text("SKILL SCORE")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(KickIQAICoachTheme.accent)

                Spacer()

                if storage.sessions.count >= 2 {
                    let diff = storage.sessions[0].overallScore - storage.sessions[1].overallScore
                    HStack(spacing: 4) {
                        Image(systemName: diff >= 0 ? "arrow.up.right" : "arrow.down.right")
                        Text(diff >= 0 ? "+\(diff)" : "\(diff)")
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(diff >= 0 ? .green : .red)
                }
            }

            lineChartView

            skillFilterChips
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
    }

    private var lineChartView: some View {
        let recentSessions = Array(storage.sessions.prefix(10).reversed())

        return GeometryReader { geo in
            let width = geo.size.width
            let height: CGFloat = 100
            let maxVal: Double = 100

            let points = recentSessions.enumerated().map { index, session -> CGPoint in
                let x = recentSessions.count > 1 ? width * CGFloat(index) / CGFloat(recentSessions.count - 1) : width / 2
                let val = selectedSkill.flatMap { skill in
                    session.skillScores.first(where: { $0.category == skill }).map { Double($0.score) * 10 }
                } ?? Double(session.overallScore)
                let y = height - (height * val / maxVal)
                return CGPoint(x: x, y: y)
            }

            ZStack {
                if points.count > 1 {
                    Path { path in
                        path.move(to: CGPoint(x: points[0].x, y: height))
                        path.addLine(to: points[0])
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                        path.addLine(to: CGPoint(x: points.last!.x, y: height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [KickIQAICoachTheme.accent.opacity(0.3), KickIQAICoachTheme.accent.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    Path { path in
                        path.move(to: points[0])
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(KickIQAICoachTheme.accent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                }

                ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                    Circle()
                        .fill(KickIQAICoachTheme.accent)
                        .frame(width: 6, height: 6)
                        .position(point)
                }
            }
        }
        .frame(height: 100)
        .animation(.spring(response: 0.5), value: selectedSkill)
    }

    private var skillFilterChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                Button {
                    withAnimation(.spring(response: 0.3)) { selectedSkill = nil }
                } label: {
                    Text("All")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, KickIQAICoachTheme.Spacing.sm)
                        .background(selectedSkill == nil ? KickIQAICoachTheme.accent : KickIQAICoachTheme.surface, in: Capsule())
                        .foregroundStyle(selectedSkill == nil ? KickIQAICoachTheme.onAccent : KickIQAICoachTheme.textSecondary)
                }

                ForEach(position.skills) { skill in
                    Button {
                        withAnimation(.spring(response: 0.3)) { selectedSkill = skill }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: skill.icon)
                                .font(.system(size: 10))
                            Text(skill.rawValue)
                                .font(.caption.weight(.semibold))
                        }
                        .padding(.horizontal, KickIQAICoachTheme.Spacing.sm + 2)
                        .padding(.vertical, KickIQAICoachTheme.Spacing.sm)
                        .background(selectedSkill == skill ? KickIQAICoachTheme.accent : KickIQAICoachTheme.surface, in: Capsule())
                        .foregroundStyle(selectedSkill == skill ? KickIQAICoachTheme.onAccent : KickIQAICoachTheme.textSecondary)
                    }
                }
            }
        }
        .contentMargins(.horizontal, 0)
        .scrollIndicators(.hidden)
    }

    private var compareSessionsButton: some View {
        Button {
            showComparison = true
        } label: {
            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.subheadline)
                    .foregroundStyle(KickIQAICoachTheme.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Compare Sessions")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    Text("See how your skills changed over time")
                        .font(.caption)
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.3))
            }
            .padding(KickIQAICoachTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                    .fill(KickIQAICoachTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                            .stroke(KickIQAICoachTheme.accent.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.07), value: appeared)
    }

    // MARK: - Per-Skill Breakdown
    private var skillBreakdownCard: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm + 2) {
            Text("SKILL TRENDS")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQAICoachTheme.accent)

            if let latest = storage.sessions.first {
                let previous = storage.sessions.count > 1 ? storage.sessions[1] : nil

                ForEach(latest.skillScores) { score in
                    let prevScore = previous?.skillScores.first(where: { $0.category == score.category })?.score
                    let trend = prevScore.map { score.score - $0 }

                    HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                        Image(systemName: score.category.icon)
                            .font(.caption)
                            .foregroundStyle(KickIQAICoachTheme.accent)
                            .frame(width: 20)

                        Text(score.category.rawValue)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(KickIQAICoachTheme.textPrimary.opacity(0.8))

                        Spacer()

                        if let trend {
                            Image(systemName: trend > 0 ? "arrow.up" : trend < 0 ? "arrow.down" : "arrow.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(trend > 0 ? .green : trend < 0 ? .red : KickIQAICoachTheme.textSecondary)
                        }

                        Text("\(score.score)/10")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(KickIQAICoachTheme.textPrimary)
                            .frame(width: 40, alignment: .trailing)
                    }
                    .padding(.vertical, KickIQAICoachTheme.Spacing.xs)
                }
            }
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.05), value: appeared)
    }

    // MARK: - Streak Heatmap (GitHub-style)
    private var streakHeatmapCard: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            HStack {
                Text("STREAK CALENDAR")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(KickIQAICoachTheme.accent)

                Spacer()

                HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(KickIQAICoachTheme.accent)
                    Text("\(storage.streakCount) days")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                }
            }

            heatmapGrid
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.1), value: appeared)
    }

    private var heatmapGrid: some View {
        let calendar = Calendar.current
        let today = Date()
        let weeks = 12
        let totalDays = weeks * 7

        let dates: [Date] = (0..<totalDays).compactMap { offset in
            calendar.date(byAdding: .day, value: -(totalDays - 1 - offset), to: today)
        }

        let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: weeks)

        return LazyVGrid(columns: columns, spacing: 3) {
            ForEach(0..<totalDays, id: \.self) { index in
                let date = dates[index]
                let hasSession = storage.hasSessionOnDate(date)

                RoundedRectangle(cornerRadius: 2)
                    .fill(hasSession ? KickIQAICoachTheme.accent : KickIQAICoachTheme.divider.opacity(0.5))
                    .frame(height: 12)
                    .opacity(hasSession ? 1.0 : 0.3)
            }
        }
    }

    // MARK: - Badges
    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            Text("MILESTONES")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQAICoachTheme.accent)

            ScrollView(.horizontal) {
                HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                    ForEach(MilestoneBadge.allCases) { badge in
                        let earned = storage.earnedBadges.contains(badge)
                        badgeCard(badge: badge, earned: earned)
                    }
                }
            }
            .contentMargins(.horizontal, 0)
            .scrollIndicators(.hidden)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.15), value: appeared)
    }

    private func badgeCard(badge: MilestoneBadge, earned: Bool) -> some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            Image(systemName: badge.icon)
                .font(.title2)
                .foregroundStyle(earned ? KickIQAICoachTheme.accent : KickIQAICoachTheme.textSecondary.opacity(0.3))

            Text(badge.rawValue)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(earned ? KickIQAICoachTheme.textPrimary : KickIQAICoachTheme.textSecondary.opacity(0.4))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 80, height: 80)
        .background(earned ? KickIQAICoachTheme.accent.opacity(0.12) : KickIQAICoachTheme.surface, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.md)
                .stroke(earned ? KickIQAICoachTheme.accent.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    // MARK: - Session History
    private var sessionHistoryList: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            Text("ANALYSIS HISTORY")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQAICoachTheme.accent)

            ForEach(storage.sessions) { session in
                Button {
                    selectedSession = session
                } label: {
                    sessionRow(session)
                }
            }
        }
        .opacity(appeared ? 1 : 0)
    }

    private func sessionRow(_ session: TrainingSession) -> some View {
        HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            VStack(spacing: 2) {
                Text(session.date, format: .dateTime.day())
                    .font(.title3.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                Text(session.date, format: .dateTime.month(.abbreviated))
                    .font(.caption2)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.6))
            }
            .frame(width: 44)

            VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.xs) {
                HStack {
                    Text(session.position.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    Spacer()
                    Text("\(session.overallScore)")
                        .font(.headline.weight(.black))
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }

                HStack(spacing: 4) {
                    ForEach(session.skillScores.prefix(3)) { score in
                        HStack(spacing: 2) {
                            Image(systemName: score.category.icon)
                                .font(.system(size: 8))
                            Text("\(score.score)")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.6))
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.3))
        }
        .padding(KickIQAICoachTheme.Spacing.sm + 2)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
    }

    // MARK: - Share Progress
    private var shareProgressButton: some View {
        Button {
            generateProgressCard()
        } label: {
            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                Image(systemName: "square.and.arrow.up")
                Text("Share Progress")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(KickIQAICoachTheme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(KickIQAICoachTheme.accent.opacity(0.15), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.md)
                    .stroke(KickIQAICoachTheme.accent.opacity(0.3), lineWidth: 1)
            )
        }
    }

    @MainActor
    private func generateProgressCard() {
        guard let first = storage.sessions.last, let latest = storage.sessions.first else { return }
        let weeks = max(1, Calendar.current.dateComponents([.weekOfYear], from: first.date, to: latest.date).weekOfYear ?? 1)
        let improvement = latest.overallScore - first.overallScore

        if let image = ShareCardGenerator.generateImage(
            type: .progress(score: latest.overallScore, improvement: improvement, weeks: weeks),
            playerName: storage.profile?.name ?? "Player",
            position: storage.profile?.position ?? .midfielder,
            streakCount: storage.streakCount,
            skillScore: storage.skillScore
        ) {
            shareImage = image
            showShareSheet = true
        }
    }
}
