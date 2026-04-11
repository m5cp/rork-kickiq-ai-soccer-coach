import SwiftUI

struct SettingsView: View {
    let storage: StorageService
    let calendarService: CalendarService
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false
    @State private var showNotificationSettings = false
    @State private var showCalendarSettings = false
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQTheme.Spacing.md) {
                    sectionHeader("PREFERENCES")
                    settingsRow(icon: "bell.fill", title: "Notification Preferences") {
                        showNotificationSettings = true
                    }
                    settingsRow(icon: "calendar", title: "Calendar Sync") {
                        showCalendarSettings = true
                    }

                    sectionHeader("DATA")
                    settingsRow(icon: "arrow.counterclockwise", title: "Reset Onboarding") {
                        storage.resetOnboarding()
                        dismiss()
                    }
                    settingsRow(icon: "trash.fill", title: "Delete All Data", isDestructive: true) {
                        showDeleteAlert = true
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
                    .padding(.top, KickIQTheme.Spacing.md)
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .padding(.bottom, KickIQTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
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
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.bold))
            .tracking(1)
            .foregroundStyle(KickIQTheme.textSecondary.opacity(0.5))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, KickIQTheme.Spacing.sm)
    }

    private func settingsRow(icon: String, title: String, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: KickIQTheme.Spacing.sm + 2) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(isDestructive ? .red : KickIQTheme.accent)
                    .frame(width: 24)

                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isDestructive ? .red : KickIQTheme.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(KickIQTheme.textSecondary.opacity(0.2))
            }
            .padding(KickIQTheme.Spacing.md)
            .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
        }
    }
}
