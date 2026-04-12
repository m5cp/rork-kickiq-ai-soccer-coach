import SwiftUI

struct ContentView: View {
    @State private var storage = StorageService()
    @State private var notificationService = NotificationService()
    @State private var selectedTab: Int = 0
    @State private var celebratingBadge: MilestoneBadge?
    @State private var previousBadgeCount: Int = 0

    var body: some View {
        ZStack {
            Group {
                if storage.hasCompletedOnboarding {
                    mainTabView
                } else {
                    OnboardingView(storage: storage)
                }
            }
            .animation(.spring(response: 0.5), value: storage.hasCompletedOnboarding)

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
        .preferredColorScheme(.dark)
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
        }
        .onChange(of: storage.hasCompletedOnboarding) { _, completed in
            guard completed else { return }
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

            Tab("Analyze", systemImage: "video.fill", value: 1) {
                AnalyzeView(storage: storage)
            }

            Tab("Drills", systemImage: "figure.soccer", value: 2) {
                DrillsView(storage: storage)
            }

            Tab("Progress", systemImage: "chart.line.uptrend.xyaxis", value: 3) {
                ProgressTabView(storage: storage)
            }

            Tab("Profile", systemImage: "person.fill", value: 4) {
                ProfileView(storage: storage)
            }
        }
        .tint(KickIQTheme.accent)
    }
}
