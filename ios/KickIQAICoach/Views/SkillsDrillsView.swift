import SwiftUI

struct SkillsDrillsView: View {
    let storage: StorageService
    @State private var drillsService = DrillsService()
    @State private var appeared = false
    @State private var selectedDrill: Drill?
    @State private var completedTrigger = 0
    @State private var expandedCategories: Set<String> = []
    @State private var showGeneratePlan = false
    @State private var showPlanDetail = false
    @State private var showQRSheet = false
    @State private var qrDrill: Drill?

    var body: some View {
        ScrollView {
            VStack(spacing: KickIQAICoachTheme.Spacing.md) {
                generatePlanBanner
                if let plan = storage.skillsPlan {
                    existingPlanCard(plan)
                }
                if drillsService.allDrills.isEmpty {
                    emptyState
                } else {
                    headerInfo
                    skillCategorySections
                }
            }
            .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
            .padding(.bottom, KickIQAICoachTheme.Spacing.xl)
        }
        .scrollIndicators(.hidden)
        .background(KickIQAICoachTheme.background.ignoresSafeArea())
        .navigationTitle("Skills Drills")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedDrill) { drill in
            DrillDetailSheet(drill: drill, storage: storage, drillsService: drillsService, completedTrigger: $completedTrigger)
        }
        .sheet(isPresented: $showGeneratePlan) {
            PlanGeneratorSheet(storage: storage, planType: .skills) { plan in
                showPlanDetail = true
            }
        }
        .sheet(isPresented: $showPlanDetail) {
            if let plan = storage.skillsPlan {
                GeneratedPlanDetailView(storage: storage, plan: plan)
            }
        }
        .sheet(isPresented: $showQRSheet) {
            if let drill = qrDrill {
                QRDrillShareSheet(drill: drill)
            }
        }
        .onAppear {
            loadDrills()
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
        .sensoryFeedback(.success, trigger: completedTrigger)
    }

    private var generatePlanBanner: some View {
        Button {
            showGeneratePlan = true
        } label: {
            HStack(spacing: KickIQAICoachTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(KickIQAICoachTheme.accent.opacity(0.2))
                        .frame(width: 48, height: 48)
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("GENERATE SKILLS PLAN")
                        .font(.caption.weight(.black))
                        .tracking(1)
                        .foregroundStyle(KickIQAICoachTheme.accent)
                    Text("1-12 weeks • Custom focus • AI powered")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.accent)
            }
            .padding(KickIQAICoachTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                    .fill(KickIQAICoachTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                            .stroke(KickIQAICoachTheme.accent.opacity(0.3), lineWidth: 1.5)
                    )
            )
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.4), value: appeared)
    }

    private func existingPlanCard(_ plan: GeneratedPlan) -> some View {
        Button {
            showPlanDetail = true
        } label: {
            HStack(spacing: KickIQAICoachTheme.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.sm)
                        .fill(KickIQAICoachTheme.accent.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "doc.text.fill")
                        .font(.body)
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Active Skills Plan")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    Text("\(plan.config.weeks) weeks • \(plan.config.daysPerWeek) days/wk • \(plan.config.minutesPerSession)m")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }

                Spacer()

                if plan.isSynced {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.3))
            }
            .padding(KickIQAICoachTheme.Spacing.md)
            .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.4).delay(0.03), value: appeared)
    }

    private var headerInfo: some View {
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
        .animation(.spring(response: 0.4).delay(0.05), value: appeared)
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

    private var skillCategorySections: some View {
        LazyVStack(spacing: KickIQAICoachTheme.Spacing.md + 4) {
            ForEach(Array(groupedDrills.enumerated()), id: \.element.category) { sectionIndex, group in
                VStack(spacing: 0) {
                    categoryHeader(group.category, icon: group.icon, count: group.drills.count, isExpanded: expandedCategories.contains(group.category))
                        .onAppear {
                            if sectionIndex < 3 {
                                expandedCategories.insert(group.category)
                            }
                        }

                    if expandedCategories.contains(group.category) {
                        VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                            ForEach(Array(group.drills.enumerated()), id: \.element.id) { drillIndex, drill in
                                Button {
                                    selectedDrill = drill
                                } label: {
                                    drillCard(drill)
                                }
                                .contextMenu {
                                    Button {
                                        storage.toggleFavoriteDrill(drill.id)
                                    } label: {
                                        Label(
                                            storage.isDrillFavorite(drill.id) ? "Remove from Favorites" : "Add to Favorites",
                                            systemImage: storage.isDrillFavorite(drill.id) ? "heart.slash" : "heart"
                                        )
                                    }
                                    Button {
                                        qrDrill = drill
                                        showQRSheet = true
                                    } label: {
                                        Label("Share QR Code", systemImage: "qrcode")
                                    }
                                }
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 10)
                                .animation(.spring(response: 0.35).delay(Double(drillIndex) * 0.04), value: appeared)
                            }
                        }
                        .padding(.top, KickIQAICoachTheme.Spacing.sm)
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
            HStack(spacing: KickIQAICoachTheme.Spacing.sm + 2) {
                ZStack {
                    RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.sm)
                        .fill(KickIQAICoachTheme.accent.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    Text("\(count) drill\(count == 1 ? "" : "s")")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.4))
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            .padding(KickIQAICoachTheme.Spacing.md)
            .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        }
        .sensoryFeedback(.selection, trigger: isExpanded)
    }

    private func drillCard(_ drill: Drill) -> some View {
        let isCompleted = storage.completedDrillIDs.contains(drill.id)

        return HStack(spacing: KickIQAICoachTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green.opacity(0.15) : KickIQAICoachTheme.surface)
                    .frame(width: 38, height: 38)
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(isCompleted ? .green : KickIQAICoachTheme.textSecondary.opacity(0.3))
            }

            VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.xs) {
                Text(drill.name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                    Label(drill.duration, systemImage: "clock")
                    Text("·")
                    Text(drill.difficulty.rawValue)
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.3))
        }
        .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
        .padding(.vertical, KickIQAICoachTheme.Spacing.sm + 4)
        .background(KickIQAICoachTheme.surface, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
    }

    private var emptyState: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.md) {
            Spacer().frame(height: 60)
            Image(systemName: "figure.soccer")
                .font(.system(size: 48))
                .foregroundStyle(KickIQAICoachTheme.accent.opacity(0.5))
            Text("Skills Drills Loading")
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
    }
}
