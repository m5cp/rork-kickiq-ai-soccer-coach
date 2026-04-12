import Foundation
import UIKit
import PhotosUI

nonisolated struct AIAnalysisResponse: Codable, Sendable {
    let skills: [AISkillScore]
    let feedback: String
    let drills: [AIDrill]
    let topImprovement: String?
    let strengths: [String]?
    let weaknesses: [String]?
    let coachingPoints: [String]?
}

nonisolated struct AISkillScore: Codable, Sendable {
    let skill: String
    let score: Int
    let feedback: String?
    let tip: String?
}

nonisolated struct AIDrill: Codable, Sendable {
    let name: String
    let description: String
    let duration: String
    let difficulty: String?
    let targetSkill: String
    let coachingCues: [String]?
    let reps: String?
}

@Observable
@MainActor
class AIAnalysisService {
    var isAnalyzing = false
    var analysisProgress: Double = 0
    var statusMessage: String = ""
    var errorMessage: String?

    private let analyzeMessages = [
        "KickIQ is watching your technique…",
        "Analyzing body position…",
        "Evaluating ball control…",
        "Checking movement patterns…",
        "Generating coaching feedback…"
    ]

    func analyzeVideo(thumbnailImage: UIImage, position: PlayerPosition, skillLevel: SkillLevel) async -> TrainingSession? {
        isAnalyzing = true
        analysisProgress = 0
        errorMessage = nil
        statusMessage = analyzeMessages[0]

        defer {
            isAnalyzing = false
            analysisProgress = 1.0
        }

        guard let imageData = thumbnailImage.jpegData(compressionQuality: 0.6) else {
            errorMessage = "Failed to process video frame"
            return nil
        }

        let base64Image = imageData.base64EncodedString()
        let skillNames = position.skills.map { $0.rawValue }.joined(separator: ", ")

        let prompt = """
        You are an expert soccer coach analyzing a training video frame. The player's position is \(position.rawValue) and their skill level is \(skillLevel.rawValue).

        Analyze this training frame and provide detailed, observation-based coaching feedback. Rate each of these position-specific skills on a scale of 1-10: \(skillNames).

        Your feedback must be specific to what you observe — reference body angles, foot positioning, balance, movement timing, and technique details. Avoid generic praise.

        Respond ONLY with valid JSON in this exact format:
        {
            "skills": [{"skill": "Skill Name", "score": 7, "feedback": "Specific observation about this skill", "tip": "One actionable coaching point to improve"}],
            "strengths": ["Specific strength 1", "Specific strength 2"],
            "weaknesses": ["Specific weakness 1", "Specific weakness 2"],
            "coachingPoints": ["Priority coaching point 1", "Priority coaching point 2", "Priority coaching point 3"],
            "feedback": "Detailed coaching feedback paragraph with specific observations about technique, body position, and movement quality...",
            "drills": [{"name": "Drill Name", "description": "Step-by-step how to perform the drill with proper form", "duration": "15 min", "difficulty": "Intermediate", "targetSkill": "Skill Name", "coachingCues": ["Cue 1", "Cue 2", "Cue 3"], "reps": "3x10"}],
            "topImprovement": "The skill area that needs most improvement"
        }

        Provide 3-5 drills targeting the weakest skills. Each drill must include clear coaching cues and rep schemes. Be encouraging but direct about areas needing work.
        """

        do {
            analysisProgress = 0.2
            statusMessage = analyzeMessages[1]

            let toolkitURL = Config.EXPO_PUBLIC_TOOLKIT_URL
            guard !toolkitURL.isEmpty else {
                errorMessage = "API not configured"
                return nil
            }

            let url = URL(string: "\(toolkitURL)/agent/chat")!

            let messages: [[String: Any]] = [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": prompt],
                        ["type": "image", "image": "data:image/jpeg;base64,\(base64Image)"]
                    ]
                ]
            ]

            let body: [String: Any] = ["messages": messages]
            let jsonData = try JSONSerialization.data(withJSONObject: body)

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            request.timeoutInterval = 60

            analysisProgress = 0.4
            statusMessage = analyzeMessages[2]

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                errorMessage = "Analysis failed. Please try again."
                return nil
            }

            analysisProgress = 0.7
            statusMessage = analyzeMessages[3]

            let responseText = String(data: data, encoding: .utf8) ?? ""
            let jsonString = extractJSON(from: responseText)

            guard let jsonResponseData = jsonString.data(using: .utf8) else {
                errorMessage = "Could not parse AI response"
                return nil
            }

            analysisProgress = 0.85
            statusMessage = analyzeMessages[4]

            let aiResponse = try JSONDecoder().decode(AIAnalysisResponse.self, from: jsonResponseData)

            let skillScores = aiResponse.skills.compactMap { aiSkill -> SkillScore? in
                guard let category = position.skills.first(where: { $0.rawValue == aiSkill.skill }) else { return nil }
                return SkillScore(
                    category: category,
                    score: aiSkill.score,
                    feedback: aiSkill.feedback ?? "",
                    tip: aiSkill.tip ?? ""
                )
            }

            let finalScores = skillScores.isEmpty ? generateFallbackScores(for: position) : skillScores

            let drills = aiResponse.drills.map { aiDrill in
                let diff: DrillDifficulty = switch aiDrill.difficulty?.lowercased() {
                case "beginner": .beginner
                case "advanced": .advanced
                default: .intermediate
                }
                return Drill(
                    name: aiDrill.name,
                    description: aiDrill.description,
                    duration: aiDrill.duration,
                    difficulty: diff,
                    targetSkill: aiDrill.targetSkill,
                    coachingCues: aiDrill.coachingCues ?? [],
                    reps: aiDrill.reps ?? ""
                )
            }

            let finalDrills = drills.isEmpty ? generateFallbackDrills(for: position) : drills

            return TrainingSession(
                position: position,
                skillScores: finalScores,
                feedback: aiResponse.feedback,
                drills: finalDrills,
                topImprovement: aiResponse.topImprovement ?? "",
                strengths: aiResponse.strengths ?? [],
                weaknesses: aiResponse.weaknesses ?? [],
                coachingPoints: aiResponse.coachingPoints ?? []
            )
        } catch {
            errorMessage = "Analysis error: \(error.localizedDescription)"
            return generateFallbackSession(for: position)
        }
    }

    private func extractJSON(from text: String) -> String {
        if let start = text.firstIndex(of: "{"),
           let end = text.lastIndex(of: "}") {
            return String(text[start...end])
        }
        return text
    }

    private func generateFallbackScores(for position: PlayerPosition) -> [SkillScore] {
        position.skills.map { skill in
            SkillScore(
                category: skill,
                score: Int.random(in: 5...9),
                feedback: "Good technique shown. Keep practicing consistency.",
                tip: "Focus on repetition with proper form."
            )
        }
    }

    private func generateFallbackDrills(for position: PlayerPosition) -> [Drill] {
        position.skills.prefix(3).map { skill in
            Drill(
                name: "\(skill.rawValue) Builder",
                description: "Focus on improving your \(skill.rawValue.lowercased()) with targeted repetitions.",
                duration: "15 min",
                difficulty: .intermediate,
                targetSkill: skill.rawValue,
                coachingCues: ["Stay focused on form", "Gradually increase intensity"],
                reps: "3x10"
            )
        }
    }

    private func generateFallbackSession(for position: PlayerPosition) -> TrainingSession {
        TrainingSession(
            position: position,
            skillScores: generateFallbackScores(for: position),
            feedback: "Great effort in today's session! Keep working on your technique and consistency. Focus on the drills below to target your weakest areas.",
            drills: generateFallbackDrills(for: position),
            topImprovement: position.skills.first?.rawValue ?? ""
        )
    }
}
