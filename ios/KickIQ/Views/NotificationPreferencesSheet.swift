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
                VStack(spacing: KickIQTheme.Spacing.lg) {
                    if !notificationsEnabled {
                        notificationsDisabledBanner
                    }

                    VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
                        Text("REMINDERS")
                            .font(.caption.weight(.bold))
                            .tracking(1)
                            .foregroundStyle(KickIQTheme.accent)

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
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .padding(.top, KickIQTheme.Spacing.md)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        savePreferences()
                        dismiss()
                    }
                    .foregroundStyle(KickIQTheme.accent)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
        .task {
            await checkNotificationStatus()
            loadPreferences()
            loaded = true
        }
    }

    private var notificationsDisabledBanner: some View {
        VStack(spacing: KickIQTheme.Spacing.sm) {
            Image(systemName: "bell.slash.fill")
                .font(.title2)
                .foregroundStyle(KickIQTheme.accent)

            Text("Notifications are off")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KickIQTheme.textPrimary)

            Text("Turn on notifications to get streak reminders, weekly recaps, and monthly check-ins.")
                .font(.caption)
                .foregroundStyle(KickIQTheme.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    let center = UNUserNotificationCenter.current()
                    let settings = await center.notificationSettings()
                    if settings.authorizationStatus == .notDetermined {
                        let granted = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
                        notificationsEnabled = granted ?? false
                        if notificationsEnabled {
                            scheduleAllEnabled()
                        }
                    } else {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            await UIApplication.shared.open(url)
                        }
                    }
                }
            } label: {
                Text("Enable Notifications")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, KickIQTheme.Spacing.lg)
                    .padding(.vertical, KickIQTheme.Spacing.sm)
                    .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.sm))
            }
            .padding(.top, KickIQTheme.Spacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(KickIQTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                .fill(KickIQTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                        .stroke(KickIQTheme.accent.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func toggleRow(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: KickIQTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(KickIQTheme.accent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(KickIQTheme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(KickIQTheme.textSecondary)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(KickIQTheme.accent)
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
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
        let service = NotificationService()

        if streakReminders {
            service.scheduleStreakReminder()
        } else {
            center.removePendingNotificationRequests(withIdentifiers: ["streak_reminder"])
        }
        if weeklySummary {
            service.scheduleWeeklySummary()
        } else {
            center.removePendingNotificationRequests(withIdentifiers: ["weekly_summary", "weekly_summary_custom"])
        }
        if monthlyReassessment {
            service.scheduleMonthlyReassessment()
        } else {
            center.removePendingNotificationRequests(withIdentifiers: ["monthly_reassessment"])
        }
    }

    private func scheduleAllEnabled() {
        let service = NotificationService()
        if streakReminders { service.scheduleStreakReminder() }
        if weeklySummary { service.scheduleWeeklySummary() }
        if monthlyReassessment { service.scheduleMonthlyReassessment() }
    }
}
