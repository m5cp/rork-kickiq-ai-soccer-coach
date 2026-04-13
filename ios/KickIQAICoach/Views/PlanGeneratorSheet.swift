import SwiftUI

struct PlanGeneratorSheet: View {
    let storage: StorageService
    let planType: GeneratedPlanType
    let onPlanGenerated: (GeneratedPlan) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var weeks: Int = 4
    @State private var daysPerWeek: Int = 5
    @State private var minutesPerSession: Int = 45
    @State private var selectedSkillFocuses: Set<String> = []
    @State private var selectedConditioningFocuses: Set<String> = []
    @State private var isGenerating = false
    @State private var appeared = false

    private var focusOptions: [String] {
        if planType == .skills {
            return (storage.profile?.position.skills ?? SkillCategory.allCases).map(\.rawValue)
        } else {
            return ConditioningFocus.allCases.map(\.rawValue)
        }
    }

    private var selectedFocuses: Set<String> {
        planType == .skills ? selectedSkillFocuses : selectedConditioningFocuses
    }

    private var canGenerate: Bool {
        !selectedFocuses.isEmpty && !isGenerating
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQAICoachTheme.Spacing.lg) {
                    headerSection
                    durationSection
                    frequencySection
                    sessionTimeSection
                    focusSection
                    generateButton
                }
                .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                .padding(.bottom, KickIQAICoachTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQAICoachTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.body.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.background)
        .onAppear {
            if planType == .skills {
                selectedSkillFocuses = Set(focusOptions)
            } else {
                selectedConditioningFocuses = Set(focusOptions)
            }
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
        }
    }

    private var headerSection: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(KickIQAICoachTheme.accent.opacity(0.15))
                    .frame(width: 64, height: 64)
                Image(systemName: planType == .skills ? "figure.soccer" : "heart.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(KickIQAICoachTheme.accent)
            }

            Text("GENERATE \(planType.rawValue.uppercased()) PLAN")
                .font(.caption.weight(.black))
                .tracking(2)
                .foregroundStyle(KickIQAICoachTheme.accent)

            Text("Build your personalized\n\(planType == .skills ? "skills training" : "conditioning") program")
                .font(.title3.weight(.bold))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, KickIQAICoachTheme.Spacing.md)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            Label("PLAN DURATION", systemImage: "calendar")
                .font(.caption.weight(.black))
                .tracking(1)
                .foregroundStyle(KickIQAICoachTheme.accent)

            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                Text("\(weeks)")
                    .font(.system(size: 36, weight: .black))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    .contentTransition(.numericText())
                    .frame(width: 50)

                Text(weeks == 1 ? "week" : "weeks")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)

                Spacer()

                HStack(spacing: KickIQAICoachTheme.Spacing.md) {
                    Button {
                        if weeks > 1 { withAnimation(.spring(response: 0.3)) { weeks -= 1 } }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(weeks > 1 ? KickIQAICoachTheme.accent : KickIQAICoachTheme.textSecondary.opacity(0.3))
                    }
                    .disabled(weeks <= 1)

                    Button {
                        if weeks < 12 { withAnimation(.spring(response: 0.3)) { weeks += 1 } }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(weeks < 12 ? KickIQAICoachTheme.accent : KickIQAICoachTheme.textSecondary.opacity(0.3))
                    }
                    .disabled(weeks >= 12)
                }
            }
            .sensoryFeedback(.selection, trigger: weeks)
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.4).delay(0.05), value: appeared)
    }

    private var frequencySection: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            Label("DAYS PER WEEK", systemImage: "repeat")
                .font(.caption.weight(.black))
                .tracking(1)
                .foregroundStyle(KickIQAICoachTheme.accent)

            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                Text("\(daysPerWeek)")
                    .font(.system(size: 36, weight: .black))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    .contentTransition(.numericText())
                    .frame(width: 50)

                Text(daysPerWeek == 1 ? "day" : "days")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)

                Spacer()

                HStack(spacing: KickIQAICoachTheme.Spacing.md) {
                    Button {
                        if daysPerWeek > 3 { withAnimation(.spring(response: 0.3)) { daysPerWeek -= 1 } }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(daysPerWeek > 3 ? KickIQAICoachTheme.accent : KickIQAICoachTheme.textSecondary.opacity(0.3))
                    }
                    .disabled(daysPerWeek <= 3)

                    Button {
                        if daysPerWeek < 7 { withAnimation(.spring(response: 0.3)) { daysPerWeek += 1 } }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(daysPerWeek < 7 ? KickIQAICoachTheme.accent : KickIQAICoachTheme.textSecondary.opacity(0.3))
                    }
                    .disabled(daysPerWeek >= 7)
                }
            }
            .sensoryFeedback(.selection, trigger: daysPerWeek)

            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { day in
                    let index = ["M", "T", "W", "T", "F", "S", "S"].firstIndex(of: day) ?? 0
                    Circle()
                        .fill(index < daysPerWeek ? KickIQAICoachTheme.accent : KickIQAICoachTheme.divider)
                        .frame(width: 28, height: 28)
                        .overlay {
                            Text(day)
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(index < daysPerWeek ? KickIQAICoachTheme.onAccent : KickIQAICoachTheme.textSecondary)
                        }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.4).delay(0.1), value: appeared)
    }

    private var sessionTimeSection: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            Label("TIME PER SESSION", systemImage: "clock.fill")
                .font(.caption.weight(.black))
                .tracking(1)
                .foregroundStyle(KickIQAICoachTheme.accent)

            let timeOptions = [15, 30, 45, 60, 90]
            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                ForEach(timeOptions, id: \.self) { mins in
                    Button {
                        withAnimation(.spring(response: 0.3)) { minutesPerSession = mins }
                    } label: {
                        Text("\(mins)m")
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(minutesPerSession == mins ? KickIQAICoachTheme.onAccent : KickIQAICoachTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(minutesPerSession == mins ? KickIQAICoachTheme.accent : KickIQAICoachTheme.surface, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
                    }
                }
            }
            .sensoryFeedback(.selection, trigger: minutesPerSession)
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.4).delay(0.15), value: appeared)
    }

    private var focusSection: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            HStack {
                Label("FOCUS AREAS", systemImage: "target")
                    .font(.caption.weight(.black))
                    .tracking(1)
                    .foregroundStyle(KickIQAICoachTheme.accent)
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        if selectedFocuses.count == focusOptions.count {
                            if planType == .skills { selectedSkillFocuses.removeAll() } else { selectedConditioningFocuses.removeAll() }
                        } else {
                            if planType == .skills { selectedSkillFocuses = Set(focusOptions) } else { selectedConditioningFocuses = Set(focusOptions) }
                        }
                    }
                } label: {
                    Text(selectedFocuses.count == focusOptions.count ? "Deselect All" : "Select All")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: KickIQAICoachTheme.Spacing.sm)], spacing: KickIQAICoachTheme.Spacing.sm) {
                ForEach(focusOptions, id: \.self) { focus in
                    let isSelected = selectedFocuses.contains(focus)
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            if planType == .skills {
                                if isSelected { selectedSkillFocuses.remove(focus) } else { selectedSkillFocuses.insert(focus) }
                            } else {
                                if isSelected { selectedConditioningFocuses.remove(focus) } else { selectedConditioningFocuses.insert(focus) }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: iconFor(focus))
                                .font(.system(size: 12))
                            Text(focus)
                                .font(.caption.weight(.bold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(isSelected ? KickIQAICoachTheme.onAccent : KickIQAICoachTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 8)
                        .background(isSelected ? KickIQAICoachTheme.accent : KickIQAICoachTheme.surface, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
                    }
                    .sensoryFeedback(.selection, trigger: isSelected)
                }
            }
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.4).delay(0.2), value: appeared)
    }

    private var generateButton: some View {
        Button {
            Task { await generatePlan() }
        } label: {
            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                if isGenerating {
                    ProgressView()
                        .tint(KickIQAICoachTheme.onAccent)
                } else {
                    Image(systemName: "calendar.badge.plus")
                }
                Text(isGenerating ? "Building Plan..." : "Build \(planType.rawValue) Plan")
            }
            .font(.headline.weight(.black))
            .foregroundStyle(KickIQAICoachTheme.onAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(canGenerate ? KickIQAICoachTheme.accent : KickIQAICoachTheme.textSecondary.opacity(0.3), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        }
        .disabled(!canGenerate)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.4).delay(0.25), value: appeared)
    }

    private func iconFor(_ focus: String) -> String {
        if let skill = SkillCategory.allCases.first(where: { $0.rawValue == focus }) {
            return skill.icon
        }
        if let cond = ConditioningFocus.allCases.first(where: { $0.rawValue == focus }) {
            return cond.icon
        }
        return "circle.fill"
    }

    private func generatePlan() async {
        isGenerating = true

        let focuses = Array(selectedFocuses)

        let config = PlanConfig(
            planType: planType,
            weeks: weeks,
            daysPerWeek: daysPerWeek,
            minutesPerSession: minutesPerSession,
            focusAreas: focuses
        )

        let context = PlayerContext.from(storage: storage)
        let plan = AlgorithmicPlanBuilder.buildPlan(config: config, context: context)
        storage.saveGeneratedPlan(plan)
        onPlanGenerated(plan)

        isGenerating = false
        dismiss()
    }
}
