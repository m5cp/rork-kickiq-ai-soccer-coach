import Foundation

nonisolated struct GeminiContent: Codable, Sendable {
    let role: String
    let parts: [GeminiPart]
}

nonisolated struct GeminiPart: Codable, Sendable {
    let text: String
}

nonisolated struct GeminiRequest: Codable, Sendable {
    let contents: [GeminiContent]
    let systemInstruction: GeminiContent?
    let generationConfig: GeminiGenerationConfig?
}

nonisolated struct GeminiGenerationConfig: Codable, Sendable {
    let temperature: Double?
    let maxOutputTokens: Int?
}

nonisolated struct GeminiResponse: Codable, Sendable {
    let candidates: [GeminiCandidate]?
    let error: GeminiError?
}

nonisolated struct GeminiCandidate: Codable, Sendable {
    let content: GeminiCandidateContent?
}

nonisolated struct GeminiCandidateContent: Codable, Sendable {
    let parts: [GeminiPart]?
}

nonisolated struct GeminiError: Codable, Sendable {
    let message: String?
    let code: Int?
}

struct CoachMessage: Identifiable, Equatable {
    let id: String
    let role: CoachMessageRole
    let content: String
    let timestamp: Date

    init(id: String = UUID().uuidString, role: CoachMessageRole, content: String, timestamp: Date = .now) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

enum CoachMessageRole: Equatable {
    case user
    case coach
}

nonisolated enum TokenTier: Sendable {
    case free
    case monthly
    case annual

    var dailyTokenBudget: Int {
        switch self {
        case .free: 100
        case .monthly: 750
        case .annual: 2_000
        }
    }

    var label: String {
        switch self {
        case .free: "Free"
        case .monthly: "Monthly"
        case .annual: "Annual"
        }
    }
}

nonisolated enum TokenPackSize: Sendable {
    case small
    case medium
    case large

    var tokenAmount: Int {
        switch self {
        case .small: 1_000
        case .medium: 5_000
        case .large: 20_000
        }
    }

    var storeIdentifier: String {
        switch self {
        case .small: "kickiq_tokens_small"
        case .medium: "kickiq_tokens_medium"
        case .large: "kickiq_tokens_large"
        }
    }
}

@Observable
@MainActor
class AICoachService {
    var messages: [CoachMessage] = []
    var isLoading = false
    var errorMessage: String?
    var isOffline = false
    var hasShownOnboarding = false
    var lastFailedUserText: String?
    var tokensRemaining: Int = 0
    var isAtLimit = false

    private var conversationHistory: [GeminiContent] = []
    private let systemPrompt: String
    private let playerName: String
    private let position: String
    private let weakness: String
    private let isPremium: Bool
    private weak var storage: StorageService?

    private static let cacheKey = "kickiq_coach_cache"
    private static let onboardingKey = "kickiq_coach_onboarded"
    private static let dailyTokensUsedKey = "kickiq_coach_daily_tokens"
    private static let dailyDateKey = "kickiq_coach_daily_date"

    private static let offlineResponses: [String: String] = [
        "weak foot": "To improve your weak foot, start with wall passes — 50 reps each foot daily. Then progress to dribbling figure-8s using only your weak foot. Within 2 weeks of consistent practice you'll notice a big difference. Focus on striking through the center of the ball with your laces.",
        "shooting": "For shooting, focus on your plant foot placement — it should point at your target, about a ball's width from the ball. Strike through the center or top half of the ball. Practice with 20 shots from outside the box daily, focusing on technique over power.",
        "dribbling": "Close ball control is everything. Do 10 minutes of cone dribbling daily — inside-outside touches, pull-backs, and Cruyff turns. Keep the ball within 1 foot of you at all times. Watch how Messi keeps the ball glued to his feet at full speed.",
        "fitness": "Soccer fitness requires both endurance and explosiveness. Do interval sprints: 6x 30-second sprints with 60-second rests. Add 20 minutes of steady jogging. Include ladder drills for agility. Do this 3x per week alongside your technical training.",
        "defending": "Good defending starts with positioning. Stay goal-side, watch the attacker's hips not the ball, and delay rather than dive in. Practice 1v1 defending drills where you focus on shepherding attackers away from goal.",
        "first touch": "Your first touch determines everything. Practice receiving passes against a wall from different angles. Cushion the ball by withdrawing your foot on contact. Aim to control the ball within one stride of where you want to go next.",
        "game day": "Game day prep: Light meal 3 hours before, hydrate well, dynamic warm-up 30 minutes before. Mentally visualize 3 key plays you want to execute. Stay loose, stay confident. Remember — the game is won in preparation.",
        "default": "Great question! While I need internet to give you a fully personalized answer, here's a universal tip: The best players practice with purpose every single day. Even 15 focused minutes beats 2 hours of unfocused kicking. Set a specific skill goal for each session."
    ]

    init(storage: StorageService, isPremium: Bool = false) {
        self.storage = storage
        self.isPremium = isPremium
        let profile = storage.profile
        self.playerName = profile?.name ?? "Player"
        self.position = profile?.position.rawValue ?? "Midfielder"
        self.weakness = profile?.weakness.rawValue ?? "First Touch"

        let playerContext = storage.coachContextSummary

        self.systemPrompt = """
        You are KickIQ Coach, an elite AI soccer coaching assistant. You are knowledgeable, motivating, and direct — like a top-tier youth academy coach.

        PLAYER DATA (this is real, live data from the player's app — use it):
        \(playerContext)

        Guidelines:
        - Give specific, actionable soccer coaching advice
        - Reference real techniques, drills, and professional player examples
        - Be encouraging but honest about areas needing work
        - Keep responses concise (2-4 paragraphs max) unless asked for detailed plans
        - Use soccer terminology naturally
        - When suggesting drills, include reps, duration, and coaching cues
        - If asked about non-soccer topics, gently redirect to training
        - Address the player by name occasionally
        - Adapt advice to their position and skill level
        - REMEMBER their benchmark scores, trends, and weaknesses — reference them proactively
        - Track their progress across conversations. If they improved, celebrate. If declining, address it.
        - When they mention completing a drill or hitting a score, acknowledge it and suggest what's next
        - Be their personal coach who KNOWS their journey — not a generic chatbot
        - If they're on a training streak, praise their consistency
        - Suggest specific drills from their weak areas to keep them on track
        """

        hasShownOnboarding = UserDefaults.standard.bool(forKey: Self.onboardingKey)
        loadCachedMessages()
        refreshTokenBudget()
    }

    var tokenTier: TokenTier {
        isPremium ? .annual : .free
    }

    var dailyBudget: Int {
        tokenTier.dailyTokenBudget
    }

    var totalAvailableTokens: Int {
        let daily = max(0, dailyBudget - dailyTokensUsed)
        let bonus = storage?.tokenBalance ?? 0
        return daily + bonus
    }

    private var dailyTokensUsed: Int {
        let today = Calendar.current.startOfDay(for: .now)
        let storedDate = UserDefaults.standard.double(forKey: Self.dailyDateKey)
        let storedDay = Date(timeIntervalSince1970: storedDate)

        if storedDate == 0 || !Calendar.current.isDate(storedDay, inSameDayAs: today) {
            return 0
        }
        return UserDefaults.standard.integer(forKey: Self.dailyTokensUsedKey)
    }

    private func refreshTokenBudget() {
        let today = Calendar.current.startOfDay(for: .now)
        let storedDate = UserDefaults.standard.double(forKey: Self.dailyDateKey)
        let storedDay = Date(timeIntervalSince1970: storedDate)

        if storedDate == 0 || !Calendar.current.isDate(storedDay, inSameDayAs: today) {
            UserDefaults.standard.set(0, forKey: Self.dailyTokensUsedKey)
            UserDefaults.standard.set(today.timeIntervalSince1970, forKey: Self.dailyDateKey)
        }

        tokensRemaining = totalAvailableTokens
        isAtLimit = tokensRemaining <= 0
    }

    private func recordTokensUsed(_ tokens: Int) {
        let today = Calendar.current.startOfDay(for: .now)
        let storedDate = UserDefaults.standard.double(forKey: Self.dailyDateKey)
        let storedDay = Date(timeIntervalSince1970: storedDate)

        if storedDate == 0 || !Calendar.current.isDate(storedDay, inSameDayAs: today) {
            UserDefaults.standard.set(tokens, forKey: Self.dailyTokensUsedKey)
            UserDefaults.standard.set(today.timeIntervalSince1970, forKey: Self.dailyDateKey)
        } else {
            let current = UserDefaults.standard.integer(forKey: Self.dailyTokensUsedKey)
            UserDefaults.standard.set(current + tokens, forKey: Self.dailyTokensUsedKey)
        }

        let dailyRemaining = max(0, dailyBudget - dailyTokensUsed - tokens)
        if dailyRemaining <= 0 && tokens > 0 {
            let overflow = tokens - max(0, dailyBudget - (UserDefaults.standard.integer(forKey: Self.dailyTokensUsedKey) - tokens))
            if overflow > 0 {
                storage?.deductTokens(overflow)
            }
        }

        refreshTokenBudget()
    }

    func startOnboardingConversation() {
        guard !hasShownOnboarding else { return }
        hasShownOnboarding = true
        UserDefaults.standard.set(true, forKey: Self.onboardingKey)

        let greeting = CoachMessage(
            role: .coach,
            content: "Hey \(playerName)! I'm your KickIQ AI Coach. I already know you play \(position) and want to work on \(weakness) — so I'm ready to help.\n\nI keep track of your benchmark scores, training streaks, and progress — so the more you use the app, the better I can coach you.\n\nTry asking something like \"What should I work on today?\" or \"How can I improve my \(weakness.lowercased())?\" to get started!"
        )
        messages.append(greeting)
    }

    func sendMessage(_ text: String) async {
        refreshTokenBudget()
        guard !isAtLimit else {
            let capMsg = CoachMessage(role: .coach, content: "You've used all your coaching tokens for today. \(isPremium ? "Your daily budget resets at midnight, or you can grab a token pack for extra coaching." : "Upgrade to Premium for 20x more daily coaching, or grab a token pack to keep going.")")
            messages.append(capMsg)
            return
        }

        let userMessage = CoachMessage(role: .user, content: text)
        messages.append(userMessage)

        conversationHistory.append(GeminiContent(role: "user", parts: [GeminiPart(text: text)]))

        isLoading = true
        errorMessage = nil
        isOffline = false

        defer {
            isLoading = false
            cacheMessages()
        }

        lastFailedUserText = nil

        let apiKey = Config.EXPO_PUBLIC_GEMINI_API_KEY
        guard !apiKey.isEmpty else {
            let fallback = CoachMessage(role: .coach, content: "AI Coach is not configured yet. Please try again later.")
            messages.append(fallback)
            conversationHistory.removeLast()
            return
        }

        let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
        guard let url = URL(string: endpoint) else {
            errorMessage = "Invalid API configuration"
            return
        }

        let requestBody = GeminiRequest(
            contents: conversationHistory,
            systemInstruction: GeminiContent(role: "user", parts: [GeminiPart(text: systemPrompt)]),
            generationConfig: GeminiGenerationConfig(temperature: 0.8, maxOutputTokens: 1024)
        )

        do {
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
            urlRequest.httpBody = try JSONEncoder().encode(requestBody)
            urlRequest.timeoutInterval = 30

            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                let rawBody = String(data: data, encoding: .utf8) ?? "no body"
                var detail = "error \(statusCode)"
                if let geminiResp = try? JSONDecoder().decode(GeminiResponse.self, from: data),
                   let errMsg = geminiResp.error?.message {
                    detail = errMsg
                }
                errorMessage = detail
                conversationHistory.removeLast()
                lastFailedUserText = text
                let errorMsg = CoachMessage(role: .coach, content: "Message failed (\(detail)). No tokens used — tap retry or send again.")
                messages.append(errorMsg)
                return
            }

            let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)

            guard let responseText = geminiResponse.candidates?.first?.content?.parts?.first?.text,
                  !responseText.isEmpty else {
                conversationHistory.removeLast()
                lastFailedUserText = text
                let fallback = CoachMessage(role: .coach, content: "Message failed (empty response from AI). No tokens used — tap retry or send again.")
                messages.append(fallback)
                return
            }

            let tokensUsed = max(1, responseText.count / 40)
            let coachMessage = CoachMessage(role: .coach, content: responseText)
            messages.append(coachMessage)
            conversationHistory.append(GeminiContent(role: "model", parts: [GeminiPart(text: responseText)]))
            recordTokensUsed(tokensUsed)
            extractAndSaveMemory(userText: userMessage.content, coachText: responseText)
        } catch is URLError {
            isOffline = true
            conversationHistory.removeLast()
            lastFailedUserText = text
            let offlineResponse = getOfflineResponse(for: text)
            let offlineMsg = CoachMessage(role: .coach, content: "\(offlineResponse)\n\n_\u{1F4F6} Offline mode — no tokens used. Connect to the internet for personalized coaching._")
            messages.append(offlineMsg)
        } catch {
            errorMessage = "Connection error. Check your internet and try again."
            conversationHistory.removeLast()
            lastFailedUserText = text
            let errorMsg = CoachMessage(role: .coach, content: "Message failed — no tokens used. Check your connection and tap retry.")
            messages.append(errorMsg)
        }
    }

    func retryLastMessage() async {
        guard let text = lastFailedUserText else { return }
        if let lastMsg = messages.last, lastMsg.role == .coach, lastMsg.content.contains("no tokens used") {
            messages.removeLast()
        }
        if let lastUserMsg = messages.last, lastUserMsg.role == .user {
            messages.removeLast()
        }
        await sendMessage(text)
    }

    func clearHistory() {
        messages.removeAll()
        conversationHistory.removeAll()
        clearCache()
    }

    var formattedTokensRemaining: String {
        if tokensRemaining >= 10_000 {
            return String(format: "%.1fK", Double(tokensRemaining) / 1_000.0)
        } else if tokensRemaining >= 1_000 {
            return String(format: "%.1fK", Double(tokensRemaining) / 1_000.0)
        }
        return "\(tokensRemaining)"
    }

    private func extractAndSaveMemory(userText: String, coachText: String) {
        let lower = userText.lowercased()
        if lower.contains("scored") || lower.contains("goal") || lower.contains("hit") {
            storage?.addCoachMemory(CoachMemoryEntry(type: .improvement, content: "Player reported: \(userText)"))
        }
        if lower.contains("struggling") || lower.contains("can't") || lower.contains("hard") || lower.contains("weak") {
            storage?.addCoachMemory(CoachMemoryEntry(type: .weakness, content: "Player mentioned difficulty: \(userText)"))
        }
        if lower.contains("completed") || lower.contains("finished") || lower.contains("did") && lower.contains("drill") {
            storage?.addCoachMemory(CoachMemoryEntry(type: .drillCompleted, content: "Player completed: \(userText)"))
        }
    }

    private func getOfflineResponse(for query: String) -> String {
        let lowered = query.lowercased()
        for (keyword, response) in Self.offlineResponses {
            if keyword != "default" && lowered.contains(keyword) {
                return response
            }
        }
        return Self.offlineResponses["default"]!
    }

    private func cacheMessages() {
        let cacheable = messages.map { CachedMessage(role: $0.role == .user ? "user" : "coach", content: $0.content) }
        if let data = try? JSONEncoder().encode(cacheable) {
            UserDefaults.standard.set(data, forKey: Self.cacheKey)
        }
    }

    private func loadCachedMessages() {
        guard let data = UserDefaults.standard.data(forKey: Self.cacheKey),
              let cached = try? JSONDecoder().decode([CachedMessage].self, from: data) else { return }
        messages = cached.map {
            CoachMessage(role: $0.role == "user" ? .user : .coach, content: $0.content)
        }
    }

    private func clearCache() {
        UserDefaults.standard.removeObject(forKey: Self.cacheKey)
    }
}

nonisolated struct CachedMessage: Codable, Sendable {
    let role: String
    let content: String
}
