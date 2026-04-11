import SwiftUI

enum AppTab: Int, CaseIterable, Identifiable {
    case home = 0
    case analyze = 1
    case drills = 2
    case team = 3
    case progress = 4
    case profile = 5

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .analyze: "Analyze"
        case .drills: "Drills"
        case .team: "Team"
        case .progress: "Progress"
        case .profile: "Profile"
        }
    }

    var icon: String {
        switch self {
        case .home: "house.fill"
        case .analyze: "video.fill"
        case .drills: "figure.soccer"
        case .team: "person.3.fill"
        case .progress: "chart.line.uptrend.xyaxis"
        case .profile: "person.fill"
        }
    }
}

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var storage = StorageService()
    @State private var notificationService = NotificationService()
    @State private var calendarService = CalendarService()
    @State private var selectedTab: Int = 0
    @State private var celebratingBadge: MilestoneBadge?
    @State private var previousBadgeCount: Int = 0

    var body: some View {
        ZStack {
            Group {
                if storage.hasCompletedOnboarding {
                    if sizeClass == .regular {
                        iPadLayout
                    } else {
                        mainTabView
                    }
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
        .preferredColorScheme(ThemeManager.shared.colorScheme)
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

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: 0) {
                HomeView(storage: storage, calendarService: calendarService, selectedTab: $selectedTab)
            }

            Tab("Analyze", systemImage: "video.fill", value: 1) {
                AnalyzeView(storage: storage)
            }

            Tab("Drills", systemImage: "figure.soccer", value: 2) {
                DrillsView(storage: storage)
            }

            Tab("Team", systemImage: "person.3.fill", value: 3) {
                TeamView(storage: storage)
            }

            Tab("Progress", systemImage: "chart.line.uptrend.xyaxis", value: 4) {
                ProgressTabView(storage: storage)
            }

            Tab("Profile", systemImage: "person.fill", value: 5) {
                ProfileView(storage: storage, calendarService: calendarService)
            }
        }
        .tint(KickIQTheme.accent)
    }

    private var iPadLayout: some View {
        NavigationSplitView {
            iPadSidebar
                .navigationTitle("KickIQ")
        } detail: {
            iPadDetailView
        }
        .tint(KickIQTheme.accent)
        .navigationSplitViewStyle(.balanced)
    }

    private var iPadSidebar: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    ForEach(AppTab.allCases) { tab in
                        Button {
                            selectedTab = tab.rawValue
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: tab.icon)
                                    .font(.body)
                                    .foregroundStyle(selectedTab == tab.rawValue ? KickIQTheme.accent : KickIQTheme.textSecondary)
                                    .frame(width: 24)
                                Text(tab.title)
                                    .font(.body.weight(selectedTab == tab.rawValue ? .semibold : .regular))
                                    .foregroundStyle(selectedTab == tab.rawValue ? KickIQTheme.textPrimary : KickIQTheme.textSecondary)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(
                            selectedTab == tab.rawValue
                                ? KickIQTheme.accent.opacity(0.12)
                                : Color.clear
                        )
                    }
                }

                Section("Quick Stats") {
                    HStack(spacing: KickIQTheme.Spacing.md) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(storage.skillScore)")
                                .font(.title2.weight(.black))
                                .foregroundStyle(KickIQTheme.accent)
                            Text("Skill Score")
                                .font(.caption2)
                                .foregroundStyle(KickIQTheme.textSecondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.caption)
                                    .foregroundStyle(KickIQTheme.accent)
                                Text("\(storage.streakCount)")
                                    .font(.title2.weight(.black))
                                    .foregroundStyle(KickIQTheme.textPrimary)
                            }
                            Text("Day Streak")
                                .font(.caption2)
                                .foregroundStyle(KickIQTheme.textSecondary)
                        }
                    }
                    .listRowBackground(KickIQTheme.card)
                }

                Section("Player") {
                    HStack(spacing: KickIQTheme.Spacing.sm) {
                        Image(systemName: storage.playerLevel.icon)
                            .foregroundStyle(KickIQTheme.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(storage.profile?.name ?? "Player")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(KickIQTheme.textPrimary)
                            Text("\(storage.playerLevel.rawValue) · \(storage.xpPoints) XP")
                                .font(.caption2)
                                .foregroundStyle(KickIQTheme.textSecondary)
                        }
                    }
                    .listRowBackground(KickIQTheme.card)
                }
            }
            .scrollContentBackground(.hidden)
            .background(KickIQTheme.background)
        }
    }

    @ViewBuilder
    private var iPadDetailView: some View {
        switch selectedTab {
        case 0:
            HomeView(storage: storage, calendarService: calendarService, selectedTab: $selectedTab)
        case 1:
            AnalyzeView(storage: storage)
        case 2:
            DrillsView(storage: storage)
        case 3:
            TeamView(storage: storage)
        case 4:
            ProgressTabView(storage: storage)
        case 5:
            ProfileView(storage: storage, calendarService: calendarService)
        default:
            HomeView(storage: storage, calendarService: calendarService, selectedTab: $selectedTab)
        }
    }
}
