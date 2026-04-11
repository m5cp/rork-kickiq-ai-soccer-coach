import SwiftUI

@main
struct KickIQApp: App {
    @State private var themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(themeManager.colorScheme)
        }
    }
}
