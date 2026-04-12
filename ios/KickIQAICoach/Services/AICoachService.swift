import Foundation

nonisolated struct GeminiMessage: Codable, Sendable {
    let role: String
    let parts: [GeminiPart]
}

nonisolated struct GeminiPart: Codable, Sendable {
    let text: String?

    init(text: String) {
        self.text = text
    }
}

nonisolated struct GeminiRequest: Codable, Sendable {
    let contents: [GeminiMessage]
    let systemInstruction: GeminiSystemInstruction?
    let generationConfig: GeminiGenerationConfig?
}

nonisolated struct GeminiSystemInstruction: Codable, Sendable {
    let parts: [GeminiPart]
}

nonisolated struct GeminiGenerationConfig: Codable, Sendable {
    let temperature: Double?
    let maxOutputTokens: Int?
}

nonisolated struct GeminiResponse: Codable, Sendable {
    let candidates: [GeminiCandidate]?
}

nonisolated struct GeminiCandidate: Codable, Sendable {
    let content: GeminiCandidateContent?
}

nonisolated struct GeminiCandidateContent: Codable, Sendable {
    let parts: [GeminiPart]?
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

@Observable
@MainActor
class AICoachService {
    var messages: [CoachMessage] = []
    var isLoading = false
    var errorMessage: String?
    var isOffline = false
    var hasShownOnboarding = false

    private var conversationHistory: [GeminiMessage] = []
    private let systemPrompt: String
    private let playerName: String
    private let position: String
    private let weakness: String

    private static let cacheKey = "kickiq_coach_cache"
    private static let onboardingKey = "kickiq_coach_onboarded"

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

    init(playerName: String = "Player", position: String = "Midfielder", skillLevel: String = "Intermediate", weakness: String = "First Touch") {
        self.playerName = playerName
        self.position = position
        self.weakness = weakness
        self.systemPrompt = """
        You are KickIQ Coach, an elite AI soccer coaching assistant. You are knowledgeable, motivating, and direct — like a top-tier youth academy coach.

        Player Profile:
        - Name: \(playerName)
        - Position: \(position)
        - Skill Level: \(skillLevel)
        - Focus Area: \(weakness)

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
        """
        hasShownOnboarding = UserDefaults.standard.bool(forKey: Self.onboardingKey)
        loadCachedMessages()
    }

    func startOnboardingConversation() {
        guard !hasShownOnboarding else { return }
        hasShownOnboarding = true
        UserDefaults.standard.set(true, forKey: Self.onboardingKey)

        let greeting = CoachMessage(
            role: .coach,
            content: "Hey \(playerName)! I'm your KickIQ AI Coach. I already know you play \(position) and want to work on \(weakness) — so I'm ready to help.\n\nYou can ask me anything: drill plans, technique tips, game-day advice, or how to improve a specific skill. I'll tailor everything to your level and position.\n\nTry asking something like \"Give me a 20-minute session for my \(weakness.lowercased())\" to get started!"
        )
        messages.append(greeting)
    }

    func sendMessage(_ text: String) async {
        let userMessage = CoachMessage(role: .user, content: text)
        messages.append(userMessage)

        conversationHistory.append(GeminiMessage(role: "user", parts: [GeminiPart(text: text)]))

        isLoading = true
        errorMessage = nil
        isOffline = false

        defer {
            isLoading = false
            cacheMessages()
        }

        let apiKey = Config.EXPO_PUBLIC_GEMINI_API_KEY
        guard !apiKey.isEmpty else {
            let fallback = CoachMessage(role: .coach, content: "AI Coach is not configured yet. Please add your Gemini API key to use this feature.")
            messages.append(fallback)
            return
        }

        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid API configuration"
            return
        }

        let request = GeminiRequest(
            contents: conversationHistory,
            systemInstruction: GeminiSystemInstruction(parts: [GeminiPart(text: systemPrompt)]),
            generationConfig: GeminiGenerationConfig(temperature: 0.8, maxOutputTokens: 1024)
        )

        do {
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = try JSONEncoder().encode(request)
            urlRequest.timeoutInterval = 30

            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                errorMessage = "Coach unavailable (error \(statusCode)). Try again."
                let errorMsg = CoachMessage(role: .coach, content: "I'm having trouble connecting right now. Give me a moment and try again.")
                messages.append(errorMsg)
                return
            }

            let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)

            if let text = geminiResponse.candidates?.first?.content?.parts?.first?.text, !text.isEmpty {
                let coachMessage = CoachMessage(role: .coach, content: text)
                messages.append(coachMessage)
                conversationHistory.append(GeminiMessage(role: "model", parts: [GeminiPart(text: text)]))
            } else {
                let fallback = CoachMessage(role: .coach, content: "Let me think about that differently. Can you rephrase your question?")
                messages.append(fallback)
            }
        } catch is URLError {
            isOffline = true
            let offlineResponse = getOfflineResponse(for: text)
            let offlineMsg = CoachMessage(role: .coach, content: "\(offlineResponse)\n\n_\u{1F4F6} Offline mode — connect to the internet for personalized coaching._")
            messages.append(offlineMsg)
        } catch {
            errorMessage = "Connection error. Check your internet and try again."
            let errorMsg = CoachMessage(role: .coach, content: "Looks like we lost connection. Make sure you're online and try sending that again.")
            messages.append(errorMsg)
        }
    }

    func clearHistory() {
        messages.removeAll()
        conversationHistory.removeAll()
        clearCache()
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
