import SwiftUI

struct DrillsView: View {
    let storage: StorageService
    @State private var drillsService = DrillsService()
    @State private var appeared = false
    @State private var selectedDrill: Drill?
    @State private var completedTrigger = 0
    @State private var expandedCategories: Set<String> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQTheme.Spacing.md) {
                    if drillsService.allDrills.isEmpty {
                        emptyState
                    } else {
                        headerInfo
                        categorySections
                    }
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .padding(.bottom, KickIQTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle("Drills")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $selectedDrill) { drill in
                DrillDetailSheet(drill: drill, storage: storage, drillsService: drillsService, completedTrigger: $completedTrigger)
            }
        }
        .onAppear {
            loadDrills()
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
        .sensoryFeedback(.success, trigger: completedTrigger)
    }

    private var headerInfo: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            let weakSkills = storage.weakestSkills
            if !weakSkills.isEmpty {
                HStack(spacing: KickIQTheme.Spacing.sm) {
                    Image(systemName: "target")
                        .foregroundStyle(KickIQTheme.accent)
                    Text("Focused on your weakest areas")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(KickIQTheme.textSecondary)
                }

                ScrollView(.horizontal) {
                    HStack(spacing: KickIQTheme.Spacing.sm) {
                        ForEach(weakSkills) { skill in
                            HStack(spacing: 4) {
                                Image(systemName: skill.icon)
                                    .font(.system(size: 10))
                                Text(skill.rawValue)
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(KickIQTheme.accent)
                            .padding(.horizontal, KickIQTheme.Spacing.sm + 4)
                            .padding(.vertical, 6)
                            .background(KickIQTheme.accent.opacity(0.15), in: Capsule())
                        }
                    }
                }
                .contentMargins(.horizontal, 0)
                .scrollIndicators(.hidden)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(appeared ? 1 : 0)
    }

    private var groupedDrills: [(category: String, icon: String, drills: [Drill])] {
        let filteredDrills = drillsService.filteredDrills(weakestSkills: storage.weakestSkills)
        var groups: [String: [Drill]] = [:]
        for drill in filteredDrills {
            groups[drill.targetSkill, default: []].append(drill)
        }

        let categoryOrder: [String] = SkillCategory.allCases.map(\.rawValue)
        return categoryOrder.compactMap { name in
            guard let drills = groups[name], !drills.isEmpty else { return nil }
            let icon = SkillCategory.allCases.first(where: { $0.rawValue == name })?.icon ?? "figure.run"
            return (category: name, icon: icon, drills: drills)
        }
    }

    private var categorySections: some View {
        LazyVStack(spacing: KickIQTheme.Spacing.md + 4) {
            ForEach(Array(groupedDrills.enumerated()), id: \.element.category) { sectionIndex, group in
                VStack(spacing: 0) {
                    categoryHeader(group.category, icon: group.icon, count: group.drills.count, isExpanded: expandedCategories.contains(group.category))
                        .onAppear {
                            if sectionIndex < 3 {
                                expandedCategories.insert(group.category)
                            }
                        }

                    if expandedCategories.contains(group.category) {
                        VStack(spacing: KickIQTheme.Spacing.sm) {
                            ForEach(Array(group.drills.enumerated()), id: \.element.id) { drillIndex, drill in
                                Button {
                                    selectedDrill = drill
                                } label: {
                                    drillCard(drill)
                                }
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 10)
                                .animation(.spring(response: 0.35).delay(Double(drillIndex) * 0.04), value: appeared)
                            }
                        }
                        .padding(.top, KickIQTheme.Spacing.sm)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 15)
                .animation(.spring(response: 0.4).delay(Double(sectionIndex) * 0.06), value: appeared)
            }
        }
    }

    private func categoryHeader(_ name: String, icon: String, count: Int, isExpanded: Bool) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                if expandedCategories.contains(name) {
                    expandedCategories.remove(name)
                } else {
                    expandedCategories.insert(name)
                }
            }
        } label: {
            HStack(spacing: KickIQTheme.Spacing.sm + 2) {
                ZStack {
                    RoundedRectangle(cornerRadius: KickIQTheme.Radius.sm)
                        .fill(KickIQTheme.accent.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(KickIQTheme.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(KickIQTheme.textPrimary)
                    Text("\(count) drill\(count == 1 ? "" : "s")")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(KickIQTheme.textSecondary)
                }

                Spacer()

                let completedCount = storage.completedDrillIDs.count
                let categoryCompleted = count > 0 ? min(completedCount, count) : 0
                if categoryCompleted > 0 {
                    Text("\(categoryCompleted)/\(count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.green.opacity(0.12), in: Capsule())
                }

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KickIQTheme.textSecondary.opacity(0.4))
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            .padding(KickIQTheme.Spacing.md)
            .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
        }
        .sensoryFeedback(.selection, trigger: isExpanded)
    }

    private func drillCard(_ drill: Drill) -> some View {
        let isCompleted = storage.completedDrillIDs.contains(drill.id)

        return HStack(spacing: KickIQTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green.opacity(0.15) : KickIQTheme.surface)
                    .frame(width: 38, height: 38)

                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(isCompleted ? .green : KickIQTheme.textSecondary.opacity(0.3))
            }

            VStack(alignment: .leading, spacing: KickIQTheme.Spacing.xs) {
                Text(drill.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KickIQTheme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: KickIQTheme.Spacing.sm) {
                    Label(drill.duration, systemImage: "clock")
                    Text("·")
                    Text(drill.difficulty.rawValue)
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(KickIQTheme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(KickIQTheme.textSecondary.opacity(0.3))
        }
        .padding(.horizontal, KickIQTheme.Spacing.md)
        .padding(.vertical, KickIQTheme.Spacing.sm + 4)
        .background(KickIQTheme.surface, in: .rect(cornerRadius: KickIQTheme.Radius.md))
    }

    private var emptyState: some View {
        VStack(spacing: KickIQTheme.Spacing.md) {
            Spacer().frame(height: 60)

            Image(systemName: "figure.soccer")
                .font(.system(size: 48))
                .foregroundStyle(KickIQTheme.accent.opacity(0.5))

            Text("Drills Loading")
                .font(.title3.weight(.bold))
                .foregroundStyle(KickIQTheme.textPrimary)

            Text("Complete your profile to get\npersonalized drill recommendations")
                .font(.subheadline)
                .foregroundStyle(KickIQTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private func loadDrills() {
        guard let profile = storage.profile else { return }
        drillsService.loadDrills(for: profile.position, weakness: profile.weakness, skillLevel: profile.skillLevel)
    }
}

struct DrillDetailSheet: View {
    let drill: Drill
    let storage: StorageService
    let drillsService: DrillsService
    @Binding var completedTrigger: Int
    @Environment(\.dismiss) private var dismiss
    @State private var showTimer = false

    private var isCompleted: Bool {
        storage.completedDrillIDs.contains(drill.id)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: KickIQTheme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
                        HStack(spacing: KickIQTheme.Spacing.sm) {
                            Text(drill.difficulty.rawValue)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(difficultyColor)
                                .padding(.horizontal, KickIQTheme.Spacing.sm)
                                .padding(.vertical, 4)
                                .background(difficultyColor.opacity(0.15), in: Capsule())

                            Text(drill.targetSkill)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(KickIQTheme.accent)
                                .padding(.horizontal, KickIQTheme.Spacing.sm)
                                .padding(.vertical, 4)
                                .background(KickIQTheme.accent.opacity(0.15), in: Capsule())

                            Spacer()

                            Label(drill.duration, systemImage: "clock")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(KickIQTheme.textSecondary)
                        }

                        Text(drill.name)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(KickIQTheme.textPrimary)
                    }

                    VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
                        Text("DESCRIPTION")
                            .font(.caption.weight(.bold))
                            .tracking(1)
                            .foregroundStyle(KickIQTheme.accent)

                        Text(drill.description)
                            .font(.body)
                            .foregroundStyle(KickIQTheme.textPrimary.opacity(0.85))
                            .lineSpacing(4)
                    }

                    if !drill.coachingCues.isEmpty {
                        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
                            Text("COACHING CUES")
                                .font(.caption.weight(.bold))
                                .tracking(1)
                                .foregroundStyle(KickIQTheme.accent)

                            ForEach(drill.coachingCues, id: \.self) { cue in
                                HStack(alignment: .top, spacing: KickIQTheme.Spacing.sm) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(KickIQTheme.accent)
                                        .padding(.top, 2)
                                    Text(cue)
                                        .font(.subheadline)
                                        .foregroundStyle(KickIQTheme.textPrimary.opacity(0.8))
                                }
                            }
                        }
                    }

                    if !drill.reps.isEmpty {
                        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
                            Text("REPS / SETS")
                                .font(.caption.weight(.bold))
                                .tracking(1)
                                .foregroundStyle(KickIQTheme.accent)

                            Text(drill.reps)
                                .font(.headline)
                                .foregroundStyle(KickIQTheme.textPrimary)
                        }
                    }

                    Button {
                        showTimer = true
                    } label: {
                        HStack(spacing: KickIQTheme.Spacing.sm) {
                            Image(systemName: "timer")
                            Text("Start Drill Timer")
                        }
                        .font(.headline)
                        .foregroundStyle(KickIQTheme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, KickIQTheme.Spacing.md)
                        .background(KickIQTheme.accent.opacity(0.15), in: .rect(cornerRadius: KickIQTheme.Radius.lg))
                        .overlay(
                            RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                                .stroke(KickIQTheme.accent.opacity(0.3), lineWidth: 1)
                        )
                    }

                    Button {
                        if !isCompleted {
                            storage.completeDrill(drill)
                            completedTrigger += 1
                        }
                        dismiss()
                    } label: {
                        HStack(spacing: KickIQTheme.Spacing.sm) {
                            Image(systemName: isCompleted ? "checkmark.circle.fill" : "checkmark")
                            Text(isCompleted ? "Completed" : "Mark Complete")
                        }
                        .font(.headline)
                        .foregroundStyle(isCompleted ? KickIQTheme.textSecondary : .black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, KickIQTheme.Spacing.md)
                        .background(isCompleted ? KickIQTheme.surface : KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
                    }
                }
                .padding(KickIQTheme.Spacing.md + 4)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
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
        .sheet(isPresented: $showTimer) {
            DrillTimerView(drill: drill)
        }
    }

    private var difficultyColor: Color {
        switch drill.difficulty {
        case .beginner: .green
        case .intermediate: .orange
        case .advanced: .red
        }
    }
}
