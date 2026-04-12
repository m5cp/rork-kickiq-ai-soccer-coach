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
    @State private var selectedTab: Int = 0
    @State private var celebratingBadge: MilestoneBadge?
    @State private var previousBadgeCount: Int = 0
    @State private var appPhase: AppPhase = .welcome

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
                    mainTabView
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

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: 0) {
                HomeView(storage: storage, selectedTab: $selectedTab)
            }

            Tab("Coach", systemImage: "brain.head.profile.fill", value: 1) {
                AICoachView(storage: storage)
            }

            Tab("Analyze", systemImage: "video.fill", value: 2) {
                AnalyzeView(storage: storage)
            }

            Tab("Drills", systemImage: "figure.soccer", value: 3) {
                DrillsView(storage: storage)
            }

            Tab("Progress", systemImage: "chart.line.uptrend.xyaxis", value: 4) {
                ProgressTabView(storage: storage)
            }

            Tab("Profile", systemImage: "person.fill", value: 5) {
                ProfileView(storage: storage)
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tint(KickIQAICoachTheme.accent)
        .environment(themeManager)
    }
}
