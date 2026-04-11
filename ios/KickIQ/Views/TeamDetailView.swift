import SwiftUI

struct TeamDetailView: View {
    let team: TeamDTO
    let storage: StorageService
    @State private var teamService = TeamService.shared
    @State private var cloudDrill = CloudDrillService.shared
    @State private var challengeService = ChallengeService.shared
    @State private var feedService = ActivityFeedService.shared
    @State private var assignmentService = CoachAssignmentService.shared
    @State private var selectedSection: TeamSection = .roster
    @State private var showAssignDrill = false
    @State private var showCreateChallenge = false
    @State private var showLeaveAlert = false
    @State private var appeared = false

    private var myRole: TeamRole? {
        teamService.myRole(in: team.id)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: KickIQTheme.Spacing.lg) {
                teamHeader
                sectionPicker
                sectionContent
            }
            .padding(.horizontal, KickIQTheme.Spacing.md)
            .padding(.bottom, KickIQTheme.Spacing.xl)
        }
        .scrollIndicators(.hidden)
        .background(KickIQTheme.background.ignoresSafeArea())
        .navigationTitle(team.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if myRole?.isCoachOrOwner == true {
                        Button { showAssignDrill = true } label: {
                            Label("Assign Drill", systemImage: "clipboard")
                        }
                    }
                    Button { showCreateChallenge = true } label: {
                        Label("New Challenge", systemImage: "trophy")
                    }
                    Divider()
                    Button(role: .destructive) { showLeaveAlert = true } label: {
                        Label("Leave Team", systemImage: "arrow.right.square")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(KickIQTheme.accent)
                }
            }
        }
        .sheet(isPresented: $showAssignDrill) {
            AssignDrillSheet(teamId: team.id, members: teamService.teamMembers, storage: storage)
        }
        .sheet(isPresented: $showCreateChallenge) {
            CreateChallengeSheet(teamId: team.id, storage: storage)
        }
        .alert("Leave Team?", isPresented: $showLeaveAlert) {
            Button("Leave", role: .destructive) {
                Task { await teamService.leaveTeam(teamId: team.id) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll lose access to this team's data and activity.")
        }
        .task {
            await teamService.loadTeamMembers(teamId: team.id)
            await cloudDrill.loadLeaderboard(teamId: team.id)
            await challengeService.loadChallenges(teamId: team.id)
            await feedService.loadFeed(teamId: team.id)
            await assignmentService.loadMyAssignments(teamId: team.id)
            if myRole?.isCoachOrOwner == true {
                await assignmentService.loadAssignments(teamId: team.id)
            }
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
    }

    private var teamHeader: some View {
        VStack(spacing: KickIQTheme.Spacing.md) {
            HStack(spacing: KickIQTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 11))
                        Text(team.join_code)
                            .font(.caption.weight(.bold).monospaced())
                    }
                    .foregroundStyle(KickIQTheme.accent)

                    if let role = myRole {
                        HStack(spacing: 4) {
                            Image(systemName: role.icon)
                                .font(.system(size: 10))
                            Text(role.label)
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(KickIQTheme.textSecondary)
                    }
                }

                Spacer()

                HStack(spacing: KickIQTheme.Spacing.lg) {
                    VStack(spacing: 2) {
                        Text("\(teamService.teamMembers.count)")
                            .font(.title3.weight(.black))
                            .foregroundStyle(KickIQTheme.textPrimary)
                        Text("Players")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(KickIQTheme.textSecondary)
                    }

                    VStack(spacing: 2) {
                        Text("\(challengeService.challenges.count)")
                            .font(.title3.weight(.black))
                            .foregroundStyle(KickIQTheme.textPrimary)
                        Text("Challenges")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(KickIQTheme.textSecondary)
                    }
                }
            }
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
    }

    private var sectionPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(TeamSection.allCases) { section in
                    let isActive = selectedSection == section
                    Button {
                        withAnimation(.spring(response: 0.3)) { selectedSection = section }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: section.icon)
                                .font(.system(size: 11, weight: .semibold))
                            Text(section.label)
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(isActive ? .black : KickIQTheme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(isActive ? KickIQTheme.accent : KickIQTheme.card, in: Capsule())
                    }
                    .sensoryFeedback(.selection, trigger: isActive)
                }
            }
        }
        .contentMargins(.horizontal, 0)
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .roster:
            rosterSection
        case .leaderboard:
            leaderboardSection
        case .challenges:
            challengesSection
        case .feed:
            activityFeedSection
        case .assignments:
            assignmentsSection
        case .plans:
            CoachTrainingPlansView(teamId: team.id, isCoach: myRole?.isCoachOrOwner == true)
        }
    }

    private var rosterSection: some View {
        LazyVStack(spacing: KickIQTheme.Spacing.sm) {
            ForEach(teamService.teamMembers) { member in
                let role = TeamRole(rawValue: member.role) ?? .player
                HStack(spacing: KickIQTheme.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(KickIQTheme.accent.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: role.icon)
                            .font(.title3)
                            .foregroundStyle(KickIQTheme.accent)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(member.display_name ?? "Player")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KickIQTheme.textPrimary)
                        HStack(spacing: 6) {
                            Text(role.label)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(role.isCoachOrOwner ? KickIQTheme.accent : KickIQTheme.textSecondary)
                            if let pos = member.position {
                                Text("·")
                                    .foregroundStyle(KickIQTheme.textSecondary.opacity(0.4))
                                Text(pos)
                                    .font(.caption)
                                    .foregroundStyle(KickIQTheme.textSecondary)
                            }
                        }
                    }

                    Spacer()
                }
                .padding(KickIQTheme.Spacing.md)
                .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
            }
        }
    }

    private var leaderboardSection: some View {
        LazyVStack(spacing: KickIQTheme.Spacing.sm) {
            if cloudDrill.leaderboard.isEmpty {
                emptySection(icon: "chart.bar.fill", message: "No drill activity yet")
            } else {
                ForEach(cloudDrill.leaderboard) { entry in
                    HStack(spacing: KickIQTheme.Spacing.md) {
                        rankBadge(entry.rank)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.displayName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(KickIQTheme.textPrimary)
                            if let pos = entry.position {
                                Text(pos)
                                    .font(.caption)
                                    .foregroundStyle(KickIQTheme.textSecondary)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(Int(entry.value))")
                                .font(.title3.weight(.black))
                                .foregroundStyle(KickIQTheme.accent)
                            Text("drills")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(KickIQTheme.textSecondary)
                        }
                    }
                    .padding(KickIQTheme.Spacing.md)
                    .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
                }
            }
        }
    }

    private func rankBadge(_ rank: Int) -> some View {
        ZStack {
            Circle()
                .fill(rank <= 3 ? KickIQTheme.accent.opacity(0.2) : KickIQTheme.surface)
                .frame(width: 36, height: 36)

            if rank == 1 {
                Image(systemName: "crown.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(KickIQTheme.accent)
            } else {
                Text("#\(rank)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(rank <= 3 ? KickIQTheme.accent : KickIQTheme.textSecondary)
            }
        }
    }

    private var challengesSection: some View {
        LazyVStack(spacing: KickIQTheme.Spacing.sm) {
            if challengeService.challenges.isEmpty {
                emptySection(icon: "trophy.fill", message: "No challenges yet — create one!")
            } else {
                ForEach(challengeService.challenges) { challenge in
                    NavigationLink(destination: ChallengeDetailView(challenge: challenge, teamId: team.id)) {
                        challengeCard(challenge)
                    }
                }
            }
        }
    }

    private func challengeCard(_ challenge: ChallengeDTO) -> some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 11))
                    Text("CHALLENGE")
                        .font(.caption.weight(.bold))
                        .tracking(1)
                }
                .foregroundStyle(KickIQTheme.accent)

                Spacer()

                Text(challenge.creator_name ?? "Coach")
                    .font(.caption)
                    .foregroundStyle(KickIQTheme.textSecondary)
            }

            Text(challenge.drill_name)
                .font(.headline)
                .foregroundStyle(KickIQTheme.textPrimary)

            HStack(spacing: KickIQTheme.Spacing.sm) {
                HStack(spacing: 4) {
                    Image(systemName: "target")
                        .font(.system(size: 10))
                    Text("\(Int(challenge.target_value)) \(challenge.metric_type)")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(KickIQTheme.accent)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(KickIQTheme.textSecondary.opacity(0.3))
            }
        }
        .padding(KickIQTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: KickIQTheme.Radius.md)
                .fill(KickIQTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: KickIQTheme.Radius.md)
                        .stroke(KickIQTheme.accent.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var activityFeedSection: some View {
        LazyVStack(spacing: KickIQTheme.Spacing.sm) {
            if feedService.events.isEmpty {
                emptySection(icon: "bubble.left.fill", message: "Activity will appear here")
            } else {
                ForEach(feedService.events) { event in
                    activityRow(event)
                }
            }
        }
    }

    private func activityRow(_ event: ActivityEventDTO) -> some View {
        HStack(spacing: KickIQTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(KickIQTheme.accent.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: event.icon ?? "bolt.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(KickIQTheme.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(KickIQTheme.textPrimary)
                if let subtitle = event.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
            }

            Spacer()

            Text(relativeTime(event.created_at))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(KickIQTheme.textSecondary.opacity(0.5))
        }
        .padding(KickIQTheme.Spacing.sm + 4)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
    }

    private var assignmentsSection: some View {
        let items = myRole?.isCoachOrOwner == true ? assignmentService.assignments : assignmentService.myAssignments

        return LazyVStack(spacing: KickIQTheme.Spacing.sm) {
            if items.isEmpty {
                emptySection(icon: "clipboard.fill", message: myRole?.isCoachOrOwner == true ? "Assign drills from the menu" : "No assigned drills yet")
            } else {
                ForEach(items) { assignment in
                    assignmentRow(assignment)
                }
            }
        }
    }

    private func assignmentRow(_ assignment: AssignedDrillDTO) -> some View {
        HStack(spacing: KickIQTheme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(assignment.completed ? Color.green.opacity(0.15) : KickIQTheme.accent.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: assignment.completed ? "checkmark.circle.fill" : "clipboard.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(assignment.completed ? .green : KickIQTheme.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(assignment.drill_name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KickIQTheme.textPrimary)
                if let note = assignment.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(KickIQTheme.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if !assignment.completed && myRole == .player {
                Button {
                    Task { await assignmentService.markComplete(assignmentId: assignment.id) }
                } label: {
                    Text("Done")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(KickIQTheme.accent, in: Capsule())
                }
            }
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
    }

    private func emptySection(icon: String, message: String) -> some View {
        VStack(spacing: KickIQTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(KickIQTheme.textSecondary.opacity(0.3))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(KickIQTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, KickIQTheme.Spacing.xxl)
    }

    private func relativeTime(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: isoString) else {
            let basic = ISO8601DateFormatter()
            guard let d = basic.date(from: isoString) else { return "" }
            return RelativeDateTimeFormatter().localizedString(for: d, relativeTo: .now)
        }
        return RelativeDateTimeFormatter().localizedString(for: date, relativeTo: .now)
    }
}

enum TeamSection: String, CaseIterable, Identifiable {
    case roster = "Roster"
    case leaderboard = "Leaders"
    case challenges = "Challenges"
    case feed = "Feed"
    case assignments = "Assigned"
    case plans = "Plans"

    var id: String { rawValue }

    var label: String { rawValue }

    var icon: String {
        switch self {
        case .roster: "person.3.fill"
        case .leaderboard: "chart.bar.fill"
        case .challenges: "trophy.fill"
        case .feed: "bubble.left.fill"
        case .assignments: "clipboard.fill"
        case .plans: "doc.text.fill"
        }
    }
}
