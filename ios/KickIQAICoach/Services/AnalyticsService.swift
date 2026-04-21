import Foundation
import os

nonisolated enum AnalyticsEvent: String, Sendable {
    case appOpen = "app_open"
    case screenView = "screen_view"
    case onboardingStep = "onboarding_step"
    case onboardingCompleted = "onboarding_completed"
    case paywallShown = "paywall_shown"
    case paywallDismissed = "paywall_dismissed"
    case purchaseStarted = "purchase_started"
    case purchaseSucceeded = "purchase_succeeded"
    case purchaseFailed = "purchase_failed"
    case restoreTapped = "restore_tapped"
    case drillStarted = "drill_started"
    case drillCompleted = "drill_completed"
    case benchmarkCompleted = "benchmark_completed"
    case milestoneEarned = "milestone_earned"
    case shareCardOpened = "share_card_opened"
    case shareCompleted = "share_completed"
    case siriIntentInvoked = "siri_intent_invoked"
}

@MainActor
final class AnalyticsService {
    static let shared = AnalyticsService()

    private let logger = Logger(subsystem: "app.rork.kickiq", category: "Analytics")
    private var isConfigured = false

    private init() {}

    func configure() {
        guard !isConfigured else { return }
        isConfigured = true
        // To enable TelemetryDeck: add SPM package https://github.com/TelemetryDeck/SwiftSDK
        // then: TelemetryDeck.initialize(config: .init(appID: "<YOUR_APP_ID>"))
        // To enable Sentry: add SPM package https://github.com/getsentry/sentry-cocoa
        // then: SentrySDK.start { $0.dsn = "<YOUR_DSN>" }
        logger.info("AnalyticsService configured (stub mode — no external SDK wired).")
    }

    func track(_ event: AnalyticsEvent, properties: [String: String] = [:]) {
        let propsString = properties.isEmpty ? "" : " " + properties.map { "\($0.key)=\($0.value)" }.joined(separator: " ")
        logger.debug("event=\(event.rawValue, privacy: .public)\(propsString, privacy: .public)")
        // Forward to TelemetryDeck / Sentry / other providers here once SDKs are added.
    }

    func trackScreen(_ name: String) {
        track(.screenView, properties: ["name": name])
    }

    func recordError(_ error: Error, context: String = "") {
        logger.error("error=\(String(describing: error), privacy: .public) context=\(context, privacy: .public)")
        // SentrySDK.capture(error: error) once wired.
    }
}
