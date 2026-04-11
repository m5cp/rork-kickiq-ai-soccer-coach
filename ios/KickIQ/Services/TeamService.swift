import Foundation
import Supabase

@Observable
@MainActor
class TeamService {
    static let shared = TeamService()

    var myTeams: [TeamDTO] = []
    var currentTeam: TeamDTO?
    var teamMembers: [TeamMemberDTO] = []
    var isLoading: Bool = false
    var errorMessage: String?

    private let supabase = SupabaseService.shared
    private let auth = AuthService.shared

    private init() {}

    func loadMyTeams() async {
        guard let userId = auth.userId else { return }
        isLoading = true
        do {
            let members: [TeamMemberDTO] = try await supabase.client.from("team_members")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value

            let teamIds = members.map(\.team_id)
            guard !teamIds.isEmpty else {
                myTeams = []
                isLoading = false
                return
            }

            let teams: [TeamDTO] = try await supabase.client.from("teams")
                .select()
                .in("id", values: teamIds)
                .execute()
                .value

            myTeams = teams
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func createTeam(name: String, ageGroup: String?) async -> TeamDTO? {
        guard let userId = auth.userId else { return nil }
        isLoading = true
        errorMessage = nil

        let joinCode = generateJoinCode()
        let teamId = UUID().uuidString

        do {
            let teamData: [String: String] = [
                "id": teamId,
                "name": name,
                "join_code": joinCode,
                "age_group": ageGroup ?? "",
                "created_by": userId
            ]

            try await supabase.client.from("teams")
                .insert(teamData)
                .execute()

            let memberData: [String: String] = [
                "id": UUID().uuidString,
                "team_id": teamId,
                "user_id": userId,
                "role": TeamRole.owner.rawValue,
                "display_name": auth.userDisplayName
            ]

            try await supabase.client.from("team_members")
                .insert(memberData)
                .execute()

            let team = TeamDTO(
                id: teamId,
                name: name,
                join_code: joinCode,
                age_group: ageGroup,
                created_by: userId,
                created_at: ISO8601DateFormatter().string(from: .now)
            )
            myTeams.append(team)
            isLoading = false
            return team
        } catch {
            errorMessage = "Failed to create team: \(error.localizedDescription)"
            isLoading = false
            return nil
        }
    }

    func joinTeam(code: String, displayName: String, position: String?) async -> Bool {
        guard let userId = auth.userId else { return false }
        isLoading = true
        errorMessage = nil

        do {
            let teams: [TeamDTO] = try await supabase.client.from("teams")
                .select()
                .eq("join_code", value: code.uppercased())
                .execute()
                .value

            guard let team = teams.first else {
                errorMessage = "No team found with that code"
                isLoading = false
                return false
            }

            let existing: [TeamMemberDTO] = try await supabase.client.from("team_members")
                .select()
                .eq("team_id", value: team.id)
                .eq("user_id", value: userId)
                .execute()
                .value

            if !existing.isEmpty {
                errorMessage = "You're already on this team"
                isLoading = false
                return false
            }

            var memberData: [String: String] = [
                "id": UUID().uuidString,
                "team_id": team.id,
                "user_id": userId,
                "role": TeamRole.player.rawValue,
                "display_name": displayName
            ]
            if let position { memberData["position"] = position }

            try await supabase.client.from("team_members")
                .insert(memberData)
                .execute()

            await postActivity(
                teamId: team.id,
                eventType: "player_joined",
                title: "\(displayName) joined the team",
                icon: "person.badge.plus"
            )

            myTeams.append(team)
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to join team: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    func loadTeamMembers(teamId: String) async {
        do {
            teamMembers = try await supabase.client.from("team_members")
                .select()
                .eq("team_id", value: teamId)
                .order("joined_at")
                .execute()
                .value
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeMember(memberId: String, teamId: String) async {
        do {
            try await supabase.client.from("team_members")
                .delete()
                .eq("id", value: memberId)
                .execute()
            teamMembers.removeAll { $0.id == memberId }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func regenerateJoinCode(teamId: String) async -> String? {
        let newCode = generateJoinCode()
        do {
            try await supabase.client.from("teams")
                .update(["join_code": newCode])
                .eq("id", value: teamId)
                .execute()

            if let idx = myTeams.firstIndex(where: { $0.id == teamId }) {
                let old = myTeams[idx]
                myTeams[idx] = TeamDTO(id: old.id, name: old.name, join_code: newCode, age_group: old.age_group, created_by: old.created_by, created_at: old.created_at)
            }
            return newCode
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func leaveTeam(teamId: String) async {
        guard let userId = auth.userId else { return }
        do {
            try await supabase.client.from("team_members")
                .delete()
                .eq("team_id", value: teamId)
                .eq("user_id", value: userId)
                .execute()
            myTeams.removeAll { $0.id == teamId }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func myRole(in teamId: String) -> TeamRole? {
        guard let userId = auth.userId else { return nil }
        let member = teamMembers.first { $0.team_id == teamId && $0.user_id == userId }
        guard let roleStr = member?.role else { return nil }
        return TeamRole(rawValue: roleStr)
    }

    func postActivity(teamId: String, eventType: String, title: String, subtitle: String? = nil, icon: String? = nil) async {
        guard let userId = auth.userId else { return }
        let data: [String: String] = [
            "id": UUID().uuidString,
            "team_id": teamId,
            "user_id": userId,
            "display_name": auth.userDisplayName,
            "event_type": eventType,
            "title": title,
            "subtitle": subtitle ?? "",
            "icon": icon ?? "bolt.fill"
        ]
        do {
            try await supabase.client.from("activity_feed")
                .insert(data)
                .execute()
        } catch {}
    }

    private func generateJoinCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        let code = (0..<6).map { _ in String(chars.randomElement()!) }.joined()
        return "KIQ-\(code)"
    }
}
