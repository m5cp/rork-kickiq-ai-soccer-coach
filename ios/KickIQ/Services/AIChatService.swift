import Foundation

nonisolated struct ChatMessage: Identifiable, Sendable {
    let id: String
    let role: ChatRole
    let content: String
    let timestamp: Date
    let isError: Bool

    init(id: String = UUID().uuidString, role: ChatRole, content: String, timestamp: Date = .now, isError: Bool = false) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.isError = isError
    }
}

nonisolated enum ChatRole: String, Sendable {
    case user
    case assistant
    case system
}

@Observable
@MainActor
class AIChatService {
    var messages: [ChatMessage] = []
    var isResponding = false
    var errorMessage: String?

    private let tokenService = ChatTokenService.shared

    func sendMessage(_ text: String, storage: StorageService) async {
        guard tokenService.canSendMessage else { return }

        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)
        tokenService.consumeToken()

        isResponding = true
        errorMessage = nil

        do {
            let response = try await callAI(storage: storage)
            let assistantMessage = ChatMessage(role: .assistant, content: response)
            messages.append(assistantMessage)
        } catch let chatErr as ChatError {
            tokenService.refundToken()
            let errorMsg = ChatMessage(
                role: .assistant,
                content: chatErr.userMessage,
                isError: true
            )
            messages.append(errorMsg)
            errorMessage = chatErr.localizedDescription
        } catch {
            tokenService.refundToken()
            let errorMsg = ChatMessage(
                role: .assistant,
                content: "Connection error — your token has been refunded. Check your internet and try again.",
                isError: true
            )
            messages.append(errorMsg)
            errorMessage = error.localizedDescription
        }

        isResponding = false
    }

    func clearChat() {
        messages = []
        tokenService.startNewSession()
    }

    private func callAI(storage: StorageService) async throws -> String {
        let systemContext = buildSystemContext(storage: storage)

        let chatMessages = messages.filter { !$0.isError }.map { msg in
            (role: msg.role.rawValue, content: msg.content)
        }

        do {
            return try await GeminiService.generateContent(
                systemPrompt: systemContext,
                messages: chatMessages,
                temperature: 0.7,
                maxTokens: 2048
            )
        } catch let error as GeminiError {
            throw ChatError.geminiError(error)
        }
    }

    private func buildSystemContext(storage: StorageService) -> String {
        let profile = storage.profile
        let role = profile?.userRole ?? .player
        let name = profile?.name ?? "Player"
        let score = storage.skillScore
        let streak = storage.streakCount
        let analysisCount = storage.analysisCount

        if role == .coach {
            return buildCoachContext(profile: profile, name: name, analysisCount: analysisCount)
        }

        let position = profile?.position.rawValue ?? "Unknown"
        let level = profile?.skillLevel.rawValue ?? "Unknown"
        let weakness = profile?.weakness.rawValue ?? "Unknown"

        var latestFeedback = ""
        if let latest = storage.latestSession {
            latestFeedback = """
            Latest analysis (score: \(latest.overallScore)/100):
            Feedback: \(latest.feedback)
            Top improvement area: \(latest.topImprovement)
            Skill scores: \(latest.skillScores.map { "\($0.category.rawValue): \($0.score)/10" }.joined(separator: ", "))
            """
            if let sf = latest.structuredFeedback {
                latestFeedback += "\nStrengths: \(sf.strengths.joined(separator: ", "))"
                latestFeedback += "\nNeeds improvement: \(sf.needsImprovement.joined(separator: ", "))"
            }
        }

        let weakSkills = storage.weakestSkills.map(\.rawValue).joined(separator: ", ")

        return """
        You are KickIQ Coach, an expert AI soccer coach. You provide personalized skill improvement advice based on the player's data.

        PLAYER PROFILE:
        - Name: \(name)
        - Position: \(position)
        - Skill Level: \(level)
        - Main Weakness: \(weakness)
        - Current Skill Score: \(score)/100
        - Training Streak: \(streak) days
        - Total Analyses: \(analysisCount)
        - Weakest Skills: \(weakSkills.isEmpty ? "Not yet assessed" : weakSkills)

        \(latestFeedback.isEmpty ? "" : "LATEST ANALYSIS DATA:\n\(latestFeedback)")

        GUIDELINES:
        - Use simple, athlete-friendly language a 14-year-old club player would understand.
        - Give specific, actionable advice — not generic motivation.
        - Reference the player's actual data when relevant (their scores, position, weaknesses).
        - Suggest specific drills with clear instructions when asked.
        - Keep responses concise but helpful (2-4 paragraphs max).
        - If asked about video analysis, explain you can help interpret their results and suggest improvements.
        - Be encouraging but honest about areas that need work.
        - Never make up data you don't have — stick to what's provided.
        """
    }

    private func buildCoachContext(profile: PlayerProfile?, name: String, analysisCount: Int) -> String {
        return """
        You are KickIQ Coach Assistant, an expert AI soccer coaching advisor. You help coaches manage their teams, plan sessions, and develop players.

        COACH PROFILE:
        - Name: \(name)
        - Total Analyses Run: \(analysisCount)

        GUIDELINES:
        - You are speaking to a COACH, not a player. Use coaching terminology and strategic thinking.
        - Help with session planning, drill design, periodization, and player development strategies.
        - When asked about a player's analysis, provide coaching insights on what to work on with that player.
        - Suggest team drills, small-sided games, and session structures.
        - Help interpret video analysis results from a coaching perspective.
        - Advise on managing different skill levels within a team.
        - Provide advice on training load, recovery, and season planning.
        - Keep responses professional but practical (2-4 paragraphs max).
        - Never make up data you don't have — stick to what's provided.
        - If asked about individual players, explain you can analyze their clips and provide coaching reports.
        """
    }
}

nonisolated enum ChatError: Error, LocalizedError, Sendable {
    case configMissing(detail: String)
    case networkError
    case httpError(statusCode: Int, body: String)
    case emptyResponse
    case geminiError(GeminiError)

    var errorDescription: String? {
        switch self {
        case .configMissing(let detail): "AI service not configured: \(detail)"
        case .networkError: "Could not connect to the server."
        case .httpError(let code, _): "Server error (\(code))."
        case .emptyResponse: "Received an empty response."
        case .geminiError(let err): err.errorDescription
        }
    }

    var userMessage: String {
        switch self {
        case .configMissing(let detail):
            "AI Coach isn't configured (\(detail)). Please try again later."
        case .networkError:
            "Couldn't reach the server — check your internet connection. Your token has been refunded."
        case .httpError(let code, let body):
            "Server error (\(code)): \(body.prefix(120)). Token refunded."
        case .emptyResponse:
            "Got an empty response — your token has been refunded. Please try again."
        case .geminiError(let err):
            err.userMessage
        }
    }
}
