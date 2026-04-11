import SwiftUI

struct TrainingPlanView: View {
    let storage: StorageService
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: TrainingPlanViewModel?
    @State private var appeared = false
    @State private var selectedDayPlan: DailyPlan?
    @State private var showPreferences = false
    @State private var completedTrigger = 0
    @State private var selectedTab: PlanTab = .today

    private enum PlanTab: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case full = "Full Plan"
    }

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    if vm.smartPlan != nil {
                        planContent(vm)
                    } else {
                        emptyState(vm)
                    }
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(KickIQTheme.background)
                }
            }
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle("Training Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(KickIQTheme.accent)
                }
                if viewModel?.smartPlan != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showPreferences = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundStyle(KickIQTheme.accent)
                        }
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
        .sheet(item: $selectedDayPlan) { day in
            DayDetailSheet(day: day, viewModel: viewModel!, storage: storage, completedTrigger: $completedTrigger)
        }
        .sheet(isPresented: $showPreferences) {
            if let vm = viewModel {
                PlanPreferencesSheet(viewModel: vm)
            }
        }
        .sensoryFeedback(.success, trigger: completedTrigger)
        .onAppear {
            if viewModel == nil {
                viewModel = TrainingPlanViewModel(storage: storage)
            }
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
        }
    }

    private func planContent(_ vm: TrainingPlanViewModel) -> some View {
        ScrollView {
            VStack(spacing: KickIQTheme.Spacing.md + 4) {
                tabPicker
                switch selectedTab {
                case .today:
                    todaySection(vm)
                case .week:
                    weekSection(vm)
                case .full:
                    fullPlanSection(vm)
                }
            }
            .padding(.horizontal, KickIQTheme.Spacing.md)
            .padding(.bottom, KickIQTheme.Spacing.xl)
        }
        .scrollIndicators(.hidden)
    }

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(PlanTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3)) { selectedTab = tab }
                } label: {
                    Text(tab.rawValue)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(selectedTab == tab ? .black : KickIQTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedTab == tab ? KickIQTheme.accent : Color.clear,
                            in: Capsule()
                        )
                }
            }
        }
        .padding(3)
        .background(KickIQTheme.card, in: Capsule())
        .opacity(appeared ? 1 : 0)
    }

    @ViewBuilder
    private func todaySection(_ vm: TrainingPlanViewModel) -> some View {
        if let today = vm.todaysPlan {
            todayFocusCard(today)
            weaknessPriorityCard(today)
            todayDrillsList(today, vm: vm)
            if !vm.recentScoreTrend.isEmpty {
                trendCard(vm)
            }
        } else {
            noTodayCard(vm)
        }
    }

    private func todayFocusCard(_ day: DailyPlan) -> some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TODAY'S FOCUS")
                        .font(.caption.weight(.bold))
                        .tracking(1)
                        .foregroundStyle(KickIQTheme.accent)
                    Text(day.focus)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(KickIQTheme.textPrimary)
                }
                Spacer()
                dayBadge(day)
            }

            HStack(spacing: KickIQTheme.Spacing.md) {
                statPill(icon: day.intensity.icon, label: day.intensity.rawValue, color: intensityColor(day.intensity))
                statPill(icon: "clock", label: day.duration.label, color: KickIQTheme.accent)
                statPill(icon: day.mode.icon, label: day.mode.rawValue, color: .blue)
            }

            progressBar(day)
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.xl))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.4).delay(0.05), value: appeared)
    }

    private func weaknessPriorityCard(_ day: DailyPlan) -> some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                Text("WEAKNESS PRIORITY")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(.red)
            }

            ScrollView(.horizontal) {
                HStack(spacing: KickIQTheme.Spacing.sm) {
                    ForEach(day.weaknessPriority, id: \.self) { skill in
                        let cat = SkillCategory.allCases.first(where: { $0.rawValue == skill })
                        HStack(spacing: 5) {
                            Image(systemName: cat?.icon ?? "target")
                                .font(.system(size: 11))
                            Text(skill)
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(.red.opacity(0.12), in: Capsule())
                    }
                }
            }
            .contentMargins(.horizontal, 0)
            .scrollIndicators(.hidden)
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.4).delay(0.1), value: appeared)
    }

    private func todayDrillsList(_ day: DailyPlan, vm: TrainingPlanViewModel) -> some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            HStack {
                Text("TODAY'S DRILLS")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(KickIQTheme.accent)
                Spacer()
                Text("\(day.completedCount)/\(day.drills.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(day.isFullyCompleted ? .green : KickIQTheme.textSecondary)
            }

            ForEach(Array(day.drills.enumerated()), id: \.element.id) { index, drill in
                smartDrillCard(drill, dayID: day.id, index: index, vm: vm)
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.4).delay(0.15), value: appeared)
    }

    private func smartDrillCard(_ drill: SmartDrill, dayID: String, index: Int, vm: TrainingPlanViewModel) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: KickIQTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(drill.isCompleted ? Color.green.opacity(0.15) : KickIQTheme.surface)
                        .frame(width: 40, height: 40)
                    Image(systemName: drill.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18))
                        .foregroundStyle(drill.isCompleted ? .green : KickIQTheme.textSecondary.opacity(0.3))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(drill.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(drill.isCompleted ? KickIQTheme.textSecondary : KickIQTheme.textPrimary)
                        .strikethrough(drill.isCompleted, color: KickIQTheme.textSecondary)
                    HStack(spacing: KickIQTheme.Spacing.sm) {
                        Label(drill.duration, systemImage: "clock")
                        Text("·")
                        Text(drill.targetSkill)
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(KickIQTheme.textSecondary)
                }

                Spacer()

                if !drill.isCompleted {
                    Menu {
                        Button {
                            vm.completeDrill(dayID: dayID, drillID: drill.id)
                            completedTrigger += 1
                        } label: {
                            Label("Complete", systemImage: "checkmark")
                        }
                        Button {
                            vm.swappingDrillIndex = index
                            vm.selectedDay = vm.smartPlan?.days.first(where: { $0.id == dayID })
                            vm.showDrillSwap = true
                        } label: {
                            Label("Swap Drill", systemImage: "arrow.triangle.swap")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KickIQTheme.textSecondary)
                            .frame(width: 32, height: 32)
                    }
                }
            }
            .padding(KickIQTheme.Spacing.md)

            HStack(spacing: 4) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(KickIQTheme.accent.opacity(0.7))
                Text(drill.reason)
                    .font(.system(size: 11))
                    .foregroundStyle(KickIQTheme.textSecondary.opacity(0.8))
                    .lineLimit(2)
            }
            .padding(.horizontal, KickIQTheme.Spacing.md)
            .padding(.bottom, KickIQTheme.Spacing.sm + 2)
        }
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
    }

    private func trendCard(_ vm: TrainingPlanViewModel) -> some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            Text("RECENT PERFORMANCE")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQTheme.accent)

            HStack(alignment: .bottom, spacing: KickIQTheme.Spacing.sm) {
                ForEach(vm.recentScoreTrend, id: \.0) { label, score in
                    VStack(spacing: 4) {
                        Text("\(score)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(KickIQTheme.textPrimary)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(KickIQTheme.accent.opacity(0.8))
                            .frame(height: max(CGFloat(score) * 0.8, 4))
                        Text(label)
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(KickIQTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 100)
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.4).delay(0.2), value: appeared)
    }

    private func weekSection(_ vm: TrainingPlanViewModel) -> some View {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now))!
        let weekDays = vm.smartPlan?.days.filter { day in
            day.date >= startOfWeek && day.date < calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
        } ?? []

        return VStack(spacing: KickIQTheme.Spacing.md) {
            weekOverview(weekDays)
            ForEach(weekDays) { day in
                weekDayRow(day)
            }
        }
    }

    private func weekOverview(_ days: [DailyPlan]) -> some View {
        let completed = days.filter(\.isFullyCompleted).count
        let total = days.count

        return HStack(spacing: KickIQTheme.Spacing.md) {
            VStack(spacing: 4) {
                Text("\(completed)")
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(KickIQTheme.accent)
                Text("of \(total) days done")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(KickIQTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 4) {
                let totalDrills = days.reduce(0) { $0 + $1.drills.count }
                let completedDrills = days.reduce(0) { $0 + $1.completedCount }
                Text("\(completedDrills)")
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(.green)
                Text("of \(totalDrills) drills")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(KickIQTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(KickIQTheme.Spacing.lg)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.xl))
    }

    private func weekDayRow(_ day: DailyPlan) -> some View {
        let isToday = Calendar.current.isDateInToday(day.date)

        return Button {
            selectedDayPlan = day
        } label: {
            HStack(spacing: KickIQTheme.Spacing.md) {
                VStack(spacing: 2) {
                    Text(day.date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(isToday ? KickIQTheme.accent : KickIQTheme.textSecondary)
                    Text(day.date.formatted(.dateTime.day()))
                        .font(.headline)
                        .foregroundStyle(isToday ? KickIQTheme.accent : KickIQTheme.textPrimary)
                }
                .frame(width: 40)

                VStack(alignment: .leading, spacing: 3) {
                    Text(day.focus)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KickIQTheme.textPrimary)
                        .lineLimit(1)
                    HStack(spacing: KickIQTheme.Spacing.sm) {
                        Image(systemName: day.intensity.icon)
                            .font(.system(size: 10))
                            .foregroundStyle(intensityColor(day.intensity))
                        Text(day.intensity.rawValue)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(KickIQTheme.textSecondary)
                        Text("·")
                            .foregroundStyle(KickIQTheme.textSecondary.opacity(0.4))
                        Text(day.duration.label)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(KickIQTheme.textSecondary)
                    }
                }

                Spacer()

                if day.isFullyCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else if day.completedCount > 0 {
                    Text("\(day.completedCount)/\(day.drills.count)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(KickIQTheme.accent)
                }

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
                            .stroke(isToday ? KickIQTheme.accent.opacity(0.4) : Color.clear, lineWidth: 1)
                    )
            )
        }
    }

    private func fullPlanSection(_ vm: TrainingPlanViewModel) -> some View {
        VStack(spacing: KickIQTheme.Spacing.md) {
            if let plan = vm.smartPlan {
                planSummaryCard(plan)

                ForEach(plan.days) { day in
                    Button {
                        selectedDayPlan = day
                    } label: {
                        compactDayRow(day)
                    }
                }

                regenerateButton(vm)
            }
        }
    }

    private func planSummaryCard(_ plan: SmartTrainingPlan) -> some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("30-DAY PLAN")
                        .font(.caption.weight(.bold))
                        .tracking(1)
                        .foregroundStyle(KickIQTheme.accent)
                    Text("Created \(plan.createdAt, format: .dateTime.month(.abbreviated).day())")
                        .font(.caption2)
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(plan.completedDaysCount)/\(plan.days.count)")
                        .font(.headline)
                        .foregroundStyle(KickIQTheme.textPrimary)
                    Text("days done")
                        .font(.caption2)
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
            }

            Text(plan.summary)
                .font(.subheadline)
                .foregroundStyle(KickIQTheme.textSecondary)
                .lineSpacing(3)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(KickIQTheme.divider)
                        .frame(height: 6)
                    Capsule()
                        .fill(KickIQTheme.accent)
                        .frame(width: max(0, geo.size.width * Double(plan.completedDaysCount) / Double(max(1, plan.days.count))), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
    }

    private func compactDayRow(_ day: DailyPlan) -> some View {
        let isPast = day.date < Calendar.current.startOfDay(for: .now)
        let isToday = Calendar.current.isDateInToday(day.date)

        return HStack(spacing: KickIQTheme.Spacing.sm + 2) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isToday ? KickIQTheme.accent.opacity(0.2) : KickIQTheme.surface)
                    .frame(width: 36, height: 36)

                if day.isFullyCompleted {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.green)
                } else {
                    Text("\(day.dayNumber)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(isToday ? KickIQTheme.accent : KickIQTheme.textSecondary)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(day.focus)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isPast && !day.isFullyCompleted ? KickIQTheme.textSecondary : KickIQTheme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: day.intensity.icon)
                        .font(.system(size: 8))
                        .foregroundStyle(intensityColor(day.intensity))
                    Text(day.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
            }

            Spacer()

            if day.completedCount > 0 && !day.isFullyCompleted {
                Text("\(day.completedCount)/\(day.drills.count)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(KickIQTheme.accent)
            }
        }
        .padding(.horizontal, KickIQTheme.Spacing.sm + 2)
        .padding(.vertical, KickIQTheme.Spacing.sm)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
    }

    private func regenerateButton(_ vm: TrainingPlanViewModel) -> some View {
        Button {
            vm.generatePlan()
        } label: {
            HStack(spacing: KickIQTheme.Spacing.sm) {
                if vm.isGenerating {
                    ProgressView().tint(KickIQTheme.accent)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                Text(vm.isGenerating ? "Regenerating..." : "Regenerate Plan")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(KickIQTheme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(KickIQTheme.accent.opacity(0.15), in: .rect(cornerRadius: KickIQTheme.Radius.md))
        }
        .disabled(vm.isGenerating)
    }

    private func emptyState(_ vm: TrainingPlanViewModel) -> some View {
        ScrollView {
            VStack(spacing: KickIQTheme.Spacing.lg) {
                Spacer().frame(height: 40)

                ZStack {
                    Circle()
                        .fill(KickIQTheme.accent.opacity(0.1))
                        .frame(width: 100, height: 100)
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 44))
                        .foregroundStyle(KickIQTheme.accent)
                }

                VStack(spacing: KickIQTheme.Spacing.sm) {
                    Text("Smart Training Plan")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(KickIQTheme.textPrimary)

                    Text("Generate a 30-day daily training plan that prioritizes your weaknesses, alternates intensity, and adapts to your schedule.")
                        .font(.subheadline)
                        .foregroundStyle(KickIQTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                VStack(alignment: .leading, spacing: KickIQTheme.Spacing.md) {
                    featureRow(icon: "flame.fill", color: .orange, text: "Daily plans — no off days, smart recovery")
                    featureRow(icon: "target", color: .red, text: "Weakness-first drill selection from AI analysis")
                    featureRow(icon: "arrow.triangle.swap", color: .blue, text: "Swap drills & customize session goals")
                    featureRow(icon: "clock", color: .green, text: "Flexible durations: 20–90 min sessions")
                    featureRow(icon: "person.2.fill", color: .purple, text: "Solo, partner, or team training modes")
                }
                .padding(KickIQTheme.Spacing.md)
                .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))

                Button {
                    vm.generatePlan()
                } label: {
                    HStack(spacing: KickIQTheme.Spacing.sm) {
                        if vm.isGenerating {
                            ProgressView().tint(.black)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text(vm.isGenerating ? "Generating..." : "Generate My Plan")
                    }
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, KickIQTheme.Spacing.md)
                    .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
                }
                .disabled(vm.isGenerating)
            }
            .padding(.horizontal, KickIQTheme.Spacing.md)
            .padding(.bottom, KickIQTheme.Spacing.xl)
        }
        .scrollIndicators(.hidden)
    }

    private func noTodayCard(_ vm: TrainingPlanViewModel) -> some View {
        VStack(spacing: KickIQTheme.Spacing.lg) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 40))
                .foregroundStyle(KickIQTheme.accent.opacity(0.6))

            Text("Plan expired — regenerate for a fresh 30 days")
                .font(.subheadline)
                .foregroundStyle(KickIQTheme.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                vm.generatePlan()
            } label: {
                HStack(spacing: KickIQTheme.Spacing.sm) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Regenerate Plan")
                }
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, KickIQTheme.Spacing.md)
                .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
            }
        }
        .padding(KickIQTheme.Spacing.xl)
    }

    private func featureRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: KickIQTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(KickIQTheme.textPrimary.opacity(0.85))
        }
    }

    private func statPill(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(label)
                .font(.caption2.weight(.bold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.12), in: Capsule())
    }

    private func dayBadge(_ day: DailyPlan) -> some View {
        VStack(spacing: 2) {
            Text("DAY")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(KickIQTheme.accent)
            Text("\(day.dayNumber)")
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(KickIQTheme.textPrimary)
        }
        .frame(width: 48, height: 48)
        .background(KickIQTheme.accent.opacity(0.15), in: .rect(cornerRadius: KickIQTheme.Radius.md))
    }

    private func progressBar(_ day: DailyPlan) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(KickIQTheme.divider)
                    .frame(height: 8)
                Capsule()
                    .fill(day.isFullyCompleted ? Color.green : KickIQTheme.accent)
                    .frame(width: max(0, geo.size.width * day.progressPercent), height: 8)
            }
        }
        .frame(height: 8)
    }

    private func intensityColor(_ intensity: TrainingIntensity) -> Color {
        switch intensity {
        case .light: .green
        case .medium: .orange
        case .heavy: .red
        }
    }
}

struct DayDetailSheet: View {
    let day: DailyPlan
    let viewModel: TrainingPlanViewModel
    let storage: StorageService
    @Binding var completedTrigger: Int
    @Environment(\.dismiss) private var dismiss
    @State private var showSwap = false
    @State private var swapIndex: Int?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: KickIQTheme.Spacing.lg) {
                    dayHeader
                    drillsSection
                }
                .padding(KickIQTheme.Spacing.md)
                .padding(.bottom, KickIQTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle(day.focus)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(KickIQTheme.accent)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
        .sheet(isPresented: $showSwap) {
            if let idx = swapIndex {
                DrillSwapSheet(viewModel: viewModel, dayID: day.id, drillIndex: idx)
            }
        }
    }

    private var dayHeader: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Day \(day.dayNumber) · \(day.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(KickIQTheme.accent)
                    Text(day.focus)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(KickIQTheme.textPrimary)
                }
                Spacer()
            }

            HStack(spacing: KickIQTheme.Spacing.md) {
                Label(day.intensity.rawValue, systemImage: day.intensity.icon)
                Label(day.duration.label, systemImage: "clock")
                Label(day.mode.rawValue, systemImage: day.mode.icon)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(KickIQTheme.textSecondary)

            Text(day.intensity.description)
                .font(.subheadline)
                .foregroundStyle(KickIQTheme.textSecondary.opacity(0.8))

            if !day.weaknessPriority.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "target")
                        .font(.caption2)
                        .foregroundStyle(.red)
                    Text("Targeting: \(day.weaknessPriority.joined(separator: ", "))")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.red.opacity(0.8))
                }
            }
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
    }

    private var drillsSection: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            Text("DRILLS (\(day.completedCount)/\(day.drills.count))")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQTheme.accent)

            ForEach(Array(day.drills.enumerated()), id: \.element.id) { index, drill in
                detailDrillCard(drill, index: index)
            }
        }
    }

    private func detailDrillCard(_ drill: SmartDrill, index: Int) -> some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(drill.name)
                        .font(.headline)
                        .foregroundStyle(drill.isCompleted ? KickIQTheme.textSecondary : KickIQTheme.textPrimary)
                        .strikethrough(drill.isCompleted, color: KickIQTheme.textSecondary)

                    HStack(spacing: KickIQTheme.Spacing.sm) {
                        Text(drill.difficulty.rawValue)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(difficultyColor(drill.difficulty))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(difficultyColor(drill.difficulty).opacity(0.12), in: Capsule())
                        Label(drill.duration, systemImage: "clock")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(KickIQTheme.textSecondary)
                        if !drill.reps.isEmpty {
                            Text("· \(drill.reps)")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(KickIQTheme.textSecondary)
                        }
                    }
                }
                Spacer()
                if drill.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                }
            }

            Text(drill.description)
                .font(.subheadline)
                .foregroundStyle(KickIQTheme.textPrimary.opacity(0.8))
                .lineSpacing(3)

            if !drill.coachingCues.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(drill.coachingCues, id: \.self) { cue in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(KickIQTheme.accent)
                                .padding(.top, 2)
                            Text(cue)
                                .font(.caption)
                                .foregroundStyle(KickIQTheme.textSecondary)
                        }
                    }
                }
            }

            HStack(spacing: 4) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(KickIQTheme.accent.opacity(0.7))
                Text(drill.reason)
                    .font(.caption)
                    .foregroundStyle(KickIQTheme.textSecondary.opacity(0.8))
                    .italic()
            }
            .padding(.top, 2)

            if !drill.isCompleted {
                HStack(spacing: KickIQTheme.Spacing.sm) {
                    Button {
                        viewModel.completeDrill(dayID: day.id, drillID: drill.id)
                        completedTrigger += 1
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                            Text("Complete")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.md))
                    }

                    Button {
                        swapIndex = index
                        showSwap = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.swap")
                            Text("Swap")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KickIQTheme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(KickIQTheme.accent.opacity(0.15), in: .rect(cornerRadius: KickIQTheme.Radius.md))
                    }
                }
            }
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
    }

    private func difficultyColor(_ difficulty: DrillDifficulty) -> Color {
        switch difficulty {
        case .beginner: .green
        case .intermediate: .orange
        case .advanced: .red
        }
    }
}

struct DrillSwapSheet: View {
    let viewModel: TrainingPlanViewModel
    let dayID: String
    let drillIndex: Int
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var categories: [(category: String, drills: [SmartDrill])] {
        let all = viewModel.drillsByCategory()
        if searchText.isEmpty { return all }
        return all.compactMap { cat, drills in
            let filtered = drills.filter {
                $0.name.localizedStandardContains(searchText) ||
                $0.targetSkill.localizedStandardContains(searchText)
            }
            return filtered.isEmpty ? nil : (cat, filtered)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(categories, id: \.category) { category, drills in
                    Section {
                        ForEach(drills) { drill in
                            Button {
                                viewModel.swapDrill(dayID: dayID, drillIndex: drillIndex, with: drill)
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(drill.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(KickIQTheme.textPrimary)
                                    HStack(spacing: KickIQTheme.Spacing.sm) {
                                        Text(drill.difficulty.rawValue)
                                            .font(.caption2.weight(.bold))
                                        Text("·")
                                        Text(drill.duration)
                                            .font(.caption2)
                                    }
                                    .foregroundStyle(KickIQTheme.textSecondary)
                                }
                            }
                            .listRowBackground(KickIQTheme.card)
                        }
                    } header: {
                        Text(category)
                            .foregroundStyle(KickIQTheme.accent)
                    }
                }
            }
            .listStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .searchable(text: $searchText, prompt: "Search drills...")
            .navigationTitle("Swap Drill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(KickIQTheme.accent)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
    }
}

struct PlanPreferencesSheet: View {
    let viewModel: TrainingPlanViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var duration: SessionDuration = .thirty
    @State private var mode: TrainingMode = .solo

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQTheme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: KickIQTheme.Spacing.md) {
                        Text("SESSION DURATION")
                            .font(.caption.weight(.bold))
                            .tracking(1)
                            .foregroundStyle(KickIQTheme.accent)

                        HStack(spacing: KickIQTheme.Spacing.sm) {
                            ForEach(SessionDuration.allCases) { dur in
                                Button {
                                    duration = dur
                                } label: {
                                    Text(dur.label)
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(duration == dur ? .black : KickIQTheme.textSecondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            duration == dur ? KickIQTheme.accent : KickIQTheme.surface,
                                            in: .rect(cornerRadius: KickIQTheme.Radius.md)
                                        )
                                }
                            }
                        }
                    }
                    .padding(KickIQTheme.Spacing.md)
                    .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))

                    VStack(alignment: .leading, spacing: KickIQTheme.Spacing.md) {
                        Text("TRAINING MODE")
                            .font(.caption.weight(.bold))
                            .tracking(1)
                            .foregroundStyle(KickIQTheme.accent)

                        ForEach(TrainingMode.allCases) { tm in
                            Button {
                                mode = tm
                            } label: {
                                HStack(spacing: KickIQTheme.Spacing.md) {
                                    Image(systemName: tm.icon)
                                        .font(.title3)
                                        .foregroundStyle(mode == tm ? KickIQTheme.accent : KickIQTheme.textSecondary)
                                        .frame(width: 28)
                                    Text(tm.rawValue)
                                        .font(.headline)
                                        .foregroundStyle(mode == tm ? KickIQTheme.textPrimary : KickIQTheme.textSecondary)
                                    Spacer()
                                    if mode == tm {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(KickIQTheme.accent)
                                    }
                                }
                                .padding(KickIQTheme.Spacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: KickIQTheme.Radius.md)
                                        .fill(mode == tm ? KickIQTheme.accent.opacity(0.12) : KickIQTheme.surface)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: KickIQTheme.Radius.md)
                                                .stroke(mode == tm ? KickIQTheme.accent : Color.clear, lineWidth: 1.5)
                                        )
                                )
                            }
                        }
                    }
                    .padding(KickIQTheme.Spacing.md)
                    .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))

                    Button {
                        let prefs = PlanPreferences(preferredDuration: duration, preferredMode: mode)
                        viewModel.updatePreferences(prefs)
                        viewModel.generatePlan()
                        dismiss()
                    } label: {
                        HStack(spacing: KickIQTheme.Spacing.sm) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Apply & Regenerate Plan")
                        }
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, KickIQTheme.Spacing.md)
                        .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
                    }
                }
                .padding(KickIQTheme.Spacing.md)
                .padding(.bottom, KickIQTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle("Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(KickIQTheme.accent)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
        .onAppear {
            if let prefs = viewModel.smartPlan?.preferences {
                duration = prefs.preferredDuration
                mode = prefs.preferredMode
            }
        }
    }
}

nonisolated struct AIPlanResponse: Codable, Sendable {
    let summary: String
    let days: [AIPlanDay]
}

nonisolated struct AIPlanDay: Codable, Sendable {
    let dayLabel: String
    let focus: String
    let restDay: Bool
    let drills: [AIPlanDrill]?
}

nonisolated struct AIPlanDrill: Codable, Sendable {
    let name: String
    let description: String
    let duration: String
    let targetSkill: String
    let reps: String?
}
