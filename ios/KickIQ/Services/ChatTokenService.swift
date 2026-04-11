import Foundation

@Observable
@MainActor
class ChatTokenService {
    static let shared = ChatTokenService()

    private let sessionLimitKey = "kickiq_chat_session_count"
    private let dailyLimitKey = "kickiq_chat_daily_count"
    private let dailyDateKey = "kickiq_chat_daily_date"
    private let sessionIDKey = "kickiq_chat_session_id"
    private let bonusTokensKey = "kickiq_chat_bonus_tokens"

    private let maxPerSession = 20
    private let maxPerDay = 60

    var sessionMessageCount: Int = 0
    var dailyMessageCount: Int = 0
    var bonusTokens: Int = 0

    private var currentSessionID: String = ""

    init() {
        loadState()
    }

    var sessionRemaining: Int {
        max(0, maxPerSession - sessionMessageCount) + (dailyRemaining > 0 ? 0 : bonusTokens)
    }

    var dailyRemaining: Int {
        max(0, maxPerDay - dailyMessageCount) + bonusTokens
    }

    var canSendMessage: Bool {
        let withinSession = sessionMessageCount < maxPerSession
        let withinDaily = dailyMessageCount < maxPerDay || bonusTokens > 0
        return withinSession && withinDaily
    }

    var limitReason: String? {
        if sessionMessageCount >= maxPerSession {
            return "You've reached the 20-message session limit. Start a new chat session to continue."
        }
        if dailyMessageCount >= maxPerDay && bonusTokens <= 0 {
            return "You've used all 60 daily messages. Purchase extra tokens or come back tomorrow."
        }
        return nil
    }

    func consumeToken() {
        sessionMessageCount += 1
        dailyMessageCount += 1

        if dailyMessageCount > maxPerDay && bonusTokens > 0 {
            bonusTokens -= 1
            UserDefaults.standard.set(bonusTokens, forKey: bonusTokensKey)
        }

        saveState()
    }

    func refundToken() {
        if sessionMessageCount > 0 { sessionMessageCount -= 1 }
        if dailyMessageCount > 0 { dailyMessageCount -= 1 }
        saveState()
    }

    func startNewSession() {
        currentSessionID = UUID().uuidString
        sessionMessageCount = 0
        UserDefaults.standard.set(currentSessionID, forKey: sessionIDKey)
        UserDefaults.standard.set(0, forKey: sessionLimitKey)
    }

    func addBonusTokens(_ count: Int) {
        bonusTokens += count
        UserDefaults.standard.set(bonusTokens, forKey: bonusTokensKey)
    }

    private func loadState() {
        let storedDate = UserDefaults.standard.string(forKey: dailyDateKey) ?? ""
        let today = formattedToday()

        if storedDate != today {
            dailyMessageCount = 0
            UserDefaults.standard.set(today, forKey: dailyDateKey)
            UserDefaults.standard.set(0, forKey: dailyLimitKey)
        } else {
            dailyMessageCount = UserDefaults.standard.integer(forKey: dailyLimitKey)
        }

        sessionMessageCount = UserDefaults.standard.integer(forKey: sessionLimitKey)
        currentSessionID = UserDefaults.standard.string(forKey: sessionIDKey) ?? UUID().uuidString
        bonusTokens = UserDefaults.standard.integer(forKey: bonusTokensKey)
    }

    private func saveState() {
        UserDefaults.standard.set(sessionMessageCount, forKey: sessionLimitKey)
        UserDefaults.standard.set(dailyMessageCount, forKey: dailyLimitKey)
        UserDefaults.standard.set(formattedToday(), forKey: dailyDateKey)
    }

    private func formattedToday() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: .now)
    }
}
