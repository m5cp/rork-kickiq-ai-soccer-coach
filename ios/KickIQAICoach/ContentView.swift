import SwiftUI

private enum AppPhase: Equatable {
    case welcome
    case onboarding
    case main
}

struct ContentView: View {
    @State private var storage = StorageService()
    @State private var notificationService = NotificationService()
    @State private var themeManager = KickIQAICoachTheme.shared
    @State private var storeVM = StoreViewModel()
    @State private var customContentService = CustomContentService()
    @State private var selectedTab: Int = 0
    @State private var celebratingBadge: MilestoneBadge?
    @State private var previousBadgeCount: Int = 0
    @State private var appPhase: AppPhase = .welcome
    @State private var showAICoach: Bool = false
    @State private var showPostBenchmarkPaywall: Bool = false

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Group {
                switch appPhase {
                case .welcome:
                    WelcomeView()
                        .transition(.opacity)
                case .onboarding:
                    OnboardingView(storage: storage)
                        .transition(.opacity)
                case .main:
                    ZStack(alignment: .bottomTrailing) {
                        mainTabView

                        floatingChatButton
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.8), value: appPhase)

            if let badge = celebratingBadge {
                MilestoneCelebrationView(
                    badge: badge,
                    onDismiss: { celebratingBadge = nil },
                    playerName: storage.profile?.name ?? "Player",
                    position: storage.profile?.position ?? .midfielder,
                    streakCount: storage.streakCount,
                    skillScore: storage.skillScore
                )
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .preferredColorScheme(themeManager.appearanceMode.colorScheme)
        .onChange(of: storage.isFirstBenchmarkJustCompleted) { _, flagged in
            guard flagged, !storeVM.isPremium else {
                storage.isFirstBenchmarkJustCompleted = false
                return
            }
            storage.isFirstBenchmarkJustCompleted = false
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.2))
                showPostBenchmarkPaywall = true
            }
        }
        .sheet(isPresented: $showPostBenchmarkPaywall) {
            PaywallView(store: storeVM)
        }
        .onChange(of: storage.earnedBadges.count) { oldValue, newValue in
            guard newValue > oldValue, oldValue > 0 else {
                previousBadgeCount = newValue
                return
            }
            let newBadges = storage.checkNewMilestones()
            if let first = newBadges.first {
                storage.markMilestonesShown(newBadges)
                withAnimation(.spring(response: 0.5)) {
                    celebratingBadge = first
                }
            }
            previousBadgeCount = newValue
        }
        .task {
            previousBadgeCount = storage.earnedBadges.count
            storage.markMilestonesShown(storage.earnedBadges)

            try? await Task.sleep(for: .seconds(2.5))
            withAnimation(.easeInOut(duration: 0.8)) {
                appPhase = storage.hasCompletedOnboarding ? .main : .onboarding
            }
            handlePendingIntent()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                handlePendingIntent()
            }
        }
        .onChange(of: storage.hasCompletedOnboarding) { _, completed in
            guard completed else { return }
            withAnimation(.easeInOut(duration: 0.6)) {
                appPhase = .main
            }
            Task {
                await notificationService.requestPermission()
                notificationService.scheduleStreakReminder()
                notificationService.scheduleMonthlyReassessment()
                let weeklyDrills = storage.completedDrillIDs.count
                let scoreChange = storage.sessions.count >= 2
                    ? storage.sessions[0].overallScore - storage.sessions[1].overallScore
                    : 0
                notificationService.scheduleCustomSummary(drillsCompleted: weeklyDrills, scoreChange: scoreChange)
            }
        }
    }

    private func handlePendingIntent() {
        guard let action = KickIQIntentBridge.consumePendingAction(), appPhase == .main else { return }
        AnalyticsService.shared.track(.siriIntentInvoked, properties: ["action": action.rawValue])
        withAnimation(.spring(response: 0.3)) {
            switch action {
            case .startNextDrill:
                selectedTab = 2
            case .showStreak:
                selectedTab = 3
            }
        }
    }

    private var isCoachMode: Bool {
        storage.profile?.position == .coachTrainer
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: 0) {
                ZStack(alignment: .topTrailing) {
                    HomeView(storage: storage, customContentService: customContentService, selectedTab: $selectedTab, storeVM: storeVM)
                        .environment(customContentService)

                    if isCoachMode {
                        Text("COACH")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(KickIQAICoachTheme.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(KickIQAICoachTheme.accent.opacity(0.15), in: Capsule())
                            .padding(.trailing, 16)
                            .padding(.top, 8)
                    }
                }
            }

            if isCoachMode {
                Tab("Plan", systemImage: "clipboard.fill", value: 1) {
                    CoachPlanView()
                }
            } else {
                Tab("Benchmark", systemImage: "chart.bar.doc.horizontal.fill", value: 1) {
                    BenchmarkView(storage: storage, customContentService: customContentService)
                }
            }

            Tab("Drills", systemImage: "figure.soccer", value: 2) {
                DrillsView(storage: storage, customContentService: customContentService, storeVM: storeVM)
            }

            Tab("Progress", systemImage: "chart.line.uptrend.xyaxis", value: 3) {
                ProgressTabView(storage: storage)
            }

            Tab("Profile", systemImage: "person.fill", value: 4) {
                ProfileView(storage: storage, storeVM: storeVM, customContentService: customContentService)
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tint(KickIQAICoachTheme.accent)
        .environment(themeManager)
        .onChange(of: notificationService.pendingDeepLink) { _, link in
            guard let link else { return }
            withAnimation(.spring(response: 0.3)) {
                selectedTab = link.tabIndex
            }
            notificationService.pendingDeepLink = nil
        }
        .sheet(isPresented: $showAICoach) {
            AICoachView(storage: storage, isPremium: storeVM.isPremium, storeVM: storeVM)
        }
    }

    private var floatingChatButton: some View {
        Button {
            showAICoach = true
        } label: {
            Image(systemName: "message.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [KickIQAICoachTheme.accent, KickIQAICoachTheme.accent.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: KickIQAICoachTheme.accent.opacity(0.4), radius: 12, x: 0, y: 4)
                )
        }
        .padding(.trailing, 20)
        .padding(.bottom, 90)
        .sensoryFeedback(.impact(weight: .medium), trigger: showAICoach)
    }
}
