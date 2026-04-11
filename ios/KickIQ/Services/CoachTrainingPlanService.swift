import Foundation
import Supabase

@Observable
@MainActor
class CoachTrainingPlanService {
    static let shared = CoachTrainingPlanService()

    var plans: [CoachTrainingPlanDTO] = []
    var isLoading: Bool = false
    var errorMessage: String?

    private let supabase = SupabaseService.shared
    private let auth = AuthService.shared

    private init() {}

    func loadPlans(teamId: String) async {
        isLoading = true
        errorMessage = nil
        do {
            plans = try await supabase.client.from("coach_training_plans")
                .select()
                .eq("team_id", value: teamId)
                .order("created_at", ascending: false)
                .execute()
                .value
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func createPlan(
        teamId: String,
        title: String,
        description: String?,
        ageGroup: String?,
        difficulty: String?,
        durationMinutes: Int?,
        focusAreas: [String],
        drills: [CoachPlanDrillDTO]
    ) async -> Bool {
        guard let userId = auth.userId else { return false }
        isLoading = true
        errorMessage = nil

        let planId = UUID().uuidString

        let drillDicts: [[String: Any]] = drills.enumerated().map { idx, drill in
            [
                "id": drill.id,
                "name": drill.name,
                "description": drill.description ?? "",
                "duration": drill.duration ?? "",
                "reps": drill.reps ?? "",
                "coaching_cues": drill.coaching_cues,
                "order": idx
            ]
        }

        guard let drillsData = try? JSONSerialization.data(withJSONObject: drillDicts),
              let drillsJSON = String(data: drillsData, encoding: .utf8) else {
            errorMessage = "Failed to encode drills"
            isLoading = false
            return false
        }

        let focusData = try? JSONSerialization.data(withJSONObject: focusAreas)
        let focusJSON = focusData.flatMap { String(data: $0, encoding: .utf8) } ?? "[]"

        do {
            try await supabase.client.from("coach_training_plans")
                .insert([
                    "id": planId,
                    "team_id": teamId,
                    "coach_id": userId,
                    "coach_name": auth.userDisplayName,
                    "title": title,
                    "description": description ?? "",
                    "age_group": ageGroup ?? "",
                    "difficulty": difficulty ?? "Intermediate",
                    "duration_minutes": "\(durationMinutes ?? 30)",
                    "focus_areas": focusJSON,
                    "drills": drillsJSON
                ])
                .execute()

            await TeamService.shared.postActivity(
                teamId: teamId,
                eventType: "plan_created",
                title: "New training plan: \(title)",
                subtitle: "\(drills.count) drills",
                icon: "doc.text.fill"
            )

            await loadPlans(teamId: teamId)
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    func deletePlan(planId: String, teamId: String) async {
        do {
            try await supabase.client.from("coach_training_plans")
                .delete()
                .eq("id", value: planId)
                .execute()
            plans.removeAll { $0.id == planId }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
