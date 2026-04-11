import SwiftUI
import StoreKit

struct HomeView: View {
    let storage: StorageService
    let calendarService: CalendarService
    @Binding var selectedTab: Int
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var appeared = false
    @State private var streakBounce = false
    @State private var scoreAnimated = false
    @State private var showSettings = false
    @State private var showReassessment = false
    @State private var showWeeklyGoal = false
    @State private var showTrainingPlan = false
    @State private var showQRScanner = false
    @State private var showSkillAssessment = false

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var isIPad: Bool { sizeClass == .regular }

    var body: some View {
        NavigationStack {
            ScrollView {
                if isIPad {
                    iPadHomeLayout
                } else {
                    iPhoneHomeLayout
                }
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showQRScanner = true
                    } label: {
                        Image(systemName: "qrcode.viewfinder")
                            .foregroundStyle(KickIQTheme.accent)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(KickIQTheme.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(storage: storage, calendarService: calendarService)
            }
            .sheet(isPresented: $showWeeklyGoal) {
                WeeklyGoalSheet(storage: storage)
            }
            .sheet(isPresented: $showTrainingPlan) {
                TrainingPlanView(storage: storage)
            }
            .sheet(isPresented: $showQRScanner) {
                QRScannerView(storage: storage)
            }
            .sheet(isPresented: $showSkillAssessment) {
                SkillAssessmentView(storage: storage)
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

    // MARK: - iPhone Layout

    private var iPhoneHomeLayout: some View {
        VStack(spacing: KickIQTheme.Spacing.md + 4) {
            headerSection
            playerLevelCard
            skillScoreCard
            weeklyGoalCard
            streakCard
            analyzeCTA
            skillAssessmentCTA
            trainingPlanCTA
            todaysDrillCard
            if storage.shouldShowMonthlyReassessment {
                reassessmentCard
            }
            if let session = storage.latestSession {
                recentAnalysisCard(session)
            }
        }
        .padding(.horizontal, KickIQTheme.Spacing.md)
        .padding(.bottom, KickIQTheme.Spacing.xl)
    }

    // MARK: - iPad Layout

    private var iPadHomeLayout: some View {
        VStack(spacing: KickIQTheme.Spacing.lg) {
            headerSection

            HStack(alignment: .top, spacing: KickIQTheme.Spacing.lg) {
                VStack(spacing: KickIQTheme.Spacing.md + 4) {
                    skillScoreCard
                    playerLevelCard
                    streakCard
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: KickIQTheme.Spacing.md + 4) {
                    weeklyGoalCard
                    analyzeCTA
                    skillAssessmentCTA
                    trainingPlanCTA
                }
                .frame(maxWidth: .infinity)
            }

            todaysDrillCard

            if storage.shouldShowMonthlyReassessment {
                reassessmentCard
            }
            if let session = storage.latestSession {
                recentAnalysisCard(session)
            }
        }
        .padding(.horizontal, KickIQTheme.Spacing.lg)
        .padding(.bottom, KickIQTheme.Spacing.xl)
        .frame(maxWidth: AdaptiveLayout.iPadWideMaxContentWidth)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Cards

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.xs) {
            Text("KICKIQ")
                .font(.system(.caption, design: .default, weight: .bold).width(.compressed))
                .tracking(3)
                .foregroundStyle(KickIQTheme.accent)

            Text("\(greeting), \(storage.profile?.name ?? "Player")")
                .font(.system(isIPad ? .title : .title2, design: .default, weight: .bold))
                .foregroundStyle(KickIQTheme.textPrimary)

            HStack(spacing: 6) {
                Image(systemName: storage.playerLevel.icon)
                    .font(.caption)
                    .foregroundStyle(KickIQTheme.accent)
                Text(storage.playerLevel.rawValue)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(KickIQTheme.accent)
                Text("·")
                    .foregroundStyle(KickIQTheme.textSecondary.opacity(0.4))
                Text("\(storage.xpPoints) XP")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(KickIQTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, KickIQTheme.Spacing.sm)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
    }

    private var skillScoreCard: some View {
        let score = storage.skillScore
        let circleSize: CGFloat = isIPad ? 160 : 140

        return VStack(spacing: KickIQTheme.Spacing.md) {
            Text("SKILL SCORE")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQTheme.accent)

            ZStack {
                Circle()
                    .stroke(KickIQTheme.divider, lineWidth: 10)
                    .frame(width: circleSize, height: circleSize)

                Circle()
                    .trim(from: 0, to: scoreAnimated ? Double(score) / 100.0 : 0)
                    .stroke(
                        AngularGradient(
                            colors: [KickIQTheme.accent, KickIQTheme.accent.opacity(0.4), KickIQTheme.accent],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: circleSize, height: circleSize)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(score)")
                        .font(.system(size: isIPad ? 56 : 48, weight: .black, design: .default))
                        .foregroundStyle(KickIQTheme.textPrimary)
                        .contentTransition(.numericText())
                    Text("/ 100")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
                .scaleEffect(scoreAnimated ? 1 : 0.6)
                .opacity(scoreAnimated ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, KickIQTheme.Spacing.lg)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.xl))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Skill score \(score) out of 100")
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.05), value: appeared)
    }

    private var playerLevelCard: some View {
        VStack(spacing: KickIQTheme.Spacing.sm) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: storage.playerLevel.icon)
                        .font(.subheadline)
                        .foregroundStyle(KickIQTheme.accent)
                    Text(storage.playerLevel.rawValue.uppercased())
                        .font(.caption.weight(.black))
                        .tracking(1)
                        .foregroundStyle(KickIQTheme.accent)
                }
                Spacer()
                if let progress = storage.xpProgress {
                    Text("\(progress.current)/\(progress.needed) XP")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(KickIQTheme.textSecondary)
                } else {
                    Text("MAX LEVEL")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(KickIQTheme.accent)
                }
            }

            if let progress = storage.xpProgress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(KickIQTheme.divider)
                            .frame(height: 6)
                        Capsule()
                            .fill(KickIQTheme.accent)
                            .frame(width: max(0, geo.size.width * Double(progress.current) / Double(max(1, progress.needed))), height: 6)
                    }
                }
                .frame(height: 6)

                if let next = storage.playerLevel.nextLevel {
                    Text("Next: \(next.rawValue)")
                        .font(.caption2)
                        .foregroundStyle(KickIQTheme.textSecondary.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.07), value: appeared)
    }

    private var streakCard: some View {
        VStack(spacing: KickIQTheme.Spacing.sm) {
            HStack(spacing: KickIQTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(storage.isStreakBroken ? Color.red.opacity(0.12) : storage.streakFrozenToday ? Color.blue.opacity(0.15) : KickIQTheme.accent.opacity(0.15))
                        .frame(width: 52, height: 52)

                    Image(systemName: storage.streakFrozenToday ? "snowflake" : storage.isStreakBroken ? "flame" : "flame.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(storage.streakFrozenToday ? .blue : storage.isStreakBroken ? KickIQTheme.textSecondary : KickIQTheme.accent)
                        .symbolEffect(.bounce, value: streakBounce)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(storage.streakCount)")
                            .font(.system(.title2, design: .default, weight: .black))
                            .foregroundStyle(KickIQTheme.textPrimary)
                        Text("day streak")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(KickIQTheme.textSecondary)
                    }

                    Text(storage.streakMessage)
                        .font(.caption)
                        .foregroundStyle(storage.isStreakBroken ? KickIQTheme.accent : KickIQTheme.textSecondary.opacity(0.7))
                }

                Spacer()
            }

            if storage.canUseStreakFreeze && !storage.streakFrozenToday {
                Button {
                    storage.useStreakFreeze()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "snowflake")
                            .font(.caption.weight(.bold))
                        Text("Use Streak Freeze")
                            .font(.caption.weight(.bold))
                        Text("(1/week)")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.blue.opacity(0.7))
                    }
                    .foregroundStyle(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1), in: .rect(cornerRadius: KickIQTheme.Radius.sm))
                    .overlay(
                        RoundedRectangle(cornerRadius: KickIQTheme.Radius.sm)
                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    )
                }
            } else if storage.streakFreezeUsedThisWeek && !storage.streakFrozenToday {
                HStack(spacing: 5) {
                    Image(systemName: "snowflake")
                        .font(.system(size: 9))
                    Text("Streak freeze used this week")
                        .font(.caption2.weight(.medium))
                }
                .foregroundStyle(KickIQTheme.textSecondary.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
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
            HStack(spacing: KickIQTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .stroke(KickIQTheme.divider, lineWidth: 5)
                        .frame(width: 52, height: 52)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(KickIQTheme.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .frame(width: 52, height: 52)
                        .rotationEffect(.degrees(-90))

                    Text("\(completed)/\(target)")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(KickIQTheme.textPrimary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("WEEKLY GOAL")
                        .font(.caption.weight(.bold))
                        .tracking(1)
                        .foregroundStyle(KickIQTheme.accent)

                    if goal != nil {
                        Text(completed >= target ? "Goal reached! 🎯" : "\(target - completed) more to go")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(completed >= target ? .green : KickIQTheme.textSecondary)
                    } else {
                        Text("Tap to set a weekly training goal")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(KickIQTheme.textSecondary)
                    }
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
                            .stroke(completed >= target && goal != nil ? KickIQTheme.accent.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.08), value: appeared)
    }

    private var trainingPlanCTA: some View {
        Button {
            showTrainingPlan = true
        } label: {
            Group {
                if let plan = storage.smartTrainingPlan, let today = plan.todaysPlan {
                    smartPlanCard(today, plan: plan)
                } else {
                    HStack(spacing: KickIQTheme.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(KickIQTheme.accent.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: "calendar.badge.plus")
                                .font(.title3)
                                .foregroundStyle(KickIQTheme.accent)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Smart Training Plan")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(KickIQTheme.textPrimary)
                            Text("30-day daily plan based on your weaknesses")
                                .font(.caption)
                                .foregroundStyle(KickIQTheme.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(KickIQTheme.textSecondary.opacity(0.3))
                    }
                    .padding(KickIQTheme.Spacing.md)
                    .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.17), value: appeared)
    }

    private func smartPlanCard(_ today: DailyPlan, plan: SmartTrainingPlan) -> some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text("TODAY'S SESSION")
                            .font(.caption.weight(.bold))
                            .tracking(1)
                    }
                    .foregroundStyle(KickIQTheme.accent)

                    Text(today.focus)
                        .font(.headline)
                        .foregroundStyle(KickIQTheme.textPrimary)
                }
                Spacer()
                VStack(spacing: 2) {
                    Text("DAY")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(KickIQTheme.accent)
                    Text("\(today.dayNumber)")
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(KickIQTheme.textPrimary)
                }
                .frame(width: 42, height: 42)
                .background(KickIQTheme.accent.opacity(0.15), in: .rect(cornerRadius: KickIQTheme.Radius.sm))
            }

            HStack(spacing: KickIQTheme.Spacing.sm) {
                HStack(spacing: 4) {
                    Image(systemName: today.intensity.icon)
                        .font(.system(size: 10))
                    Text(today.intensity.rawValue)
                        .font(.caption2.weight(.bold))
                }
                .foregroundStyle(intensityColor(today.intensity))

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text(today.duration.label)
                        .font(.caption2.weight(.bold))
                }
                .foregroundStyle(KickIQTheme.textSecondary)

                HStack(spacing: 4) {
                    Image(systemName: today.mode.icon)
                        .font(.system(size: 10))
                    Text(today.mode.rawValue)
                        .font(.caption2.weight(.bold))
                }
                .foregroundStyle(KickIQTheme.textSecondary)

                Spacer()

                Text("\(today.completedCount)/\(today.drills.count) drills")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(today.isFullyCompleted ? .green : KickIQTheme.accent)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(KickIQTheme.divider)
                        .frame(height: 6)
                    Capsule()
                        .fill(today.isFullyCompleted ? Color.green : KickIQTheme.accent)
                        .frame(width: max(0, geo.size.width * today.progressPercent), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(KickIQTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                .fill(KickIQTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                        .stroke(KickIQTheme.accent.opacity(0.25), lineWidth: 1)
                )
        )
    }

    private func intensityColor(_ intensity: TrainingIntensity) -> Color {
        switch intensity {
        case .light: .green
        case .medium: .orange
        case .heavy: .red
        }
    }

    private var skillAssessmentCTA: some View {
        Button {
            showSkillAssessment = true
        } label: {
            HStack(spacing: KickIQTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "clipboard.fill")
                        .font(.title3)
                        .foregroundStyle(.purple)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Skill Assessment")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KickIQTheme.textPrimary)
                    Text("Test your skills with timed challenges")
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
                            .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.16), value: appeared)
    }

    private var analyzeCTA: some View {
        Button {
            selectedTab = 1
        } label: {
            HStack(spacing: KickIQTheme.Spacing.sm) {
                Image(systemName: "video.fill")
                    .font(.title3)
                Text("Analyze a Clip")
                    .font(.headline)
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: selectedTab)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.15), value: appeared)
    }

    private var todaysDrillCard: some View {
        let weakSkills = storage.weakestSkills
        let drillIndex = storage.todaysDrillIndex
        let skillIndex = weakSkills.isEmpty ? 0 : drillIndex % weakSkills.count
        let weakSkill = weakSkills.isEmpty ? SkillCategory.ballControl : weakSkills[skillIndex]

        let drillNames: [String] = [
            "Quick Feet Circuit", "Touch & Turn Drill", "Cone Slalom Sprint",
            "Wall Pass Combos", "Reaction Ball Challenge", "Shadow Play Session",
            "1v1 Box Drill"
        ]
        let todaysDrillName = drillNames[drillIndex % drillNames.count]

        return Group {
            if storage.smartTrainingPlan?.todaysPlan != nil {
                EmptyView()
            } else {
                VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.caption)
                            Text("TODAY'S DRILL")
                                .font(.caption.weight(.bold))
                                .tracking(1)
                        }
                        .foregroundStyle(KickIQTheme.accent)
                        Spacer()
                        Image(systemName: weakSkill.icon)
                            .font(.caption)
                            .foregroundStyle(KickIQTheme.accent)
                    }

                    Text(todaysDrillName)
                        .font(.headline)
                        .foregroundStyle(KickIQTheme.textPrimary)

                    Text("Focus: \(weakSkill.rawValue) — tailored to your weakest area. Resets daily.")
                        .font(.subheadline)
                        .foregroundStyle(KickIQTheme.textSecondary)
                        .lineLimit(2)

                    Button {
                        selectedTab = 2
                    } label: {
                        Text("Start Drill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KickIQTheme.accent)
                            .padding(.horizontal, KickIQTheme.Spacing.md)
                            .padding(.vertical, KickIQTheme.Spacing.sm)
                            .background(KickIQTheme.accent.opacity(0.15), in: .rect(cornerRadius: KickIQTheme.Radius.sm))
                    }
                    .padding(.top, KickIQTheme.Spacing.xs)
                }
                .padding(KickIQTheme.Spacing.md)
                .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.2), value: appeared)
    }

    private var reassessmentCard: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption)
                Text("MONTHLY CHECK-IN")
                    .font(.caption.weight(.bold))
                    .tracking(1)
            }
            .foregroundStyle(.orange)

            Text("Time to recheck your weakest skill")
                .font(.headline)
                .foregroundStyle(KickIQTheme.textPrimary)

            Text("It's been a month — update your focus area to keep improving.")
                .font(.subheadline)
                .foregroundStyle(KickIQTheme.textSecondary)

            HStack(spacing: KickIQTheme.Spacing.sm) {
                Button {
                    showReassessment = true
                } label: {
                    Text("Update Focus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, KickIQTheme.Spacing.md)
                        .padding(.vertical, KickIQTheme.Spacing.sm)
                        .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.sm))
                }

                Button {
                    storage.recordMonthlyReassessment()
                } label: {
                    Text("Dismiss")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
            }
        }
        .padding(KickIQTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                .fill(KickIQTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                        .stroke(KickIQTheme.accent.opacity(0.3), lineWidth: 1)
                )
        )
        .sheet(isPresented: $showReassessment) {
            ReassessmentSheet(storage: storage)
        }
    }

    private func recentAnalysisCard(_ session: TrainingSession) -> some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            HStack {
                Text("RECENT ANALYSIS")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(KickIQTheme.accent)
                Spacer()
                Text(session.date, style: .relative)
                    .font(.caption)
                    .foregroundStyle(KickIQTheme.textSecondary.opacity(0.6))
            }

            HStack(spacing: KickIQTheme.Spacing.sm) {
                ForEach(session.skillScores.prefix(isIPad ? 5 : 3)) { score in
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .stroke(KickIQTheme.divider, lineWidth: 3)
                                .frame(width: 40, height: 40)
                            Circle()
                                .trim(from: 0, to: score.percentage)
                                .stroke(KickIQTheme.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .frame(width: 40, height: 40)
                                .rotationEffect(.degrees(-90))
                            Text("\(score.score)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(KickIQTheme.textPrimary)
                        }
                        Text(score.category.rawValue)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(KickIQTheme.textSecondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            Text(session.feedback)
                .font(.caption)
                .foregroundStyle(KickIQTheme.textSecondary)
                .lineLimit(isIPad ? 3 : 2)
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.25), value: appeared)
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
                VStack(spacing: KickIQTheme.Spacing.lg) {
                    VStack(spacing: KickIQTheme.Spacing.sm) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 40))
                            .foregroundStyle(KickIQTheme.accent)

                        Text("What needs the most work?")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(KickIQTheme.textPrimary)

                        Text("Pick the area you want to focus on this month.")
                            .font(.subheadline)
                            .foregroundStyle(KickIQTheme.textSecondary)
                    }
                    .padding(.top, KickIQTheme.Spacing.md)

                    VStack(spacing: 10) {
                        ForEach(WeaknessArea.allCases) { area in
                            Button {
                                selectedWeakness = area
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: area.icon)
                                        .font(.title3)
                                        .foregroundStyle(selectedWeakness == area ? KickIQTheme.accent : KickIQTheme.textSecondary)
                                        .frame(width: 32)
                                    Text(area.rawValue)
                                        .font(.headline)
                                        .foregroundStyle(selectedWeakness == area ? KickIQTheme.textPrimary : KickIQTheme.textSecondary)
                                    Spacer()
                                    if selectedWeakness == area {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(KickIQTheme.accent)
                                    }
                                }
                                .padding(KickIQTheme.Spacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: KickIQTheme.Radius.md)
                                        .fill(selectedWeakness == area ? KickIQTheme.accent.opacity(0.15) : KickIQTheme.card)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: KickIQTheme.Radius.md)
                                                .stroke(selectedWeakness == area ? KickIQTheme.accent : Color.clear, lineWidth: 1.5)
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
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, KickIQTheme.Spacing.md)
                            .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
                    }
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .frame(maxWidth: AdaptiveLayout.iPadMaxContentWidth)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
        .onAppear {
            selectedWeakness = storage.profile?.weakness ?? .firstTouch
        }
    }
}
