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

    private var conversationHistory: [GeminiMessage] = []

    private let systemPrompt: String

    init(playerName: String = "Player", position: String = "Midfielder", skillLevel: String = "Intermediate", weakness: String = "First Touch") {
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
    }

    func sendMessage(_ text: String) async {
        let userMessage = CoachMessage(role: .user, content: text)
        messages.append(userMessage)

        conversationHistory.append(GeminiMessage(role: "user", parts: [GeminiPart(text: text)]))

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

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
        } catch {
            errorMessage = "Connection error. Check your internet and try again."
            let errorMsg = CoachMessage(role: .coach, content: "Looks like we lost connection. Make sure you're online and try sending that again.")
            messages.append(errorMsg)
        }
    }

    func clearHistory() {
        messages.removeAll()
        conversationHistory.removeAll()
    }
}
