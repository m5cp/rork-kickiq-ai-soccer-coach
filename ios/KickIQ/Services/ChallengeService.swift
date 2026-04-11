import Foundation
import Supabase

@Observable
@MainActor
class ChallengeService {
    static let shared = ChallengeService()

    var challenges: [ChallengeDTO] = []
    var challengeResults: [String: [ChallengeResultDTO]] = [:]
    var isLoading: Bool = false
    var errorMessage: String?

    private let supabase = SupabaseService.shared
    private let auth = AuthService.shared

    private init() {}

    func loadChallenges(teamId: String) async {
        isLoading = true
        do {
            challenges = try await supabase.client.from("challenges")
                .select()
                .eq("team_id", value: teamId)
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
                .value
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func createChallenge(teamId: String, drillId: String, drillName: String, targetValue: Double, metricType: String) async -> Bool {
        guard let userId = auth.userId else { return false }
        isLoading = true
        errorMessage = nil

        let data: [String: String] = [
            "id": UUID().uuidString,
            "team_id": teamId,
            "creator_id": userId,
            "creator_name": auth.userDisplayName,
            "drill_id": drillId,
            "drill_name": drillName,
            "target_value": String(targetValue),
            "metric_type": metricType,
            "status": "active"
        ]

        do {
            try await supabase.client.from("challenges")
                .insert(data)
                .execute()

            await TeamService.shared.postActivity(
                teamId: teamId,
                eventType: "challenge_created",
                title: "\(auth.userDisplayName) started a challenge",
                subtitle: "\(drillName) — \(Int(targetValue)) \(metricType)",
                icon: "trophy.fill"
            )

            await loadChallenges(teamId: teamId)
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    func submitResult(challengeId: String, teamId: String, value: Double) async -> Bool {
        guard let userId = auth.userId else { return false }

        let data: [String: String] = [
            "id": UUID().uuidString,
            "challenge_id": challengeId,
            "user_id": userId,
            "display_name": auth.userDisplayName,
            "value": String(value)
        ]

        do {
            try await supabase.client.from("challenge_results")
                .insert(data)
                .execute()

            if let challenge = challenges.first(where: { $0.id == challengeId }) {
                await TeamService.shared.postActivity(
                    teamId: teamId,
                    eventType: "challenge_result",
                    title: "\(auth.userDisplayName) scored \(Int(value)) on a challenge",
                    subtitle: challenge.drill_name,
                    icon: "flame.fill"
                )
            }

            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func loadResults(challengeId: String) async {
        do {
            let results: [ChallengeResultDTO] = try await supabase.client.from("challenge_results")
                .select()
                .eq("challenge_id", value: challengeId)
                .order("value", ascending: false)
                .execute()
                .value
            challengeResults[challengeId] = results
        } catch {}
    }
}
