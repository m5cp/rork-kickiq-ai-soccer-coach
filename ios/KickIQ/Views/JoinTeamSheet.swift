import SwiftUI

struct JoinTeamSheet: View {
    let storage: StorageService
    @Environment(\.dismiss) private var dismiss
    @State private var teamService = TeamService.shared
    @State private var joinCode: String = ""
    @State private var displayName: String = ""
    @State private var joined = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQTheme.Spacing.lg) {
                    if joined {
                        successView
                    } else {
                        formView
                    }
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .padding(.top, KickIQTheme.Spacing.md)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle(joined ? "Joined!" : "Join Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(joined ? "Done" : "Cancel") { dismiss() }
                        .foregroundStyle(KickIQTheme.accent)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
        .onAppear {
            displayName = storage.profile?.name ?? ""
        }
    }

    private var formView: some View {
        VStack(spacing: KickIQTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(KickIQTheme.accent.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 36))
                    .foregroundStyle(KickIQTheme.accent)
            }

            VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
                Text("JOIN CODE")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(KickIQTheme.textSecondary)
                TextField("e.g. KIQ-X7R4M2", text: $joinCode)
                    .font(.system(.headline, design: .monospaced))
                    .textInputAutocapitalization(.characters)
                    .padding(KickIQTheme.Spacing.md)
                    .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
            }

            VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
                Text("YOUR NAME")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(KickIQTheme.textSecondary)
                TextField("Display name", text: $displayName)
                    .font(.headline)
                    .padding(KickIQTheme.Spacing.md)
                    .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
            }

            if let error = teamService.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Button {
                Task {
                    let position = storage.profile?.position.rawValue
                    let success = await teamService.joinTeam(
                        code: joinCode.trimmingCharacters(in: .whitespaces),
                        displayName: displayName.trimmingCharacters(in: .whitespaces),
                        position: position
                    )
                    if success {
                        withAnimation(.spring(response: 0.4)) { joined = true }
                    }
                }
            } label: {
                HStack(spacing: KickIQTheme.Spacing.sm) {
                    if teamService.isLoading {
                        ProgressView().tint(.black)
                    }
                    Text("Join Team")
                }
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, KickIQTheme.Spacing.md)
                .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
            }
            .disabled(joinCode.trimmingCharacters(in: .whitespaces).isEmpty || displayName.trimmingCharacters(in: .whitespaces).isEmpty || teamService.isLoading)
            .opacity(joinCode.isEmpty || displayName.isEmpty ? 0.5 : 1)
        }
    }

    private var successView: some View {
        VStack(spacing: KickIQTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(.green.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.green)
            }

            Text("You're on the team!")
                .font(.title2.weight(.bold))
                .foregroundStyle(KickIQTheme.textPrimary)

            Text("Your coach and teammates can now see your progress.")
                .font(.subheadline)
                .foregroundStyle(KickIQTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}
