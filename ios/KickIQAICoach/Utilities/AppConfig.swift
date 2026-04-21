import Foundation

enum AppConfig {
    static let appStoreID: String? = nil

    static var appStoreURL: String {
        if let id = appStoreID, !id.isEmpty {
            return "https://apps.apple.com/app/id\(id)"
        }
        return "https://kickiq.app"
    }

    static let supportEmail = "contact@m5cairo.com"
}
