import SwiftUI

struct ConditioningDrillsView: View {
    let storage: StorageService
    @State private var conditioningService = ConditioningDrillsService()
    @State private var appeared = false
    @State private var showGeneratePlan = false
    @State private var showPlanDetail = false

    var body: some View {
        ScrollView {
            VStack(spacing: KickIQAICoachTheme.Spacing.md) {
                generatePlanBanner
                if let plan = storage.conditioningPlan {
                    existingPlanCard(plan)
                }
                if conditioningService.conditioningDrills.isEmpty {
                    emptyState
                } else {
                    conditioningHeaderInfo
                    categoryCardsGrid
                }
            }
            .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
            .padding(.bottom, KickIQAICoachTheme.Spacing.xl)
        }
        .scrollIndicators(.hidden)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Fitness Generator")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showGeneratePlan) {
            PlanGeneratorSheet(storage: storage, planType: .conditioning) { _ in
                showPlanDetail = true
            }
        }
        .sheet(isPresented: $showPlanDetail) {
            if let plan = storage.conditioningPlan {
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
                    Text("GENERATE FITNESS PLAN")
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
                    Text("Active Fitness Plan")
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

    private var conditioningHeaderInfo: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                Image(systemName: "heart.circle.fill")
                    .foregroundStyle(KickIQAICoachTheme.accent)
                Text("Build your athletic foundation")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.4).delay(0.05), value: appeared)
    }

    private var categoryCardsGrid: some View {
        let groups = conditioningService.drillsByFocus()
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Array(groups.enumerated()), id: \.element.focus) { index, group in
                NavigationLink {
                    ConditioningCategoryDetailView(
                        focus: group.focus,
                        drills: group.drills,
                        storage: storage
                    )
                } label: {
                    conditioningCategoryCard(focus: group.focus, drillCount: group.drills.count, drills: group.drills, index: index)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 15)
                .animation(.spring(response: 0.4).delay(Double(index) * 0.05), value: appeared)
            }
        }
    }

    private func conditioningCategoryCard(focus: ConditioningFocus, drillCount: Int, drills: [Drill], index: Int) -> some View {
        let completedCount = drills.filter { storage.completedDrillIDs.contains($0.id) }.count

        return VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(KickIQAICoachTheme.accent.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: focus.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(KickIQAICoachTheme.accent)
            }

            Text(focus.rawValue)
                .font(.subheadline.weight(.black))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Text("\(drillCount) exercise\(drillCount == 1 ? "" : "s")")
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
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(KickIQAICoachTheme.accent.opacity(0.5))
            Text("Conditioning Loading")
                .font(.title3.weight(.black))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
            Text("Complete your profile to get\npersonalized conditioning recommendations")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private func loadDrills() {
        guard let profile = storage.profile else { return }
        conditioningService.loadDrills(for: profile.skillLevel)
    }
}
