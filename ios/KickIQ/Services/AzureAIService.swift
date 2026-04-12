import Foundation
import UIKit

nonisolated struct AzureChatRequest: Codable, Sendable {
    let messages: [AzureChatMessage]
    let temperature: Double?
    let max_tokens: Int?
}

nonisolated struct AzureChatMessage: Codable, Sendable {
    let role: String
    let content: AzureChatContent

    init(role: String, text: String) {
        self.role = role
        self.content = .string(text)
    }

    init(role: String, parts: [AzureContentPart]) {
        self.role = role
        self.content = .parts(parts)
    }
}

nonisolated enum AzureChatContent: Codable, Sendable {
    case string(String)
    case parts([AzureContentPart])

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let text):
            try container.encode(text)
        case .parts(let parts):
            try container.encode(parts)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let text = try? container.decode(String.self) {
            self = .string(text)
        } else {
            self = .parts(try container.decode([AzureContentPart].self))
        }
    }
}

nonisolated struct AzureContentPart: Codable, Sendable {
    let type: String
    let text: String?
    let image_url: AzureImageURL?

    static func text(_ text: String) -> AzureContentPart {
        AzureContentPart(type: "text", text: text, image_url: nil)
    }

    static func imageBase64(_ base64: String, mimeType: String = "image/jpeg") -> AzureContentPart {
        AzureContentPart(
            type: "image_url",
            text: nil,
            image_url: AzureImageURL(url: "data:\(mimeType);base64,\(base64)")
        )
    }
}

nonisolated struct AzureImageURL: Codable, Sendable {
    let url: String
}

nonisolated struct AzureChatResponse: Codable, Sendable {
    let choices: [AzureChoice]?
    let error: AzureAPIError?
}

nonisolated struct AzureChoice: Codable, Sendable {
    let message: AzureResponseMessage?
    let finish_reason: String?
}

nonisolated struct AzureResponseMessage: Codable, Sendable {
    let role: String?
    let content: String?
}

nonisolated struct AzureAPIError: Codable, Sendable {
    let message: String?
    let code: String?
}

enum AzureAIService {
    private static var endpoint: String { Config.EXPO_PUBLIC_AZURE_ENDPOINT }
    private static var apiKey: String { Config.EXPO_PUBLIC_AZURE_API_KEY }
    private static var deployment: String { Config.EXPO_PUBLIC_AZURE_DEPLOYMENT }

    static func generateContent(
        systemPrompt: String?,
        messages: [(role: String, content: String)],
        temperature: Double = 0.7,
        maxTokens: Int = 4096
    ) async throws -> String {
        let url = try buildURL()

        var chatMessages: [AzureChatMessage] = []

        if let systemPrompt, !systemPrompt.isEmpty {
            chatMessages.append(AzureChatMessage(role: "system", text: systemPrompt))
        }

        for msg in messages {
            let role = msg.role == "model" ? "assistant" : msg.role
            chatMessages.append(AzureChatMessage(role: role, text: msg.content))
        }

        let requestBody = AzureChatRequest(
            messages: chatMessages,
            temperature: temperature,
            max_tokens: maxTokens
        )

        let data = try await performRequest(url: url, body: requestBody)
        return try extractText(from: data)
    }

    static func generateContentWithImages(
        systemPrompt: String?,
        prompt: String,
        images: [UIImage],
        temperature: Double = 0.7,
        maxTokens: Int = 8192
    ) async throws -> String {
        let url = try buildURL()

        var chatMessages: [AzureChatMessage] = []

        if let systemPrompt, !systemPrompt.isEmpty {
            chatMessages.append(AzureChatMessage(role: "system", text: systemPrompt))
        }

        var parts: [AzureContentPart] = [.text(prompt)]
        for image in images {
            if let jpegData = image.jpegData(compressionQuality: 0.5) {
                let base64 = jpegData.base64EncodedString()
                parts.append(.imageBase64(base64))
            }
        }

        chatMessages.append(AzureChatMessage(role: "user", parts: parts))

        let requestBody = AzureChatRequest(
            messages: chatMessages,
            temperature: temperature,
            max_tokens: maxTokens
        )

        let data = try await performRequest(url: url, body: requestBody, timeout: 90)
        return try extractText(from: data)
    }

    private static func buildURL() throws -> URL {
        guard !apiKey.isEmpty else { throw AzureAIError.apiKeyMissing }
        guard !endpoint.isEmpty else { throw AzureAIError.endpointMissing }
        guard !deployment.isEmpty else { throw AzureAIError.deploymentMissing }

        let baseURL = endpoint.hasSuffix("/") ? String(endpoint.dropLast()) : endpoint

        let urlString: String
        if baseURL.contains("services.ai.azure.com") || baseURL.contains("models.inference") {
            urlString = "\(baseURL)/openai/deployments/\(deployment)/chat/completions?api-version=2024-10-21"
        } else {
            urlString = "\(baseURL)/openai/deployments/\(deployment)/chat/completions?api-version=2024-10-21"
        }

        guard let url = URL(string: urlString) else {
            throw AzureAIError.invalidURL
        }
        return url
    }

    private static func performRequest(url: URL, body: AzureChatRequest, timeout: TimeInterval = 60) async throws -> Data {
        let jsonData = try JSONEncoder().encode(body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "api-key")
        request.httpBody = jsonData
        request.timeoutInterval = timeout

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AzureAIError.networkError
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            if let errorResponse = try? JSONDecoder().decode(AzureChatResponse.self, from: data),
               let errorMsg = errorResponse.error?.message {
                throw AzureAIError.apiError(code: httpResponse.statusCode, message: errorMsg)
            }
            throw AzureAIError.apiError(code: httpResponse.statusCode, message: body.prefix(200).description)
        }

        return data
    }

    private static func extractText(from data: Data) throws -> String {
        let response = try JSONDecoder().decode(AzureChatResponse.self, from: data)

        if let error = response.error {
            throw AzureAIError.apiError(code: 0, message: error.message ?? "Unknown API error")
        }

        guard let text = response.choices?.first?.message?.content, !text.isEmpty else {
            throw AzureAIError.emptyResponse
        }

        return text
    }
}

nonisolated enum AzureAIError: Error, LocalizedError, Sendable {
    case apiKeyMissing
    case endpointMissing
    case deploymentMissing
    case invalidURL
    case networkError
    case apiError(code: Int, message: String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .apiKeyMissing: "Azure API key is not configured."
        case .endpointMissing: "Azure endpoint is not configured."
        case .deploymentMissing: "Azure deployment name is not configured."
        case .invalidURL: "Invalid API URL."
        case .networkError: "Could not connect to Azure AI."
        case .apiError(let code, let message): "Azure AI error (\(code)): \(message)"
        case .emptyResponse: "Received an empty response from Azure AI."
        }
    }

    var userMessage: String {
        switch self {
        case .apiKeyMissing:
            "AI Coach isn't configured yet. Please add your Azure API key."
        case .endpointMissing:
            "AI Coach endpoint isn't configured. Please add your Azure endpoint."
        case .deploymentMissing:
            "AI Coach deployment isn't configured. Please add your Azure deployment name."
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
