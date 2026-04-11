import SwiftUI

struct TeamView: View {
    let storage: StorageService
    @Environment(\.dismiss) private var dismiss
    @State private var auth = AuthService.shared
    @State private var teamService = TeamService.shared
    @State private var showCreateTeam = false
    @State private var showJoinTeam = false
    @State private var appeared = false
    @State private var showCoachTips = false

    private let coachTipsShownKey = "kickiq_coach_tips_shown"

    var body: some View {
        NavigationStack {
            Group {
                if auth.isSignedIn && !teamService.myTeams.isEmpty {
                    teamsListView
                } else if auth.isSignedIn && teamService.myTeams.isEmpty && !teamService.isLoading {
                    emptyTeamsView
                } else {
                    gettingStartedView
                }
            }
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle("Teams")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(KickIQTheme.accent)
                }
                if auth.isSignedIn {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button { showCreateTeam = true } label: {
                                Label("Create Team", systemImage: "plus.circle")
                            }
                            Button { showJoinTeam = true } label: {
                                Label("Join Team", systemImage: "person.badge.plus")
                            }
                        } label: {
                            Image(systemName: "plus")
                                .foregroundStyle(KickIQTheme.accent)
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateTeam) {
                CreateTeamSheet(storage: storage)
            }
            .sheet(isPresented: $showJoinTeam) {
                JoinTeamSheet(storage: storage)
            }
        }
        .task {
            if auth.isSignedIn {
                await teamService.loadMyTeams()
            }
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
            if !UserDefaults.standard.bool(forKey: coachTipsShownKey) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    showCoachTips = true
                }
            }
        }
        .overlay {
            if showCoachTips {
                CoachTipsOverlay(tips: CoachTipsData.teamFeatureTips) {
                    showCoachTips = false
                    UserDefaults.standard.set(true, forKey: coachTipsShownKey)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showCoachTips)
    }

    private var gettingStartedView: some View {
        VStack(spacing: KickIQTheme.Spacing.xl) {
            Spacer()

            VStack(spacing: KickIQTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(KickIQTheme.accent.opacity(0.1))
                        .frame(width: 100, height: 100)
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(KickIQTheme.accent.opacity(0.6))
                }

                Text("Team Features")
                    .font(.system(.title, design: .default, weight: .bold))
                    .foregroundStyle(KickIQTheme.textPrimary)

                Text("Create a team as a coach and invite players, or join a team with a code from your coach.")
                    .font(.subheadline)
                    .foregroundStyle(KickIQTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, KickIQTheme.Spacing.lg)
            }

            VStack(spacing: KickIQTheme.Spacing.md) {
                featureRow(icon: "shield.fill", title: "Coach Creates Team", desc: "Sign in, name your team, and get a unique invite code")
                featureRow(icon: "link", title: "Share Invite Code", desc: "Send the code to your players via text or in person")
                featureRow(icon: "person.badge.plus", title: "Players Join", desc: "Players sign in and enter the code to join the team")
                featureRow(icon: "iphone", title: "Solo Users", desc: "No sign-in needed — everything saves to your phone")
            }
            .padding(.horizontal, KickIQTheme.Spacing.md)

            Spacer()

            VStack(spacing: KickIQTheme.Spacing.sm) {
                Button { showCreateTeam = true } label: {
                    HStack(spacing: KickIQTheme.Spacing.sm) {
                        Image(systemName: "plus.circle.fill")
                        Text("Create a Team (Coach)")
                    }
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, KickIQTheme.Spacing.md)
                    .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
                }

                Button { showJoinTeam = true } label: {
                    HStack(spacing: KickIQTheme.Spacing.sm) {
                        Image(systemName: "person.badge.plus")
                        Text("Join with Code")
                    }
                    .font(.headline)
                    .foregroundStyle(KickIQTheme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, KickIQTheme.Spacing.md)
                    .background(KickIQTheme.accent.opacity(0.15), in: .rect(cornerRadius: KickIQTheme.Radius.lg))
                }
            }
            .padding(.horizontal, KickIQTheme.Spacing.md)
            .padding(.bottom, KickIQTheme.Spacing.xl)
        }
    }

    private var emptyTeamsView: some View {
        VStack(spacing: KickIQTheme.Spacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(KickIQTheme.accent.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "person.3.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(KickIQTheme.accent.opacity(0.6))
            }

            VStack(spacing: KickIQTheme.Spacing.sm) {
                Text("No Teams Yet")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(KickIQTheme.textPrimary)
                Text("Create a team as a coach, or join one with a code from your coach.")
                    .font(.subheadline)
                    .foregroundStyle(KickIQTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: KickIQTheme.Spacing.sm) {
                Button { showCreateTeam = true } label: {
                    HStack(spacing: KickIQTheme.Spacing.sm) {
                        Image(systemName: "plus.circle.fill")
                        Text("Create a Team")
                    }
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, KickIQTheme.Spacing.md)
                    .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
                }

                Button { showJoinTeam = true } label: {
                    HStack(spacing: KickIQTheme.Spacing.sm) {
                        Image(systemName: "person.badge.plus")
                        Text("Join with Code")
                    }
                    .font(.headline)
                    .foregroundStyle(KickIQTheme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, KickIQTheme.Spacing.md)
                    .background(KickIQTheme.accent.opacity(0.15), in: .rect(cornerRadius: KickIQTheme.Radius.lg))
                }
            }
            .padding(.horizontal, KickIQTheme.Spacing.lg)

            Spacer()
        }
        .padding(.horizontal, KickIQTheme.Spacing.md)
    }

    private var teamsListView: some View {
        ScrollView {
            LazyVStack(spacing: KickIQTheme.Spacing.md) {
                ForEach(teamService.myTeams) { team in
                    NavigationLink(destination: TeamDetailView(team: team, storage: storage)) {
                        teamCard(team)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                }
            }
            .padding(.horizontal, KickIQTheme.Spacing.md)
            .padding(.bottom, KickIQTheme.Spacing.xl)
        }
        .scrollIndicators(.hidden)
        .refreshable {
            await teamService.loadMyTeams()
        }
    }

    private func teamCard(_ team: TeamDTO) -> some View {
        HStack(spacing: KickIQTheme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: KickIQTheme.Radius.md)
                    .fill(KickIQTheme.accent.opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: "shield.fill")
                    .font(.title2)
                    .foregroundStyle(KickIQTheme.accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(team.name)
                    .font(.headline)
                    .foregroundStyle(KickIQTheme.textPrimary)

                HStack(spacing: 6) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 10))
                    Text(team.join_code)
                        .font(.caption.weight(.bold).monospaced())
                }
                .foregroundStyle(KickIQTheme.accent)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(KickIQTheme.textSecondary.opacity(0.3))
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
    }

    private func featureRow(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: KickIQTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(KickIQTheme.accent)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KickIQTheme.textPrimary)
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(KickIQTheme.textSecondary)
            }

            Spacer()
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
    }
}
