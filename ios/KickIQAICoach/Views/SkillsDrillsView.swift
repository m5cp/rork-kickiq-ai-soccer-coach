import SwiftUI

struct SkillsDrillsView: View {
    let storage: StorageService
    let customContentService: CustomContentService
    @State private var drillsService = DrillsService()
    @State private var appeared = false
    @State private var showGeneratePlan = false
    @State private var showPlanDetail = false
    @State private var showImport = false

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
                    categoryCardsGrid
                }
                if !customContentService.library.drills.isEmpty {
                    customDrillsSection
                }
            }
            .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
            .padding(.bottom, KickIQAICoachTheme.Spacing.xl)
        }
        .scrollIndicators(.hidden)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Drills Generator")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showImport = true
                } label: {
                    Image(systemName: "doc.badge.plus")
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }
            }
        }
        .sheet(isPresented: $showImport) {
            PDFImportView(customContentService: customContentService)
        }
        .sheet(isPresented: $showGeneratePlan) {
            PlanGeneratorSheet(storage: storage, planType: .skills) { _ in
                showPlanDetail = true
            }
        }
        .sheet(isPresented: $showPlanDetail) {
            if let plan = storage.skillsPlan {
                GeneratedPlanDetailView(storage: storage, plan: plan)
            }
        }
        .onAppear {
            loadDrills()
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
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

    private var categoryCardsGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Array(groupedDrills.enumerated()), id: \.element.category) { index, group in
                NavigationLink {
                    SkillCategoryDetailView(
                        categoryName: group.category,
                        categoryIcon: group.icon,
                        drills: group.drills,
                        storage: storage
                    )
                } label: {
                    skillCategoryCard(name: group.category, icon: group.icon, drillCount: group.drills.count, index: index)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 15)
                .animation(.spring(response: 0.4).delay(Double(index) * 0.05), value: appeared)
            }
        }
    }

    private func skillCategoryCard(name: String, icon: String, drillCount: Int, index: Int) -> some View {
        let completedCount = groupedDrills.first(where: { $0.category == name })?.drills.filter { storage.completedDrillIDs.contains($0.id) }.count ?? 0

        return VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(KickIQAICoachTheme.accent.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(KickIQAICoachTheme.accent)
            }

            Text(name)
                .font(.subheadline.weight(.black))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Text("\(drillCount) drill\(drillCount == 1 ? "" : "s")")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary)

            Spacer()

            if completedCount > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.green)
                    Text("\(completedCount) done")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.green)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(KickIQAICoachTheme.Spacing.md)
        .frame(minHeight: 150)
        .background(
            RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                .fill(KickIQAICoachTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                        .stroke(KickIQAICoachTheme.accent.opacity(0.12), lineWidth: 1)
                )
        )
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

    private var customDrillsSection: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: "person.fill.badge.plus")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.orange)
                Text("MY CUSTOM DRILLS")
                    .font(.system(.caption2, design: .default, weight: .black))
                    .tracking(1.5)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
            }

            let customDrills = customContentService.allCustomDrillsAsDrills()
            let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array(customGroupedDrills(customDrills).enumerated()), id: \.element.category) { index, group in
                    NavigationLink {
                        SkillCategoryDetailView(
                            categoryName: group.category,
                            categoryIcon: "person.fill.badge.plus",
                            drills: group.drills,
                            storage: storage
                        )
                    } label: {
                        customCategoryCard(name: group.category, drillCount: group.drills.count)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 15)
                    .animation(.spring(response: 0.4).delay(Double(index) * 0.05 + 0.2), value: appeared)
                }
            }
        }
        .padding(.top, KickIQAICoachTheme.Spacing.sm)
    }

    private func customGroupedDrills(_ drills: [Drill]) -> [(category: String, drills: [Drill])] {
        var groups: [String: [Drill]] = [:]
        for drill in drills {
            groups[drill.targetSkill, default: []].append(drill)
        }
        return groups.map { (category: $0.key, drills: $0.value) }.sorted { $0.category < $1.category }
    }

    private func customCategoryCard(name: String, drillCount: Int) -> some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "person.fill.badge.plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.orange)
            }

            Text(name)
                .font(.subheadline.weight(.black))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Text("\(drillCount) custom drill\(drillCount == 1 ? "" : "s")")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.orange)

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(KickIQAICoachTheme.Spacing.md)
        .frame(minHeight: 150)
        .background(
            RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                .fill(KickIQAICoachTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private func loadDrills() {
        guard let profile = storage.profile else { return }
        drillsService.loadDrills(for: profile.position, weakness: profile.weakness, skillLevel: profile.skillLevel)
    }
}
