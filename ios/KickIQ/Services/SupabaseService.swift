import Foundation
import Supabase

@Observable
@MainActor
class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        let url = Config.allValues["EXPO_PUBLIC_SUPABASE_URL"] ?? ""
        let key = Config.allValues["EXPO_PUBLIC_SUPABASE_ANON_KEY"] ?? ""

        client = SupabaseClient(
            supabaseURL: URL(string: url.isEmpty ? "https://placeholder.supabase.co" : url)!,
            supabaseKey: key.isEmpty ? "placeholder" : key
        )
    }

    var isConfigured: Bool {
        let url = Config.allValues["EXPO_PUBLIC_SUPABASE_URL"] ?? ""
        let key = Config.allValues["EXPO_PUBLIC_SUPABASE_ANON_KEY"] ?? ""
        return !url.isEmpty && !key.isEmpty && url != "https://placeholder.supabase.co"
    }
}
