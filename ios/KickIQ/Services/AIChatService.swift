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
        let toolkitURL = Config.EXPO_PUBLIC_TOOLKIT_URL
        guard !toolkitURL.isEmpty else {
            throw ChatError.notConfigured
        }

        let baseURL = toolkitURL.hasSuffix("/") ? String(toolkitURL.dropLast()) : toolkitURL
        guard let url = URL(string: "\(baseURL)/agent/chat") else {
            throw ChatError.notConfigured
        }

        let systemContext = buildSystemContext(storage: storage)

        var apiMessages: [[String: Any]] = []

        for msg in messages where !msg.isError {
            apiMessages.append([
                "role": msg.role.rawValue,
                "content": msg.content
            ])
        }

        let body: [String: Any] = [
            "messages": apiMessages,
            "system": systemContext
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let secretKey = Config.EXPO_PUBLIC_RORK_TOOLKIT_SECRET_KEY
        if !secretKey.isEmpty {
            request.setValue("Bearer \(secretKey)", forHTTPHeaderField: "Authorization")
        }
        let appKey = ConfigHelper.value(forKey: "EXPO_PUBLIC_RORK_APP_KEY")
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
            throw ChatError.networkError
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("[KickIQ] AI Chat API error (\(httpResponse.statusCode)): \(errorBody)")
            throw ChatError.httpError(statusCode: httpResponse.statusCode, body: errorBody)
        }

        let responseText = String(data: data, encoding: .utf8) ?? ""

        if responseText.isEmpty {
            throw ChatError.emptyResponse
        }

        let cleaned = extractTextContent(from: responseText)
        if cleaned.isEmpty {
            print("[KickIQ] AI Chat: could not parse response: \(responseText.prefix(500))")
            throw ChatError.emptyResponse
        }

        return cleaned
    }

    private func extractTextContent(from response: String) -> String {
        let v4Text = parseVercelV4Stream(response)
        if !v4Text.isEmpty {
            return v4Text
        }

        if response.contains("data: ") {
            let sseText = parseSSEResponse(response)
            if !sseText.isEmpty {
                return sseText
            }
        }

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
            if let messages = json["messages"] as? [[String: Any]],
               let last = messages.last(where: { ($0["role"] as? String) == "assistant" }) {
                if let content = last["content"] as? String {
                    return content
                }
                if let parts = last["content"] as? [[String: Any]] {
                    let textParts = parts.compactMap { part -> String? in
                        guard (part["type"] as? String) == "text" else { return nil }
                        return part["text"] as? String
                    }
                    if !textParts.isEmpty {
                        return textParts.joined()
                    }
                }
                if let parts = last["parts"] as? [[String: Any]] {
                    let textParts = parts.compactMap { part -> String? in
                        guard (part["type"] as? String) == "text" else { return nil }
                        return part["text"] as? String
                    }
                    if !textParts.isEmpty {
                        return textParts.joined()
                    }
                }
            }
        }
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("{") || trimmed.hasPrefix("[") {
            return ""
        }
        return trimmed
    }

    private func parseVercelV4Stream(_ response: String) -> String {
        var collectedText = ""
        let lines = response.components(separatedBy: "\n")
        var hasV4Lines = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            if trimmed.hasPrefix("0:") {
                hasV4Lines = true
                let payload = String(trimmed.dropFirst(2))
                if let data = payload.data(using: .utf8),
                   let text = try? JSONSerialization.jsonObject(with: data) as? String {
                    collectedText += text
                }
            } else if trimmed.hasPrefix("f:") || trimmed.hasPrefix("d:") || trimmed.hasPrefix("e:") {
                hasV4Lines = true
            }
        }

        return hasV4Lines ? collectedText.trimmingCharacters(in: .whitespacesAndNewlines) : ""
    }

    private func parseSSEResponse(_ response: String) -> String {
        var collectedText = ""
        let lines = response.components(separatedBy: "\n")

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("data: ") else { continue }

            let payload = String(trimmed.dropFirst(6))
            if payload == "[DONE]" { break }

            guard let data = payload.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                continue
            }

            if let type = json["type"] as? String {
                if type == "text-delta" {
                    if let delta = json["delta"] as? String {
                        collectedText += delta
                    }
                } else if type == "text" {
                    if let textVal = json["text"] as? String {
                        collectedText += textVal
                    }
                } else if type == "content_block_delta" {
                    if let delta = json["delta"] as? [String: Any],
                       let text = delta["text"] as? String {
                        collectedText += text
                    }
                }
                continue
            }

            if let text = json["text"] as? String {
                collectedText += text
            } else if let delta = json["delta"] as? [String: Any],
                      let content = delta["content"] as? String {
                collectedText += content
            } else if let choices = json["choices"] as? [[String: Any]],
                      let first = choices.first,
                      let delta = first["delta"] as? [String: Any],
                      let content = delta["content"] as? String {
                collectedText += content
            } else if let content = json["content"] as? String {
                collectedText += content
            }
        }

        return collectedText.trimmingCharacters(in: .whitespacesAndNewlines)
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
    case networkError
    case httpError(statusCode: Int, body: String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .notConfigured: "AI service is not configured."
        case .networkError: "Could not connect to the server."
        case .httpError(let code, _): "Server error (\(code))."
        case .emptyResponse: "Received an empty response."
        }
    }

    var userMessage: String {
        switch self {
        case .notConfigured:
            "AI Coach isn't configured yet. Please try again later."
        case .networkError:
            "Couldn't reach the server — check your internet connection. Your token has been refunded."
        case .httpError(let code, _):
            "Server error (\(code)) — your token has been refunded. Please try again."
        case .emptyResponse:
            "Got an empty response — your token has been refunded. Please try again."
        }
    }
}
