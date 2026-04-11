import Foundation
import Supabase

@Observable
@MainActor
class CoachAssignmentService {
    static let shared = CoachAssignmentService()

    var assignments: [AssignedDrillDTO] = []
    var myAssignments: [AssignedDrillDTO] = []
    var isLoading: Bool = false
    var errorMessage: String?

    private let supabase = SupabaseService.shared
    private let auth = AuthService.shared

    private init() {}

    func assignDrill(teamId: String, drillId: String, drillName: String, assignedTo: String?, note: String?, dueDate: Date?) async -> Bool {
        guard let userId = auth.userId else { return false }
        isLoading = true
        errorMessage = nil

        var data: [String: String] = [
            "id": UUID().uuidString,
            "team_id": teamId,
            "drill_id": drillId,
            "drill_name": drillName,
            "assigned_by": userId,
            "completed": "false"
        ]
        if let assignedTo { data["assigned_to"] = assignedTo }
        if let note { data["note"] = note }
        if let dueDate {
            data["due_date"] = ISO8601DateFormatter().string(from: dueDate)
        }

        do {
            try await supabase.client.from("assigned_drills")
                .insert(data)
                .execute()

            await TeamService.shared.postActivity(
                teamId: teamId,
                eventType: "drill_assigned",
                title: "Coach assigned \(drillName)",
                subtitle: assignedTo != nil ? "To a player" : "To the whole team",
                icon: "clipboard.fill"
            )

            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    func loadAssignments(teamId: String) async {
        isLoading = true
        do {
            assignments = try await supabase.client.from("assigned_drills")
                .select()
                .eq("team_id", value: teamId)
                .order("created_at", ascending: false)
                .execute()
                .value
        } catch {}
        isLoading = false
    }

    func loadMyAssignments(teamId: String) async {
        guard let userId = auth.userId else { return }
        do {
            let all: [AssignedDrillDTO] = try await supabase.client.from("assigned_drills")
                .select()
                .eq("team_id", value: teamId)
                .execute()
                .value

            myAssignments = all.filter { $0.assigned_to == nil || $0.assigned_to == userId }
        } catch {}
    }

    func markComplete(assignmentId: String) async {
        do {
            try await supabase.client.from("assigned_drills")
                .update(["completed": true])
                .eq("id", value: assignmentId)
                .execute()

            if let idx = assignments.firstIndex(where: { $0.id == assignmentId }) {
                let old = assignments[idx]
                assignments[idx] = AssignedDrillDTO(
                    id: old.id, team_id: old.team_id, drill_id: old.drill_id,
                    drill_name: old.drill_name, assigned_by: old.assigned_by,
                    assigned_to: old.assigned_to, assignee_name: old.assignee_name,
                    due_date: old.due_date, completed: true, note: old.note,
                    created_at: old.created_at
                )
            }
            if let idx = myAssignments.firstIndex(where: { $0.id == assignmentId }) {
                let old = myAssignments[idx]
                myAssignments[idx] = AssignedDrillDTO(
                    id: old.id, team_id: old.team_id, drill_id: old.drill_id,
                    drill_name: old.drill_name, assigned_by: old.assigned_by,
                    assigned_to: old.assigned_to, assignee_name: old.assignee_name,
                    due_date: old.due_date, completed: true, note: old.note,
                    created_at: old.created_at
                )
            }
        } catch {}
    }
}
