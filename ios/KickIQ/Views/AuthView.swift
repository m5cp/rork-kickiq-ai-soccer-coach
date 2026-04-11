import SwiftUI
import AuthenticationServices

struct AuthView: View {
    let onSignedIn: () -> Void
    @State private var auth = AuthService.shared
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: KickIQTheme.Spacing.xl) {
            Spacer()

            VStack(spacing: KickIQTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(KickIQTheme.accent.opacity(0.15))
                        .frame(width: 96, height: 96)
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(KickIQTheme.accent)
                }

                Text("Team Features")
                    .font(.system(.title, design: .default, weight: .bold))
                    .foregroundStyle(KickIQTheme.textPrimary)

                Text("Sign in to create or join a team, compete in challenges, and track progress with your squad.")
                    .font(.subheadline)
                    .foregroundStyle(KickIQTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, KickIQTheme.Spacing.lg)
            }

            VStack(spacing: KickIQTheme.Spacing.md) {
                featureRow(icon: "shield.fill", title: "Team Roster", desc: "Coach creates a team, players join with a code")
                featureRow(icon: "chart.bar.fill", title: "Leaderboards", desc: "See who's putting in the work")
                featureRow(icon: "trophy.fill", title: "Challenges", desc: "Challenge teammates to beat your scores")
                featureRow(icon: "bubble.left.fill", title: "Activity Feed", desc: "See when teammates complete drills")
            }
            .padding(.horizontal, KickIQTheme.Spacing.md)

            Spacer()

            VStack(spacing: KickIQTheme.Spacing.sm) {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    Task {
                        await auth.handleAppleSignIn(result: result)
                        if auth.isSignedIn {
                            onSignedIn()
                        }
                    }
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 54)
                .clipShape(.rect(cornerRadius: KickIQTheme.Radius.lg))

                if let error = auth.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, KickIQTheme.Spacing.md)
            .padding(.bottom, KickIQTheme.Spacing.xl)
        }
        .background(KickIQTheme.background.ignoresSafeArea())
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
