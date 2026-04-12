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
                VStack(spacing: KickIQTheme.Spacing.md + 4) {
                    if storage.sessions.isEmpty {
                        emptyState
                    } else {
                        levelOverviewCard
                        scoreOverTimeCard
                        if storage.sessions.count >= 2 {
                            compareSessionsButton
                        }
                        skillBreakdownCard
                        streakHeatmapCard
                        badgesSection
                        sessionHistoryList
                        shareProgressButton
                    }
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .padding(.bottom, KickIQTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $selectedSession) { session in
                NavigationStack {
                    AnalysisResultView(session: session, storage: storage) {
                        selectedSession = nil
                    }
                }
                .presentationDragIndicator(.visible)
                .presentationBackground(KickIQTheme.background)
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
        VStack(spacing: KickIQTheme.Spacing.md) {
            Spacer().frame(height: 60)

            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(KickIQTheme.accent.opacity(0.5))

            Text("No Progress Yet")
                .font(.title3.weight(.bold))
                .foregroundStyle(KickIQTheme.textPrimary)

            Text("Complete your first analysis session\nto start tracking your progress")
                .font(.subheadline)
                .foregroundStyle(KickIQTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var levelOverviewCard: some View {
        VStack(spacing: KickIQTheme.Spacing.md) {
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(KickIQTheme.accent.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: storage.playerLevel.icon)
                            .font(.title3)
                            .foregroundStyle(KickIQTheme.accent)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(storage.playerLevel.rawValue)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(KickIQTheme.textPrimary)
                        Text("\(storage.xpPoints) XP earned")
                            .font(.caption)
                            .foregroundStyle(KickIQTheme.textSecondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(storage.analysisCount)")
                        .font(.title3.weight(.black))
                        .foregroundStyle(KickIQTheme.accent)
                    Text("analyses")
                        .font(.caption2)
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
            }

            if let progress = storage.xpProgress {
                VStack(spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(KickIQTheme.divider)
                                .frame(height: 8)
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [KickIQTheme.accent.opacity(0.7), KickIQTheme.accent],
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
                            .foregroundStyle(KickIQTheme.textSecondary.opacity(0.6))
                        Spacer()
                        if let next = storage.playerLevel.nextLevel {
                            Text(next.rawValue)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(KickIQTheme.accent.opacity(0.6))
                        }
                    }
                }
            }
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
    }

    // MARK: - Score Over Time Chart
    private var scoreOverTimeCard: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.md) {
            HStack {
                Text("SKILL SCORE")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(KickIQTheme.accent)

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
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
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
                            colors: [KickIQTheme.accent.opacity(0.3), KickIQTheme.accent.opacity(0.0)],
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
                    .stroke(KickIQTheme.accent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                }

                ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                    Circle()
                        .fill(KickIQTheme.accent)
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
            HStack(spacing: KickIQTheme.Spacing.sm) {
                Button {
                    withAnimation(.spring(response: 0.3)) { selectedSkill = nil }
                } label: {
                    Text("All")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, KickIQTheme.Spacing.sm)
                        .background(selectedSkill == nil ? KickIQTheme.accent : KickIQTheme.surface, in: Capsule())
                        .foregroundStyle(selectedSkill == nil ? .black : KickIQTheme.textSecondary)
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
                        .padding(.horizontal, KickIQTheme.Spacing.sm + 2)
                        .padding(.vertical, KickIQTheme.Spacing.sm)
                        .background(selectedSkill == skill ? KickIQTheme.accent : KickIQTheme.surface, in: Capsule())
                        .foregroundStyle(selectedSkill == skill ? .black : KickIQTheme.textSecondary)
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
            HStack(spacing: KickIQTheme.Spacing.sm) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.subheadline)
                    .foregroundStyle(KickIQTheme.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Compare Sessions")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KickIQTheme.textPrimary)
                    Text("See how your skills changed over time")
                        .font(.caption)
                        .foregroundStyle(KickIQTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(KickIQTheme.textSecondary.opacity(0.3))
            }
            .padding(KickIQTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                    .fill(KickIQTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                            .stroke(KickIQTheme.accent.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.07), value: appeared)
    }

    // MARK: - Per-Skill Breakdown
    private var skillBreakdownCard: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm + 2) {
            Text("SKILL TRENDS")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQTheme.accent)

            if let latest = storage.sessions.first {
                let previous = storage.sessions.count > 1 ? storage.sessions[1] : nil

                ForEach(latest.skillScores) { score in
                    let prevScore = previous?.skillScores.first(where: { $0.category == score.category })?.score
                    let trend = prevScore.map { score.score - $0 }

                    HStack(spacing: KickIQTheme.Spacing.sm) {
                        Image(systemName: score.category.icon)
                            .font(.caption)
                            .foregroundStyle(KickIQTheme.accent)
                            .frame(width: 20)

                        Text(score.category.rawValue)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(KickIQTheme.textPrimary.opacity(0.8))

                        Spacer()

                        if let trend {
                            Image(systemName: trend > 0 ? "arrow.up" : trend < 0 ? "arrow.down" : "arrow.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(trend > 0 ? .green : trend < 0 ? .red : KickIQTheme.textSecondary)
                        }

                        Text("\(score.score)/10")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(KickIQTheme.textPrimary)
                            .frame(width: 40, alignment: .trailing)
                    }
                    .padding(.vertical, KickIQTheme.Spacing.xs)
                }
            }
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.05), value: appeared)
    }

    // MARK: - Streak Heatmap (GitHub-style)
    private var streakHeatmapCard: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            HStack {
                Text("STREAK CALENDAR")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(KickIQTheme.accent)

                Spacer()

                HStack(spacing: KickIQTheme.Spacing.sm) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(KickIQTheme.accent)
                    Text("\(storage.streakCount) days")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(KickIQTheme.textPrimary)
                }
            }

            heatmapGrid
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
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
                    .fill(hasSession ? KickIQTheme.accent : KickIQTheme.divider.opacity(0.5))
                    .frame(height: 12)
                    .opacity(hasSession ? 1.0 : 0.3)
            }
        }
    }

    // MARK: - Badges
    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            Text("MILESTONES")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQTheme.accent)

            ScrollView(.horizontal) {
                HStack(spacing: KickIQTheme.Spacing.sm) {
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
        VStack(spacing: KickIQTheme.Spacing.sm) {
            Image(systemName: badge.icon)
                .font(.title2)
                .foregroundStyle(earned ? KickIQTheme.accent : KickIQTheme.textSecondary.opacity(0.3))

            Text(badge.rawValue)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(earned ? KickIQTheme.textPrimary : KickIQTheme.textSecondary.opacity(0.4))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 80, height: 80)
        .background(earned ? KickIQTheme.accent.opacity(0.12) : KickIQTheme.surface, in: .rect(cornerRadius: KickIQTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: KickIQTheme.Radius.md)
                .stroke(earned ? KickIQTheme.accent.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    // MARK: - Session History
    private var sessionHistoryList: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            Text("ANALYSIS HISTORY")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQTheme.accent)

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
        HStack(spacing: KickIQTheme.Spacing.sm) {
            VStack(spacing: 2) {
                Text(session.date, format: .dateTime.day())
                    .font(.title3.weight(.bold))
                    .foregroundStyle(KickIQTheme.textPrimary)
                Text(session.date, format: .dateTime.month(.abbreviated))
                    .font(.caption2)
                    .foregroundStyle(KickIQTheme.textSecondary.opacity(0.6))
            }
            .frame(width: 44)

            VStack(alignment: .leading, spacing: KickIQTheme.Spacing.xs) {
                HStack {
                    Text(session.position.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KickIQTheme.textPrimary)
                    Spacer()
                    Text("\(session.overallScore)")
                        .font(.headline.weight(.black))
                        .foregroundStyle(KickIQTheme.accent)
                }

                HStack(spacing: 4) {
                    ForEach(session.skillScores.prefix(3)) { score in
                        HStack(spacing: 2) {
                            Image(systemName: score.category.icon)
                                .font(.system(size: 8))
                            Text("\(score.score)")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(KickIQTheme.textSecondary.opacity(0.6))
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(KickIQTheme.textSecondary.opacity(0.3))
        }
        .padding(KickIQTheme.Spacing.sm + 2)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
    }

    // MARK: - Share Progress
    private var shareProgressButton: some View {
        Button {
            generateProgressCard()
        } label: {
            HStack(spacing: KickIQTheme.Spacing.sm) {
                Image(systemName: "square.and.arrow.up")
                Text("Share Progress")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(KickIQTheme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(KickIQTheme.accent.opacity(0.15), in: .rect(cornerRadius: KickIQTheme.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: KickIQTheme.Radius.md)
                    .stroke(KickIQTheme.accent.opacity(0.3), lineWidth: 1)
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
