import SwiftUI
import StoreKit

struct HomeView: View {
    let storage: StorageService
    let customContentService: CustomContentService
    @Binding var selectedTab: Int
    @State private var appeared = false
    @State private var streakBounce = false
    @State private var scoreAnimated = false
    @State private var showSettings = false
    @State private var showReassessment = false
    @State private var showWeeklyGoal = false
    @State private var showTrainingPlan = false

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                        .padding(.horizontal, KickIQAICoachTheme.Spacing.md)

                    VStack(spacing: KickIQAICoachTheme.Spacing.md) {
                        trainingCategoryCards
                    }
                    .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                    .padding(.top, KickIQAICoachTheme.Spacing.md)

                    sectionBlock(title: "YOUR PROGRESS", icon: "chart.bar.fill") {
                        VStack(spacing: KickIQAICoachTheme.Spacing.sm + 4) {
                            skillScoreCard
                            playerLevelCard
                            quickStatsRow
                        }
                    }

                    sectionBlock(title: "TRAINING", icon: "flame.fill") {
                        VStack(spacing: KickIQAICoachTheme.Spacing.sm + 4) {
                            weeklyGoalCard
                            streakCard
                        }
                    }

                    sectionBlock(title: "BENCHMARK", icon: "chart.bar.doc.horizontal.fill") {
                        VStack(spacing: KickIQAICoachTheme.Spacing.sm + 4) {
                            benchmarkCTA
                            if !storage.favoriteDrillIDs.isEmpty {
                                favoriteDrillsPreview
                            }
                        }
                    }

                    if storage.shouldShowMonthlyReassessment {
                        sectionBlock(title: "ACTION NEEDED", icon: "exclamationmark.circle.fill") {
                            reassessmentCard
                        }
                    }

                    if !storage.benchmarkResults.isEmpty {
                        sectionBlock(title: "FOCUS AREAS", icon: "target") {
                            benchmarkFocusCard
                        }
                    }
                }
                .padding(.bottom, KickIQAICoachTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(storage: storage)
            }
            .sheet(isPresented: $showWeeklyGoal) {
                WeeklyGoalSheet(storage: storage)
            }
            .sheet(isPresented: $showTrainingPlan) {
                TrainingPlanView(storage: storage)
            }
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "skills":
                    SkillsDrillsView(storage: storage, customContentService: customContentService)
                case "conditioning":
                    ConditioningDrillsView(storage: storage, customContentService: customContentService)
                case "myContent":
                    CustomContentLibraryView(customContentService: customContentService, storage: storage)
                default:
                    EmptyView()
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) { scoreAnimated = true }
            }
            if storage.streakCount > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    streakBounce.toggle()
                }
            }
            checkReviewPrompt()
        }
    }

    private func sectionBlock<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm + 2) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(KickIQAICoachTheme.accent)
                Text(title)
                    .font(.system(.caption2, design: .default, weight: .black))
                    .tracking(1.5)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
            }
            .padding(.horizontal, KickIQAICoachTheme.Spacing.md)

            VStack(spacing: KickIQAICoachTheme.Spacing.sm + 4) {
                content()
            }
            .padding(KickIQAICoachTheme.Spacing.md)
            .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.xl))
            .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
        }
        .padding(.top, KickIQAICoachTheme.Spacing.lg)
    }

    private var headerSection: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.xl)
                .fill(
                    LinearGradient(
                        colors: [
                            KickIQAICoachTheme.accent,
                            KickIQAICoachTheme.accent.opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 170)
                .overlay {
                    RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.xl)
                        .fill(
                            MeshGradient(
                                width: 3, height: 3,
                                points: [
                                    [0, 0], [0.5, 0], [1, 0],
                                    [0, 0.5], [0.6, 0.4], [1, 0.5],
                                    [0, 1], [0.5, 1], [1, 1]
                                ],
                                colors: [
                                    .clear, .white.opacity(0.08), .clear,
                                    .clear, .white.opacity(0.05), .clear,
                                    .clear, .clear, .white.opacity(0.03)
                                ]
                            )
                        )
                }
                .overlay(alignment: .topTrailing) {
                    Button {
                        selectedTab = 1
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "brain.head.profile.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text("AI Coach")
                                .font(.caption.weight(.black))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.2), in: Capsule())
                        .overlay(Capsule().stroke(.white.opacity(0.3), lineWidth: 1))
                    }
                    .padding(KickIQAICoachTheme.Spacing.md)
                    .sensoryFeedback(.impact(weight: .light), trigger: selectedTab)
                }
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "soccerball")
                        .font(.system(size: 70))
                        .foregroundStyle(.white.opacity(0.06))
                        .rotationEffect(.degrees(15))
                        .offset(x: 10, y: 10)
                }

            VStack(alignment: .leading, spacing: 6) {
                Text("KICKIQ")
                    .font(.system(.caption, design: .default, weight: .black).width(.compressed))
                    .tracking(4)
                    .foregroundStyle(.white.opacity(0.7))

                Text("\(greeting),")
                    .font(.system(.title3, design: .default, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))

                Text(storage.profile?.name ?? "Player")
                    .font(.system(.title, design: .default, weight: .black))
                    .foregroundStyle(.white)

                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: storage.playerLevel.icon)
                            .font(.system(size: 11, weight: .bold))
                        Text(storage.playerLevel.rawValue)
                            .font(.caption.weight(.black))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.2), in: Capsule())

                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 9))
                        Text("\(storage.xpPoints) XP")
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(.white.opacity(0.8))
                }
            }
            .padding(KickIQAICoachTheme.Spacing.lg)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
    }

    private var trainingCategoryCards: some View {
        HStack(spacing: KickIQAICoachTheme.Spacing.sm + 2) {
            NavigationLink(value: "skills") {
                VStack(alignment: .leading, spacing: 0) {
                    ZStack {
                        Circle()
                            .fill(KickIQAICoachTheme.accent.opacity(0.2))
                            .frame(width: 48, height: 48)
                        Image(systemName: "figure.soccer")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(KickIQAICoachTheme.accent)
                    }
                    .padding(.bottom, 12)

                    Text("DRILLS")
                        .font(.system(.headline, design: .default, weight: .black))
                        .tracking(1)
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                        .padding(.bottom, 2)

                    Text("GENERATOR")
                        .font(.system(.caption, design: .default, weight: .black))
                        .tracking(1)
                        .foregroundStyle(KickIQAICoachTheme.accent)
                        .padding(.bottom, 8)

                    if storage.skillsPlan != nil {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(.green)
                            Text("Active Plan")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.green)
                        }
                    } else {
                        Text("Tap to explore")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(KickIQAICoachTheme.Spacing.md)
                .frame(height: 170)
                .background(
                    RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.xl)
                        .fill(
                            LinearGradient(
                                colors: [KickIQAICoachTheme.accent.opacity(0.15), KickIQAICoachTheme.accent.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.xl)
                                .stroke(KickIQAICoachTheme.accent.opacity(0.25), lineWidth: 1)
                        )
                )
            }
            .sensoryFeedback(.impact(weight: .light), trigger: appeared)

            NavigationLink(value: "conditioning") {
                VStack(alignment: .leading, spacing: 0) {
                    ZStack {
                        Circle()
                            .fill(KickIQAICoachTheme.accent.opacity(0.2))
                            .frame(width: 48, height: 48)
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(KickIQAICoachTheme.accent)
                    }
                    .padding(.bottom, 12)

                    Text("FITNESS")
                        .font(.system(.headline, design: .default, weight: .black))
                        .tracking(1)
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                        .padding(.bottom, 2)

                    Text("GENERATOR")
                        .font(.system(.caption, design: .default, weight: .black))
                        .tracking(1)
                        .foregroundStyle(KickIQAICoachTheme.accent)
                        .padding(.bottom, 8)

                    if storage.conditioningPlan != nil {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(.green)
                            Text("Active Plan")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.green)
                        }
                    } else {
                        Text("Tap to explore")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(KickIQAICoachTheme.Spacing.md)
                .frame(height: 170)
                .background(
                    RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.xl)
                        .fill(
                            LinearGradient(
                                colors: [KickIQAICoachTheme.accent.opacity(0.15), KickIQAICoachTheme.accent.opacity(0.05)],
                                startPoint: .topTrailing,
                                endPoint: .bottomLeading
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.xl)
                                .stroke(KickIQAICoachTheme.accent.opacity(0.25), lineWidth: 1)
                        )
                )
            }
            .sensoryFeedback(.impact(weight: .light), trigger: appeared)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.03), value: appeared)
    }

    private var skillScoreCard: some View {
        let score = storage.skillScore

        return HStack(spacing: KickIQAICoachTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .stroke(KickIQAICoachTheme.divider, lineWidth: 8)
                    .frame(width: 90, height: 90)

                Circle()
                    .trim(from: 0, to: scoreAnimated ? Double(score) / 100.0 : 0)
                    .stroke(
                        AngularGradient(
                            colors: [KickIQAICoachTheme.accent, KickIQAICoachTheme.accent.opacity(0.3), KickIQAICoachTheme.accent],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: KickIQAICoachTheme.accent.opacity(0.3), radius: 8, x: 0, y: 0)

                VStack(spacing: 0) {
                    Text("\(score)")
                        .font(.system(size: 32, weight: .black, design: .default))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                        .contentTransition(.numericText())
                    Text("/ 100")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }
                .scaleEffect(scoreAnimated ? 1 : 0.6)
                .opacity(scoreAnimated ? 1 : 0)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("SKILL SCORE")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(KickIQAICoachTheme.accent)

                Text(score > 75 ? "Crushing it!" : score > 50 ? "Building momentum" : score > 0 ? "Keep grinding" : "Analyze to start")
                    .font(.headline.weight(.black))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)

                if let latest = storage.latestSession {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text(latest.date, style: .relative)
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.6))
                }
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Skill score \(score) out of 100")
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.05), value: appeared)
    }

    private var playerLevelCard: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: storage.playerLevel.icon)
                        .font(.subheadline)
                        .foregroundStyle(KickIQAICoachTheme.accent)
                    Text(storage.playerLevel.rawValue.uppercased())
                        .font(.caption.weight(.black))
                        .tracking(1)
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }
                Spacer()
                if let progress = storage.xpProgress {
                    Text("\(progress.current)/\(progress.needed) XP")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                } else {
                    Text("MAX LEVEL")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }
            }

            if let progress = storage.xpProgress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(KickIQAICoachTheme.divider)
                            .frame(height: 6)
                        Capsule()
                            .fill(KickIQAICoachTheme.accent)
                            .frame(width: max(0, geo.size.width * Double(progress.current) / Double(max(1, progress.needed))), height: 6)
                    }
                }
                .frame(height: 6)

                if let next = storage.playerLevel.nextLevel {
                    Text("Next: \(next.rawValue)")
                        .font(.caption2)
                        .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .padding(KickIQAICoachTheme.Spacing.sm + 4)
        .background(Color(.tertiarySystemGroupedBackground), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.07), value: appeared)
    }

    private var streakCard: some View {
        HStack(spacing: KickIQAICoachTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(storage.isStreakBroken ? Color.red.opacity(0.12) : KickIQAICoachTheme.accent.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: storage.isStreakBroken ? "flame" : "flame.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(storage.isStreakBroken ? KickIQAICoachTheme.textSecondary : KickIQAICoachTheme.accent)
                    .symbolEffect(.bounce, value: streakBounce)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(storage.streakCount)")
                        .font(.system(.title2, design: .default, weight: .black))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    Text("day streak")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }

                Text(storage.streakMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(storage.isStreakBroken ? KickIQAICoachTheme.accent : KickIQAICoachTheme.textSecondary.opacity(0.7))
            }

            Spacer()
        }
        .padding(KickIQAICoachTheme.Spacing.sm + 4)
        .background(Color(.tertiarySystemGroupedBackground), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(storage.streakCount) day streak. \(storage.streakMessage)")
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.1), value: appeared)
    }

    private var weeklyGoalCard: some View {
        let goal = storage.weeklyGoal
        let completed = storage.weeklySessionsCompleted
        let target = goal?.sessionsPerWeek ?? 3
        let progress = min(Double(completed) / Double(max(target, 1)), 1.0)

        return Button {
            showWeeklyGoal = true
        } label: {
            HStack(spacing: KickIQAICoachTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .stroke(KickIQAICoachTheme.divider, lineWidth: 5)
                        .frame(width: 48, height: 48)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(KickIQAICoachTheme.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .frame(width: 48, height: 48)
                        .rotationEffect(.degrees(-90))

                    Text("\(completed)/\(target)")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("WEEKLY GOAL")
                        .font(.caption.weight(.bold))
                        .tracking(1)
                        .foregroundStyle(KickIQAICoachTheme.accent)

                    if goal != nil {
                        Text(completed >= target ? "Goal reached!" : "\(target - completed) more to go")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(completed >= target ? .green : KickIQAICoachTheme.textSecondary)
                    } else {
                        Text("Tap to set a weekly training goal")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.3))
            }
            .padding(KickIQAICoachTheme.Spacing.sm + 4)
            .background(
                RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.md)
                    .fill(Color(.tertiarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.md)
                            .stroke(completed >= target && goal != nil ? KickIQAICoachTheme.accent.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.08), value: appeared)
    }

    private var benchmarkCTA: some View {
        Button {
            selectedTab = 2
        } label: {
            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                Image(systemName: "chart.bar.doc.horizontal.fill")
                    .font(.title3)
                Text(storage.benchmarkResults.isEmpty ? "Start Benchmark" : "Retest Skills")
                    .font(.headline.weight(.bold))
            }
            .foregroundStyle(KickIQAICoachTheme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.md)
                    .fill(KickIQAICoachTheme.accent.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.md)
                            .stroke(KickIQAICoachTheme.accent.opacity(0.3), lineWidth: 1.5)
                    )
            )
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: selectedTab)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.15), value: appeared)
    }

    private var benchmarkFocusCard: some View {
        let weak = storage.benchmarkWeakestCategories
        let rank = storage.benchmarkPlayerRank

        return VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: rank.icon)
                        .font(.subheadline)
                    Text(rank.rawValue.uppercased())
                        .font(.caption.weight(.black))
                        .tracking(1)
                }
                .foregroundStyle(KickIQAICoachTheme.accent)

                Spacer()

                Text("\(Int(storage.benchmarkOverallScore))%")
                    .font(.headline.weight(.black))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
            }

            if !weak.isEmpty {
                Text("Priority drill areas:")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)

                HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                    ForEach(weak.prefix(3)) { cat in
                        HStack(spacing: 4) {
                            Image(systemName: cat.icon)
                                .font(.system(size: 10))
                            Text(cat.rawValue)
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.orange.opacity(0.12), in: Capsule())
                    }
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.25), value: appeared)
    }

    private var quickStatsRow: some View {
        HStack(spacing: 0) {
            statItem(icon: "clock.fill", iconColor: KickIQAICoachTheme.accent, value: "\(storage.thisWeekDrillMinutes)m", label: "This Week")
            Rectangle().fill(KickIQAICoachTheme.divider).frame(width: 1, height: 28)
            statItem(icon: "checkmark.circle.fill", iconColor: .green, value: "\(storage.completedDrillIDs.count)", label: "Drills Done")
            Rectangle().fill(KickIQAICoachTheme.divider).frame(width: 1, height: 28)
            statItem(icon: "heart.fill", iconColor: .red.opacity(0.7), value: "\(storage.favoriteDrillIDs.count)", label: "Favorites")
            Rectangle().fill(KickIQAICoachTheme.divider).frame(width: 1, height: 28)
            statItem(icon: "trophy.fill", iconColor: KickIQAICoachTheme.accent, value: "\(storage.sessions.map(\.overallScore).max() ?? 0)", label: "Best Score")
        }
        .padding(.vertical, KickIQAICoachTheme.Spacing.sm + 2)
        .background(Color(.tertiarySystemGroupedBackground), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.12), value: appeared)
    }

    private func statItem(icon: String, iconColor: Color, value: String, label: String) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                    .foregroundStyle(iconColor)
                Text(value)
                    .font(.caption.weight(.black))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
            }
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var favoriteDrillsPreview: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                    Text("SAVED DRILLS")
                        .font(.caption.weight(.bold))
                        .tracking(1)
                }
                .foregroundStyle(.red.opacity(0.8))
                Spacer()
                Button {
                    selectedTab = 4
                } label: {
                    Text("See All")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }
            }

            Text("\(storage.favoriteDrillIDs.count) drill\(storage.favoriteDrillIDs.count == 1 ? "" : "s") saved for quick access")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
        }
        .padding(KickIQAICoachTheme.Spacing.sm + 4)
        .background(Color(.tertiarySystemGroupedBackground), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.22), value: appeared)
    }

    private var reassessmentCard: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption)
                Text("MONTHLY CHECK-IN")
                    .font(.caption.weight(.bold))
                    .tracking(1)
            }
            .foregroundStyle(.orange)

            Text("Time to recheck your weakest skill")
                .font(.headline.weight(.bold))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)

            Text("It's been a month — update your focus area to keep improving.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary)

            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                Button {
                    showReassessment = true
                } label: {
                    Text("Update Focus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KickIQAICoachTheme.onAccent)
                        .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                        .padding(.vertical, KickIQAICoachTheme.Spacing.sm)
                        .background(KickIQAICoachTheme.accent, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.sm))
                }

                Button {
                    storage.recordMonthlyReassessment()
                } label: {
                    Text("Dismiss")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }
            }
        }
        .sheet(isPresented: $showReassessment) {
            ReassessmentSheet(storage: storage)
        }
    }



    private func checkReviewPrompt() {
        guard storage.shouldPromptReview else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                AppStore.requestReview(in: scene)
                storage.recordReviewPrompt()
            }
        }
    }
}

struct ReassessmentSheet: View {
    let storage: StorageService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedWeakness: WeaknessArea = .firstTouch

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQAICoachTheme.Spacing.lg) {
                    VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 40))
                            .foregroundStyle(KickIQAICoachTheme.accent)

                        Text("What needs the most work?")
                            .font(.title3.weight(.black))
                            .foregroundStyle(KickIQAICoachTheme.textPrimary)

                        Text("Pick the area you want to focus on this month.")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    }
                    .padding(.top, KickIQAICoachTheme.Spacing.md)

                    VStack(spacing: 10) {
                        ForEach(WeaknessArea.allCases) { area in
                            Button {
                                selectedWeakness = area
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: area.icon)
                                        .font(.title3)
                                        .foregroundStyle(selectedWeakness == area ? KickIQAICoachTheme.accent : KickIQAICoachTheme.textSecondary)
                                        .frame(width: 32)
                                    Text(area.rawValue)
                                        .font(.headline)
                                        .foregroundStyle(selectedWeakness == area ? KickIQAICoachTheme.textPrimary : KickIQAICoachTheme.textSecondary)
                                    Spacer()
                                    if selectedWeakness == area {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(KickIQAICoachTheme.accent)
                                    }
                                }
                                .padding(KickIQAICoachTheme.Spacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.md)
                                        .fill(selectedWeakness == area ? KickIQAICoachTheme.accent.opacity(0.15) : KickIQAICoachTheme.card)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.md)
                                                .stroke(selectedWeakness == area ? KickIQAICoachTheme.accent : Color.clear, lineWidth: 1.5)
                                        )
                                )
                            }
                        }
                    }

                    Button {
                        if var profile = storage.profile {
                            profile.weakness = selectedWeakness
                            storage.saveProfile(profile)
                        }
                        storage.recordMonthlyReassessment()
                        dismiss()
                    } label: {
                        Text("Update Focus")
                            .font(.headline)
                            .foregroundStyle(KickIQAICoachTheme.onAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, KickIQAICoachTheme.Spacing.md)
                            .background(KickIQAICoachTheme.accent, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
                    }
                }
                .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
            }
            .scrollIndicators(.hidden)
            .background(KickIQAICoachTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.background)
        .onAppear {
            selectedWeakness = storage.profile?.weakness ?? .firstTouch
        }
    }
}
