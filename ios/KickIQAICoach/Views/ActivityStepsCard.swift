import SwiftUI

struct ActivityStepsCard: View {
    @State private var pedometer = PedometerService.shared
    @State private var showPermissionIntro = false

    var body: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm + 2) {
            HStack(spacing: 8) {
                Image(systemName: "figure.walk.motion")
                    .foregroundStyle(KickIQAICoachTheme.accent)
                Text("Activity")
                    .font(.headline)
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                Spacer()
                Text("Today")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
            }

            if !pedometer.isAvailable {
                unavailableState
            } else if pedometer.todaySteps == 0 && !pedometer.isAuthorized {
                permissionState
            } else {
                content
            }
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .onAppear {
            pedometer.requestAndLoadToday()
        }
        .sheet(isPresented: $showPermissionIntro) {
            MotionPermissionIntro {
                pedometer.requestAndLoadToday()
                showPermissionIntro = false
            }
        }
    }

    private var content: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.md) {
            HStack(spacing: KickIQAICoachTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .stroke(KickIQAICoachTheme.divider, lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: pedometer.goalProgress)
                        .stroke(KickIQAICoachTheme.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("\(pedometer.todaySteps)")
                            .font(.title3.weight(.black))
                            .foregroundStyle(KickIQAICoachTheme.textPrimary)
                            .contentTransition(.numericText())
                        Text("steps")
                            .font(.caption2)
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    }
                }
                .frame(width: 90, height: 90)

                VStack(alignment: .leading, spacing: 6) {
                    statRow(label: "Goal", value: "\(pedometer.dailyGoal)")
                    statRow(label: "Distance", value: String(format: "%.2f mi", pedometer.todayDistanceMiles))
                    statRow(label: "Progress", value: "\(Int(pedometer.goalProgress * 100))%")
                }
            }

            if !pedometer.weeklySteps.isEmpty {
                weekChart
            }
        }
    }

    private var weekChart: some View {
        let maxSteps = max(pedometer.weeklySteps.map(\.steps).max() ?? 1, 1)
        return HStack(alignment: .bottom, spacing: 6) {
            ForEach(pedometer.weeklySteps) { day in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isToday(day.date) ? KickIQAICoachTheme.accent : KickIQAICoachTheme.accent.opacity(0.4))
                        .frame(height: max(CGFloat(day.steps) / CGFloat(maxSteps) * 60, 2))
                    Text(dayLabel(day.date))
                        .font(.system(size: 9).weight(.semibold))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 80)
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    private func dayLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "E"
        return String(f.string(from: date).prefix(1))
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
        }
    }

    private var permissionState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Track your daily activity")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
            Text("See steps, distance, and weekly trends while you train.")
                .font(.caption)
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
            Button {
                showPermissionIntro = true
            } label: {
                Text("Enable Motion Access")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.onAccent)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(KickIQAICoachTheme.accent, in: Capsule())
            }
        }
    }

    private var unavailableState: some View {
        Text("Step counting is not available on this device.")
            .font(.caption)
            .foregroundStyle(KickIQAICoachTheme.textSecondary)
    }
}

struct MotionPermissionIntro: View {
    @Environment(\.dismiss) private var dismiss
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.lg) {
            Spacer()
            Image(systemName: "figure.walk.motion")
                .font(.system(size: 64))
                .foregroundStyle(KickIQAICoachTheme.accent)
            Text("Track Your Training Load")
                .font(.title2.bold())
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
            Text("We use Motion & Fitness to count steps and distance during drills and across the day — like Apple Fitness. No data leaves your device.")
                .font(.subheadline)
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, KickIQAICoachTheme.Spacing.lg)
            Spacer()
            Button {
                onContinue()
                dismiss()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .foregroundStyle(KickIQAICoachTheme.onAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(KickIQAICoachTheme.accent, in: .rect(cornerRadius: 14))
            }
            Button("Not Now") { dismiss() }
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
        }
        .padding(KickIQAICoachTheme.Spacing.lg)
        .background(KickIQAICoachTheme.background.ignoresSafeArea())
    }
}
