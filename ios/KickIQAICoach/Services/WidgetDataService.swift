import Foundation
import WidgetKit

enum WidgetDataService {
    private static let suiteName = "group.app.rork.kickiq"

    static func updateWidgetData(storage: StorageService) {
        guard let shared = UserDefaults(suiteName: suiteName) else { return }
        shared.set(storage.streakCount, forKey: "widget_streak")
        shared.set(storage.skillScore, forKey: "widget_score")
        shared.set(storage.completedDrillIDs.count, forKey: "widget_drills_done")
        shared.set(storage.xpPoints, forKey: "widget_xp")
        shared.set(storage.playerLevel.rawValue, forKey: "widget_level")
        shared.set(storage.profile?.name ?? "Player", forKey: "widget_name")
        shared.set(storage.thisWeekDrillMinutes, forKey: "widget_weekly_minutes")
        shared.set(storage.weeklyGoal?.sessionsPerWeek ?? 3, forKey: "widget_weekly_goal")
        shared.set(storage.weeklySessionsCompleted, forKey: "widget_weekly_completed")
        WidgetCenter.shared.reloadAllTimelines()
    }
}
