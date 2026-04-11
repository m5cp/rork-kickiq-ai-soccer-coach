import SwiftUI

struct ConditioningPlanView: View {
    let storage: StorageService
    @Environment(\.dismiss) private var dismiss
    @State private var isGenerating = false
    @State private var plan: ConditioningPlan?
    @State private var selectedFocus: ConditioningType = .sprints
    @State private var duration: SessionDuration = .thirty
    @State private var appeared = false
    @State private var completedTrigger = 0
    @State private var calendarService = CalendarService()
    @State private var calendarSynced = false
    @State private var showCalendarAlert = false

    var body: some View {
        NavigationStack {
            Group {
                if let plan {
                    planContent(plan)
                } else {
                    setupContent
                }
            }
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle("Conditioning Plan")
            .navigationBarTitleDisplayMode(.inline)
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
        .sensoryFeedback(.success, trigger: completedTrigger)
        .onAppear {
            if let saved = storage.savedConditioningPlan {
                plan = saved
            }
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
        }
    }

    private var setupContent: some View {
        ScrollView {
            VStack(spacing: KickIQTheme.Spacing.lg) {
                Spacer().frame(height: 20)

                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 100, height: 100)
                    Image(systemName: "flame.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.orange)
                }

                VStack(spacing: KickIQTheme.Spacing.sm) {
                    Text("Conditioning Plan")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(KickIQTheme.textPrimary)

                    Text("Generate a focused conditioning plan based on your goals. Choose a focus area and session length.")
                        .font(.subheadline)
                        .foregroundStyle(KickIQTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                VStack(alignment: .leading, spacing: KickIQTheme.Spacing.md) {
                    Text("FOCUS AREA")
                        .font(.caption.weight(.bold))
                        .tracking(1)
                        .foregroundStyle(KickIQTheme.accent)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(ConditioningType.allCases) { type in
                            Button {
                                selectedFocus = type
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: type.icon)
                                        .font(.system(size: 14, weight: .semibold))
                                    Text(type.rawValue)
                                        .font(.caption.weight(.bold))
                                        .lineLimit(1)
                                }
                                .foregroundStyle(selectedFocus == type ? .black : KickIQTheme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    selectedFocus == type ? KickIQTheme.accent : KickIQTheme.card,
                                    in: .rect(cornerRadius: KickIQTheme.Radius.md)
                                )
                            }
                        }
                    }
                }
                .padding(KickIQTheme.Spacing.md)
                .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))

                VStack(alignment: .leading, spacing: KickIQTheme.Spacing.md) {
                    Text("SESSION LENGTH")
                        .font(.caption.weight(.bold))
                        .tracking(1)
                        .foregroundStyle(KickIQTheme.accent)

                    HStack(spacing: 8) {
                        ForEach(SessionDuration.allCases) { dur in
                            Button {
                                duration = dur
                            } label: {
                                Text(dur.label)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(duration == dur ? .black : KickIQTheme.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        duration == dur ? KickIQTheme.accent : KickIQTheme.surface,
                                        in: Capsule()
                                    )
                            }
                        }
                    }
                }
                .padding(KickIQTheme.Spacing.md)
                .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))

                Button {
                    generatePlan()
                } label: {
                    HStack(spacing: KickIQTheme.Spacing.sm) {
                        if isGenerating {
                            ProgressView().tint(.black)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text(isGenerating ? "Generating..." : "Generate Plan")
                    }
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, KickIQTheme.Spacing.md)
                    .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
                }
                .disabled(isGenerating)
            }
            .padding(.horizontal, KickIQTheme.Spacing.md)
            .padding(.bottom, KickIQTheme.Spacing.xl)
        }
        .scrollIndicators(.hidden)
    }

    private func planContent(_ plan: ConditioningPlan) -> some View {
        ScrollView {
            VStack(spacing: KickIQTheme.Spacing.md + 4) {
                planHeader(plan)

                ForEach(Array(plan.drills.enumerated()), id: \.element.id) { index, drill in
                    conditioningDrillCard(drill, index: index, plan: plan)
                }

                syncToCalendarButton

                Button {
                    self.plan = nil
                    storage.clearConditioningPlan()
                    calendarSynced = false
                } label: {
                    HStack(spacing: KickIQTheme.Spacing.sm) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("New Plan")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KickIQTheme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(KickIQTheme.accent.opacity(0.15), in: .rect(cornerRadius: KickIQTheme.Radius.md))
                }
            }
            .padding(.horizontal, KickIQTheme.Spacing.md)
            .padding(.bottom, KickIQTheme.Spacing.xl)
        }
        .scrollIndicators(.hidden)
    }

    private func planHeader(_ plan: ConditioningPlan) -> some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CONDITIONING SESSION")
                        .font(.caption.weight(.bold))
                        .tracking(1)
                        .foregroundStyle(.orange)
                    Text(plan.focusType.rawValue)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(KickIQTheme.textPrimary)
                }
                Spacer()
                VStack(spacing: 2) {
                    Image(systemName: plan.focusType.icon)
                        .font(.system(size: 22))
                        .foregroundStyle(.orange)
                    Text(plan.duration.label)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
                .frame(width: 48, height: 48)
                .background(Color.orange.opacity(0.15), in: .rect(cornerRadius: KickIQTheme.Radius.md))
            }

            let completed = plan.drills.filter(\.isCompleted).count
            let total = plan.drills.count

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(KickIQTheme.divider)
                        .frame(height: 8)
                    Capsule()
                        .fill(completed == total ? Color.green : Color.orange)
                        .frame(width: max(0, geo.size.width * Double(completed) / Double(max(1, total))), height: 8)
                }
            }
            .frame(height: 8)

            Text("\(completed)/\(total) completed")
                .font(.caption.weight(.semibold))
                .foregroundStyle(completed == total ? .green : KickIQTheme.textSecondary)
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.xl))
    }

    private func conditioningDrillCard(_ drill: ConditioningPlanDrill, index: Int, plan: ConditioningPlan) -> some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            HStack {
                HStack(spacing: KickIQTheme.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(drill.isCompleted ? Color.green.opacity(0.15) : KickIQTheme.surface)
                            .frame(width: 36, height: 36)
                        if drill.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.green)
                        } else {
                            Text("\(index + 1)")
                                .font(.caption.weight(.black))
                                .foregroundStyle(KickIQTheme.accent)
                        }
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(drill.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(drill.isCompleted ? KickIQTheme.textSecondary : KickIQTheme.textPrimary)
                            .strikethrough(drill.isCompleted, color: KickIQTheme.textSecondary)
                        HStack(spacing: KickIQTheme.Spacing.sm) {
                            Label(drill.duration, systemImage: "clock")
                            if !drill.reps.isEmpty {
                                Text("·")
                                Text(drill.reps)
                            }
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(KickIQTheme.textSecondary)
                    }
                }

                Spacer()
            }

            Text(drill.description)
                .font(.caption)
                .foregroundStyle(KickIQTheme.textSecondary.opacity(0.8))
                .lineLimit(3)

            if !drill.isCompleted {
                Button {
                    completeDrill(drillID: drill.id)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                        Text("Complete")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.md))
                }
            }
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
    }

    private func generatePlan() {
        isGenerating = true

        let drillsService = DrillsService()
        if let profile = storage.profile {
            drillsService.loadDrills(for: profile.position, weakness: profile.weakness, skillLevel: profile.skillLevel)
        }

        let conditioningPool = drillsService.allDrills.filter { ConditioningType.isConditioningDrill($0) }
        let focused = conditioningPool.filter { ConditioningType.classify($0) == selectedFocus }
        let pool = focused.isEmpty ? conditioningPool : focused

        let targetCount: Int
        switch duration {
        case .twenty: targetCount = 3
        case .thirty: targetCount = 4
        case .fortyFive: targetCount = 5
        case .sixty: targetCount = 6
        case .ninety: targetCount = 8
        }

        var selected: [ConditioningPlanDrill] = []
        var usedNames: Set<String> = []

        for drill in pool.shuffled().prefix(targetCount) {
            guard !usedNames.contains(drill.name) else { continue }
            usedNames.insert(drill.name)
            selected.append(ConditioningPlanDrill(
                name: drill.name,
                description: drill.description,
                duration: drill.duration,
                reps: drill.reps,
                intensity: drill.intensity
            ))
        }

        if selected.count < targetCount {
            let remaining = conditioningPool.filter { !usedNames.contains($0.name) }
            for drill in remaining.shuffled().prefix(targetCount - selected.count) {
                usedNames.insert(drill.name)
                selected.append(ConditioningPlanDrill(
                    name: drill.name,
                    description: drill.description,
                    duration: drill.duration,
                    reps: drill.reps,
                    intensity: drill.intensity
                ))
            }
        }

        let newPlan = ConditioningPlan(
            focusType: selectedFocus,
            duration: duration,
            drills: selected
        )

        plan = newPlan
        storage.saveConditioningPlan(newPlan)
        isGenerating = false
    }

    private var syncToCalendarButton: some View {
        Button {
            Task {
                if !calendarService.isAuthorized {
                    let granted = await calendarService.requestAccess()
                    if !granted {
                        showCalendarAlert = true
                        return
                    }
                }
                if !calendarService.calendarSyncEnabled {
                    calendarService.enableSync(true)
                }
                if let plan {
                    let success = calendarService.addConditioningEvent(plan: plan)
                    if success {
                        calendarSynced = true
                    }
                }
            }
        } label: {
            HStack(spacing: KickIQTheme.Spacing.sm) {
                Image(systemName: calendarSynced ? "checkmark.circle.fill" : "calendar.badge.plus")
                Text(calendarSynced ? "Synced to Calendar" : "Sync to Calendar")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(calendarSynced ? .green : .black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                calendarSynced ? Color.green.opacity(0.15) : KickIQTheme.accent,
                in: .rect(cornerRadius: KickIQTheme.Radius.md)
            )
        }
        .disabled(calendarSynced)
        .alert("Calendar Access", isPresented: $showCalendarAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable calendar access in Settings to sync your conditioning plan.")
        }
    }

    private func completeDrill(drillID: String) {
        guard var current = plan,
              let idx = current.drills.firstIndex(where: { $0.id == drillID }) else { return }
        current.drills[idx].isCompleted = true
        plan = current
        storage.saveConditioningPlan(current)
        completedTrigger += 1
    }
}

nonisolated struct ConditioningPlanDrill: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let description: String
    let duration: String
    let reps: String
    let intensity: DrillIntensity
    var isCompleted: Bool

    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        duration: String,
        reps: String,
        intensity: DrillIntensity = .moderate,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.duration = duration
        self.reps = reps
        self.intensity = intensity
        self.isCompleted = isCompleted
    }
}

nonisolated struct ConditioningPlan: Codable, Sendable, Identifiable {
    let id: String
    let createdAt: Date
    let focusType: ConditioningType
    let duration: SessionDuration
    var drills: [ConditioningPlanDrill]

    init(
        id: String = UUID().uuidString,
        createdAt: Date = .now,
        focusType: ConditioningType,
        duration: SessionDuration,
        drills: [ConditioningPlanDrill]
    ) {
        self.id = id
        self.createdAt = createdAt
        self.focusType = focusType
        self.duration = duration
        self.drills = drills
    }
}
