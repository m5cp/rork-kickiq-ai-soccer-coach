import SwiftUI
import PhotosUI

struct ProfileView: View {
    let storage: StorageService
    let calendarService: CalendarService
    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false
    @State private var showEditProfile = false
    @State private var showSettings = false
    @State private var showCoachReport = false
    @State private var showTeam = false
    @State private var showAICoach = false
    @State private var showDeleteAlert = false
    @State private var showSignOutAlert = false
    @State private var showNotificationPrefs = false
    @State private var auth = AuthService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQTheme.Spacing.md + 4) {
                    avatarSection
                    statsRow
                    aiCoachCard
                    teamCard
                    coachReportCard
                    notificationCard
                    legalSection
                    supportSection
                    dangerSection
                    appFooter
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .padding(.bottom, KickIQTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(KickIQTheme.accent)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(KickIQTheme.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showEditProfile) {
                ProfileEditSheet(storage: storage)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(storage: storage, calendarService: calendarService)
            }
            .sheet(isPresented: $showCoachReport) {
                CoachReportView(storage: storage)
            }
            .sheet(isPresented: $showAICoach) {
                AICoachChatView(storage: storage)
            }
            .sheet(isPresented: $showTeam) {
                TeamView(storage: storage)
            }
            .sheet(isPresented: $showNotificationPrefs) {
                NotificationPreferencesSheet()
            }
            .alert("Delete All Data?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    storage.deleteAccount()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete your profile and all local data. This action cannot be undone.")
            }
            .alert("Sign Out?", isPresented: $showSignOutAlert) {
                Button("Sign Out", role: .destructive) {
                    Task { await auth.signOut() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You'll be signed out of team features. Your local data (drills, progress, scores) stays on your phone.")
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
    }

    private var avatarSection: some View {
        VStack(spacing: KickIQTheme.Spacing.md) {
            Button {
                showEditProfile = true
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    profileAvatarView(size: 96)

                    ZStack {
                        Circle()
                            .fill(KickIQTheme.accent)
                            .frame(width: 28, height: 28)
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.black)
                    }
                    .offset(x: 2, y: 2)
                }
            }

            VStack(spacing: KickIQTheme.Spacing.xs) {
                Text(storage.profile?.name ?? "Player")
                    .font(.system(.title2, design: .default, weight: .bold))
                    .foregroundStyle(KickIQTheme.textPrimary)

                HStack(spacing: KickIQTheme.Spacing.sm) {
                    if let pos = storage.profile?.position {
                        HStack(spacing: 4) {
                            Image(systemName: pos.icon)
                                .font(.caption)
                            Text(pos.rawValue)
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(KickIQTheme.accent)
                    }
                    if let level = storage.profile?.skillLevel {
                        Text("·")
                            .foregroundStyle(KickIQTheme.textSecondary.opacity(0.4))
                        Text(level.rawValue)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(KickIQTheme.textSecondary)
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 9))
                    Text("KICKIQ ATHLETE")
                        .font(.system(size: 10, weight: .black))
                        .tracking(1.5)
                }
                .foregroundStyle(KickIQTheme.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(KickIQTheme.accent.opacity(0.15), in: Capsule())
                .padding(.top, KickIQTheme.Spacing.xs)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, KickIQTheme.Spacing.lg)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.xl))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
    }

    @ViewBuilder
    private func profileAvatarView(size: CGFloat) -> some View {
        if let avatar = storage.profile?.avatar,
           let data = avatar.imageDataValue,
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(Circle().stroke(KickIQTheme.accent.opacity(0.3), lineWidth: 2))
        } else if let avatar = storage.profile?.avatar,
                  let symbol = avatar.symbolName {
            ZStack {
                Circle()
                    .fill(KickIQTheme.accent.opacity(0.15))
                    .frame(width: size, height: size)
                Image(systemName: symbol)
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(KickIQTheme.accent)
            }
            .overlay(Circle().stroke(KickIQTheme.accent.opacity(0.3), lineWidth: 2))
        } else {
            ZStack {
                Circle()
                    .fill(KickIQTheme.accent.opacity(0.15))
                    .frame(width: size, height: size)
                Image(systemName: storage.profile?.position.icon ?? "person.fill")
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(KickIQTheme.accent)
            }
            .overlay(Circle().stroke(KickIQTheme.accent.opacity(0.3), lineWidth: 2))
        }
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(value: "\(storage.skillScore)", label: "Skill Score", icon: "chart.bar.fill")
            Rectangle().fill(KickIQTheme.divider).frame(width: 1, height: 40)
            statItem(value: "\(storage.streakCount)", label: "Day Streak", icon: "flame.fill")
            Rectangle().fill(KickIQTheme.divider).frame(width: 1, height: 40)
            statItem(value: "\(storage.analysisCount)", label: "Analyses", icon: "video.fill")
            Rectangle().fill(KickIQTheme.divider).frame(width: 1, height: 40)
            statItem(value: "\(storage.xpPoints)", label: "XP", icon: "star.fill")
        }
        .padding(.vertical, KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.05), value: appeared)
    }

    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(KickIQTheme.accent)
                Text(value)
                    .font(.headline.weight(.black))
                    .foregroundStyle(KickIQTheme.textPrimary)
            }
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(KickIQTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var aiCoachCard: some View {
        Button {
            showAICoach = true
        } label: {
            HStack(spacing: KickIQTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "brain.head.profile.fill")
                        .font(.title3)
                        .foregroundStyle(.purple)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Coach")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KickIQTheme.textPrimary)
                    Text("Chat with your personal AI soccer coach")
                        .font(.caption)
                        .foregroundStyle(KickIQTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(KickIQTheme.textSecondary.opacity(0.3))
            }
            .padding(KickIQTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                    .fill(KickIQTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                            .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.07), value: appeared)
    }

    private var teamCard: some View {
        Button {
            showTeam = true
        } label: {
            HStack(spacing: KickIQTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "person.3.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Team")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KickIQTheme.textPrimary)
                    Text("Manage teams, leaderboards, and challenges")
                        .font(.caption)
                        .foregroundStyle(KickIQTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(KickIQTheme.textSecondary.opacity(0.3))
            }
            .padding(KickIQTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                    .fill(KickIQTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.09), value: appeared)
    }

    private var coachReportCard: some View {
        Button {
            showCoachReport = true
        } label: {
            HStack(spacing: KickIQTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(KickIQTheme.accent.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "doc.text.fill")
                        .font(.title3)
                        .foregroundStyle(KickIQTheme.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Coach Report")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KickIQTheme.textPrimary)
                    Text("Generate a detailed report to send to your coach")
                        .font(.caption)
                        .foregroundStyle(KickIQTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(KickIQTheme.textSecondary.opacity(0.3))
            }
            .padding(KickIQTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                    .fill(KickIQTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                            .stroke(KickIQTheme.accent.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.11), value: appeared)
    }

    private var notificationCard: some View {
        Button {
            showNotificationPrefs = true
        } label: {
            HStack(spacing: KickIQTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "bell.badge.fill")
                        .font(.title3)
                        .foregroundStyle(.orange)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Notifications")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KickIQTheme.textPrimary)
                    Text("Manage streak reminders & weekly summaries")
                        .font(.caption)
                        .foregroundStyle(KickIQTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(KickIQTheme.textSecondary.opacity(0.3))
            }
            .padding(KickIQTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                    .fill(KickIQTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                            .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.13), value: appeared)
    }

    private var legalSection: some View {
        VStack(spacing: 0) {
            sectionHeader("LEGAL & POLICIES")

            VStack(spacing: 2) {
                NavigationLink(destination: LegalPageView(page: .privacyPolicy)) {
                    legalRow(icon: "lock.shield.fill", title: "Privacy Policy")
                }
                NavigationLink(destination: LegalPageView(page: .termsOfUse)) {
                    legalRow(icon: "doc.text.fill", title: "Terms of Use")
                }
                NavigationLink(destination: LegalPageView(page: .eula)) {
                    legalRow(icon: "doc.badge.gearshape.fill", title: "End User License Agreement")
                }
                NavigationLink(destination: LegalPageView(page: .disclaimer)) {
                    legalRow(icon: "exclamationmark.triangle.fill", title: "Disclaimers")
                }
                NavigationLink(destination: LegalPageView(page: .risks)) {
                    legalRow(icon: "shield.lefthalf.filled", title: "Risks & Safety")
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.15), value: appeared)
    }

    private var supportSection: some View {
        VStack(spacing: 0) {
            sectionHeader("SUPPORT")

            VStack(spacing: 2) {
                NavigationLink(destination: SupportView()) {
                    legalRow(icon: "envelope.fill", title: "Contact Support")
                }
                settingsActionRow(icon: "creditcard.fill", title: "Manage Subscription") {
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        UIApplication.shared.open(url)
                    }
                }
                settingsActionRow(icon: "arrow.counterclockwise", title: "Restore Purchases") {
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.2), value: appeared)
    }

    private var dangerSection: some View {
        VStack(spacing: 0) {
            sectionHeader("ACCOUNT")

            VStack(spacing: 2) {
                if auth.isSignedIn {
                    settingsActionRow(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out") {
                        showSignOutAlert = true
                    }
                }
                settingsActionRow(icon: "trash.fill", title: "Delete All Data", isDestructive: true) {
                    showDeleteAlert = true
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.25), value: appeared)
    }

    private var appFooter: some View {
        VStack(spacing: 2) {
            Text("KickIQ v1.0")
                .font(.caption)
                .foregroundStyle(KickIQTheme.textSecondary.opacity(0.4))
            Text("AI-Powered Soccer Coaching")
                .font(.caption2)
                .foregroundStyle(KickIQTheme.textSecondary.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, KickIQTheme.Spacing.sm)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.bold))
            .tracking(1)
            .foregroundStyle(KickIQTheme.textSecondary.opacity(0.5))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, KickIQTheme.Spacing.sm)
            .padding(.bottom, KickIQTheme.Spacing.xs)
    }

    private func legalRow(icon: String, title: String) -> some View {
        HStack(spacing: KickIQTheme.Spacing.sm + 2) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(KickIQTheme.accent)
                .frame(width: 24)

            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(KickIQTheme.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(KickIQTheme.textSecondary.opacity(0.2))
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
    }

    private func settingsActionRow(icon: String, title: String, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
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
