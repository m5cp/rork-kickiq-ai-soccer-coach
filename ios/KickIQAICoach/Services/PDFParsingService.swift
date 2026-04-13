import Foundation
import PDFKit

@Observable
@MainActor
class PDFParsingService {
    var isProcessing = false
    var errorMessage: String?
    var parseResult: PDFParseResult?

    func extractTextFromPDF(at url: URL) -> String? {
        guard let document = PDFDocument(url: url) else { return nil }
        var fullText = ""
        for i in 0..<document.pageCount {
            if let page = document.page(at: i), let text = page.string {
                fullText += text + "\n"
            }
        }
        return fullText.isEmpty ? nil : fullText
    }

    func parsePDFWithAI(text: String, contentType: CustomContentType, fileName: String) async {
        isProcessing = true
        errorMessage = nil
        parseResult = nil

        defer { isProcessing = false }

        let toolkitURL = Config.EXPO_PUBLIC_TOOLKIT_URL
        guard !toolkitURL.isEmpty else {
            errorMessage = "AI not configured. Please try again later."
            return
        }

        let prompt = buildPrompt(for: contentType, text: text)
        let systemMsg = "You are a soccer training document parser. Extract drills, exercises, and benchmarks from documents into structured JSON. Always return valid JSON."

        let endpoint = toolkitURL.hasSuffix("/") ? "\(toolkitURL)agent/chat" : "\(toolkitURL)/agent/chat"
        guard let url = URL(string: endpoint) else {
            errorMessage = "Invalid API configuration"
            return
        }

        let requestBody = ToolkitChatRequest(messages: [
            ToolkitMessage(role: "system", content: systemMsg),
            ToolkitMessage(role: "user", content: prompt)
        ])

        do {
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = try JSONEncoder().encode(requestBody)
            urlRequest.timeoutInterval = 60

            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                errorMessage = "Failed to process document. Please try again."
                return
            }

            let responseText: String
            if let toolkitResponse = try? JSONDecoder().decode(ToolkitChatResponse.self, from: data),
               let txt = toolkitResponse.text, !txt.isEmpty {
                responseText = txt
            } else if let rawString = String(data: data, encoding: .utf8), !rawString.isEmpty {
                responseText = rawString.trimmingCharacters(in: CharacterSet(charactersIn: "\"").union(.whitespacesAndNewlines))
            } else {
                errorMessage = "Could not extract content from document."
                return
            }

            let jsonString = extractJSON(from: responseText)
            guard let jsonData = jsonString.data(using: .utf8) else {
                errorMessage = "Failed to parse AI response."
                return
            }

            parseResult = try JSONDecoder().decode(PDFParseResult.self, from: jsonData)
        } catch is DecodingError {
            errorMessage = "Could not understand the document format. Try a different PDF."
        } catch is URLError {
            errorMessage = "No internet connection. Please try again when online."
        } catch {
            errorMessage = "Error processing document: \(error.localizedDescription)"
        }
    }

    private func buildPrompt(for contentType: CustomContentType, text: String) -> String {
        let typeInstructions: String
        switch contentType {
        case .drill:
            typeInstructions = """
            Focus on extracting SKILL DRILLS (ball control, passing, shooting, dribbling, first touch, etc.)
            For each drill extract: name, description, duration (e.g. "10 min"), difficulty (Beginner/Intermediate/Advanced), targetSkill (the skill category), coachingCues (list of tips), reps.
            Put results in the "drills" array. Leave "conditioning" and "benchmarks" as empty arrays.
            """
        case .conditioning:
            typeInstructions = """
            Focus on extracting CONDITIONING/FITNESS exercises (speed, endurance, strength, flexibility, plyometrics).
            For each exercise extract: name, description, duration (e.g. "10 min"), difficulty (Beginner/Intermediate/Advanced), focus (Speed & Agility/Endurance/Strength/Flexibility & Recovery/Plyometrics), coachingCues (list of tips), reps.
            Put results in the "conditioning" array. Leave "drills" and "benchmarks" as empty arrays.
            """
        case .benchmark:
            typeInstructions = """
            Focus on extracting BENCHMARK TESTS (timed tests, scored evaluations, measurable assessments).
            For each benchmark extract: name, category (Ball Control/First Touch/Passing/Shooting/Dribbling/Agility/Endurance), instructions (how to perform), howToRecord (what to measure), unit (e.g. "seconds", "touches", "out of 10"), higherIsBetter (true if higher score = better).
            Put results in the "benchmarks" array. Leave "drills" and "conditioning" as empty arrays.
            """
        }

        return """
        Parse this soccer training document and extract the exercises/drills into structured JSON.

        \(typeInstructions)

        Return ONLY valid JSON with this exact structure (no markdown, no explanation):
        {
            "drills": [{"name": "", "description": "", "duration": "", "difficulty": "", "targetSkill": "", "coachingCues": [], "reps": ""}],
            "conditioning": [{"name": "", "description": "", "duration": "", "difficulty": "", "focus": "", "coachingCues": [], "reps": ""}],
            "benchmarks": [{"name": "", "category": "", "instructions": "", "howToRecord": "", "unit": "", "higherIsBetter": true}]
        }

        If the document doesn't contain relevant content for a category, return an empty array for that category.
        Extract as many items as you can find. Be thorough.

        DOCUMENT TEXT:
        \(String(text.prefix(8000)))
        """
    }

    private func extractJSON(from text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
