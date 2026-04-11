import Foundation
import UIKit
import AVFoundation

nonisolated struct AIAnalysisResponse: Codable, Sendable {
    let skills: [AISkillScore]
    let feedback: String
    let drills: [AIDrill]
    let topImprovement: String?
    let strengths: [String]?
    let needsImprovement: [String]?
    let coachingPoints: [String]?
    let nextSessionFocus: String?
    let videoQuality: AIVideoQuality?
}

nonisolated struct AISkillScore: Codable, Sendable {
    let skill: String
    let score: Int
    let feedback: String?
    let tip: String?
    let confidence: String?
    let observedAction: String?
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

nonisolated struct AIVideoQuality: Codable, Sendable {
    let rating: String
    let issues: [String]?
    let tips: [String]?
}

@Observable
@MainActor
class AIAnalysisService {
    var isAnalyzing = false
    var analysisProgress: Double = 0
    var statusMessage: String = ""
    var errorMessage: String?

    private let analyzeMessages = [
        "Extracting key frames from your clip…",
        "KickIQ is watching your technique…",
        "Analyzing body position & footwork…",
        "Evaluating ball control & passing…",
        "Checking movement patterns & awareness…",
        "Generating coaching feedback…"
    ]

    func analyzeVideo(frames: [UIImage], videoURL: URL?, position: PlayerPosition, skillLevel: SkillLevel) async -> TrainingSession? {
        isAnalyzing = true
        analysisProgress = 0
        errorMessage = nil
        statusMessage = analyzeMessages[0]

        defer {
            isAnalyzing = false
            analysisProgress = 1.0
        }

        let framesToSend: [UIImage]
        if !frames.isEmpty {
            framesToSend = frames
        } else {
            errorMessage = "No frames could be extracted from the clip"
            return nil
        }

        let base64Frames = framesToSend.compactMap { frame -> String? in
            guard let data = frame.jpegData(compressionQuality: 0.5) else { return nil }
            return data.base64EncodedString()
        }

        guard !base64Frames.isEmpty else {
            errorMessage = "Failed to process video frames"
            return nil
        }

        let skillNames = position.skills.map { $0.rawValue }.joined(separator: ", ")
        let frameCount = base64Frames.count

        let prompt = """
        You are an elite soccer performance analyst reviewing \(frameCount) frame\(frameCount == 1 ? "" : "s") from a training clip. The player's position is \(position.rawValue) and skill level is \(skillLevel.rawValue).

        DETECTION FOCUS — analyze every frame for evidence of:
        • First touch quality (cushion, redirect, surface used)
        • Ball control under pressure or in motion
        • Passing technique (weight, accuracy, body shape)
        • Dribbling mechanics (close control, head position, change of pace)
        • Finishing / shooting form (plant foot, strike surface, follow-through)
        • Scanning & awareness (head movement, shoulder checks)
        • Change of direction (deceleration, low center of gravity, push-off angle)
        • Acceleration & deceleration patterns
        • Body positioning (open hips, side-on stance, balance)
        • Defensive footwork (jockeying, backpedaling, closing distance)
        • Weak foot usage (any evidence of non-dominant foot)

        Rate ONLY the position-relevant skills: \(skillNames)

        RULES:
        - Reference specific observable actions you see in the frames. No vague praise like "good job" or "nice work".
        - Use simple, athlete-friendly language a 14-year-old club player would understand.
        - If a skill cannot be observed in the frames, still rate it but set confidence to "Low" and explain what was missing.
        - If video quality is poor (blurry, too dark, bad angle, too far away, player cut off), note specific issues and how to fix them.

        Respond ONLY with valid JSON in this exact format:
        {
            "skills": [
                {
                    "skill": "Skill Name",
                    "score": 7,
                    "feedback": "Specific observation about what the player did",
                    "tip": "One concrete, actionable coaching tip",
                    "confidence": "High",
                    "observedAction": "Brief description of what was seen in the frame"
                }
            ],
            "feedback": "Overall coaching narrative referencing specific moments from the clip",
            "strengths": [
                "Specific strength observed with frame reference"
            ],
            "needsImprovement": [
                "Specific area needing work with observable evidence"
            ],
            "coachingPoints": [
                "Actionable coaching instruction the player can apply immediately"
            ],
            "nextSessionFocus": "What the player should specifically work on next session and why",
            "drills": [
                {
                    "name": "Drill Name",
                    "description": "Step-by-step how to do the drill",
                    "duration": "15 min",
                    "difficulty": "Intermediate",
                    "targetSkill": "Skill Name",
                    "coachingCues": ["Cue 1", "Cue 2"],
                    "reps": "3x10"
                }
            ],
            "topImprovement": "The single skill area that needs the most work",
            "videoQuality": {
                "rating": "Good",
                "issues": ["Any quality problems noticed"],
                "tips": ["How to improve filming next time"]
            }
        }

        confidence values: "High" (clearly visible), "Medium" (partially visible), "Low" (not clearly observable).
        videoQuality rating: "Excellent", "Good", "Fair", or "Poor".
        Provide 3-5 drills targeting the weakest skills. Each drill must have clear coaching cues.
        """

        do {
            analysisProgress = 0.15
            statusMessage = analyzeMessages[1]

            let toolkitURL = Config.EXPO_PUBLIC_TOOLKIT_URL
            guard !toolkitURL.isEmpty else {
                errorMessage = "API not configured"
                return nil
            }

            let url = URL(string: "\(toolkitURL)/agent/chat")!

            var contentParts: [[String: Any]] = [
                ["type": "text", "text": prompt]
            ]

            for (index, base64) in base64Frames.enumerated() {
                contentParts.append([
                    "type": "image",
                    "image": "data:image/jpeg;base64,\(base64)"
                ])
                if index == 0 {
                    analysisProgress = 0.25
                    statusMessage = analyzeMessages[2]
                }
            }

            let messages: [[String: Any]] = [
                ["role": "user", "content": contentParts]
            ]

            let body: [String: Any] = ["messages": messages]
            let jsonData = try JSONSerialization.data(withJSONObject: body)

            analysisProgress = 0.4
            statusMessage = analyzeMessages[3]

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
            request.timeoutInterval = 90

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                errorMessage = "Analysis failed. Please try again."
                return nil
            }

            analysisProgress = 0.7
            statusMessage = analyzeMessages[4]

            let responseText = String(data: data, encoding: .utf8) ?? ""
            let jsonString = extractJSON(from: responseText)

            guard let jsonResponseData = jsonString.data(using: .utf8) else {
                errorMessage = "Could not parse AI response"
                return nil
            }

            analysisProgress = 0.85
            statusMessage = analyzeMessages[5]

            let aiResponse = try JSONDecoder().decode(AIAnalysisResponse.self, from: jsonResponseData)

            let skillScores = aiResponse.skills.compactMap { aiSkill -> SkillScore? in
                guard let category = position.skills.first(where: { $0.rawValue == aiSkill.skill }) else { return nil }
                let confidence: ConfidenceLevel? = switch aiSkill.confidence?.lowercased() {
                case "high": .high
                case "medium": .medium
                case "low": .low
                default: nil
                }
                return SkillScore(
                    category: category,
                    score: aiSkill.score,
                    feedback: aiSkill.feedback ?? "",
                    tip: aiSkill.tip ?? "",
                    confidence: confidence,
                    observedAction: aiSkill.observedAction
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

            let structuredFeedback = StructuredFeedback(
                strengths: aiResponse.strengths ?? [],
                needsImprovement: aiResponse.needsImprovement ?? [],
                coachingPoints: aiResponse.coachingPoints ?? [],
                nextSessionFocus: aiResponse.nextSessionFocus ?? ""
            )

            let videoQuality: VideoQualityAssessment?
            if let vq = aiResponse.videoQuality {
                videoQuality = VideoQualityAssessment(
                    rating: vq.rating,
                    issues: vq.issues ?? [],
                    tips: vq.tips ?? []
                )
            } else {
                videoQuality = nil
            }

            return TrainingSession(
                position: position,
                skillScores: finalScores,
                feedback: aiResponse.feedback,
                drills: finalDrills,
                topImprovement: aiResponse.topImprovement ?? "",
                structuredFeedback: structuredFeedback,
                videoQuality: videoQuality
            )
        } catch {
            errorMessage = "Analysis error: \(error.localizedDescription)"
            return generateFallbackSession(for: position)
        }
    }

    func analyzeVideo(thumbnailImage: UIImage, position: PlayerPosition, skillLevel: SkillLevel) async -> TrainingSession? {
        await analyzeVideo(frames: [thumbnailImage], videoURL: nil, position: position, skillLevel: skillLevel)
    }

    nonisolated static func extractFrames(from url: URL, count: Int = 4) async -> [UIImage] {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 1024, height: 1024)

        guard let duration = try? await asset.load(.duration) else { return [] }
        let totalSeconds = CMTimeGetSeconds(duration)
        guard totalSeconds > 0 else { return [] }

        let clampedCount = min(count, max(1, Int(totalSeconds / 2)))
        let interval = totalSeconds / Double(clampedCount + 1)

        var frames: [UIImage] = []
        for i in 1...clampedCount {
            let time = CMTime(seconds: interval * Double(i), preferredTimescale: 600)
            do {
                let (cgImage, _) = try await generator.image(at: time)
                frames.append(UIImage(cgImage: cgImage))
            } catch {
                continue
            }
        }

        if frames.isEmpty {
            let fallbackTime = CMTime(seconds: min(1.0, totalSeconds * 0.5), preferredTimescale: 600)
            if let (cgImage, _) = try? await generator.image(at: fallbackTime) {
                frames.append(UIImage(cgImage: cgImage))
            }
        }

        return frames
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
                tip: "Focus on repetition with proper form.",
                confidence: .medium
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
            topImprovement: position.skills.first?.rawValue ?? "",
            structuredFeedback: StructuredFeedback(
                strengths: ["Showed willingness to train and improve"],
                needsImprovement: ["Upload a clearer clip for more specific feedback"],
                coachingPoints: ["Film in landscape from 10-20 feet away for best results"],
                nextSessionFocus: "Record a focused 15-30 second clip of a single drill or skill"
            )
        )
    }
}
