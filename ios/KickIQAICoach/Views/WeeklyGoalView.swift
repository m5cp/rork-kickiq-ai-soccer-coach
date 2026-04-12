import SwiftUI

struct WeeklyGoalSheet: View {
    let storage: StorageService
    @Environment(\.dismiss) private var dismiss
    @State private var sessionsPerWeek: Int = 3

    var body: some View {
        NavigationStack {
            VStack(spacing: KickIQAICoachTheme.Spacing.lg) {
                VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                    Image(systemName: "target")
                        .font(.system(size: 40))
                        .foregroundStyle(KickIQAICoachTheme.accent)

                    Text("Set Your Weekly Goal")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)

                    Text("How many training sessions do you want to complete each week?")
                        .font(.subheadline)
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, KickIQAICoachTheme.Spacing.lg)

                VStack(spacing: KickIQAICoachTheme.Spacing.md) {
                    Text("\(sessionsPerWeek)")
                        .font(.system(size: 64, weight: .black))
                        .foregroundStyle(KickIQAICoachTheme.accent)
                        .contentTransition(.numericText())

                    Text("sessions per week")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)

                    HStack(spacing: KickIQAICoachTheme.Spacing.lg) {
                        Button {
                            if sessionsPerWeek > 1 {
                                withAnimation(.spring(response: 0.3)) { sessionsPerWeek -= 1 }
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(sessionsPerWeek > 1 ? KickIQAICoachTheme.accent : KickIQAICoachTheme.textSecondary.opacity(0.3))
                        }
                        .disabled(sessionsPerWeek <= 1)
                        .sensoryFeedback(.selection, trigger: sessionsPerWeek)

                        Button {
                            if sessionsPerWeek < 7 {
                                withAnimation(.spring(response: 0.3)) { sessionsPerWeek += 1 }
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(sessionsPerWeek < 7 ? KickIQAICoachTheme.accent : KickIQAICoachTheme.textSecondary.opacity(0.3))
                        }
                        .disabled(sessionsPerWeek >= 7)
                    }
                }

                Spacer()

                goalPreview

                Button {
                    storage.saveWeeklyGoal(WeeklyGoal(sessionsPerWeek: sessionsPerWeek))
                    dismiss()
                } label: {
                    Text("Set Goal")
                        .font(.headline)
                        .foregroundStyle(KickIQAICoachTheme.onAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, KickIQAICoachTheme.Spacing.md)
                        .background(KickIQAICoachTheme.accent, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
                }
            }
            .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
            .padding(.bottom, KickIQAICoachTheme.Spacing.md)
            .background(KickIQAICoachTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQAICoachTheme.background)
        .onAppear {
            sessionsPerWeek = storage.weeklyGoal?.sessionsPerWeek ?? 3
        }
    }

    private var goalPreview: some View {
        HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            ForEach(1...7, id: \.self) { day in
                VStack(spacing: 4) {
                    Circle()
                        .fill(day <= sessionsPerWeek ? KickIQAICoachTheme.accent : KickIQAICoachTheme.divider)
                        .frame(width: 28, height: 28)
                        .overlay {
                            if day <= sessionsPerWeek {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(KickIQAICoachTheme.onAccent)
                            }
                        }

                    Text(dayLabel(day))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }
            }
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
    }

    private func dayLabel(_ day: Int) -> String {
        ["M", "T", "W", "T", "F", "S", "S"][day - 1]
    }
}
