import Foundation
import AuthenticationServices
import Supabase
import CryptoKit

@Observable
@MainActor
class AuthService {
    static let shared = AuthService()

    var currentUser: Supabase.User?
    var isSignedIn: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?

    private let supabase = SupabaseService.shared
    private var currentNonce: String?

    private init() {
        Task { await checkSession() }
    }

    func checkSession() async {
        guard supabase.isConfigured else { return }
        do {
            let session = try await supabase.client.auth.session
            currentUser = session.user
            isSignedIn = true
        } catch {
            isSignedIn = false
            currentUser = nil
        }
    }

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = nil

        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let idTokenData = credential.identityToken,
                  let idToken = String(data: idTokenData, encoding: .utf8) else {
                errorMessage = "Failed to get Apple ID credentials"
                isLoading = false
                return
            }

            do {
                let session = try await supabase.client.auth.signInWithIdToken(
                    credentials: .init(
                        provider: .apple,
                        idToken: idToken
                    )
                )
                currentUser = session.user
                isSignedIn = true

                let displayName: String
                if let fullName = credential.fullName {
                    let parts = [fullName.givenName, fullName.familyName].compactMap { $0 }
                    displayName = parts.joined(separator: " ")
                } else {
                    displayName = ""
                }

                if !displayName.isEmpty {
                    await upsertProfile(userId: session.user.id.uuidString, displayName: displayName)
                }
            } catch {
                errorMessage = "Sign in failed: \(error.localizedDescription)"
            }

        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
            }
        }

        isLoading = false
    }

    func signOut() async {
        do {
            try await supabase.client.auth.signOut()
            currentUser = nil
            isSignedIn = false
        } catch {
            errorMessage = "Sign out failed: \(error.localizedDescription)"
        }
    }

    private func upsertProfile(userId: String, displayName: String) async {
        do {
            try await supabase.client.from("profiles")
                .upsert([
                    "id": userId,
                    "display_name": displayName
                ])
                .execute()
        } catch {
            // Profile upsert is best-effort
        }
    }

    var userDisplayName: String {
        currentUser?.email ?? "Player"
    }

    var userId: String? {
        currentUser?.id.uuidString
    }
}
