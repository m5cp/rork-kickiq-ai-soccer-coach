import SwiftUI

struct SettingsView: View {
    let storage: StorageService
    let calendarService: CalendarService
    @Environment(\.dismiss) private var dismiss
    @State private var themeManager = ThemeManager.shared
    @State private var showDeleteAlert = false
    @State private var showNotificationSettings = false
    @State private var showCalendarSettings = false
    @State private var showThemeSettings = false
    @State private var showDataBackup = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    appearanceModeSection

                    settingsSection("PREFERENCES") {
                        settingsRow(icon: "paintbrush.fill", title: "Colors & Theme") {
                            showThemeSettings = true
                        }
                        settingsRow(icon: "bell.fill", title: "Notifications") {
                            showNotificationSettings = true
                        }
                        settingsRow(icon: "calendar", title: "Calendar Sync") {
                            showCalendarSettings = true
                        }
                    }

                    settingsSection("DATA") {
                        settingsRow(icon: "externaldrive.fill", title: "Backup & Restore") {
                            showDataBackup = true
                        }
                        settingsRow(icon: "arrow.counterclockwise", title: "Reset Onboarding") {
                            storage.resetOnboarding()
                            dismiss()
                        }
                        settingsRow(icon: "trash.fill", title: "Delete All Data", isDestructive: true) {
                            showDeleteAlert = true
                        }
                    }

                    VStack(spacing: 2) {
                        Text("KickIQ v1.0")
                            .font(.caption)
                            .foregroundStyle(KickIQTheme.textSecondary.opacity(0.4))
                        Text("AI-Powered Soccer Coaching")
                            .font(.caption2)
                            .foregroundStyle(KickIQTheme.textSecondary.opacity(0.3))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(KickIQTheme.accent)
                }
            }
            .alert("Delete All Data?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    storage.deleteAccount()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete your profile and all session data. This action cannot be undone.")
            }
            .sheet(isPresented: $showNotificationSettings) {
                NotificationPreferencesSheet()
            }
            .sheet(isPresented: $showCalendarSettings) {
                CalendarSettingsSheet(calendarService: calendarService, storage: storage)
            }
            .sheet(isPresented: $showThemeSettings) {
                ThemeSettingsView()
            }
            .sheet(isPresented: $showDataBackup) {
                DataBackupView(storage: storage)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
    }

    private var appearanceModeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("APPEARANCE")
                .font(.caption.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(KickIQTheme.textSecondary.opacity(0.5))

            HStack(spacing: 0) {
                ForEach(AppearanceMode.allCases, id: \.rawValue) { mode in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            themeManager.appearanceMode = mode
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 18, weight: .medium))
                                .symbolEffect(.bounce, value: themeManager.appearanceMode == mode)
                            Text(mode.rawValue)
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(themeManager.appearanceMode == mode ? KickIQTheme.buttonLabel : KickIQTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background {
                            if themeManager.appearanceMode == mode {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(KickIQTheme.accent)
                            }
                        }
                    }
                    .sensoryFeedback(.selection, trigger: themeManager.appearanceMode == mode)
                }
            }
            .padding(4)
            .background(KickIQTheme.card, in: .rect(cornerRadius: 14))
        }
    }

    private func settingsSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(KickIQTheme.textSecondary.opacity(0.5))

            VStack(spacing: 2) {
                content()
            }
        }
    }

    private func settingsRow(icon: String, title: String, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(isDestructive ? .red : KickIQTheme.accent)
                    .frame(width: 24, alignment: .center)

                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isDestructive ? .red : KickIQTheme.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(KickIQTheme.textSecondary.opacity(0.25))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(KickIQTheme.card, in: .rect(cornerRadius: 12))
        }
    }
}
