import SwiftUI
import PhotosUI
import StoreKit

struct ProfileView: View {
    let storage: StorageService
    var storeVM: StoreViewModel
    let customContentService: CustomContentService
    @State private var appeared = false
    @State private var showEditProfile = false
    @State private var showSettings = false
    @State private var showCoachReport = false
    @State private var showDeleteAlert = false
    @State private var showRestoreAlert = false
    @State private var restoreMessage = ""
    @State private var isRestoring = false
    @State private var showPaywall = false
    @State private var showTokenPacks = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQAICoachTheme.Spacing.md + 4) {
                    avatarSection
                    statsRow
                    tokenBalanceCard
                    myContentCard
                    coachReportCard
                    legalSection
                    supportSection
                    dangerSection
                    appFooter
                }
                .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                .padding(.bottom, KickIQAICoachTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQAICoachTheme.background.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showEditProfile) {
                ProfileEditSheet(storage: storage)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(storage: storage)
            }
            .sheet(isPresented: $showCoachReport) {
                CoachReportView(storage: storage)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(store: storeVM)
            }
            .sheet(isPresented: $showTokenPacks) {
                TokenPacksView(storage: storage, storeVM: storeVM, showSubscriptionUpsell: !storeVM.isPremium)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
    }

    private var avatarSection: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.md) {
            Button {
                showEditProfile = true
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    profileAvatarView(size: 96)

                    ZStack {
                        Circle()
                            .fill(KickIQAICoachTheme.accent)
                            .frame(width: 28, height: 28)
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(KickIQAICoachTheme.onAccent)
                    }
                    .offset(x: 2, y: 2)
                }
            }

            VStack(spacing: KickIQAICoachTheme.Spacing.xs) {
                Text(storage.profile?.name ?? "Player")
                    .font(.system(.title2, design: .default, weight: .black))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)

                HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                    if let pos = storage.profile?.position {
                        HStack(spacing: 4) {
                            Image(systemName: pos.icon)
                                .font(.caption)
                            Text(pos.rawValue)
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(KickIQAICoachTheme.accent)
                    }
                    if let level = storage.profile?.skillLevel {
                        Text("·")
                            .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.4))
                        Text(level.rawValue)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 9))
                    Text("KICKIQ ATHLETE")
                        .font(.system(size: 10, weight: .black))
                        .tracking(1.5)
                }
                .foregroundStyle(KickIQAICoachTheme.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(KickIQAICoachTheme.accent.opacity(0.15), in: Capsule())
                .padding(.top, KickIQAICoachTheme.Spacing.xs)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, KickIQAICoachTheme.Spacing.lg)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.xl))
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
                .overlay(Circle().stroke(KickIQAICoachTheme.accent.opacity(0.3), lineWidth: 2))
        } else if let avatar = storage.profile?.avatar,
                  let symbol = avatar.symbolName {
            ZStack {
                Circle()
                    .fill(KickIQAICoachTheme.accent.opacity(0.15))
                    .frame(width: size, height: size)
                Image(systemName: symbol)
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(KickIQAICoachTheme.accent)
            }
            .overlay(Circle().stroke(KickIQAICoachTheme.accent.opacity(0.3), lineWidth: 2))
        } else {
            ZStack {
                Circle()
                    .fill(KickIQAICoachTheme.accent.opacity(0.15))
                    .frame(width: size, height: size)
                Image(systemName: storage.profile?.position.icon ?? "person.fill")
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(KickIQAICoachTheme.accent)
            }
            .overlay(Circle().stroke(KickIQAICoachTheme.accent.opacity(0.3), lineWidth: 2))
        }
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(value: "\(storage.skillScore)", label: "Skill Score", icon: "chart.bar.fill")
            Rectangle().fill(KickIQAICoachTheme.divider).frame(width: 1, height: 40)
            statItem(value: "\(storage.streakCount)", label: "Day Streak", icon: "flame.fill")
            Rectangle().fill(KickIQAICoachTheme.divider).frame(width: 1, height: 40)
            statItem(value: "\(storage.analysisCount)", label: "Analyses", icon: "video.fill")
            Rectangle().fill(KickIQAICoachTheme.divider).frame(width: 1, height: 40)
            statItem(value: "\(storage.xpPoints)", label: "XP", icon: "star.fill")
        }
        .padding(.vertical, KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.05), value: appeared)
    }

    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(KickIQAICoachTheme.accent)
                Text(value)
                    .font(.headline.weight(.black))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
            }
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var myContentCard: some View {
        NavigationLink {
            CustomContentLibraryView(customContentService: customContentService, storage: storage)
        } label: {
            HStack(spacing: KickIQAICoachTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "doc.badge.plus")
                        .font(.title3)
                        .foregroundStyle(.orange)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("My Custom Content")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    let total = customContentService.totalCustomItems
                    Text(total > 0 ? "\(total) imported item\(total == 1 ? "" : "s")" : "Import drills, exercises & benchmarks from PDF")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }

                Spacer()

                if customContentService.totalCustomItems > 0 {
                    Text("\(customContentService.totalCustomItems)")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.12), in: Capsule())
                }

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.3))
            }
            .padding(KickIQAICoachTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                    .fill(KickIQAICoachTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                            .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.07), value: appeared)
    }

    private var coachReportCard: some View {
        Button {
            showCoachReport = true
        } label: {
            HStack(spacing: KickIQAICoachTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(KickIQAICoachTheme.accent.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "doc.text.fill")
                        .font(.title3)
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Coach Report")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    Text("Generate a detailed report to send to your coach")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.3))
            }
            .padding(KickIQAICoachTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                    .fill(KickIQAICoachTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                            .stroke(KickIQAICoachTheme.accent.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.1), value: appeared)
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
                    Task { await restorePurchases() }
                }

                if !storeVM.isPremium {
                    settingsActionRow(icon: "crown.fill", title: "Upgrade to Premium") {
                        showPaywall = true
                    }
                } else {
                    HStack(spacing: KickIQAICoachTheme.Spacing.sm + 2) {
                        Image(systemName: "crown.fill")
                            .font(.subheadline)
                            .foregroundStyle(KickIQAICoachTheme.accent)
                            .frame(width: 24)
                        Text("Premium Active")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.green)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    .padding(KickIQAICoachTheme.Spacing.md)
                    .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
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

            settingsActionRow(icon: "trash.fill", title: "Delete Account", isDestructive: true) {
                showDeleteAlert = true
            }
        }
        .alert("Delete Account?", isPresented: $showDeleteAlert) {
            Button("Delete Everything", role: .destructive) {
                storage.deleteAccount()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your profile, all training data, progress, and session history. This action cannot be undone.")
        }
        .alert("Restore Purchases", isPresented: $showRestoreAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(restoreMessage)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.25), value: appeared)
    }

    private var tokenBalanceCard: some View {
        Button {
            showTokenPacks = true
        } label: {
            HStack(spacing: KickIQAICoachTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(.orange.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "bolt.fill")
                        .font(.title3)
                        .foregroundStyle(.orange)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Token Balance")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    Text("\(storage.tokenBalance) bonus tokens available")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11))
                    Text(formattedTokenBalance)
                        .font(.headline.weight(.black))
                }
                .foregroundStyle(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.orange.opacity(0.12), in: Capsule())
            }
            .padding(KickIQAICoachTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                    .fill(KickIQAICoachTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                            .stroke(.orange.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .sensoryFeedback(.impact(weight: .light), trigger: showTokenPacks)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.06), value: appeared)
    }

    private var formattedTokenBalance: String {
        if storage.tokenBalance >= 1_000 {
            return String(format: "%.1fK", Double(storage.tokenBalance) / 1_000.0)
        }
        return "\(storage.tokenBalance)"
    }

    private var appFooter: some View {
        VStack(spacing: 2) {
            Text("KickIQAICoach v2.0")
                .font(.caption.weight(.bold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.4))
            Text("AI-Powered Soccer Coaching")
                .font(.caption2.weight(.bold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, KickIQAICoachTheme.Spacing.sm)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.bold))
            .tracking(1)
            .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.5))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, KickIQAICoachTheme.Spacing.sm)
            .padding(.bottom, KickIQAICoachTheme.Spacing.xs)
    }

    private func legalRow(icon: String, title: String) -> some View {
        HStack(spacing: KickIQAICoachTheme.Spacing.sm + 2) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(KickIQAICoachTheme.accent)
                .frame(width: 24)

            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.2))
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
    }

    private func restorePurchases() async {
        isRestoring = true
        do {
            try await AppStore.sync()
            restoreMessage = "Purchases restored successfully."
        } catch {
            restoreMessage = "No purchases found to restore, or an error occurred."
        }
        isRestoring = false
        showRestoreAlert = true
    }

    private func settingsActionRow(icon: String, title: String, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: KickIQAICoachTheme.Spacing.sm + 2) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(isDestructive ? .red : KickIQAICoachTheme.accent)
                    .frame(width: 24)

                Text(title)
                    .font(.subheadline.weight(.medium))
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
}
