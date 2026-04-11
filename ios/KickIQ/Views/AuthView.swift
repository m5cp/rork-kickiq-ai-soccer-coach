import SwiftUI
import AuthenticationServices

struct AuthView: View {
    let onSignedIn: () -> Void
    @State private var auth = AuthService.shared
    @State private var showEmailAuth = false
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

                Button {
                    Task {
                        await auth.signInWithGoogle()
                        if auth.isSignedIn {
                            onSignedIn()
                        }
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
            .padding(.horizontal, KickIQTheme.Spacing.md)
            .padding(.bottom, KickIQTheme.Spacing.xl)
        }
        .background(KickIQTheme.background.ignoresSafeArea())
        .sheet(isPresented: $showEmailAuth) {
            EmailAuthSheet(onSignedIn: onSignedIn)
        }
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

struct EmailAuthSheet: View {
    let onSignedIn: () -> Void
    @State private var auth = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isSignUp: Bool = false
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var displayName: String = ""
    @FocusState private var focusedField: EmailField?

    private enum EmailField: Hashable {
        case name, email, password
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQTheme.Spacing.lg) {
                    ZStack {
                        Circle()
                            .fill(KickIQTheme.accent.opacity(0.15))
                            .frame(width: 72, height: 72)
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(KickIQTheme.accent)
                    }
                    .padding(.top, KickIQTheme.Spacing.md)

                    Text(isSignUp ? "Create Account" : "Sign In")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(KickIQTheme.textPrimary)

                    VStack(spacing: KickIQTheme.Spacing.md) {
                        if isSignUp {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("NAME")
                                    .font(.caption.weight(.bold))
                                    .tracking(1)
                                    .foregroundStyle(KickIQTheme.textSecondary)
                                TextField("Your name", text: $displayName)
                                    .font(.headline)
                                    .textContentType(.name)
                                    .focused($focusedField, equals: .name)
                                    .padding(KickIQTheme.Spacing.md)
                                    .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("EMAIL")
                                .font(.caption.weight(.bold))
                                .tracking(1)
                                .foregroundStyle(KickIQTheme.textSecondary)
                            TextField("your@email.com", text: $email)
                                .font(.headline)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .email)
                                .padding(KickIQTheme.Spacing.md)
                                .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("PASSWORD")
                                .font(.caption.weight(.bold))
                                .tracking(1)
                                .foregroundStyle(KickIQTheme.textSecondary)
                            SecureField("Password", text: $password)
                                .font(.headline)
                                .textContentType(isSignUp ? .newPassword : .password)
                                .focused($focusedField, equals: .password)
                                .padding(KickIQTheme.Spacing.md)
                                .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
                        }
                    }

                    if let error = auth.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        focusedField = nil
                        Task {
                            if isSignUp {
                                await auth.signUpWithEmail(
                                    email: email.trimmingCharacters(in: .whitespaces),
                                    password: password,
                                    displayName: displayName.trimmingCharacters(in: .whitespaces)
                                )
                            } else {
                                await auth.signInWithEmail(
                                    email: email.trimmingCharacters(in: .whitespaces),
                                    password: password
                                )
                            }
                            if auth.isSignedIn {
                                dismiss()
                                onSignedIn()
                            }
                        }
                    } label: {
                        HStack(spacing: KickIQTheme.Spacing.sm) {
                            if auth.isLoading {
                                ProgressView().tint(.black)
                            }
                            Text(isSignUp ? "Create Account" : "Sign In")
                        }
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, KickIQTheme.Spacing.md)
                        .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
                    }
                    .disabled(!isFormValid || auth.isLoading)
                    .opacity(isFormValid ? 1 : 0.5)

                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            isSignUp.toggle()
                            auth.errorMessage = nil
                        }
                    } label: {
                        Text(isSignUp ? "Already have an account? **Sign In**" : "Don't have an account? **Sign Up**")
                            .font(.subheadline)
                            .foregroundStyle(KickIQTheme.textSecondary)
                    }
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle(isSignUp ? "Create Account" : "Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(KickIQTheme.accent)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
    }

    private var isFormValid: Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        let hasEmail = trimmedEmail.contains("@") && trimmedEmail.contains(".")
        let hasPassword = password.count >= 6
        if isSignUp {
            return hasEmail && hasPassword && !displayName.trimmingCharacters(in: .whitespaces).isEmpty
        }
        return hasEmail && hasPassword
    }
}
