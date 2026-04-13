import SwiftUI

struct TrainingPlanView: View {
    let storage: StorageService
    @Environment(\.dismiss) private var dismiss
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var appeared = false
    @State private var expandedDay: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQAICoachTheme.Spacing.md + 4) {
                    if let plan = storage.trainingPlan {
                        planHeader(plan)
                        ForEach(plan.days) { day in
                            dayCard(day)
                        }
                        regenerateButton
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                .padding(.bottom, KickIQAICoachTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQAICoachTheme.background.ignoresSafeArea())
            .navigationTitle("Training Plan")
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
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
        }
    }

    private func planHeader(_ plan: TrainingPlan) -> some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("YOUR PLAN")
                        .font(.caption.weight(.bold))
                        .tracking(1)
                        .foregroundStyle(KickIQAICoachTheme.accent)
                    Text("Personalized Weekly Schedule")
                        .font(.headline)
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                }
                Spacer()
                Text("Created \(plan.createdAt, format: .dateTime.month(.abbreviated).day())")
                    .font(.caption2)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
            }

            Text(plan.summary)
                .font(.subheadline)
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
                .lineSpacing(3)
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
    }

    private func dayCard(_ day: TrainingPlanDay) -> some View {
        let isExpanded = expandedDay == day.id

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    expandedDay = isExpanded ? nil : day.id
                }
            } label: {
                HStack(spacing: KickIQAICoachTheme.Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.sm)
                            .fill(day.restDay ? Color.blue.opacity(0.15) : KickIQAICoachTheme.accent.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: day.restDay ? "bed.double.fill" : "figure.soccer")
                            .font(.title3)
                            .foregroundStyle(day.restDay ? .blue : KickIQAICoachTheme.accent)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(day.dayLabel)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(KickIQAICoachTheme.textPrimary)
                        Text(day.focus)
                            .font(.caption)
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    }

                    Spacer()

                    if !day.restDay {
                        Text("\(day.drills.count) drills")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(KickIQAICoachTheme.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(KickIQAICoachTheme.accent.opacity(0.15), in: Capsule())
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.3))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .padding(KickIQAICoachTheme.Spacing.md)

            if isExpanded && !day.restDay {
                VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
                    ForEach(day.drills) { drill in
                        HStack(alignment: .top, spacing: KickIQAICoachTheme.Spacing.sm) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundStyle(KickIQAICoachTheme.accent)
                                .padding(.top, 6)

                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(drill.name)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                                    Spacer()
                                    Text(drill.duration)
                                        .font(.caption2)
                                        .foregroundStyle(KickIQAICoachTheme.accent)
                                }
                                Text(drill.description)
                                    .font(.caption2)
                                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
                .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                .padding(.bottom, KickIQAICoachTheme.Spacing.md)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
    }

    private var emptyState: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.lg) {
            Spacer().frame(height: 40)

            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(KickIQAICoachTheme.accent.opacity(0.5))

            VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                Text("No Training Plan Yet")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)

                Text("Generate a personalized weekly training plan based on your analysis results and weak areas.")
                    .font(.subheadline)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            generateButton
        }
        .frame(maxWidth: .infinity)
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
                Text(isGenerating ? "Generating Plan..." : "Generate Training Plan")
            }
            .font(.headline)
            .foregroundStyle(KickIQAICoachTheme.onAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, KickIQAICoachTheme.Spacing.md)
            .background(KickIQAICoachTheme.accent, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        }
        .disabled(isGenerating)
    }

    private var regenerateButton: some View {
        Button {
            Task { await generatePlan() }
        } label: {
            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                if isGenerating {
                    ProgressView()
                        .tint(KickIQAICoachTheme.accent)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                Text(isGenerating ? "Regenerating..." : "Regenerate Plan")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(KickIQAICoachTheme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(KickIQAICoachTheme.accent.opacity(0.15), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
        }
        .disabled(isGenerating)
    }

    private func generatePlan() async {
        isGenerating = true
        errorMessage = nil

        let position = storage.profile?.position ?? .midfielder
        let weakness = storage.profile?.weakness ?? .firstTouch
        let goalSessions = storage.weeklyGoal?.sessionsPerWeek ?? 3

        let context = PlayerContext.from(storage: storage)

        let weakSkills = storage.weakestSkills
        let focusAreas: [String]
        if !weakSkills.isEmpty {
            focusAreas = weakSkills.map(\.rawValue)
        } else {
            focusAreas = position.skills.map(\.rawValue)
        }

        let config = PlanConfig(
            planType: .skills,
            weeks: 1,
            daysPerWeek: goalSessions,
            minutesPerSession: 45,
            focusAreas: focusAreas
        )

        let generated = AlgorithmicPlanBuilder.buildPlan(config: config, context: context)

        let days = generated.weeks.first?.days ?? []
        let plan = TrainingPlan(
            days: days,
            summary: "A balanced \(goalSessions)-day training week focused on improving your \(weakness.rawValue.lowercased()) as a \(position.rawValue.lowercased()). Each session pulls from real, tested drills with coaching cues and progressive reps."
        )
        storage.saveTrainingPlan(plan)

        isGenerating = false
    }
}
