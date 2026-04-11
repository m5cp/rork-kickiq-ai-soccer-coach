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
                if !auth.isSignedIn {
                    AuthView { Task { await teamService.loadMyTeams() } }
                } else if teamService.myTeams.isEmpty && !teamService.isLoading {
                    emptyTeamsView
                } else {
                    teamsListView
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
}
