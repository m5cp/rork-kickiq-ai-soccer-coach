import SwiftUI

struct CreateTeamSheet: View {
    let storage: StorageService
    @Environment(\.dismiss) private var dismiss
    @State private var teamService = TeamService.shared
    @State private var teamName: String = ""
    @State private var ageGroup: String = ""
    @State private var createdTeam: TeamDTO?

    private let ageGroups = ["U10", "U12", "U14", "U16", "U18", "Adult", "Mixed"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQTheme.Spacing.lg) {
                    if let team = createdTeam {
                        successView(team)
                    } else {
                        formView
                    }
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .padding(.top, KickIQTheme.Spacing.md)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle(createdTeam != nil ? "Team Created" : "Create Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(createdTeam != nil ? "Done" : "Cancel") { dismiss() }
                        .foregroundStyle(KickIQTheme.accent)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
    }

    private var formView: some View {
        VStack(spacing: KickIQTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(KickIQTheme.accent.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "shield.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(KickIQTheme.accent)
            }

            VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
                Text("TEAM NAME")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(KickIQTheme.textSecondary)
                TextField("e.g. Thunder FC", text: $teamName)
                    .font(.headline)
                    .padding(KickIQTheme.Spacing.md)
                    .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
            }

            VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
                Text("AGE GROUP (OPTIONAL)")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(KickIQTheme.textSecondary)

                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(ageGroups, id: \.self) { group in
                            Button {
                                ageGroup = ageGroup == group ? "" : group
                            } label: {
                                Text(group)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(ageGroup == group ? .black : KickIQTheme.textSecondary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        ageGroup == group ? KickIQTheme.accent : KickIQTheme.card,
                                        in: Capsule()
                                    )
                            }
                        }
                    }
                }
                .contentMargins(.horizontal, 0)
                .scrollIndicators(.hidden)
            }

            if let error = teamService.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Button {
                Task {
                    let team = await teamService.createTeam(
                        name: teamName.trimmingCharacters(in: .whitespaces),
                        ageGroup: ageGroup.isEmpty ? nil : ageGroup
                    )
                    if let team {
                        withAnimation(.spring(response: 0.4)) {
                            createdTeam = team
                        }
                    }
                }
            } label: {
                HStack(spacing: KickIQTheme.Spacing.sm) {
                    if teamService.isLoading {
                        ProgressView().tint(.black)
                    }
                    Text("Create Team")
                }
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, KickIQTheme.Spacing.md)
                .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
            }
            .disabled(teamName.trimmingCharacters(in: .whitespaces).isEmpty || teamService.isLoading)
            .opacity(teamName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
        }
    }

    private func successView(_ team: TeamDTO) -> some View {
        VStack(spacing: KickIQTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(.green.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.green)
            }

            VStack(spacing: KickIQTheme.Spacing.sm) {
                Text(team.name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(KickIQTheme.textPrimary)

                Text("Share this code with your players:")
                    .font(.subheadline)
                    .foregroundStyle(KickIQTheme.textSecondary)
            }

            VStack(spacing: KickIQTheme.Spacing.sm) {
                Text(team.join_code)
                    .font(.system(size: 32, weight: .black, design: .monospaced))
                    .foregroundStyle(KickIQTheme.accent)
                    .tracking(4)

                Button {
                    UIPasteboard.general.string = team.join_code
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.doc")
                        Text("Copy Code")
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(KickIQTheme.accent)
                    .padding(.horizontal, KickIQTheme.Spacing.md)
                    .padding(.vertical, KickIQTheme.Spacing.sm)
                    .background(KickIQTheme.accent.opacity(0.15), in: Capsule())
                }
            }
            .padding(KickIQTheme.Spacing.lg)
            .frame(maxWidth: .infinity)
            .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
        }
    }
}
