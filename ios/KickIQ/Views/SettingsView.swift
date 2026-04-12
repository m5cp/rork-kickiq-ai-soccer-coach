import SwiftUI

struct SettingsView: View {
    let storage: StorageService
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false
    @State private var showNotificationSettings = false
    @State private var appeared = false
    @State private var calendarService = CalendarService()
    @State private var showCalendarSuccess = false
    @State private var calendarEventsAdded = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQTheme.Spacing.md) {
                    sectionHeader("APPEARANCE")
                    appearanceModeSection
                    teamColorSection

                    sectionHeader("PREFERENCES")
                    settingsRow(icon: "bell.fill", title: "Notification Preferences") {
                        showNotificationSettings = true
                    }

                    sectionHeader("CALENDAR")
                    settingsRow(icon: "calendar.badge.plus", title: "Sync Training Plan to Calendar") {
                        Task { await syncCalendar() }
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
                        Text("KickIQ v2.0")
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
            .alert("Calendar Synced", isPresented: $showCalendarSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("\(calendarEventsAdded) training session\(calendarEventsAdded == 1 ? "" : "s") added to your calendar with reminders.")
            }
            .sheet(isPresented: $showNotificationSettings) {
                NotificationPreferencesSheet()
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.background)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
        }
    }

    private var appearanceModeSection: some View {
        HStack(spacing: KickIQTheme.Spacing.sm) {
            ForEach(AppearanceMode.allCases) { mode in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        KickIQTheme.shared.setAppearanceMode(mode)
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: mode.icon)
                            .font(.title3)
                            .foregroundStyle(KickIQTheme.shared.appearanceMode == mode ? KickIQTheme.accent : KickIQTheme.textSecondary)
                        Text(mode.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(KickIQTheme.shared.appearanceMode == mode ? KickIQTheme.textPrimary : KickIQTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: KickIQTheme.Radius.md)
                            .fill(KickIQTheme.shared.appearanceMode == mode ? KickIQTheme.accent.opacity(0.15) : KickIQTheme.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: KickIQTheme.Radius.md)
                                    .stroke(KickIQTheme.shared.appearanceMode == mode ? KickIQTheme.accent : Color.clear, lineWidth: 1.5)
                            )
                    )
                }
            }
        }
        .sensoryFeedback(.selection, trigger: KickIQTheme.shared.appearanceMode)
    }

    private var teamColorSection: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.md) {
            Text("TEAM COLORS")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQTheme.textSecondary.opacity(0.5))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: KickIQTheme.Spacing.sm)], spacing: KickIQTheme.Spacing.sm) {
                ForEach(TeamColor.allPresets, id: \.name) { color in
                    let isSelected = !KickIQTheme.shared.useCustomColor && KickIQTheme.shared.teamColor == color
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            KickIQTheme.shared.setTeamColor(color)
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Circle()
                                .fill(Color(hex: color.primary))
                                .frame(width: 32, height: 32)
                                .overlay {
                                    if isSelected {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(color.onPrimaryColor)
                                    }
                                }

                            Text(color.name)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(isSelected ? KickIQTheme.textPrimary : KickIQTheme.textSecondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, KickIQTheme.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: KickIQTheme.Radius.sm)
                                .fill(isSelected ? Color(hex: color.primary).opacity(0.15) : KickIQTheme.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: KickIQTheme.Radius.sm)
                                        .stroke(isSelected ? Color(hex: color.primary) : Color.clear, lineWidth: 1.5)
                                )
                        )
                    }
                }
            }

            customColorSection
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
    }

    @State private var pickerColor: Color = Color(hex: KickIQTheme.shared.activeTeamColor.primary)

    private var customColorSection: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            HStack {
                Text("CUSTOM COLOR")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(KickIQTheme.textSecondary.opacity(0.5))

                Spacer()

                if KickIQTheme.shared.useCustomColor {
                    Text("Active")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(KickIQTheme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(KickIQTheme.accent.opacity(0.15), in: Capsule())
                }
            }

            HStack(spacing: KickIQTheme.Spacing.md) {
                ColorPicker("", selection: $pickerColor, supportsOpacity: false)
                    .labelsHidden()
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Pick any color")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(KickIQTheme.textPrimary)
                    Text("Match your team's exact colors")
                        .font(.caption)
                        .foregroundStyle(KickIQTheme.textSecondary)
                }

                Spacer()

                Button {
                    applyCustomColor()
                } label: {
                    Text("Apply")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(KickIQTheme.onAccent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.sm))
                }
            }
            .padding(KickIQTheme.Spacing.sm)
            .background(KickIQTheme.surface, in: .rect(cornerRadius: KickIQTheme.Radius.md))
        }
    }

    private func applyCustomColor() {
        let resolved = UIColor(pickerColor)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        resolved.getRed(&r, green: &g, blue: &b, alpha: nil)
        withAnimation(.spring(response: 0.3)) {
            KickIQTheme.shared.setCustomColor(red: Double(r), green: Double(g), blue: Double(b))
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

    private func syncCalendar() async {
        await calendarService.requestAccess()
        guard calendarService.isAuthorized else { return }
        guard let plan = storage.trainingPlan else { return }
        let count = await calendarService.addTrainingPlanToCalendar(plan: plan)
        calendarEventsAdded = count
        showCalendarSuccess = true
    }
}
