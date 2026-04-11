import Foundation
import Supabase

@Observable
@MainActor
class ActivityFeedService {
    static let shared = ActivityFeedService()

    var events: [ActivityEventDTO] = []
    var isLoading: Bool = false

    private let supabase = SupabaseService.shared

    private init() {}

    func loadFeed(teamId: String) async {
        isLoading = true
        do {
            events = try await supabase.client.from("activity_feed")
                .select()
                .eq("team_id", value: teamId)
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
                .value
        } catch {}
        isLoading = false
    }
}
