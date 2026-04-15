import Foundation

@Observable
@MainActor
class WeeklySummaryService {
    var isGenerating = false
    var errorMessage: String?

    func generateSummary(storage: StorageService) async -> String? {
        isGenerating = true
        errorMessage = nil

        defer { isGenerating = false }

        let context = buildWeeklyContext(storage: storage)
        let prompt = buildPrompt(context: context, playerName: storage.profile?.name ?? "Player")

        let apiKey = Config.EXPO_PUBLIC_GROQ_API_KEY
        guard !apiKey.isEmpty else {
            errorMessage = "API key not configured"
            return nil
        }

        let endpoint = "https://api.groq.com/openai/v1/chat/completions"
        guard let url = URL(string: endpoint) else {
            errorMessage = "Invalid API configuration"
            return nil
        }

        let messages = [
            GroqMessage(role: "system", content: prompt),
            GroqMessage(role: "user", content: "Generate my weekly training summary for this past week.")
        ]

        let requestBody = GroqRequest(
            model: "llama-3.3-70b-versatile",
            messages: messages,
            temperature: 0.7,
            max_tokens: 512
        )

        do {
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            urlRequest.httpBody = try JSONEncoder().encode(requestBody)
            urlRequest.timeoutInterval = 30

            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                errorMessage = "Failed to generate summary"
                return nil
            }

            let groqResponse = try JSONDecoder().decode(GroqResponse.self, from: data)

            guard let responseText = groqResponse.choices?.first?.message?.content,
                  !responseText.isEmpty else {
                errorMessage = "Empty response"
                return nil
            }

            storage.saveWeeklySummary(responseText)
            return responseText
        } catch is URLError {
            errorMessage = "No internet connection"
            return nil
        } catch {
            errorMessage = "Failed to generate summary"
            return nil
        }
    }

    private func buildWeeklyContext(storage: StorageService) -> String {
        var lines: [String] = []

        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now))!

        let weekCompletions = storage.drillCompletionHistory.filter { $0.date >= startOfWeek }
        let weekMinutes = weekCompletions.reduce(0) { $0 + $1.durationSeconds } / 60
        let uniqueDrills = Set(weekCompletions.map(\.drillName))

        lines.append("Training volume: \(weekCompletions.count) exercises completed, \(weekMinutes) total minutes")
        if !uniqueDrills.isEmpty {
            lines.append("Drills practiced: \(uniqueDrills.joined(separator: ", "))")
        }

        lines.append("Current streak: \(storage.streakCount) days")
        lines.append("XP: \(storage.xpPoints), Level: \(storage.playerLevel.rawValue)")

        if !storage.benchmarkResults.isEmpty {
            let improving = storage.benchmarkResults.filter { $0.trend == .improving }.count
            let declining = storage.benchmarkResults.filter { $0.trend == .declining }.count
            lines.append("Benchmark trends: \(improving) improving, \(declining) declining")
            lines.append("Overall benchmark: \(Int(storage.benchmarkOverallScore))% (\(storage.benchmarkPlayerRank.rawValue))")
        }

        let weekAnnotations = storage.trainingAnnotations.filter { $0.date >= startOfWeek }
        for annotation in weekAnnotations {
            if !annotation.notes.isEmpty {
                lines.append("Player note: \(annotation.notes)")
            }
        }

        let recentMemory = storage.coachMemory.suffix(8)
        if !recentMemory.isEmpty {
            lines.append("\nRecent coach chat topics:")
            for entry in recentMemory {
                lines.append("- [\(entry.type.rawValue)] \(entry.content)")
            }
        }

        if let weakness = storage.profile?.weakness {
            lines.append("Focus area: \(weakness.rawValue)")
        }
        if let position = storage.profile?.position {
            lines.append("Position: \(position.rawValue)")
        }

        let goal = storage.weeklyGoal
        let weekSessions = storage.weeklySessionsCompleted
        let target = goal?.sessionsPerWeek ?? 3
        lines.append("Weekly goal: \(weekSessions)/\(target) sessions completed")

        return lines.joined(separator: "\n")
    }

    private func buildPrompt(context: String, playerName: String) -> String {
        """
        You are a supportive, knowledgeable youth soccer coach writing a brief weekly training summary for \(playerName). Write in a natural, encouraging tone — like a real coach giving a weekly debrief.

        PLAYER'S WEEK DATA:
        \(context)

        RULES:
        - Keep it to 3-4 short paragraphs max
        - Reference specific drills, scores, or streaks from the data
        - If they discussed topics in coach chat, weave those in naturally
        - Celebrate wins (streaks, improvements, consistency)
        - Gently note areas to focus on next week
        - End with one specific, actionable suggestion for next week
        - Do NOT use bullet points or headers — write flowing prose
        - Do NOT start with "Hey" or "Hi" — jump right into the summary
        - Sound like a real coach, not a chatbot
        """
    }

    func shouldAutoGenerate(storage: StorageService) -> Bool {
        guard let lastDate = storage.weeklySummaryDate else { return true }
        let daysSince = Calendar.current.dateComponents([.day], from: lastDate, to: .now).day ?? 0
        return daysSince >= 7
    }
}
