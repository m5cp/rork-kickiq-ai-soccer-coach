import SwiftUI
import CoreImage.CIFilterBuiltins

@MainActor
struct QRSharingService {
    static func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return nil }

        let scale = 10.0
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    static func drillPayload(_ drill: Drill) -> String {
        let payload = QRDrillPayload(
            name: drill.name,
            description: drill.description,
            duration: drill.duration,
            difficulty: drill.difficulty.rawValue,
            targetSkill: drill.targetSkill,
            coachingCues: drill.coachingCues,
            reps: drill.reps
        )
        guard let data = try? JSONEncoder().encode(payload),
              let json = String(data: data, encoding: .utf8) else {
            return drill.name
        }
        return "kickiq://drill?\(json)"
    }

    static func sessionPayload(_ session: TrainingSession, playerName: String) -> String {
        let skills = session.skillScores.map { "\($0.category.rawValue):\($0.score)" }.joined(separator: ",")
        return "kickiq://session?score=\(session.overallScore)&player=\(playerName)&skills=\(skills)"
    }
}

nonisolated struct QRDrillPayload: Codable, Sendable {
    let name: String
    let description: String
    let duration: String
    let difficulty: String
    let targetSkill: String
    let coachingCues: [String]
    let reps: String
}
