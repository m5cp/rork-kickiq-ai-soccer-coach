import SwiftUI
import AuthenticationServices

struct JoinTeamSheet: View {
    let storage: StorageService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var auth = AuthService.shared
    @State private var teamService = TeamService.shared
    @State private var joinCode: String = ""
    @State private var displayName: String = ""
    @State private var joined = false
    @State private var needsAuth = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQTheme.Spacing.lg) {
                    if joined {
                        successView
                    } else if needsAuth && !auth.isSignedIn {
                        signInSection
                    } else {
                        formView
                    }
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .padding(.top, KickIQTheme.Spacing.md)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle(joined ? "Joined!" : (needsAuth && !auth.isSignedIn ? "Sign In to Join" : "Join Team"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(joined ? "Done" : "Cancel") { dismiss() }
                        .foregroundStyle(KickIQTheme.accent)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
        .onAppear {
            displayName = storage.profile?.name ?? ""
        }
        .onChange(of: auth.isSignedIn) { _, signedIn in
            if signedIn && needsAuth {
                needsAuth = false
            }
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

            Text("Enter the code your coach shared with you.")
                .font(.subheadline)
                .foregroundStyle(KickIQTheme.textSecondary)
                .multilineTextAlignment(.center)

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
                if !auth.isSignedIn {
                    withAnimation(.spring(response: 0.4)) { needsAuth = true }
                } else {
                    joinTeam()
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

    private var signInSection: some View {
        VStack(spacing: KickIQTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(KickIQTheme.accent.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "person.badge.key.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(KickIQTheme.accent)
            }

            VStack(spacing: KickIQTheme.Spacing.sm) {
                Text("Sign In to Join")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(KickIQTheme.textPrimary)
                Text("Sign in so your coach can see your progress on the team.")
                    .font(.subheadline)
                    .foregroundStyle(KickIQTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if !joinCode.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "key.fill")
                        .foregroundStyle(KickIQTheme.accent)
                    Text("Code: \(joinCode)")
                        .font(.subheadline.weight(.semibold).monospaced())
                        .foregroundStyle(KickIQTheme.textPrimary)
                }
                .padding(KickIQTheme.Spacing.md)
                .frame(maxWidth: .infinity)
                .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
            }

            InlineAuthButtons { signedIn in
                if signedIn {
                    joinTeam()
                }
            }

            Button {
                withAnimation(.spring(response: 0.3)) { needsAuth = false }
            } label: {
                Text("Back to form")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(KickIQTheme.textSecondary)
            }
        }
    }

    private func joinTeam() {
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
