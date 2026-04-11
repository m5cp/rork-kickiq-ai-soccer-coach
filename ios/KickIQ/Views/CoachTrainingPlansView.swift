import SwiftUI

struct CoachTrainingPlansView: View {
    let teamId: String
    let isCoach: Bool
    @State private var planService = CoachTrainingPlanService.shared
    @State private var showCreatePlan = false
    @State private var selectedPlan: CoachTrainingPlanDTO?

    var body: some View {
        LazyVStack(spacing: KickIQTheme.Spacing.sm) {
            if isCoach {
                Button {
                    showCreatePlan = true
                } label: {
                    HStack(spacing: KickIQTheme.Spacing.sm) {
                        Image(systemName: "plus.circle.fill")
                            .font(.body)
                        Text("Create Training Plan")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(KickIQTheme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(KickIQTheme.accent.opacity(0.12), in: .rect(cornerRadius: KickIQTheme.Radius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: KickIQTheme.Radius.md)
                            .stroke(KickIQTheme.accent.opacity(0.3), lineWidth: 1)
                    )
                }
            }

            if planService.plans.isEmpty && !planService.isLoading {
                VStack(spacing: KickIQTheme.Spacing.sm) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(KickIQTheme.textSecondary.opacity(0.3))
                    Text(isCoach ? "Create your first training plan" : "No training plans yet")
                        .font(.subheadline)
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, KickIQTheme.Spacing.xxl)
            } else {
                ForEach(planService.plans) { plan in
                    Button {
                        selectedPlan = plan
                    } label: {
                        trainingPlanCard(plan)
                    }
                }
            }
        }
        .sheet(isPresented: $showCreatePlan) {
            CreateTrainingPlanSheet(teamId: teamId)
        }
        .sheet(item: $selectedPlan) { plan in
            TrainingPlanDetailSheet(plan: plan, isCoach: isCoach, teamId: teamId)
        }
        .task {
            await planService.loadPlans(teamId: teamId)
        }
    }

    private func trainingPlanCard(_ plan: CoachTrainingPlanDTO) -> some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 11))
                    Text("TRAINING PLAN")
                        .font(.caption.weight(.bold))
                        .tracking(1)
                }
                .foregroundStyle(KickIQTheme.accent)

                Spacer()

                if let coachName = plan.coach_name, !coachName.isEmpty {
                    Text(coachName)
                        .font(.caption)
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
            }

            Text(plan.title)
                .font(.headline)
                .foregroundStyle(KickIQTheme.textPrimary)
                .multilineTextAlignment(.leading)

            if let desc = plan.description, !desc.isEmpty {
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(KickIQTheme.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            HStack(spacing: KickIQTheme.Spacing.sm) {
                if let diff = plan.difficulty {
                    HStack(spacing: 4) {
                        Image(systemName: "gauge.with.dots.needle.67percent")
                            .font(.system(size: 10))
                        Text(diff)
                            .font(.caption2.weight(.bold))
                    }
                    .foregroundStyle(difficultyColor(diff))
                }

                if let mins = plan.duration_minutes {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text("\(mins) min")
                            .font(.caption2.weight(.bold))
                    }
                    .foregroundStyle(KickIQTheme.textSecondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 10))
                    Text("\(plan.drills.count) drills")
                        .font(.caption2.weight(.bold))
                }
                .foregroundStyle(KickIQTheme.textSecondary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(KickIQTheme.textSecondary.opacity(0.3))
            }

            if !plan.focus_areas.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 6) {
                        ForEach(plan.focus_areas, id: \.self) { area in
                            Text(area)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(KickIQTheme.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(KickIQTheme.accent.opacity(0.12), in: Capsule())
                        }
                    }
                }
                .contentMargins(.horizontal, 0)
                .scrollIndicators(.hidden)
            }
        }
        .padding(KickIQTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: KickIQTheme.Radius.md)
                .fill(KickIQTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: KickIQTheme.Radius.md)
                        .stroke(KickIQTheme.accent.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private func difficultyColor(_ difficulty: String) -> Color {
        switch difficulty.lowercased() {
        case "beginner": .green
        case "advanced": .red
        default: .orange
        }
    }
}

struct TrainingPlanDetailSheet: View {
    let plan: CoachTrainingPlanDTO
    let isCoach: Bool
    let teamId: String
    @Environment(\.dismiss) private var dismiss
    @State private var planService = CoachTrainingPlanService.shared
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: KickIQTheme.Spacing.lg) {
                    planHeader
                    drillsList
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .padding(.bottom, KickIQTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle(plan.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(KickIQTheme.accent)
                }
                if isCoach {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .alert("Delete Plan?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    Task {
                        await planService.deletePlan(planId: plan.id, teamId: teamId)
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This training plan will be permanently deleted.")
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
    }

    private var planHeader: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.md) {
            if let desc = plan.description, !desc.isEmpty {
                Text(desc)
                    .font(.subheadline)
                    .foregroundStyle(KickIQTheme.textSecondary)
            }

            HStack(spacing: KickIQTheme.Spacing.md) {
                if let diff = plan.difficulty {
                    statPill(icon: "gauge.with.dots.needle.67percent", label: diff)
                }
                if let mins = plan.duration_minutes {
                    statPill(icon: "clock.fill", label: "\(mins) min")
                }
                statPill(icon: "list.bullet", label: "\(plan.drills.count) drills")
            }

            if let coachName = plan.coach_name, !coachName.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "person.badge.shield.checkmark.fill")
                        .font(.caption)
                    Text("Created by \(coachName)")
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(KickIQTheme.textSecondary)
            }

            if !plan.focus_areas.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 6) {
                        ForEach(plan.focus_areas, id: \.self) { area in
                            Text(area)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(KickIQTheme.accent)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(KickIQTheme.accent.opacity(0.12), in: Capsule())
                        }
                    }
                }
                .contentMargins(.horizontal, 0)
                .scrollIndicators(.hidden)
            }
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
    }

    private func statPill(icon: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(label)
                .font(.caption2.weight(.bold))
        }
        .foregroundStyle(KickIQTheme.accent)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(KickIQTheme.accent.opacity(0.12), in: Capsule())
    }

    private var drillsList: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            Text("DRILLS")
                .font(.caption.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(KickIQTheme.textSecondary.opacity(0.5))

            ForEach(Array(plan.drills.sorted(by: { $0.order < $1.order }).enumerated()), id: \.element.id) { idx, drill in
                VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
                    HStack(spacing: KickIQTheme.Spacing.md) {
                        Text("\(idx + 1)")
                            .font(.caption.weight(.black))
                            .foregroundStyle(KickIQTheme.accent)
                            .frame(width: 28, height: 28)
                            .background(KickIQTheme.accent.opacity(0.15), in: Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(drill.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(KickIQTheme.textPrimary)

                            HStack(spacing: KickIQTheme.Spacing.sm) {
                                if let dur = drill.duration, !dur.isEmpty {
                                    HStack(spacing: 3) {
                                        Image(systemName: "clock")
                                            .font(.system(size: 9))
                                        Text(dur)
                                            .font(.caption2.weight(.medium))
                                    }
                                    .foregroundStyle(KickIQTheme.textSecondary)
                                }
                                if let reps = drill.reps, !reps.isEmpty {
                                    HStack(spacing: 3) {
                                        Image(systemName: "repeat")
                                            .font(.system(size: 9))
                                        Text(reps)
                                            .font(.caption2.weight(.medium))
                                    }
                                    .foregroundStyle(KickIQTheme.textSecondary)
                                }
                            }
                        }
                    }

                    if let desc = drill.description, !desc.isEmpty {
                        Text(desc)
                            .font(.caption)
                            .foregroundStyle(KickIQTheme.textSecondary)
                    }

                    if !drill.coaching_cues.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(drill.coaching_cues, id: \.self) { cue in
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.system(size: 9))
                                        .foregroundStyle(KickIQTheme.accent)
                                        .padding(.top, 2)
                                    Text(cue)
                                        .font(.caption)
                                        .foregroundStyle(KickIQTheme.textSecondary)
                                }
                            }
                        }
                        .padding(.leading, 28 + KickIQTheme.Spacing.md)
                    }
                }
                .padding(KickIQTheme.Spacing.md)
                .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
            }
        }
    }
}
