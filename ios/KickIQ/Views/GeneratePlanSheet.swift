import SwiftUI

struct GeneratePlanSheet: View {
    let storage: StorageService
    let planType: SavedPlanType
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAreas: Set<String> = []
    @State private var sessionDuration: SessionDuration = .thirty
    @State private var weekCount: Int = 4
    @State private var generatedPlan: SavedPlan?
    @State private var isGenerating = false
    @State private var showResult = false

    private let weekOptions = [1, 2, 3, 4, 6, 8]

    private var skillAreas: [AreaOption] {
        if planType == .conditioning {
            return ConditioningType.allCases.map { AreaOption(id: $0.rawValue, name: $0.rawValue, icon: $0.icon) }
        } else {
            let position = storage.profile?.position ?? .midfielder
            return position.skills.map { AreaOption(id: $0.rawValue, name: $0.rawValue, icon: $0.icon) }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQTheme.Spacing.lg) {
                    heroSection
                    areasSection
                    durationSection
                    weeksSection
                    generateButton
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .padding(.bottom, KickIQTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle(planType == .conditioning ? "Conditioning Plan" : "Training Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
        .fullScreenCover(isPresented: $showResult) {
            if let plan = generatedPlan {
                PlanResultView(plan: plan, storage: storage, onAccept: { acceptedPlan in
                    storage.addSavedPlan(acceptedPlan)
                    dismiss()
                }, onRegenerate: {
                    showResult = false
                    generatedPlan = nil
                })
            }
        }
    }

    private var heroSection: some View {
        VStack(spacing: KickIQTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill((planType == .conditioning ? Color.orange : KickIQTheme.accent).opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: planType == .conditioning ? "flame.fill" : "figure.soccer")
                    .font(.system(size: 36))
                    .foregroundStyle(planType == .conditioning ? .orange : KickIQTheme.accent)
            }

            Text("Customize Your Plan")
                .font(.title3.weight(.bold))
                .foregroundStyle(KickIQTheme.textPrimary)

            Text("Select areas to improve, set your session length, and choose how many weeks to train.")
                .font(.subheadline)
                .foregroundStyle(KickIQTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, KickIQTheme.Spacing.sm)
    }

    private var areasSection: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.md) {
            HStack {
                Text("FOCUS AREAS")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(planType == .conditioning ? .orange : KickIQTheme.accent)
                Spacer()
                if !selectedAreas.isEmpty {
                    Text("\(selectedAreas.count) selected")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                ForEach(skillAreas) { area in
                    let isSelected = selectedAreas.contains(area.id)
                    Button {
                        withAnimation(.spring(response: 0.25)) {
                            if isSelected {
                                selectedAreas.remove(area.id)
                            } else {
                                selectedAreas.insert(area.id)
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: area.icon)
                                .font(.system(size: 13, weight: .semibold))
                            Text(area.name)
                                .font(.caption.weight(.bold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(isSelected ? .black : KickIQTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            isSelected
                                ? (planType == .conditioning ? Color.orange : KickIQTheme.accent)
                                : KickIQTheme.card,
                            in: .rect(cornerRadius: KickIQTheme.Radius.md)
                        )
                    }
                    .sensoryFeedback(.selection, trigger: isSelected)
                }
            }

            if selectedAreas.isEmpty {
                Text("Select at least one area to focus on")
                    .font(.caption)
                    .foregroundStyle(KickIQTheme.textSecondary.opacity(0.6))
            }
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.md) {
            Text("TIME PER SESSION")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(planType == .conditioning ? .orange : KickIQTheme.accent)

            HStack(spacing: 8) {
                ForEach(SessionDuration.allCases) { dur in
                    Button {
                        sessionDuration = dur
                    } label: {
                        Text(dur.label)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(sessionDuration == dur ? .black : KickIQTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                sessionDuration == dur
                                    ? (planType == .conditioning ? Color.orange : KickIQTheme.accent)
                                    : KickIQTheme.surface,
                                in: Capsule()
                            )
                    }
                    .sensoryFeedback(.selection, trigger: sessionDuration == dur)
                }
            }
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
    }

    private var weeksSection: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.md) {
            HStack {
                Text("NUMBER OF WEEKS")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(planType == .conditioning ? .orange : KickIQTheme.accent)
                Spacer()
                Text("\(weekCount) week\(weekCount == 1 ? "" : "s")")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(KickIQTheme.textPrimary)
            }

            HStack(spacing: 8) {
                ForEach(weekOptions, id: \.self) { week in
                    Button {
                        weekCount = week
                    } label: {
                        Text("\(week)")
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(weekCount == week ? .black : KickIQTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                weekCount == week
                                    ? (planType == .conditioning ? Color.orange : KickIQTheme.accent)
                                    : KickIQTheme.surface,
                                in: .rect(cornerRadius: KickIQTheme.Radius.md)
                            )
                    }
                    .sensoryFeedback(.selection, trigger: weekCount == week)
                }
            }
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
    }

    private var generateButton: some View {
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
            .background(
                (selectedAreas.isEmpty ? Color.gray : (planType == .conditioning ? Color.orange : KickIQTheme.accent)),
                in: .rect(cornerRadius: KickIQTheme.Radius.lg)
            )
        }
        .disabled(selectedAreas.isEmpty || isGenerating)
    }

    private func generatePlan() {
        isGenerating = true
        let drillsService = DrillsService()
        if let profile = storage.profile {
            drillsService.loadDrills(for: profile.position, weakness: profile.weakness, skillLevel: profile.skillLevel)
        }

        let areas = Array(selectedAreas)
        let totalDays = weekCount * 5
        let intensityPattern: [TrainingIntensity] = [.medium, .heavy, .light, .medium, .heavy]

        var days: [SavedPlanDay] = []

        for dayIndex in 0..<totalDays {
            let weekNum = (dayIndex / 5) + 1
            let dayInWeek = (dayIndex % 5)
            let intensity = intensityPattern[dayInWeek % intensityPattern.count]
            let focusArea = areas[dayIndex % areas.count]

            let drills = buildDrillsForDay(
                service: drillsService,
                focus: focusArea,
                intensity: intensity,
                dayIndex: dayIndex
            )

            let day = SavedPlanDay(
                dayNumber: dayIndex + 1,
                weekNumber: weekNum,
                focus: focusArea,
                intensity: intensity,
                duration: sessionDuration,
                drills: drills
            )
            days.append(day)
        }

        let title: String
        if areas.count <= 2 {
            title = "\(weekCount)-Week \(areas.joined(separator: " & ")) Plan"
        } else {
            title = "\(weekCount)-Week \(planType == .conditioning ? "Conditioning" : "Skills") Plan"
        }

        let plan = SavedPlan(
            planType: planType,
            title: title,
            focusAreas: areas,
            sessionDuration: sessionDuration,
            weekCount: weekCount,
            days: days
        )

        generatedPlan = plan
        isGenerating = false
        showResult = true
    }

    private func buildDrillsForDay(service: DrillsService, focus: String, intensity: TrainingIntensity, dayIndex: Int) -> [SavedPlanDrill] {
        let targetCount: Int
        switch sessionDuration {
        case .twenty: targetCount = 2
        case .thirty: targetCount = 3
        case .fortyFive: targetCount = 4
        case .sixty: targetCount = 5
        case .ninety: targetCount = 7
        }

        var pool: [Drill]
        if planType == .conditioning {
            let allConditioning = service.allDrills.filter { ConditioningType.isConditioningDrill($0) }
            let condType = ConditioningType.allCases.first { $0.rawValue == focus }
            let focused = condType.map { t in allConditioning.filter { ConditioningType.classify($0) == t } } ?? allConditioning
            pool = focused.isEmpty ? allConditioning : focused
        } else {
            let allSkill = service.allDrills.filter { !ConditioningType.isConditioningDrill($0) }
            let focused = allSkill.filter { $0.targetSkill == focus }
            pool = focused.isEmpty ? allSkill : focused
        }

        guard !pool.isEmpty else { return [] }

        var selected: [SavedPlanDrill] = []
        var usedNames: Set<String> = []

        let shuffled = pool.shuffled()
        for drill in shuffled {
            guard selected.count < targetCount else { break }
            guard !usedNames.contains(drill.name) else { continue }
            usedNames.insert(drill.name)
            selected.append(SavedPlanDrill(
                name: drill.name,
                description: drill.description,
                duration: drill.duration,
                reps: drill.reps,
                targetSkill: drill.targetSkill,
                difficulty: drill.difficulty,
                coachingCues: drill.coachingCues
            ))
        }

        if selected.count < targetCount {
            let remaining = service.allDrills.filter { !usedNames.contains($0.name) }
            for drill in remaining.shuffled().prefix(targetCount - selected.count) {
                usedNames.insert(drill.name)
                selected.append(SavedPlanDrill(
                    name: drill.name,
                    description: drill.description,
                    duration: drill.duration,
                    reps: drill.reps,
                    targetSkill: drill.targetSkill,
                    difficulty: drill.difficulty,
                    coachingCues: drill.coachingCues
                ))
            }
        }

        return selected
    }
}

private struct AreaOption: Identifiable {
    let id: String
    let name: String
    let icon: String
}
