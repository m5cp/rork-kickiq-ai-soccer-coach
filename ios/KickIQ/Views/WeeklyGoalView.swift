import SwiftUI

struct WeeklyGoalSheet: View {
    let storage: StorageService
    @Environment(\.dismiss) private var dismiss
    @State private var sessionsPerWeek: Int = 3

    var body: some View {
        NavigationStack {
            VStack(spacing: KickIQTheme.Spacing.lg) {
                VStack(spacing: KickIQTheme.Spacing.sm) {
                    Image(systemName: "target")
                        .font(.system(size: 40))
                        .foregroundStyle(KickIQTheme.accent)

                    Text("Set Your Weekly Goal")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(KickIQTheme.textPrimary)

                    Text("How many training sessions do you want to complete each week?")
                        .font(.subheadline)
                        .foregroundStyle(KickIQTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, KickIQTheme.Spacing.lg)

                VStack(spacing: KickIQTheme.Spacing.md) {
                    Text("\(sessionsPerWeek)")
                        .font(.system(size: 64, weight: .black))
                        .foregroundStyle(KickIQTheme.accent)
                        .contentTransition(.numericText())

                    Text("sessions per week")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(KickIQTheme.textSecondary)

                    HStack(spacing: KickIQTheme.Spacing.lg) {
                        Button {
                            if sessionsPerWeek > 1 {
                                withAnimation(.spring(response: 0.3)) { sessionsPerWeek -= 1 }
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(sessionsPerWeek > 1 ? KickIQTheme.accent : KickIQTheme.textSecondary.opacity(0.3))
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
                                .foregroundStyle(sessionsPerWeek < 7 ? KickIQTheme.accent : KickIQTheme.textSecondary.opacity(0.3))
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
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, KickIQTheme.Spacing.md)
                        .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
                }
            }
            .padding(.horizontal, KickIQTheme.Spacing.md)
            .padding(.bottom, KickIQTheme.Spacing.md)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
        .onAppear {
            sessionsPerWeek = storage.weeklyGoal?.sessionsPerWeek ?? 3
        }
    }

    private var goalPreview: some View {
        HStack(spacing: KickIQTheme.Spacing.sm) {
            ForEach(1...7, id: \.self) { day in
                VStack(spacing: 4) {
                    Circle()
                        .fill(day <= sessionsPerWeek ? KickIQTheme.accent : KickIQTheme.divider)
                        .frame(width: 28, height: 28)
                        .overlay {
                            if day <= sessionsPerWeek {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.black)
                            }
                        }

                    Text(dayLabel(day))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
            }
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
    }

    private func dayLabel(_ day: Int) -> String {
        ["M", "T", "W", "T", "F", "S", "S"][day - 1]
    }
}
