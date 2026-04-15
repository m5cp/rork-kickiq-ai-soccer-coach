import SwiftUI

struct DrillsView: View {
    let storage: StorageService
    let customContentService: CustomContentService
    @State private var drillsService = DrillsService()
    @State private var conditioningService = ConditioningDrillsService()
    @State private var appeared = false
    @State private var selectedCategory: DrillCategory = .skills
    @State private var showGenerateSkillsPlan = false
    @State private var showGenerateConditioningPlan = false
    @State private var showSkillsPlanDetail = false
    @State private var showConditioningPlanDetail = false
    @State private var showResetConfirmation = false
    @State private var resetPlanType: GeneratedPlanType = .skills

    private let cardGradients: [Color] = [
        Color(hex: 0x1A6B4A),
        Color(hex: 0x2D5BA8),
        Color(hex: 0x8B3A62),
        Color(hex: 0x6B4A1A),
        Color(hex: 0x4A1A6B),
        Color(hex: 0x1A4A6B),
        Color(hex: 0x6B1A2D),
        Color(hex: 0x3A6B1A),
        Color(hex: 0x5A3A1A),
        Color(hex: 0x1A3A5A),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQAICoachTheme.Spacing.md) {
                    categoryPicker

                    if selectedCategory == .skills {
                        skillsPlanSection
                        skillsHeroCards
                    } else {
                        conditioningPlanSection
                        conditioningHeroCards
                    }
                }
                .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                .padding(.bottom, KickIQAICoachTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQAICoachTheme.background.ignoresSafeArea())
            .navigationTitle("Drills")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showGenerateSkillsPlan) {
                PlanGeneratorSheet(storage: storage, planType: .skills) { _ in
                    showSkillsPlanDetail = true
                }
            }
            .sheet(isPresented: $showGenerateConditioningPlan) {
                PlanGeneratorSheet(storage: storage, planType: .conditioning) { _ in
                    showConditioningPlanDetail = true
                }
            }
            .sheet(isPresented: $showSkillsPlanDetail) {
                if let plan = storage.skillsPlan {
                    GeneratedPlanDetailView(storage: storage, plan: plan)
                }
            }
            .sheet(isPresented: $showConditioningPlanDetail) {
                if let plan = storage.conditioningPlan {
                    GeneratedPlanDetailView(storage: storage, plan: plan)
                }
            }
            .alert("Reset Plan?", isPresented: $showResetConfirmation) {
                Button("Reset", role: .destructive) {
                    storage.clearPlan(resetPlanType)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove your active \(resetPlanType.rawValue.lowercased()) plan. You can generate a new one anytime.")
            }
        }
        .onAppear {
            loadDrills()
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
    }

    private var categoryPicker: some View {
        HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            ForEach(DrillCategory.allCases) { cat in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedCategory = cat
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: cat.icon)
                            .font(.system(size: 13))
                        Text(cat.rawValue)
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundStyle(selectedCategory == cat ? KickIQAICoachTheme.onAccent : KickIQAICoachTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedCategory == cat ? KickIQAICoachTheme.accent : KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
                }
            }
        }
        .sensoryFeedback(.selection, trigger: selectedCategory)
        .opacity(appeared ? 1 : 0)
    }

    // MARK: - Plan Sections

    private var skillsPlanSection: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            if let plan = storage.skillsPlan {
                Button {
                    showSkillsPlanDetail = true
                } label: {
                    HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(KickIQAICoachTheme.accent.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(KickIQAICoachTheme.accent)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Active Skills Plan")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(KickIQAICoachTheme.textPrimary)
                            Text("\(plan.config.weeks)w · \(plan.config.daysPerWeek)d/wk · \(plan.config.minutesPerSession)m")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(KickIQAICoachTheme.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.3))
                    }
                    .padding(KickIQAICoachTheme.Spacing.sm + 2)
                    .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
                }

                HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                    Button {
                        showGenerateSkillsPlan = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 11))
                            Text("Regenerate")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(KickIQAICoachTheme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(KickIQAICoachTheme.accent.opacity(0.1), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.sm))
                    }

                    Button {
                        resetPlanType = .skills
                        showResetConfirmation = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                            Text("Reset")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.08), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.sm))
                    }
                }
            } else {
                Button {
                    showGenerateSkillsPlan = true
                } label: {
                    HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                        ZStack {
                            Circle()
                                .fill(KickIQAICoachTheme.accent.opacity(0.2))
                                .frame(width: 40, height: 40)
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(KickIQAICoachTheme.accent)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Generate Skills Plan")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(KickIQAICoachTheme.textPrimary)
                            Text("1-12 weeks · Custom focus · AI powered")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(KickIQAICoachTheme.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(KickIQAICoachTheme.accent)
                    }
                    .padding(KickIQAICoachTheme.Spacing.sm + 2)
                    .background(
                        RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                            .fill(KickIQAICoachTheme.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                                    .stroke(KickIQAICoachTheme.accent.opacity(0.3), lineWidth: 1.5)
                            )
                    )
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.4), value: appeared)
    }

    private var conditioningPlanSection: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            if let plan = storage.conditioningPlan {
                Button {
                    showConditioningPlanDetail = true
                } label: {
                    HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(KickIQAICoachTheme.accent.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(KickIQAICoachTheme.accent)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Active Conditioning Plan")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(KickIQAICoachTheme.textPrimary)
                            Text("\(plan.config.weeks)w · \(plan.config.daysPerWeek)d/wk · \(plan.config.minutesPerSession)m")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(KickIQAICoachTheme.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.3))
                    }
                    .padding(KickIQAICoachTheme.Spacing.sm + 2)
                    .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
                }

                HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                    Button {
                        showGenerateConditioningPlan = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 11))
                            Text("Regenerate")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(KickIQAICoachTheme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(KickIQAICoachTheme.accent.opacity(0.1), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.sm))
                    }

                    Button {
                        resetPlanType = .conditioning
                        showResetConfirmation = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                            Text("Reset")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.08), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.sm))
                    }
                }
            } else {
                Button {
                    showGenerateConditioningPlan = true
                } label: {
                    HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                        ZStack {
                            Circle()
                                .fill(KickIQAICoachTheme.accent.opacity(0.2))
                                .frame(width: 40, height: 40)
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(KickIQAICoachTheme.accent)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Generate Conditioning Plan")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(KickIQAICoachTheme.textPrimary)
                            Text("1-12 weeks · Custom focus · AI powered")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(KickIQAICoachTheme.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(KickIQAICoachTheme.accent)
                    }
                    .padding(KickIQAICoachTheme.Spacing.sm + 2)
                    .background(
                        RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                            .fill(KickIQAICoachTheme.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                                    .stroke(KickIQAICoachTheme.accent.opacity(0.3), lineWidth: 1.5)
                            )
                    )
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.4), value: appeared)
    }

    // MARK: - Skills Hero Cards

    private var skillsHeroCards: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.md) {
            if drillsService.allDrills.isEmpty {
                emptyState
            } else {
                skillsHeaderInfo

                LazyVStack(spacing: KickIQAICoachTheme.Spacing.md) {
                    ForEach(Array(groupedDrills.enumerated()), id: \.element.category) { index, group in
                        NavigationLink {
                            SkillCategoryDetailView(
                                categoryName: group.category,
                                categoryIcon: group.icon,
                                drills: group.drills,
                                storage: storage
                            )
                        } label: {
                            skillHeroCard(
                                name: group.category,
                                icon: group.icon,
                                drillCount: group.drills.count,
                                drills: group.drills,
                                index: index
                            )
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.spring(response: 0.45, dampingFraction: 0.82).delay(Double(index) * 0.06), value: appeared)
                    }
                }
            }
        }
    }

    private func skillHeroCard(name: String, icon: String, drillCount: Int, drills: [Drill], index: Int) -> some View {
        let completedCount = drills.filter { storage.completedDrillIDs.contains($0.id) }.count
        let progress = drillCount > 0 ? Double(completedCount) / Double(drillCount) : 0
        let cardColor = cardGradients[index % cardGradients.count]

        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.15))
                            .frame(width: 48, height: 48)
                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    Text(name)
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(.white)

                    Text("\(drillCount) drill\(drillCount == 1 ? "" : "s")")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: KickIQAICoachTheme.Spacing.sm) {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.bold))
                        .foregroundStyle(.white.opacity(0.5))

                    Spacer()

                    if completedCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                            Text("\(completedCount)/\(drillCount)")
                                .font(.caption.weight(.black))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.2), in: Capsule())
                    }
                }
            }

            if completedCount > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.15))
                            .frame(height: 4)

                        Capsule()
                            .fill(.white.opacity(0.8))
                            .frame(width: geo.size.width * progress, height: 4)
                    }
                }
                .frame(height: 4)
                .padding(.top, KickIQAICoachTheme.Spacing.md)
            }

            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                ForEach(Array(drills.prefix(3).enumerated()), id: \.element.id) { _, drill in
                    Text(drill.name)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                }
            }
            .padding(.top, KickIQAICoachTheme.Spacing.sm)
        }
        .padding(KickIQAICoachTheme.Spacing.md + 4)
        .background(
            LinearGradient(
                colors: [cardColor, cardColor.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(.rect(cornerRadius: KickIQAICoachTheme.Radius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.xl)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var skillsHeaderInfo: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            let weakSkills = storage.weakestSkills
            if !weakSkills.isEmpty {
                HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                    Image(systemName: "target")
                        .foregroundStyle(KickIQAICoachTheme.accent)
                    Text("Focused on your weakest areas")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }

                ScrollView(.horizontal) {
                    HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                        ForEach(weakSkills) { skill in
                            HStack(spacing: 4) {
                                Image(systemName: skill.icon)
                                    .font(.system(size: 10))
                                Text(skill.rawValue)
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(KickIQAICoachTheme.accent)
                            .padding(.horizontal, KickIQAICoachTheme.Spacing.sm + 4)
                            .padding(.vertical, 6)
                            .background(KickIQAICoachTheme.accent.opacity(0.15), in: Capsule())
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

    // MARK: - Conditioning Hero Cards

    private var conditioningHeroCards: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.md) {
            if conditioningService.conditioningDrills.isEmpty {
                emptyState
            } else {
                conditioningHeaderInfo

                LazyVStack(spacing: KickIQAICoachTheme.Spacing.md) {
                    let groups = conditioningService.drillsByFocus()
                    ForEach(Array(groups.enumerated()), id: \.element.focus) { index, group in
                        NavigationLink {
                            ConditioningCategoryDetailView(
                                focus: group.focus,
                                drills: group.drills,
                                storage: storage
                            )
                        } label: {
                            conditioningHeroCard(
                                focus: group.focus,
                                drills: group.drills,
                                index: index
                            )
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.spring(response: 0.45, dampingFraction: 0.82).delay(Double(index) * 0.06), value: appeared)
                    }
                }
            }
        }
    }

    private func conditioningHeroCard(focus: ConditioningFocus, drills: [Drill], index: Int) -> some View {
        let completedCount = drills.filter { storage.completedDrillIDs.contains($0.id) }.count
        let progress = drills.count > 0 ? Double(completedCount) / Double(drills.count) : 0
        let cardColor = cardGradients[(index + 5) % cardGradients.count]

        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.15))
                            .frame(width: 48, height: 48)
                        Image(systemName: focus.icon)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    Text(focus.rawValue)
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(.white)

                    Text("\(drills.count) exercise\(drills.count == 1 ? "" : "s")")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: KickIQAICoachTheme.Spacing.sm) {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.bold))
                        .foregroundStyle(.white.opacity(0.5))

                    Spacer()

                    if completedCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                            Text("\(completedCount)/\(drills.count)")
                                .font(.caption.weight(.black))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.2), in: Capsule())
                    }
                }
            }

            if completedCount > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.15))
                            .frame(height: 4)

                        Capsule()
                            .fill(.white.opacity(0.8))
                            .frame(width: geo.size.width * progress, height: 4)
                    }
                }
                .frame(height: 4)
                .padding(.top, KickIQAICoachTheme.Spacing.md)
            }

            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                ForEach(Array(drills.prefix(3).enumerated()), id: \.element.id) { _, drill in
                    Text(drill.name)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                }
            }
            .padding(.top, KickIQAICoachTheme.Spacing.sm)
        }
        .padding(KickIQAICoachTheme.Spacing.md + 4)
        .background(
            LinearGradient(
                colors: [cardColor, cardColor.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(.rect(cornerRadius: KickIQAICoachTheme.Radius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.xl)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var conditioningHeaderInfo: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                Image(systemName: "heart.circle.fill")
                    .foregroundStyle(KickIQAICoachTheme.accent)
                Text("Build your athletic foundation")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
            }

            ScrollView(.horizontal) {
                HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                    ForEach(ConditioningFocus.allCases) { focus in
                        HStack(spacing: 4) {
                            Image(systemName: focus.icon)
                                .font(.system(size: 10))
                            Text(focus.rawValue)
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(KickIQAICoachTheme.accent)
                        .padding(.horizontal, KickIQAICoachTheme.Spacing.sm + 4)
                        .padding(.vertical, 6)
                        .background(KickIQAICoachTheme.accent.opacity(0.15), in: Capsule())
                    }
                }
            }
            .contentMargins(.horizontal, 0)
            .scrollIndicators(.hidden)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(appeared ? 1 : 0)
    }

    // MARK: - Shared

    private var emptyState: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.md) {
            Spacer().frame(height: 60)

            Image(systemName: "figure.soccer")
                .font(.system(size: 48))
                .foregroundStyle(KickIQAICoachTheme.accent.opacity(0.5))

            Text("Drills Loading")
                .font(.title3.weight(.black))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)

            Text("Complete your profile to get\npersonalized drill recommendations")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private func loadDrills() {
        guard let profile = storage.profile else { return }
        drillsService.loadDrills(for: profile.position, weakness: profile.weakness, skillLevel: profile.skillLevel)
        conditioningService.loadDrills(for: profile.skillLevel)
    }
}

struct QRDrillShareSheet: View {
    let drill: Drill
    @Environment(\.dismiss) private var dismiss
    @State private var qrImage: UIImage?

    var body: some View {
        NavigationStack {
            VStack(spacing: KickIQAICoachTheme.Spacing.lg) {
                Text("Share Drill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)

                Text(drill.name)
                    .font(.headline)
                    .foregroundStyle(KickIQAICoachTheme.accent)

                if let qrImage {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .background(Color.white, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
                        .padding(KickIQAICoachTheme.Spacing.md)
                } else {
                    ProgressView()
                        .frame(width: 200, height: 200)
                }

                Text("Scan this QR code to view the drill details")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    .multilineTextAlignment(.center)

                if let qrImage {
                    ShareLink(item: Image(uiImage: qrImage), preview: SharePreview("KickIQAICoach Drill: \(drill.name)", image: Image(uiImage: qrImage))) {
                        HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share QR Code")
                        }
                        .font(.headline)
                        .foregroundStyle(KickIQAICoachTheme.onAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, KickIQAICoachTheme.Spacing.md)
                        .background(KickIQAICoachTheme.accent, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
                    }
                    .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                }
            }
            .padding(KickIQAICoachTheme.Spacing.md)
            .background(KickIQAICoachTheme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(.background)
        .onAppear {
            let payload = QRSharingService.drillPayload(drill)
            qrImage = QRSharingService.generateQRCode(from: payload)
        }
    }
}

struct DrillDetailSheet: View {
    let drill: Drill
    let storage: StorageService
    let drillsService: DrillsService
    @Binding var completedTrigger: Int
    @Environment(\.dismiss) private var dismiss
    @State private var showTimer = false
    @State private var showQR = false
    @State private var favoriteTrigger = 0

    private var isCompleted: Bool {
        storage.completedDrillIDs.contains(drill.id)
    }

    private var isFavorite: Bool {
        storage.isDrillFavorite(drill.id)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
                        HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                            Text(drill.difficulty.rawValue)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(difficultyColor)
                                .padding(.horizontal, KickIQAICoachTheme.Spacing.sm)
                                .padding(.vertical, 4)
                                .background(difficultyColor.opacity(0.15), in: Capsule())

                            Text(drill.targetSkill)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(KickIQAICoachTheme.accent)
                                .padding(.horizontal, KickIQAICoachTheme.Spacing.sm)
                                .padding(.vertical, 4)
                                .background(KickIQAICoachTheme.accent.opacity(0.15), in: Capsule())

                            Spacer()

                            Button {
                                storage.toggleFavoriteDrill(drill.id)
                                favoriteTrigger += 1
                            } label: {
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .font(.title3)
                                    .foregroundStyle(isFavorite ? .red : KickIQAICoachTheme.textSecondary.opacity(0.4))
                                    .symbolEffect(.bounce, value: favoriteTrigger)
                            }
                        }

                        HStack {
                            Text(drill.name)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(KickIQAICoachTheme.textPrimary)
                            Spacer()
                            Label(drill.duration, systemImage: "clock")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(KickIQAICoachTheme.textSecondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
                        Text("DESCRIPTION")
                            .font(.caption.weight(.bold))
                            .tracking(1)
                            .foregroundStyle(KickIQAICoachTheme.accent)

                        Text(drill.description)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(KickIQAICoachTheme.textPrimary.opacity(0.85))
                            .lineSpacing(4)
                    }

                    if !drill.coachingCues.isEmpty {
                        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
                            Text("COACHING CUES")
                                .font(.caption.weight(.bold))
                                .tracking(1)
                                .foregroundStyle(KickIQAICoachTheme.accent)

                            ForEach(drill.coachingCues, id: \.self) { cue in
                                HStack(alignment: .top, spacing: KickIQAICoachTheme.Spacing.sm) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(KickIQAICoachTheme.accent)
                                        .padding(.top, 2)
                                    Text(cue)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(KickIQAICoachTheme.textPrimary.opacity(0.8))
                                }
                            }
                        }
                    }

                    if !drill.reps.isEmpty {
                        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
                            Text("REPS / SETS")
                                .font(.caption.weight(.bold))
                                .tracking(1)
                                .foregroundStyle(KickIQAICoachTheme.accent)

                            Text(drill.reps)
                                .font(.headline)
                                .foregroundStyle(KickIQAICoachTheme.textPrimary)
                        }
                    }

                    HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                        Button {
                            showTimer = true
                        } label: {
                            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                                Image(systemName: "timer")
                                Text("Start Timer")
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KickIQAICoachTheme.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, KickIQAICoachTheme.Spacing.md)
                            .background(KickIQAICoachTheme.accent.opacity(0.15), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
                            .overlay(
                                RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                                    .stroke(KickIQAICoachTheme.accent.opacity(0.3), lineWidth: 1)
                            )
                        }

                        Button {
                            showQR = true
                        } label: {
                            Image(systemName: "qrcode")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(KickIQAICoachTheme.accent)
                                .frame(width: 52, height: 52)
                                .background(KickIQAICoachTheme.accent.opacity(0.15), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
                                .overlay(
                                    RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                                        .stroke(KickIQAICoachTheme.accent.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }

                    Button {
                        if !isCompleted {
                            storage.completeDrill(drill)
                            storage.recordDrillCompletion(drill.id, drillName: drill.name, duration: parseDrillMinutes(drill.duration) * 60)
                            completedTrigger += 1
                        }
                        dismiss()
                    } label: {
                        HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                            Image(systemName: isCompleted ? "checkmark.circle.fill" : "checkmark")
                            Text(isCompleted ? "Completed" : "Mark Complete")
                        }
                        .font(.headline)
                        .foregroundStyle(isCompleted ? KickIQAICoachTheme.textSecondary : KickIQAICoachTheme.onAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, KickIQAICoachTheme.Spacing.md)
                        .background(isCompleted ? KickIQAICoachTheme.surface : KickIQAICoachTheme.accent, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
                    }
                }
                .padding(KickIQAICoachTheme.Spacing.md + 4)
            }
            .scrollIndicators(.hidden)
            .background(KickIQAICoachTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.background)
        .sheet(isPresented: $showTimer) {
            DrillTimerView(drill: drill)
        }
        .sheet(isPresented: $showQR) {
            QRDrillShareSheet(drill: drill)
        }
    }

    private var difficultyColor: Color {
        switch drill.difficulty {
        case .beginner: .green
        case .intermediate: .orange
        case .advanced: .red
        }
    }

    private func parseDrillMinutes(_ duration: String) -> Int {
        let numbers = duration.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap { Int($0) }
        return numbers.first ?? 10
    }
}
