import SwiftUI
import UserNotifications

struct NotificationPreferencesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var streakReminders: Bool = true
    @State private var weeklySummary: Bool = true
    @State private var monthlyReassessment: Bool = true
    @State private var notificationsEnabled: Bool = false
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQAICoachTheme.Spacing.lg) {
                    if !notificationsEnabled {
                        notificationsDisabledBanner
                    }

                    VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
                        Text("REMINDERS")
                            .font(.caption.weight(.bold))
                            .tracking(1)
                            .foregroundStyle(KickIQAICoachTheme.accent)

                        toggleRow(
                            icon: "flame.fill",
                            title: "Streak Reminders",
                            subtitle: "Daily reminder at 8 PM to keep your streak alive",
                            isOn: $streakReminders
                        )

                        toggleRow(
                            icon: "chart.bar.fill",
                            title: "Weekly Summary",
                            subtitle: "Recap your drills and score changes every Monday",
                            isOn: $weeklySummary
                        )

                        toggleRow(
                            icon: "arrow.triangle.2.circlepath",
                            title: "Monthly Reassessment",
                            subtitle: "Prompt to update your focus area each month",
                            isOn: $monthlyReassessment
                        )
                    }
                }
                .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                .padding(.top, KickIQAICoachTheme.Spacing.md)
            }
            .scrollIndicators(.hidden)
            .background(KickIQAICoachTheme.background.ignoresSafeArea())
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        savePreferences()
                        dismiss()
                    }
                    .foregroundStyle(KickIQAICoachTheme.accent)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.background)
        .task {
            await checkNotificationStatus()
            loadPreferences()
            loaded = true
        }
    }

    private var notificationsDisabledBanner: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            Image(systemName: "bell.slash.fill")
                .font(.title2)
                .foregroundStyle(KickIQAICoachTheme.accent)

            Text("Notifications are disabled")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)

            Text("Enable notifications in Settings to receive streak reminders and weekly summaries.")
                .font(.caption)
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open Settings")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.onAccent)
                    .padding(.horizontal, KickIQAICoachTheme.Spacing.lg)
                    .padding(.vertical, KickIQAICoachTheme.Spacing.sm)
                    .background(KickIQAICoachTheme.accent, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.sm))
            }
            .padding(.top, KickIQAICoachTheme.Spacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                .fill(KickIQAICoachTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                        .stroke(KickIQAICoachTheme.accent.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func toggleRow(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: KickIQAICoachTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(KickIQAICoachTheme.accent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(KickIQAICoachTheme.accent)
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
    }

    private func checkNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationsEnabled = settings.authorizationStatus == .authorized
    }

    private func loadPreferences() {
        streakReminders = UserDefaults.standard.object(forKey: "kickiq_pref_streak") as? Bool ?? true
        weeklySummary = UserDefaults.standard.object(forKey: "kickiq_pref_weekly") as? Bool ?? true
        monthlyReassessment = UserDefaults.standard.object(forKey: "kickiq_pref_monthly") as? Bool ?? true
    }

    private func savePreferences() {
        UserDefaults.standard.set(streakReminders, forKey: "kickiq_pref_streak")
        UserDefaults.standard.set(weeklySummary, forKey: "kickiq_pref_weekly")
        UserDefaults.standard.set(monthlyReassessment, forKey: "kickiq_pref_monthly")

        let center = UNUserNotificationCenter.current()

        if !streakReminders {
            center.removePendingNotificationRequests(withIdentifiers: ["streak_reminder"])
        }
        if !weeklySummary {
            center.removePendingNotificationRequests(withIdentifiers: ["weekly_summary", "weekly_summary_custom"])
        }
        if !monthlyReassessment {
            center.removePendingNotificationRequests(withIdentifiers: ["monthly_reassessment"])
        }
    }
}
