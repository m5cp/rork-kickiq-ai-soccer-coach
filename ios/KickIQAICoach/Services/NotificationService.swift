import Foundation
import UserNotifications

nonisolated enum DeepLink: String, Sendable {
    case home
    case coach
    case analyze
    case drills
    case progress
    case profile
    case skills
    case conditioning

    var tabIndex: Int {
        switch self {
        case .home: 0
        case .coach: 1
        case .analyze: 2
        case .drills: 3
        case .progress: 4
        case .profile: 5
        case .skills: 3
        case .conditioning: 3
        }
    }
}

@Observable
@MainActor
class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    var isAuthorized = false
    var pendingDeepLink: DeepLink?

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            if granted {
                scheduleWeeklySummary()
            }
        } catch {}
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        if let destination = userInfo["deepLink"] as? String,
           let link = DeepLink(rawValue: destination) {
            await MainActor.run {
                self.pendingDeepLink = link
            }
        } else {
            let id = response.notification.request.identifier
            let link: DeepLink
            switch id {
            case "streak_reminder": link = .drills
            case "weekly_summary", "weekly_summary_custom": link = .progress
            case "monthly_reassessment": link = .profile
            default: link = .home
            }
            await MainActor.run {
                self.pendingDeepLink = link
            }
        }
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }

    func scheduleWeeklySummary() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["weekly_summary"])

        let content = UNMutableNotificationContent()
        content.title = "Your Weekly KickIQAICoach Recap"
        content.body = "Check your progress this week — drills completed, skill score changes, and more."
        content.sound = .default
        content.userInfo = ["deepLink": "progress"]

        var dateComponents = DateComponents()
        dateComponents.weekday = 2
        dateComponents.hour = 18
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly_summary", content: content, trigger: trigger)
        center.add(request)
    }

    func scheduleMonthlyReassessment() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["monthly_reassessment"])

        let content = UNMutableNotificationContent()
        content.title = "Time to Reassess"
        content.body = "It's been a month — recheck your weakest skill and update your training focus."
        content.sound = .default
        content.userInfo = ["deepLink": "profile"]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 30 * 24 * 3600, repeats: true)
        let request = UNNotificationRequest(identifier: "monthly_reassessment", content: content, trigger: trigger)
        center.add(request)
    }

    func scheduleStreakReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["streak_reminder"])

        let content = UNMutableNotificationContent()
        content.title = "Don't Lose Your Streak! 🔥"
        content.body = "Train today to keep your streak alive. Open KickIQAICoach to log a session."
        content.sound = .default
        content.userInfo = ["deepLink": "drills"]

        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "streak_reminder", content: content, trigger: trigger)
        center.add(request)
    }

    func scheduleCustomSummary(drillsCompleted: Int, scoreChange: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["weekly_summary_custom"])

        let content = UNMutableNotificationContent()
        content.title = "Your Weekly KickIQAICoach Recap"
        let scoreText = scoreChange >= 0 ? "up \(scoreChange)" : "down \(abs(scoreChange))"
        content.body = "This week: \(drillsCompleted) drills completed, skill score \(scoreText) points. Keep pushing!"
        content.sound = .default
        content.userInfo = ["deepLink": "progress"]

        var dateComponents = DateComponents()
        dateComponents.weekday = 2
        dateComponents.hour = 18

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "weekly_summary_custom", content: content, trigger: trigger)
        center.add(request)
    }
}
