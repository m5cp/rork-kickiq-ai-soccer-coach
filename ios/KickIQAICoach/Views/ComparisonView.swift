import SwiftUI

struct ComparisonView: View {
    let storage: StorageService
    @Environment(\.dismiss) private var dismiss
    @State private var sessionA: TrainingSession?
    @State private var sessionB: TrainingSession?
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQAICoachTheme.Spacing.md + 4) {
                    selectorSection
                    if let a = sessionA, let b = sessionB {
                        overallComparison(a: a, b: b)
                        skillDeltaSection(a: a, b: b)
                        insightSection(a: a, b: b)
                    } else {
                        selectionPrompt
                    }
                }
                .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                .padding(.bottom, KickIQAICoachTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQAICoachTheme.background.ignoresSafeArea())
            .navigationTitle("Compare Sessions")
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
            if storage.sessions.count >= 2 {
                sessionB = storage.sessions[0]
                sessionA = storage.sessions[1]
            }
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
        }
    }

    private var selectorSection: some View {
        HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            sessionPicker(label: "EARLIER", session: sessionA, excluding: sessionB) { sessionA = $0 }
            Image(systemName: "arrow.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(KickIQAICoachTheme.accent)
            sessionPicker(label: "LATER", session: sessionB, excluding: sessionA) { sessionB = $0 }
        }
        .opacity(appeared ? 1 : 0)
    }

    private func sessionPicker(label: String, session: TrainingSession?, excluding: TrainingSession?, onSelect: @escaping (TrainingSession) -> Void) -> some View {
        Menu {
            ForEach(storage.sessions.filter { $0.id != excluding?.id }) { s in
                Button {
                    onSelect(s)
                } label: {
                    Text("\(s.date.formatted(.dateTime.month(.abbreviated).day())) — \(s.overallScore)/100")
                }
            }
        } label: {
            VStack(spacing: KickIQAICoachTheme.Spacing.xs) {
                Text(label)
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(KickIQAICoachTheme.accent)

                if let session {
                    VStack(spacing: 2) {
                        Text("\(session.overallScore)")
                            .font(.title2.weight(.black))
                            .foregroundStyle(KickIQAICoachTheme.textPrimary)
                        Text(session.date, format: .dateTime.month(.abbreviated).day())
                            .font(.caption2)
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    }
                } else {
                    Text("Select")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, KickIQAICoachTheme.Spacing.md)
            .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        }
    }

    private var selectionPrompt: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.md) {
            Spacer().frame(height: 60)
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 44))
                .foregroundStyle(KickIQAICoachTheme.accent.opacity(0.4))
            Text("Select two sessions to compare")
                .font(.subheadline)
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func overallComparison(a: TrainingSession, b: TrainingSession) -> some View {
        let diff = b.overallScore - a.overallScore

        return VStack(spacing: KickIQAICoachTheme.Spacing.md) {
            Text("OVERALL CHANGE")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQAICoachTheme.accent)

            HStack(spacing: KickIQAICoachTheme.Spacing.lg) {
                VStack(spacing: 4) {
                    Text("\(a.overallScore)")
                        .font(.system(size: 36, weight: .black))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    Text(a.date, format: .dateTime.month(.abbreviated).day())
                        .font(.caption2)
                        .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.6))
                }

                VStack(spacing: 4) {
                    Image(systemName: diff >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(diff >= 0 ? .green : .red)
                    Text(diff >= 0 ? "+\(diff)" : "\(diff)")
                        .font(.headline.weight(.black))
                        .foregroundStyle(diff >= 0 ? .green : .red)
                }

                VStack(spacing: 4) {
                    Text("\(b.overallScore)")
                        .font(.system(size: 36, weight: .black))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    Text(b.date, format: .dateTime.month(.abbreviated).day())
                        .font(.caption2)
                        .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.6))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, KickIQAICoachTheme.Spacing.lg)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.xl))
        .opacity(appeared ? 1 : 0)
    }

    private func skillDeltaSection(a: TrainingSession, b: TrainingSession) -> some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm + 2) {
            Text("SKILL CHANGES")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQAICoachTheme.accent)

            ForEach(b.skillScores) { bScore in
                let aScore = a.skillScores.first(where: { $0.category == bScore.category })?.score ?? 0
                let delta = bScore.score - aScore

                HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                    Image(systemName: bScore.category.icon)
                        .font(.caption)
                        .foregroundStyle(KickIQAICoachTheme.accent)
                        .frame(width: 20)

                    Text(bScore.category.rawValue)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary.opacity(0.8))

                    Spacer()

                    HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                        Text("\(aScore)")
                            .font(.subheadline)
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)

                        Image(systemName: "arrow.right")
                            .font(.system(size: 10))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.4))

                        Text("\(bScore.score)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    }

                    Text(delta > 0 ? "+\(delta)" : delta < 0 ? "\(delta)" : "—")
                        .font(.caption.weight(.black))
                        .foregroundStyle(delta > 0 ? .green : delta < 0 ? .red : KickIQAICoachTheme.textSecondary)
                        .frame(width: 32, alignment: .trailing)
                }
                .padding(.vertical, KickIQAICoachTheme.Spacing.sm)
                .padding(.horizontal, KickIQAICoachTheme.Spacing.sm)
                .background(
                    delta != 0 ? (delta > 0 ? Color.green.opacity(0.06) : Color.red.opacity(0.06)) : Color.clear,
                    in: .rect(cornerRadius: KickIQAICoachTheme.Radius.sm)
                )
            }
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
    }

    private func insightSection(a: TrainingSession, b: TrainingSession) -> some View {
        let improvements = b.skillScores.compactMap { bScore -> (SkillCategory, Int)? in
            guard let aScore = a.skillScores.first(where: { $0.category == bScore.category }) else { return nil }
            let delta = bScore.score - aScore.score
            return delta > 0 ? (bScore.category, delta) : nil
        }.sorted { $0.1 > $1.1 }

        let declines = b.skillScores.compactMap { bScore -> (SkillCategory, Int)? in
            guard let aScore = a.skillScores.first(where: { $0.category == bScore.category }) else { return nil }
            let delta = bScore.score - aScore.score
            return delta < 0 ? (bScore.category, delta) : nil
        }.sorted { $0.1 < $1.1 }

        return VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.md) {
            Text("INSIGHTS")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQAICoachTheme.accent)

            if !improvements.isEmpty {
                VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundStyle(.green)
                        Text("Improved")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.green)
                    }

                    ForEach(improvements, id: \.0) { skill, delta in
                        Text("\(skill.rawValue) went up by \(delta) point\(delta > 1 ? "s" : "")")
                            .font(.caption)
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    }
                }
                .padding(KickIQAICoachTheme.Spacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.08), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.sm))
            }

            if !declines.isEmpty {
                VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(.red)
                        Text("Needs Work")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.red)
                    }

                    ForEach(declines, id: \.0) { skill, delta in
                        Text("\(skill.rawValue) dropped by \(abs(delta)) point\(abs(delta) > 1 ? "s" : "")")
                            .font(.caption)
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    }
                }
                .padding(KickIQAICoachTheme.Spacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.08), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.sm))
            }

            if improvements.isEmpty && declines.isEmpty {
                Text("No changes between these sessions. Keep training!")
                    .font(.caption)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
            }
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
    }
}
