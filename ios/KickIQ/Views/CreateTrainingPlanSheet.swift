import SwiftUI

struct CreateTrainingPlanSheet: View {
    let teamId: String
    @Environment(\.dismiss) private var dismiss
    @State private var planService = CoachTrainingPlanService.shared
    @State private var title: String = ""
    @State private var planDescription: String = ""
    @State private var selectedDifficulty: String = "Intermediate"
    @State private var durationMinutes: Int = 30
    @State private var focusAreas: [String] = []
    @State private var drills: [EditableDrill] = []
    @State private var showAddDrill = false

    private let difficulties = ["Beginner", "Intermediate", "Advanced"]
    private let durations = [15, 20, 30, 45, 60, 90]
    private let allFocusAreas = ["Dribbling", "Passing", "Shooting", "First Touch", "Defending", "Fitness", "Positioning", "Ball Control"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQTheme.Spacing.lg) {
                    planInfoSection
                    settingsSection
                    focusAreasSection
                    drillsSection
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .padding(.bottom, KickIQTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle("New Training Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { createPlan() }
                        .fontWeight(.semibold)
                        .foregroundStyle(KickIQTheme.accent)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || drills.isEmpty)
                }
            }
            .sheet(isPresented: $showAddDrill) {
                AddDrillToPlansSheet(onAdd: { drill in
                    drills.append(drill)
                })
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
    }

    private var planInfoSection: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            Text("PLAN DETAILS")
                .font(.caption.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(KickIQTheme.textSecondary.opacity(0.5))

            TextField("Plan Title", text: $title)
                .font(.headline)
                .padding(KickIQTheme.Spacing.md)
                .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))

            TextField("Description (optional)", text: $planDescription, axis: .vertical)
                .font(.subheadline)
                .lineLimit(3...6)
                .padding(KickIQTheme.Spacing.md)
                .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            Text("SETTINGS")
                .font(.caption.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(KickIQTheme.textSecondary.opacity(0.5))

            HStack {
                Image(systemName: "gauge.with.dots.needle.67percent")
                    .foregroundStyle(KickIQTheme.accent)
                    .frame(width: 24)
                Text("Difficulty")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(KickIQTheme.textPrimary)
                Spacer()
                Picker("Difficulty", selection: $selectedDifficulty) {
                    ForEach(difficulties, id: \.self) { Text($0) }
                }
                .tint(KickIQTheme.accent)
            }
            .padding(KickIQTheme.Spacing.md)
            .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))

            HStack {
                Image(systemName: "clock.fill")
                    .foregroundStyle(KickIQTheme.accent)
                    .frame(width: 24)
                Text("Duration")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(KickIQTheme.textPrimary)
                Spacer()
                Picker("Duration", selection: $durationMinutes) {
                    ForEach(durations, id: \.self) { Text("\($0) min") }
                }
                .tint(KickIQTheme.accent)
            }
            .padding(KickIQTheme.Spacing.md)
            .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
        }
    }

    private var focusAreasSection: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            Text("FOCUS AREAS")
                .font(.caption.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(KickIQTheme.textSecondary.opacity(0.5))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                ForEach(allFocusAreas, id: \.self) { area in
                    let isSelected = focusAreas.contains(area)
                    Button {
                        if isSelected {
                            focusAreas.removeAll { $0 == area }
                        } else {
                            focusAreas.append(area)
                        }
                    } label: {
                        Text(area)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(isSelected ? .black : KickIQTheme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(isSelected ? KickIQTheme.accent : KickIQTheme.card, in: Capsule())
                    }
                    .sensoryFeedback(.selection, trigger: isSelected)
                }
            }
        }
    }

    private var drillsSection: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            HStack {
                Text("DRILLS (\(drills.count))")
                    .font(.caption.weight(.bold))
                    .tracking(0.8)
                    .foregroundStyle(KickIQTheme.textSecondary.opacity(0.5))
                Spacer()
                Button {
                    showAddDrill = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.caption)
                        Text("Add Drill")
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(KickIQTheme.accent)
                }
            }

            if drills.isEmpty {
                VStack(spacing: KickIQTheme.Spacing.sm) {
                    Image(systemName: "list.clipboard.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(KickIQTheme.textSecondary.opacity(0.3))
                    Text("Add drills to your training plan")
                        .font(.subheadline)
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, KickIQTheme.Spacing.xl)
            } else {
                ForEach(Array(drills.enumerated()), id: \.element.id) { idx, drill in
                    HStack(spacing: KickIQTheme.Spacing.md) {
                        Text("\(idx + 1)")
                            .font(.caption.weight(.black))
                            .foregroundStyle(KickIQTheme.accent)
                            .frame(width: 24, height: 24)
                            .background(KickIQTheme.accent.opacity(0.15), in: Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(drill.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(KickIQTheme.textPrimary)
                            if !drill.duration.isEmpty {
                                Text(drill.duration)
                                    .font(.caption)
                                    .foregroundStyle(KickIQTheme.textSecondary)
                            }
                        }

                        Spacer()

                        Button {
                            drills.remove(at: idx)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.body)
                                .foregroundStyle(KickIQTheme.textSecondary.opacity(0.4))
                        }
                    }
                    .padding(KickIQTheme.Spacing.md)
                    .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
                }
            }
        }
    }

    private func createPlan() {
        let planDrills = drills.enumerated().map { idx, drill in
            CoachPlanDrillDTO(
                id: drill.id,
                name: drill.name,
                description: drill.drillDescription.isEmpty ? nil : drill.drillDescription,
                duration: drill.duration.isEmpty ? nil : drill.duration,
                reps: drill.reps.isEmpty ? nil : drill.reps,
                coaching_cues: drill.coachingCues.filter { !$0.isEmpty },
                order: idx
            )
        }

        Task {
            let success = await planService.createPlan(
                teamId: teamId,
                title: title.trimmingCharacters(in: .whitespaces),
                description: planDescription.isEmpty ? nil : planDescription,
                ageGroup: nil,
                difficulty: selectedDifficulty,
                durationMinutes: durationMinutes,
                focusAreas: focusAreas,
                drills: planDrills
            )
            if success { dismiss() }
        }
    }
}

struct EditableDrill: Identifiable {
    let id: String = UUID().uuidString
    var name: String = ""
    var drillDescription: String = ""
    var duration: String = ""
    var reps: String = ""
    var coachingCues: [String] = [""]
}

struct AddDrillToPlansSheet: View {
    let onAdd: (EditableDrill) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var drill = EditableDrill()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQTheme.Spacing.md) {
                    TextField("Drill Name", text: $drill.name)
                        .font(.headline)
                        .padding(KickIQTheme.Spacing.md)
                        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))

                    TextField("Description", text: $drill.drillDescription, axis: .vertical)
                        .font(.subheadline)
                        .lineLimit(2...5)
                        .padding(KickIQTheme.Spacing.md)
                        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))

                    HStack(spacing: KickIQTheme.Spacing.sm) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Duration")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(KickIQTheme.textSecondary)
                            TextField("e.g. 10 min", text: $drill.duration)
                                .font(.subheadline)
                                .padding(KickIQTheme.Spacing.sm + 4)
                                .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.sm))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reps")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(KickIQTheme.textSecondary)
                            TextField("e.g. 3x10", text: $drill.reps)
                                .font(.subheadline)
                                .padding(KickIQTheme.Spacing.sm + 4)
                                .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.sm))
                        }
                    }

                    VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
                        Text("COACHING CUES")
                            .font(.caption.weight(.bold))
                            .tracking(0.8)
                            .foregroundStyle(KickIQTheme.textSecondary.opacity(0.5))

                        ForEach(drill.coachingCues.indices, id: \.self) { idx in
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .font(.caption)
                                    .foregroundStyle(KickIQTheme.accent)
                                TextField("Coaching cue \(idx + 1)", text: $drill.coachingCues[idx])
                                    .font(.subheadline)
                            }
                            .padding(KickIQTheme.Spacing.sm + 4)
                            .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.sm))
                        }

                        Button {
                            drill.coachingCues.append("")
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle")
                                    .font(.caption)
                                Text("Add Cue")
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(KickIQTheme.accent)
                        }
                    }
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .padding(.bottom, KickIQTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle("Add Drill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(drill)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(KickIQTheme.accent)
                    .disabled(drill.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
    }
}
