import Foundation

nonisolated struct GroqChatMessage: Codable, Sendable {
    let role: String
    let content: String
}

nonisolated struct GroqRequest: Codable, Sendable {
    let model: String
    let messages: [GroqChatMessage]
    let temperature: Double?
    let max_tokens: Int?
}

nonisolated struct GroqResponse: Codable, Sendable {
    let choices: [GroqChoice]?
    let error: GroqErrorDetail?
}

nonisolated struct GroqChoice: Codable, Sendable {
    let message: GroqResponseMessage?
    let finish_reason: String?
}

nonisolated struct GroqResponseMessage: Codable, Sendable {
    let role: String?
    let content: String?
}

nonisolated struct GroqErrorDetail: Codable, Sendable {
    let message: String?
    let type: String?
    let code: String?
}

nonisolated enum GroqError: Error, LocalizedError, Sendable {
    case apiKeyMissing
    case invalidURL
    case networkError
    case apiError(code: Int, message: String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .apiKeyMissing: "Groq API key is not configured."
        case .invalidURL: "Invalid API URL."
        case .networkError: "Could not connect to Groq."
        case .apiError(let code, let message): "Groq error (\(code)): \(message)"
        case .emptyResponse: "Received an empty response from Groq."
        }
    }

    var userMessage: String {
        switch self {
        case .apiKeyMissing:
            "AI Coach isn't configured yet. Please add your Groq API key."
        case .invalidURL:
            "There's a configuration issue. Please try again later."
        case .networkError:
            "Couldn't reach the AI server — check your internet connection. Your token has been refunded."
        case .apiError(let code, let message):
            "AI error (\(code)): \(message.prefix(120)). Token refunded."
        case .emptyResponse:
            "Got an empty response — your token has been refunded. Please try again."
        }
    }
}

enum GroqService {
    private static let baseURL = "https://api.groq.com/openai/v1/chat/completions"
    private static let model = "llama-3.3-70b-versatile"

    static func chatCompletion(
        systemPrompt: String?,
        messages: [(role: String, content: String)],
        temperature: Double = 0.7,
        maxTokens: Int = 2048
    ) async throws -> String {
        let apiKey = Config.EXPO_PUBLIC_GROQ_API_KEY
        guard !apiKey.isEmpty else {
            throw GroqError.apiKeyMissing
        }

        guard let url = URL(string: baseURL) else {
            throw GroqError.invalidURL
        }

        var groqMessages: [GroqChatMessage] = []

        if let systemPrompt, !systemPrompt.isEmpty {
            groqMessages.append(GroqChatMessage(role: "system", content: systemPrompt))
        }

        for msg in messages {
            groqMessages.append(GroqChatMessage(role: msg.role, content: msg.content))
        }

        let requestBody = GroqRequest(
            model: model,
            messages: groqMessages,
            temperature: temperature,
            max_tokens: maxTokens
        )

        let jsonData = try JSONEncoder().encode(requestBody)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        request.timeoutInterval = 60

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GroqError.networkError
        }

        let groqResponse = try JSONDecoder().decode(GroqResponse.self, from: data)

        if let error = groqResponse.error {
            throw GroqError.apiError(
                code: httpResponse.statusCode,
                message: error.message ?? "Unknown API error"
            )
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw GroqError.apiError(code: httpResponse.statusCode, message: body.prefix(200).description)
        }

        guard let text = groqResponse.choices?.first?.message?.content, !text.isEmpty else {
            throw GroqError.emptyResponse
        }

        return text
    }
}
