import SwiftUI

struct DrillsView: View {
    let storage: StorageService
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var drillsService = DrillsService()
    @State private var appeared = false
    @State private var selectedDrill: Drill?
    @State private var completedTrigger = 0
    @State private var expandedCategories: Set<String> = []

    private var isIPad: Bool { sizeClass == .regular }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQTheme.Spacing.lg) {
                    if drillsService.allDrills.isEmpty {
                        emptyState
                    } else {
                        headerSection
                        statsBar
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

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm + 2) {
            let weakSkills = storage.weakestSkills
            if !weakSkills.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "target")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(KickIQTheme.accent)
                    Text("Focused on your weakest areas")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(KickIQTheme.textSecondary)
                }

                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(weakSkills) { skill in
                            HStack(spacing: 5) {
                                Image(systemName: skill.icon)
                                    .font(.system(size: 10, weight: .semibold))
                                Text(skill.rawValue)
                                    .font(.caption.weight(.bold))
                            }
                            .foregroundStyle(KickIQTheme.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(KickIQTheme.accent.opacity(0.12), in: Capsule())
                            .overlay(Capsule().stroke(KickIQTheme.accent.opacity(0.2), lineWidth: 0.5))
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

    private var statsBar: some View {
        let totalDrills = groupedDrills.reduce(0) { $0 + $1.drills.count }
        let completedCount = groupedDrills.reduce(0) { sum, group in
            sum + group.drills.filter { storage.completedDrillIDs.contains($0.id) }.count
        }
        let categoryCount = groupedDrills.count

        return HStack(spacing: 0) {
            statItem(value: "\(totalDrills)", label: "Total", icon: "figure.soccer")
            Divider().frame(height: 28).overlay(KickIQTheme.divider)
            statItem(value: "\(categoryCount)", label: "Categories", icon: "square.grid.2x2")
            Divider().frame(height: 28).overlay(KickIQTheme.divider)
            statItem(value: "\(completedCount)", label: "Done", icon: "checkmark.circle")
        }
        .padding(.vertical, KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
    }

    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(KickIQTheme.accent)
                Text(value)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(KickIQTheme.textPrimary)
            }
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(KickIQTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
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
        LazyVStack(spacing: KickIQTheme.Spacing.sm + 4) {
            ForEach(Array(groupedDrills.enumerated()), id: \.element.category) { sectionIndex, group in
                let isExpanded = expandedCategories.contains(group.category)
                let completedInCategory = group.drills.filter { storage.completedDrillIDs.contains($0.id) }.count

                VStack(spacing: 0) {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            if isExpanded {
                                expandedCategories.remove(group.category)
                            } else {
                                expandedCategories.insert(group.category)
                            }
                        }
                    } label: {
                        HStack(spacing: KickIQTheme.Spacing.sm + 2) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(KickIQTheme.accent.opacity(0.12))
                                    .frame(width: 40, height: 40)
                                Image(systemName: group.icon)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(KickIQTheme.accent)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(group.category)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(KickIQTheme.textPrimary)
                                HStack(spacing: 6) {
                                    Text("\(group.drills.count) drill\(group.drills.count == 1 ? "" : "s")")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(KickIQTheme.textSecondary)

                                    if completedInCategory > 0 {
                                        HStack(spacing: 3) {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 8, weight: .bold))
                                            Text("\(completedInCategory)")
                                                .font(.system(size: 11, weight: .bold))
                                        }
                                        .foregroundStyle(.green)
                                    }
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(KickIQTheme.textSecondary.opacity(0.5))
                                .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        }
                        .padding(KickIQTheme.Spacing.md)
                        .background(
                            KickIQTheme.card
                                .shadow(.drop(color: .black.opacity(0.08), radius: 4, y: 2)),
                            in: .rect(cornerRadius: KickIQTheme.Radius.lg)
                        )
                    }
                    .sensoryFeedback(.selection, trigger: isExpanded)

                    if isExpanded {
                        VStack(spacing: 8) {
                            if isIPad {
                                iPadDrillGrid(group.drills)
                            } else {
                                ForEach(group.drills, id: \.id) { drill in
                                    Button {
                                        selectedDrill = drill
                                    } label: {
                                        drillCard(drill)
                                    }
                                }
                            }
                        }
                        .padding(.top, 10)
                        .padding(.horizontal, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .animation(.spring(response: 0.4).delay(Double(sectionIndex) * 0.04), value: appeared)
            }
        }
    }

    private func iPadDrillGrid(_ drills: [Drill]) -> some View {
        LazyVGrid(columns: AdaptiveLayout.iPadGridColumns, spacing: KickIQTheme.Spacing.sm) {
            ForEach(drills, id: \.id) { drill in
                Button {
                    selectedDrill = drill
                } label: {
                    iPadDrillCard(drill)
                }
            }
        }
    }

    private func iPadDrillCard(_ drill: Drill) -> some View {
        let isCompleted = storage.completedDrillIDs.contains(drill.id)

        return VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            HStack(spacing: KickIQTheme.Spacing.sm) {
                difficultyDot(drill.difficulty)

                Text(drill.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KickIQTheme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer()

                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.green)
                }
            }

            Text(drill.description)
                .font(.caption)
                .foregroundStyle(KickIQTheme.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            HStack(spacing: 12) {
                Label(drill.duration, systemImage: "clock")
                Label(drill.difficulty.rawValue, systemImage: "speedometer")
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(KickIQTheme.textSecondary.opacity(0.7))
        }
        .padding(KickIQTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KickIQTheme.surface, in: .rect(cornerRadius: KickIQTheme.Radius.md))
    }

    private func drillCard(_ drill: Drill) -> some View {
        let isCompleted = storage.completedDrillIDs.contains(drill.id)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: KickIQTheme.Spacing.sm) {
                difficultyDot(drill.difficulty)

                Text(drill.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KickIQTheme.textPrimary)
                    .lineLimit(1)

                Spacer()

                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(KickIQTheme.textSecondary.opacity(0.35))
                }
            }

            Text(drill.description)
                .font(.caption)
                .foregroundStyle(KickIQTheme.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text(drill.duration)
                }
                HStack(spacing: 4) {
                    Image(systemName: "speedometer")
                        .font(.system(size: 10))
                    Text(drill.difficulty.rawValue)
                }

                Spacer()

                if !drill.reps.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "repeat")
                            .font(.system(size: 10))
                        Text(drill.reps)
                            .lineLimit(1)
                    }
                }
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(KickIQTheme.textSecondary.opacity(0.7))
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.surface, in: .rect(cornerRadius: KickIQTheme.Radius.md))
    }

    private func difficultyDot(_ difficulty: DrillDifficulty) -> some View {
        Circle()
            .fill(difficultyColor(difficulty))
            .frame(width: 8, height: 8)
    }

    private func difficultyColor(_ difficulty: DrillDifficulty) -> Color {
        switch difficulty {
        case .beginner: .green
        case .intermediate: .orange
        case .advanced: .red
        }
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
    @State private var showQRShare = false

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
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showQRShare = true
                    } label: {
                        Image(systemName: "qrcode")
                            .foregroundStyle(KickIQTheme.accent)
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
        .sheet(isPresented: $showTimer) {
            DrillTimerView(drill: drill)
        }
        .sheet(isPresented: $showQRShare) {
            QRCodeShareSheet(
                payload: QRCodeService.payloadFromDrill(drill),
                title: "Share Drill",
                subtitle: "Let your teammate scan to import this drill"
            )
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
