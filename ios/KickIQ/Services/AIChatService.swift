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
        } catch {
            tokenService.refundToken()
            let errorMsg = ChatMessage(
                role: .assistant,
                content: "Sorry, something went wrong. No charge for that — your token has been refunded. Please try again.",
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
        let toolkitURL = Config.EXPO_PUBLIC_TOOLKIT_URL
        guard !toolkitURL.isEmpty else {
            throw ChatError.notConfigured
        }

        let url = URL(string: "\(toolkitURL)/agent/chat")!

        let systemContext = buildSystemContext(storage: storage)

        var apiMessages: [[String: Any]] = [
            ["role": "system", "content": systemContext]
        ]

        for msg in messages where !msg.isError {
            apiMessages.append([
                "role": msg.role.rawValue,
                "content": msg.content
            ])
        }

        let body: [String: Any] = ["messages": apiMessages]
        let jsonData = try JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let secretKey = Config.EXPO_PUBLIC_RORK_TOOLKIT_SECRET_KEY
        if !secretKey.isEmpty {
            request.setValue("Bearer \(secretKey)", forHTTPHeaderField: "Authorization")
        }
        let appKey = Config.allValues["EXPO_PUBLIC_RORK_APP_KEY"] ?? ""
        if !appKey.isEmpty {
            request.setValue(appKey, forHTTPHeaderField: "x-app-key")
        }
        let projectId = Config.EXPO_PUBLIC_PROJECT_ID
        if !projectId.isEmpty {
            request.setValue(projectId, forHTTPHeaderField: "x-project-id")
        }
        request.httpBody = jsonData
        request.timeoutInterval = 60

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatError.serverError
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("AI Chat API error (\(httpResponse.statusCode)): \(errorBody)")
            throw ChatError.serverError
        }

        let responseText = String(data: data, encoding: .utf8) ?? ""

        if responseText.isEmpty {
            throw ChatError.emptyResponse
        }

        let cleaned = extractTextContent(from: responseText)
        if cleaned.isEmpty {
            throw ChatError.emptyResponse
        }

        return cleaned
    }

    private func extractTextContent(from response: String) -> String {
        if let jsonData = response.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            if let text = json["text"] as? String {
                return text
            }
            if let content = json["content"] as? String {
                return content
            }
            if let message = json["message"] as? String {
                return message
            }
            if let choices = json["choices"] as? [[String: Any]],
               let first = choices.first,
               let msg = first["message"] as? [String: Any],
               let content = msg["content"] as? String {
                return content
            }
            if let result = json["result"] as? String {
                return result
            }
        }
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("{") || trimmed.hasPrefix("[") {
            return ""
        }
        return trimmed
    }

    private func buildSystemContext(storage: StorageService) -> String {
        let profile = storage.profile
        let position = profile?.position.rawValue ?? "Unknown"
        let level = profile?.skillLevel.rawValue ?? "Unknown"
        let weakness = profile?.weakness.rawValue ?? "Unknown"
        let name = profile?.name ?? "Player"
        let score = storage.skillScore
        let streak = storage.streakCount
        let analysisCount = storage.analysisCount

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
}

nonisolated enum ChatError: Error, LocalizedError, Sendable {
    case notConfigured
    case serverError
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .notConfigured: "AI service is not configured."
        case .serverError: "Server returned an error. Please try again."
        case .emptyResponse: "Received an empty response. Please try again."
        }
    }
}
