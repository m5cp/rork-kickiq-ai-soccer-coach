import SwiftUI

struct SettingsView: View {
    let storage: StorageService
    var storeVM: StoreViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false
    @State private var showRestoreAlert = false
    @State private var restoreMessage = ""
    @State private var isRestoring = false
    @State private var showNotificationSettings = false
    @State private var appeared = false
    @State private var calendarService = CalendarService()
    @State private var showCalendarSuccess = false
    @State private var calendarEventsAdded = 0
    @State private var exportURL: URL?
    @State private var showExportShare = false
    @State private var showParentalControls = false
    @State private var showLegalPage: LegalPage?
    @State private var safety = AgeSafetyService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQAICoachTheme.Spacing.md) {
                    sectionHeader("APPEARANCE")
                    appearanceModeSection
                    teamColorSection

                    sectionHeader("PREFERENCES")
                    terminologyToggle
                    settingsRow(icon: "bell.fill", title: "Notification Preferences") {
                        showNotificationSettings = true
                    }

                    sectionHeader("SUBSCRIPTION")
                    subscriptionSection

                    sectionHeader("CALENDAR")
                    settingsRow(icon: "calendar.badge.plus", title: "Sync Training Plan to Calendar") {
                        Task { await syncCalendar() }
                    }

                    if safety.showsParentalControls {
                        sectionHeader("PARENTAL CONTROLS")
                        settingsRow(icon: "lock.shield.fill", title: "Manage Parental Controls") {
                            showParentalControls = true
                        }
                    }

                    sectionHeader("PRIVACY & LEGAL")
                    settingsRow(icon: "lock.shield.fill", title: "Privacy Policy") {
                        showLegalPage = .privacyPolicy
                    }
                    settingsRow(icon: "doc.text.fill", title: "Terms of Use") {
                        showLegalPage = .termsOfUse
                    }
                    settingsRow(icon: "exclamationmark.triangle.fill", title: "Disclaimers") {
                        showLegalPage = .disclaimer
                    }

                    sectionHeader("DATA")
                    settingsRow(icon: "square.and.arrow.up", title: "Export Training Data") {
                        if let url = DataExportService.exportURL(from: storage) {
                            exportURL = url
                            showExportShare = true
                        }
                    }
                    settingsRow(icon: "arrow.counterclockwise", title: "Reset Onboarding") {
                        storage.resetOnboarding()
                        dismiss()
                    }
                    settingsRow(icon: "trash.fill", title: "Delete All Data", isDestructive: true) {
                        showDeleteAlert = true
                    }

                    VStack(spacing: 2) {
                        Text("KickIQAICoach v2.0")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.4))
                        Text("AI-Powered \(storage.profile?.sportName ?? "Soccer") Coaching")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.3))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, KickIQAICoachTheme.Spacing.md)
                }
                .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                .padding(.bottom, KickIQAICoachTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQAICoachTheme.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(KickIQAICoachTheme.accent)
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
            .alert("Restore Purchases", isPresented: $showRestoreAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(restoreMessage)
            }
            .alert("Calendar Synced", isPresented: $showCalendarSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("\(calendarEventsAdded) training session\(calendarEventsAdded == 1 ? "" : "s") added to your calendar with reminders.")
            }
            .sheet(isPresented: $showNotificationSettings) {
                NotificationPreferencesSheet()
            }
            .sheet(isPresented: $showExportShare) {
                if let exportURL {
                    ShareSheet(items: [exportURL])
                }
            }
            .sheet(isPresented: $showParentalControls) {
                ParentalControlsView()
            }
            .sheet(item: $showLegalPage) { page in
                NavigationStack {
                    LegalPageView(page: page)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") { showLegalPage = nil }.fontWeight(.bold)
                            }
                        }
                }
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
        HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            ForEach(AppearanceMode.allCases) { mode in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        KickIQAICoachTheme.shared.setAppearanceMode(mode)
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: mode.icon)
                            .font(.title3)
                            .foregroundStyle(KickIQAICoachTheme.shared.appearanceMode == mode ? KickIQAICoachTheme.accent : KickIQAICoachTheme.textSecondary)
                        Text(mode.rawValue)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(KickIQAICoachTheme.shared.appearanceMode == mode ? KickIQAICoachTheme.textPrimary : KickIQAICoachTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.md)
                            .fill(KickIQAICoachTheme.shared.appearanceMode == mode ? KickIQAICoachTheme.accent.opacity(0.15) : KickIQAICoachTheme.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.md)
                                    .stroke(KickIQAICoachTheme.shared.appearanceMode == mode ? KickIQAICoachTheme.accent : Color.clear, lineWidth: 1.5)
                            )
                    )
                }
            }
        }
        .sensoryFeedback(.selection, trigger: KickIQAICoachTheme.shared.appearanceMode)
    }

    private var teamColorSection: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.md) {
            Text("TEAM COLORS")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.5))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: KickIQAICoachTheme.Spacing.sm)], spacing: KickIQAICoachTheme.Spacing.sm) {
                ForEach(TeamColor.allPresets, id: \.name) { color in
                    let isSelected = !KickIQAICoachTheme.shared.useCustomColor && KickIQAICoachTheme.shared.teamColor == color
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            KickIQAICoachTheme.shared.setTeamColor(color)
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
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(isSelected ? KickIQAICoachTheme.textPrimary : KickIQAICoachTheme.textSecondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, KickIQAICoachTheme.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.sm)
                                .fill(isSelected ? Color(hex: color.primary).opacity(0.15) : KickIQAICoachTheme.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.sm)
                                        .stroke(isSelected ? Color(hex: color.primary) : Color.clear, lineWidth: 1.5)
                                )
                        )
                    }
                }
            }

            customColorSection
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
    }

    @State private var pickerColor: Color = Color(hex: KickIQAICoachTheme.shared.activeTeamColor.primary)

    private var terminologyToggle: some View {
        let usesFootball = storage.profile?.usesFootballTerminology ?? false
        return HStack(spacing: KickIQAICoachTheme.Spacing.sm + 2) {
            Image(systemName: "globe")
                .font(.subheadline)
                .foregroundStyle(KickIQAICoachTheme.accent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text("Sport Terminology")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                Text(usesFootball ? "Using \"Football\"" : "Using \"Soccer\"")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
            }

            Spacer()

            Button {
                if var profile = storage.profile {
                    profile.usesFootballTerminology.toggle()
                    storage.saveProfile(profile)
                }
            } label: {
                Text(usesFootball ? "Football" : "Soccer")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.onAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(KickIQAICoachTheme.accent, in: Capsule())
            }
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
    }

    private var customColorSection: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            HStack {
                Text("CUSTOM COLOR")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.5))

                Spacer()

                if KickIQAICoachTheme.shared.useCustomColor {
                    Text("Active")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(KickIQAICoachTheme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(KickIQAICoachTheme.accent.opacity(0.15), in: Capsule())
                }
            }

            HStack(spacing: KickIQAICoachTheme.Spacing.md) {
                ColorPicker("", selection: $pickerColor, supportsOpacity: false)
                    .labelsHidden()
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Pick any color")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    Text("Match your team's exact colors")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }

                Spacer()

                Button {
                    applyCustomColor()
                } label: {
                    Text("Apply")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.onAccent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(KickIQAICoachTheme.accent, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.sm))
                }
            }
            .padding(KickIQAICoachTheme.Spacing.sm)
            .background(KickIQAICoachTheme.surface, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
        }
    }

    private func applyCustomColor() {
        let resolved = UIColor(pickerColor)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        resolved.getRed(&r, green: &g, blue: &b, alpha: nil)
        withAnimation(.spring(response: 0.3)) {
            KickIQAICoachTheme.shared.setCustomColor(red: Double(r), green: Double(g), blue: Double(b))
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.bold))
            .tracking(1)
            .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.5))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, KickIQAICoachTheme.Spacing.sm)
    }

    private func settingsRow(icon: String, title: String, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: KickIQAICoachTheme.Spacing.sm + 2) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(isDestructive ? .red : KickIQAICoachTheme.accent)
                    .frame(width: 24)

                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isDestructive ? .red : KickIQAICoachTheme.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.2))
            }
            .padding(KickIQAICoachTheme.Spacing.md)
            .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
        }
    }

    private var subscriptionSection: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            HStack(spacing: KickIQAICoachTheme.Spacing.sm + 2) {
                Image(systemName: storeVM.isPremium ? "crown.fill" : "figure.soccer")
                    .font(.subheadline)
                    .foregroundStyle(storeVM.isPremium ? .yellow : KickIQAICoachTheme.accent)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(storeVM.isPremium ? "KickIQ Premium" : "KickIQ Free")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    Text(storeVM.isPremium ? "Premium features unlocked" : "Upgrade to unlock everything")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }
                Spacer()
            }
            .padding(KickIQAICoachTheme.Spacing.md)
            .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))

            Button {
                Task { await handleRestore() }
            } label: {
                HStack(spacing: KickIQAICoachTheme.Spacing.sm + 2) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.subheadline)
                        .foregroundStyle(KickIQAICoachTheme.accent)
                        .frame(width: 24)
                    Text("Restore Purchases")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    Spacer()
                    if isRestoring {
                        ProgressView()
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.2))
                    }
                }
                .padding(KickIQAICoachTheme.Spacing.md)
                .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
                .frame(minHeight: 44)
            }
            .disabled(isRestoring)

            settingsRow(icon: "creditcard.fill", title: "Manage Subscription") {
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    UIApplication.shared.open(url)
                }
            }
        }
    }

    private func handleRestore() async {
        isRestoring = true
        let wasPremium = storeVM.isPremium
        await storeVM.restore()
        isRestoring = false
        if storeVM.isPremium && !wasPremium {
            restoreMessage = "Your premium subscription has been restored."
        } else if storeVM.isPremium {
            restoreMessage = "Your premium subscription is active."
        } else {
            restoreMessage = "No previous purchases were found on this Apple ID."
        }
        showRestoreAlert = true
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
