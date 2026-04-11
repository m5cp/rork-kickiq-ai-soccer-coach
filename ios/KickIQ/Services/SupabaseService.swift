import Foundation
import Supabase

@Observable
@MainActor
class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient
    private let supabaseURL: String
    private let supabaseKey: String

    private init() {
        let url = ConfigHelper.value(forKey: "EXPO_PUBLIC_SUPABASE_URL")
        let key = ConfigHelper.value(forKey: "EXPO_PUBLIC_SUPABASE_ANON_KEY")
        self.supabaseURL = url
        self.supabaseKey = key

        let finalURL = url.isEmpty ? "https://placeholder.supabase.co" : url
        client = SupabaseClient(
            supabaseURL: URL(string: finalURL)!,
            supabaseKey: key.isEmpty ? "placeholder" : key
        )

        if url.isEmpty || key.isEmpty {
            print("[KickIQ] Supabase not configured. URL empty: \(url.isEmpty), Key empty: \(key.isEmpty)")
        }
    }

    var isConfigured: Bool {
        !supabaseURL.isEmpty && !supabaseKey.isEmpty && supabaseURL != "https://placeholder.supabase.co"
    }

    var configurationStatus: String {
        if isConfigured { return "Connected" }
        if supabaseURL.isEmpty { return "Supabase URL not set" }
        if supabaseKey.isEmpty { return "Supabase key not set" }
        return "Not configured"
    }
}
