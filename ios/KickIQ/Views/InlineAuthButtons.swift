import SwiftUI
import AuthenticationServices

struct InlineAuthButtons: View {
    let onComplete: (Bool) -> Void
    @State private var auth = AuthService.shared
    @State private var showEmailAuth = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: KickIQTheme.Spacing.sm) {
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                Task {
                    await auth.handleAppleSignIn(result: result)
                    onComplete(auth.isSignedIn)
                }
            }
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(height: 54)
            .clipShape(.rect(cornerRadius: KickIQTheme.Radius.lg))

            Button {
                Task {
                    await auth.signInWithGoogle()
                    onComplete(auth.isSignedIn)
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "globe")
                        .font(.title3.weight(.semibold))
                    Text("Sign in with Google")
                        .font(.headline)
                }
                .foregroundStyle(KickIQTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                        .stroke(KickIQTheme.divider, lineWidth: 1)
                )
            }

            Button {
                showEmailAuth = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "envelope.fill")
                        .font(.title3.weight(.semibold))
                    Text("Sign in with Email")
                        .font(.headline)
                }
                .foregroundStyle(KickIQTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                        .stroke(KickIQTheme.divider, lineWidth: 1)
                )
            }

            if auth.isLoading {
                ProgressView()
                    .tint(KickIQTheme.accent)
                    .padding(.top, 4)
            }

            if let error = auth.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .sheet(isPresented: $showEmailAuth) {
            EmailAuthSheet {
                onComplete(true)
            }
        }
    }
}
