import Foundation
import Supabase

@Observable
@MainActor
class CloudDrillService {
    static let shared = CloudDrillService()

    var teamDrillLogs: [DrillLogDTO] = []
    var leaderboard: [LeaderboardEntry] = []
    var isLoading: Bool = false

    private let supabase = SupabaseService.shared
    private let auth = AuthService.shared

    private init() {}

    func logDrill(drillId: String, drillName: String, teamId: String?, value: Double?, metricType: String?) async {
        guard let userId = auth.userId else { return }

        var data: [String: String] = [
            "id": UUID().uuidString,
            "user_id": userId,
            "drill_id": drillId,
            "drill_name": drillName
        ]
        if let teamId { data["team_id"] = teamId }
        if let value { data["value"] = String(value) }
        if let metricType { data["metric_type"] = metricType }

        do {
            try await supabase.client.from("drill_logs")
                .insert(data)
                .execute()

            if let teamId {
                await TeamService.shared.postActivity(
                    teamId: teamId,
                    eventType: "drill_completed",
                    title: "\(auth.userDisplayName) completed \(drillName)",
                    subtitle: value != nil ? "\(Int(value!)) \(metricType ?? "")" : nil,
                    icon: "checkmark.circle.fill"
                )
            }
        } catch {}
    }

    func loadTeamDrillLogs(teamId: String) async {
        isLoading = true
        do {
            teamDrillLogs = try await supabase.client.from("drill_logs")
                .select()
                .eq("team_id", value: teamId)
                .order("completed_at", ascending: false)
                .limit(100)
                .execute()
                .value
        } catch {}
        isLoading = false
    }

    func loadLeaderboard(teamId: String, metric: String = "total_drills") async {
        isLoading = true
        do {
            let members: [TeamMemberDTO] = try await supabase.client.from("team_members")
                .select()
                .eq("team_id", value: teamId)
                .execute()
                .value

            let logs: [DrillLogDTO] = try await supabase.client.from("drill_logs")
                .select()
                .eq("team_id", value: teamId)
                .execute()
                .value

            var userCounts: [String: Double] = [:]
            for log in logs {
                userCounts[log.user_id, default: 0] += 1
            }

            let sorted = userCounts.sorted { $0.value > $1.value }
            leaderboard = sorted.enumerated().map { index, entry in
                let member = members.first { $0.user_id == entry.key }
                return LeaderboardEntry(
                    id: entry.key,
                    userId: entry.key,
                    displayName: member?.display_name ?? "Player",
                    position: member?.position,
                    value: entry.value,
                    rank: index + 1
                )
            }
        } catch {}
        isLoading = false
    }
}
