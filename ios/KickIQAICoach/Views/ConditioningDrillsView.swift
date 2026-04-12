import SwiftUI

struct ConditioningDrillsView: View {
    let storage: StorageService
    @State private var conditioningService = ConditioningDrillsService()
    @State private var appeared = false
    @State private var selectedDrill: Drill?
    @State private var completedTrigger = 0
    @State private var expandedCategories: Set<String> = []
    @State private var showGeneratePlan = false
    @State private var showPlanDetail = false
    @State private var showQRSheet = false
    @State private var qrDrill: Drill?
    @State private var drillsService = DrillsService()

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
                    conditioningCategorySections
                }
            }
            .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
            .padding(.bottom, KickIQAICoachTheme.Spacing.xl)
        }
        .scrollIndicators(.hidden)
        .background(KickIQAICoachTheme.background.ignoresSafeArea())
        .navigationTitle("Conditioning")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedDrill) { drill in
            DrillDetailSheet(drill: drill, storage: storage, drillsService: drillsService, completedTrigger: $completedTrigger)
        }
        .sheet(isPresented: $showGeneratePlan) {
            PlanGeneratorSheet(storage: storage, planType: .conditioning) { plan in
                showPlanDetail = true
            }
        }
        .sheet(isPresented: $showPlanDetail) {
            if let plan = storage.conditioningPlan {
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
                    Text("GENERATE CONDITIONING PLAN")
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
                    Text("Active Conditioning Plan")
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
        .animation(.spring(response: 0.4).delay(0.05), value: appeared)
    }

    private var conditioningCategorySections: some View {
        let groups = conditioningService.drillsByFocus()

        return LazyVStack(spacing: KickIQAICoachTheme.Spacing.md + 4) {
            ForEach(Array(groups.enumerated()), id: \.element.focus) { sectionIndex, group in
                VStack(spacing: 0) {
                    conditioningCategoryHeader(group.focus, count: group.drills.count, isExpanded: expandedCategories.contains(group.focus.rawValue))
                        .onAppear {
                            if sectionIndex < 3 {
                                expandedCategories.insert(group.focus.rawValue)
                            }
                        }

                    if expandedCategories.contains(group.focus.rawValue) {
                        VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                            ForEach(Array(group.drills.enumerated()), id: \.element.id) { drillIndex, drill in
                                Button {
                                    selectedDrill = drill
                                } label: {
                                    drillCard(drill)
                                }
                                .contextMenu {
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

    private func conditioningCategoryHeader(_ focus: ConditioningFocus, count: Int, isExpanded: Bool) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                if expandedCategories.contains(focus.rawValue) {
                    expandedCategories.remove(focus.rawValue)
                } else {
                    expandedCategories.insert(focus.rawValue)
                }
            }
        } label: {
            HStack(spacing: KickIQAICoachTheme.Spacing.sm + 2) {
                ZStack {
                    RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.sm)
                        .fill(KickIQAICoachTheme.accent.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: focus.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(focus.rawValue)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    Text("\(count) exercise\(count == 1 ? "" : "s")")
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
        drillsService.loadDrills(for: profile.position, weakness: profile.weakness, skillLevel: profile.skillLevel)
    }
}
