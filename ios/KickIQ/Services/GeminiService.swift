import Foundation
import UIKit

nonisolated struct GeminiResponse: Codable, Sendable {
    let candidates: [GeminiCandidate]?
    let error: GeminiErrorDetail?
}

nonisolated struct GeminiCandidate: Codable, Sendable {
    let content: GeminiContent?
    let finishReason: String?
}

nonisolated struct GeminiContent: Codable, Sendable {
    let parts: [GeminiPart]?
    let role: String?
}

nonisolated struct GeminiPart: Codable, Sendable {
    let text: String?
}

nonisolated struct GeminiErrorDetail: Codable, Sendable {
    let message: String?
    let status: String?
    let code: Int?
}

nonisolated struct GeminiRequest: Codable, Sendable {
    let contents: [GeminiRequestContent]
    let systemInstruction: GeminiRequestContent?
    let generationConfig: GeminiGenerationConfig?
}

nonisolated struct GeminiRequestContent: Codable, Sendable {
    let role: String?
    let parts: [GeminiRequestPart]
}

nonisolated struct GeminiRequestPart: Codable, Sendable {
    let text: String?
    let inlineData: GeminiInlineData?

    enum CodingKeys: String, CodingKey {
        case text
        case inlineData = "inline_data"
    }
}

nonisolated struct GeminiInlineData: Codable, Sendable {
    let mimeType: String
    let data: String

    enum CodingKeys: String, CodingKey {
        case mimeType = "mime_type"
        case data
    }
}

nonisolated struct GeminiGenerationConfig: Codable, Sendable {
    let temperature: Double?
    let maxOutputTokens: Int?
}

enum GeminiService {
    private static let baseURL = "https://generativelanguage.googleapis.com/v1beta"
    private static let model = "gemini-2.5-flash"

    static func generateContent(
        systemPrompt: String?,
        messages: [(role: String, content: String)],
        temperature: Double = 0.7,
        maxTokens: Int = 4096
    ) async throws -> String {
        let apiKey = Config.EXPO_PUBLIC_GEMINI_API_KEY
        guard !apiKey.isEmpty else {
            throw GeminiError.apiKeyMissing
        }

        guard let url = URL(string: "\(baseURL)/models/\(model):generateContent?key=\(apiKey)") else {
            throw GeminiError.invalidURL
        }

        let contents = messages.map { msg in
            GeminiRequestContent(
                role: msg.role == "assistant" ? "model" : "user",
                parts: [GeminiRequestPart(text: msg.content, inlineData: nil)]
            )
        }

        let systemInstruction: GeminiRequestContent?
        if let systemPrompt, !systemPrompt.isEmpty {
            systemInstruction = GeminiRequestContent(
                role: nil,
                parts: [GeminiRequestPart(text: systemPrompt, inlineData: nil)]
            )
        } else {
            systemInstruction = nil
        }

        let requestBody = GeminiRequest(
            contents: contents,
            systemInstruction: systemInstruction,
            generationConfig: GeminiGenerationConfig(
                temperature: temperature,
                maxOutputTokens: maxTokens
            )
        )

        let jsonData = try JSONEncoder().encode(requestBody)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 60

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.networkError
        }

        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)

        if let error = geminiResponse.error {
            throw GeminiError.apiError(
                code: httpResponse.statusCode,
                message: error.message ?? "Unknown API error"
            )
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw GeminiError.apiError(code: httpResponse.statusCode, message: body.prefix(200).description)
        }

        guard let text = geminiResponse.candidates?.first?.content?.parts?.first?.text, !text.isEmpty else {
            throw GeminiError.emptyResponse
        }

        return text
    }

    static func generateContentWithImages(
        systemPrompt: String?,
        prompt: String,
        images: [UIImage],
        temperature: Double = 0.7,
        maxTokens: Int = 8192
    ) async throws -> String {
        let apiKey = Config.EXPO_PUBLIC_GEMINI_API_KEY
        guard !apiKey.isEmpty else {
            throw GeminiError.apiKeyMissing
        }

        guard let url = URL(string: "\(baseURL)/models/\(model):generateContent?key=\(apiKey)") else {
            throw GeminiError.invalidURL
        }

        var parts: [GeminiRequestPart] = [
            GeminiRequestPart(text: prompt, inlineData: nil)
        ]

        for image in images {
            if let jpegData = image.jpegData(compressionQuality: 0.5) {
                let base64 = jpegData.base64EncodedString()
                parts.append(GeminiRequestPart(
                    text: nil,
                    inlineData: GeminiInlineData(mimeType: "image/jpeg", data: base64)
                ))
            }
        }

        let contents = [GeminiRequestContent(role: "user", parts: parts)]

        let systemInstruction: GeminiRequestContent?
        if let systemPrompt, !systemPrompt.isEmpty {
            systemInstruction = GeminiRequestContent(
                role: nil,
                parts: [GeminiRequestPart(text: systemPrompt, inlineData: nil)]
            )
        } else {
            systemInstruction = nil
        }

        let requestBody = GeminiRequest(
            contents: contents,
            systemInstruction: systemInstruction,
            generationConfig: GeminiGenerationConfig(
                temperature: temperature,
                maxOutputTokens: maxTokens
            )
        )

        let jsonData = try JSONEncoder().encode(requestBody)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 90

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.networkError
        }

        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)

        if let error = geminiResponse.error {
            throw GeminiError.apiError(
                code: httpResponse.statusCode,
                message: error.message ?? "Unknown API error"
            )
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw GeminiError.apiError(code: httpResponse.statusCode, message: body.prefix(200).description)
        }

        guard let text = geminiResponse.candidates?.first?.content?.parts?.first?.text, !text.isEmpty else {
            throw GeminiError.emptyResponse
        }

        return text
    }
}

nonisolated enum GeminiError: Error, LocalizedError, Sendable {
    case apiKeyMissing
    case invalidURL
    case networkError
    case apiError(code: Int, message: String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .apiKeyMissing: "Gemini API key is not configured."
        case .invalidURL: "Invalid API URL."
        case .networkError: "Could not connect to Gemini."
        case .apiError(let code, let message): "Gemini error (\(code)): \(message)"
        case .emptyResponse: "Received an empty response from Gemini."
        }
    }

    var userMessage: String {
        switch self {
        case .apiKeyMissing:
            "AI Coach isn't configured yet. Please add your Gemini API key."
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
