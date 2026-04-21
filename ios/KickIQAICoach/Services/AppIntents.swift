import AppIntents
import Foundation

nonisolated enum KickIQIntentAction: String, Sendable {
    case startNextDrill = "start_next_drill"
    case showStreak = "show_streak"
}

nonisolated enum KickIQIntentBridge {
    static let suiteName = "group.app.rork.kickiq"
    static let pendingActionKey = "pending_intent_action"

    static func setPendingAction(_ action: KickIQIntentAction) {
        UserDefaults(suiteName: suiteName)?.set(action.rawValue, forKey: pendingActionKey)
    }

    static func consumePendingAction() -> KickIQIntentAction? {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let raw = defaults.string(forKey: pendingActionKey),
              let action = KickIQIntentAction(rawValue: raw) else { return nil }
        defaults.removeObject(forKey: pendingActionKey)
        return action
    }
}

struct StartNextDrillIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Next Drill"
    static var description = IntentDescription("Opens KickIQ and jumps straight into today's drill.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        KickIQIntentBridge.setPendingAction(.startNextDrill)
        return .result()
    }
}

struct ShowStreakIntent: AppIntent {
    static var title: LocalizedStringResource = "Show My Streak"
    static var description = IntentDescription("Shows your current KickIQ training streak.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        KickIQIntentBridge.setPendingAction(.showStreak)
        let streak = UserDefaults(suiteName: KickIQIntentBridge.suiteName)?.integer(forKey: "widget_streak") ?? 0
        let message: String
        if streak == 0 {
            message = "You haven't started a streak yet. Let's change that!"
        } else if streak == 1 {
            message = "You're on a 1-day streak. Keep it going!"
        } else {
            message = "You're on a \(streak)-day streak. Keep it going!"
        }
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

struct KickIQShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartNextDrillIntent(),
            phrases: [
                "Start my next \(.applicationName) drill",
                "Start training in \(.applicationName)",
                "Begin \(.applicationName) drill"
            ],
            shortTitle: "Start Next Drill",
            systemImageName: "figure.soccer"
        )
        AppShortcut(
            intent: ShowStreakIntent(),
            phrases: [
                "Show my \(.applicationName) streak",
                "What's my streak in \(.applicationName)",
                "\(.applicationName) streak"
            ],
            shortTitle: "Show My Streak",
            systemImageName: "flame.fill"
        )
    }
}
