import SwiftUI
import CoreImage.CIFilterBuiltins

@MainActor
struct QRCodeService {
    static func generateQRImage(from payload: QRSharePayload, size: CGFloat = 280) -> UIImage? {
        guard let data = try? JSONEncoder().encode(payload) else { return nil }

        let compressed = try? (data as NSData).compressed(using: .zlib) as Data
        let qrData = compressed ?? data

        guard let base64 = qrData.base64EncodedString().data(using: .utf8) else { return nil }

        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = base64
        filter.correctionLevel = "L"

        guard let outputImage = filter.outputImage else { return nil }

        let scale = size / outputImage.extent.size.width
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        let colorFilter = CIFilter.falseColor()
        colorFilter.inputImage = scaledImage
        colorFilter.color0 = CIColor(color: UIColor(KickIQTheme.accent))
        colorFilter.color1 = CIColor(color: UIColor(Color(hex: 0x1A1A1A)))

        guard let coloredImage = colorFilter.outputImage,
              let cgImage = context.createCGImage(coloredImage, from: coloredImage.extent) else { return nil }

        return UIImage(cgImage: cgImage)
    }

    static func decodePayload(from string: String) -> QRSharePayload? {
        guard let base64Data = string.data(using: .utf8),
              let compressed = Data(base64Encoded: base64Data) else { return nil }

        if let decompressed = try? (compressed as NSData).decompressed(using: .zlib) as Data,
           let payload = try? JSONDecoder().decode(QRSharePayload.self, from: decompressed) {
            return payload
        }

        if let payload = try? JSONDecoder().decode(QRSharePayload.self, from: compressed) {
            return payload
        }

        return nil
    }

    static func payloadFromDrill(_ drill: Drill) -> QRSharePayload {
        QRSharePayload(drill: QRDrillPayload(
            name: drill.name,
            description: drill.description,
            duration: drill.duration,
            difficulty: drill.difficulty,
            targetSkill: drill.targetSkill,
            coachingCues: drill.coachingCues,
            reps: drill.reps
        ))
    }

    static func payloadFromSmartDrill(_ drill: SmartDrill) -> QRSharePayload {
        QRSharePayload(drill: QRDrillPayload(
            name: drill.name,
            description: drill.description,
            duration: drill.duration,
            difficulty: drill.difficulty,
            targetSkill: drill.targetSkill,
            coachingCues: drill.coachingCues,
            reps: drill.reps
        ))
    }

    static func payloadFromSession(_ session: TrainingSession) -> QRSharePayload {
        QRSharePayload(session: QRSessionPayload(
            date: session.date,
            position: session.position,
            overallScore: session.overallScore,
            feedback: session.feedback,
            skillScores: session.skillScores.map {
                QRSkillScorePayload(category: $0.category, score: $0.score, feedback: $0.feedback, tip: $0.tip)
            },
            drills: session.drills.map {
                QRDrillPayload(name: $0.name, description: $0.description, duration: $0.duration, difficulty: $0.difficulty, targetSkill: $0.targetSkill, coachingCues: $0.coachingCues, reps: $0.reps)
            },
            strengths: session.structuredFeedback?.strengths ?? [],
            needsImprovement: session.structuredFeedback?.needsImprovement ?? [],
            coachingPoints: session.structuredFeedback?.coachingPoints ?? [],
            nextSessionFocus: session.structuredFeedback?.nextSessionFocus ?? ""
        ))
    }

    static func payloadFromDailyPlan(_ day: DailyPlan) -> QRSharePayload {
        QRSharePayload(dailyPlan: QRDailyPlanPayload(
            focus: day.focus,
            intensity: day.intensity,
            duration: day.duration,
            mode: day.mode,
            weaknessPriority: day.weaknessPriority,
            drills: day.drills.map {
                QRDrillPayload(name: $0.name, description: $0.description, duration: $0.duration, difficulty: $0.difficulty, targetSkill: $0.targetSkill, coachingCues: $0.coachingCues, reps: $0.reps)
            }
        ))
    }

    static func importDrill(from payload: QRDrillPayload) -> Drill {
        Drill(
            name: payload.name,
            description: payload.description,
            duration: payload.duration,
            difficulty: payload.difficulty,
            targetSkill: payload.targetSkill,
            coachingCues: payload.coachingCues,
            reps: payload.reps
        )
    }

    static func importSession(from payload: QRSessionPayload) -> TrainingSession {
        TrainingSession(
            date: payload.date,
            position: payload.position,
            skillScores: payload.skillScores.map {
                SkillScore(category: $0.category, score: $0.score, feedback: $0.feedback, tip: $0.tip)
            },
            feedback: payload.feedback,
            drills: payload.drills.map {
                Drill(name: $0.name, description: $0.description, duration: $0.duration, difficulty: $0.difficulty, targetSkill: $0.targetSkill, coachingCues: $0.coachingCues, reps: $0.reps)
            },
            structuredFeedback: StructuredFeedback(
                strengths: payload.strengths,
                needsImprovement: payload.needsImprovement,
                coachingPoints: payload.coachingPoints,
                nextSessionFocus: payload.nextSessionFocus
            )
        )
    }
}
