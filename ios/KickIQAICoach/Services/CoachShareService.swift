import UIKit
import CoreImage.CIFilterBuiltins

nonisolated enum CoachShareService {

    // MARK: - Deep Links

    static let scheme = "kickiq"

    static func deepLink(session: CoachSession) -> URL? {
        guard let data = try? JSONEncoder().encode(session) else { return nil }
        let encoded = data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return URL(string: "\(scheme)://session/\(encoded)")
    }

    static func deepLink(campaign: Campaign) -> URL? {
        guard let data = try? JSONEncoder().encode(campaign) else { return nil }
        let encoded = data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return URL(string: "\(scheme)://campaign/\(encoded)")
    }

    static func decodeSession(from url: URL) -> CoachSession? {
        guard url.host == "session" else { return nil }
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return decodeBase64URL(path, as: CoachSession.self)
    }

    static func decodeCampaign(from url: URL) -> Campaign? {
        guard url.host == "campaign" else { return nil }
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return decodeBase64URL(path, as: Campaign.self)
    }

    private static func decodeBase64URL<T: Decodable>(_ s: String, as: T.Type) -> T? {
        var b64 = s.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        let pad = 4 - b64.count % 4
        if pad < 4 { b64 += String(repeating: "=", count: pad) }
        guard let data = Data(base64Encoded: b64) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - QR

    @MainActor
    static func qrImage(from string: String, size: CGFloat = 1024) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scale = size / output.extent.width
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let context = CIContext()
        guard let cg = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
    }

    // MARK: - Text

    static func textSummary(session: CoachSession) -> String {
        var out = "\(session.displayTitle)\n"
        out += "\(session.displayGameMoment) · \(session.duration) min · Intensity \(session.intensity)/10\n"
        out += "Age \(session.ageGroup) · \(session.playerCount) players\n"
        out += "Objective: \(session.objective)\n\n"

        let grouped = Dictionary(grouping: session.activities) { $0.resolvedPhase }
        for phase in TrainingPhase.allCases {
            guard let acts = grouped[phase], !acts.isEmpty else { continue }
            let total = acts.reduce(0) { $0 + $1.duration }
            out += "— \(phase.rawValue.uppercased()) (\(total) min) —\n"
            for a in acts.sorted(by: { $0.order < $1.order }) {
                out += "• \(a.displayTitle) — \(a.duration) min"
                if !a.fieldSize.isEmpty { out += " · \(a.fieldSize)" }
                if !a.playerNumbers.isEmpty { out += " · \(a.playerNumbers)" }
                out += "\n"
            }
            out += "\n"
        }

        if !session.notes.isEmpty {
            out += "Notes: \(session.notes)\n"
        }
        return out
    }

    static func textSummary(campaign: Campaign, resolve: (UUID) -> CoachSession?) -> String {
        var out = "\(campaign.title)\n"
        out += "\(campaign.style.rawValue) · \(campaign.weeks.count) weeks\n"
        out += "Age \(campaign.ageGroup) · \(campaign.level)\n"
        out += "Starts \(campaign.startDate.formatted(date: .abbreviated, time: .omitted))\n\n"

        for week in campaign.weeks {
            out += "WEEK \(week.weekNumber) — \(week.phaseLabel.rawValue)\n"
            for sid in week.sessionIDs {
                if let s = resolve(sid) {
                    out += "  • \(s.displayTitle) — \(s.duration) min (\(s.displayGameMoment))\n"
                }
            }
            out += "\n"
        }
        return out
    }

    // MARK: - PDF

    @MainActor
    static func pdfData(session: CoachSession) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        return renderer.pdfData { ctx in
            var cursor = PDFCursor(rect: pageRect)
            ctx.beginPage()
            drawSessionPDF(session: session, cursor: &cursor, ctx: ctx)
        }
    }

    @MainActor
    static func pdfData(campaign: Campaign, resolve: (UUID) -> CoachSession?) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        return renderer.pdfData { ctx in
            var cursor = PDFCursor(rect: pageRect)
            ctx.beginPage()

            drawHeader("TRAINING CAMPAIGN", subtitle: campaign.title, cursor: &cursor)
            drawKeyValues([
                ("Periodization", campaign.style.rawValue),
                ("Duration", "\(campaign.weeks.count) weeks · \(campaign.sessionsPerWeek) sessions/week"),
                ("Age Group", campaign.ageGroup),
                ("Level", campaign.level),
                ("Start Date", campaign.startDate.formatted(date: .long, time: .omitted))
            ], cursor: &cursor)

            for week in campaign.weeks {
                let needed: CGFloat = 80
                if cursor.y + needed > pageRect.height - 50 {
                    ctx.beginPage()
                    cursor = PDFCursor(rect: pageRect)
                }
                drawRule(cursor: &cursor)
                drawText("WEEK \(week.weekNumber) · \(week.phaseLabel.rawValue.uppercased())",
                         font: .systemFont(ofSize: 13, weight: .heavy), cursor: &cursor, padBelow: 4)
                for sid in week.sessionIDs {
                    if let s = resolve(sid) {
                        drawText("  • \(s.displayTitle) — \(s.duration) min · \(s.displayGameMoment)",
                                 font: .systemFont(ofSize: 11), cursor: &cursor, padBelow: 2)
                    }
                }
                cursor.y += 6
            }

            for week in campaign.weeks {
                for sid in week.sessionIDs {
                    guard let s = resolve(sid) else { continue }
                    ctx.beginPage()
                    cursor = PDFCursor(rect: pageRect)
                    drawSessionPDF(session: s, weekLabel: "Week \(week.weekNumber) · \(week.phaseLabel.rawValue)", cursor: &cursor, ctx: ctx)
                }
            }
        }
    }

    @MainActor
    private static func drawSessionPDF(session: CoachSession, weekLabel: String? = nil, cursor: inout PDFCursor, ctx: UIGraphicsPDFRendererContext) {
        drawHeader("TRAINING SESSION", subtitle: session.displayTitle, cursor: &cursor)

        if let weekLabel {
            drawText(weekLabel.uppercased(), font: .systemFont(ofSize: 10, weight: .semibold), color: .darkGray, cursor: &cursor, padBelow: 8)
        }

        drawKeyValues([
            ("Game Moment", session.displayGameMoment),
            ("Objective", session.objective),
            ("Duration", "\(session.duration) minutes"),
            ("Intensity", "\(session.intensity) / 10"),
            ("Age Group", session.ageGroup),
            ("Players", "\(session.playerCount)")
        ], cursor: &cursor)

        drawRule(cursor: &cursor)

        let grouped = Dictionary(grouping: session.activities) { $0.resolvedPhase }
        for phase in TrainingPhase.allCases {
            guard let acts = grouped[phase], !acts.isEmpty else { continue }
            let total = acts.reduce(0) { $0 + $1.duration }

            if cursor.y + 80 > cursor.rect.height - 50 {
                ctx.beginPage()
                cursor = PDFCursor(rect: cursor.rect)
            }

            drawText("\(phase.rawValue.uppercased())  ·  \(total) MIN",
                     font: .systemFont(ofSize: 12, weight: .heavy), cursor: &cursor, padBelow: 6)

            for a in acts.sorted(by: { $0.order < $1.order }) {
                if cursor.y + 60 > cursor.rect.height - 50 {
                    ctx.beginPage()
                    cursor = PDFCursor(rect: cursor.rect)
                }
                drawText("\(a.displayTitle) — \(a.duration) min",
                         font: .systemFont(ofSize: 11, weight: .bold), cursor: &cursor, padBelow: 2)

                var meta: [String] = []
                if !a.fieldSize.isEmpty { meta.append(a.fieldSize) }
                if !a.playerNumbers.isEmpty { meta.append(a.playerNumbers) }
                if !meta.isEmpty {
                    drawText(meta.joined(separator: "  ·  "),
                             font: .systemFont(ofSize: 9), color: .darkGray, cursor: &cursor, padBelow: 3)
                }
                if !a.setupDescription.isEmpty {
                    drawText("Setup: \(a.setupDescription)", font: .systemFont(ofSize: 10), cursor: &cursor, padBelow: 2)
                }
                if !a.instructions.isEmpty {
                    drawText("Run: \(a.instructions)", font: .systemFont(ofSize: 10), cursor: &cursor, padBelow: 2)
                }
                for p in a.phases where !p.isEmpty {
                    drawText("  › \(p)", font: .systemFont(ofSize: 10), cursor: &cursor, padBelow: 1)
                }
                if !a.coachingPoints.isEmpty {
                    drawText("Coaching Points:", font: .systemFont(ofSize: 10, weight: .semibold), cursor: &cursor, padBelow: 1)
                    for c in a.coachingPoints where !c.isEmpty {
                        drawText("  • \(c)", font: .systemFont(ofSize: 10), cursor: &cursor, padBelow: 1)
                    }
                }
                cursor.y += 8
            }
        }

        if !session.notes.isEmpty {
            drawRule(cursor: &cursor)
            drawText("NOTES", font: .systemFont(ofSize: 10, weight: .heavy), cursor: &cursor, padBelow: 4)
            drawText(session.notes, font: .systemFont(ofSize: 10), cursor: &cursor, padBelow: 4)
        }
    }

    // MARK: - PDF drawing helpers

    @MainActor
    private struct PDFCursor {
        let rect: CGRect
        var y: CGFloat
        var margin: CGFloat = 50
        init(rect: CGRect) {
            self.rect = rect
            self.y = 50
        }
        var contentWidth: CGFloat { rect.width - margin * 2 }
    }

    @MainActor
    private static func drawHeader(_ eyebrow: String, subtitle: String, cursor: inout PDFCursor) {
        drawText(eyebrow, font: .systemFont(ofSize: 9, weight: .heavy), color: .darkGray, cursor: &cursor, padBelow: 4)
        drawText(subtitle, font: .systemFont(ofSize: 24, weight: .heavy), cursor: &cursor, padBelow: 2)
        drawRule(cursor: &cursor)
    }

    @MainActor
    private static func drawKeyValues(_ pairs: [(String, String)], cursor: inout PDFCursor) {
        for (k, v) in pairs {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: UIColor.darkGray
            ]
            let kStr = NSAttributedString(string: k.uppercased(), attributes: attrs)
            kStr.draw(at: CGPoint(x: cursor.margin, y: cursor.y))

            let vAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                .foregroundColor: UIColor.black
            ]
            let vStr = NSAttributedString(string: v, attributes: vAttrs)
            vStr.draw(at: CGPoint(x: cursor.margin + 110, y: cursor.y - 1))
            cursor.y += 16
        }
        cursor.y += 6
    }

    @MainActor
    private static func drawRule(cursor: inout PDFCursor) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: cursor.margin, y: cursor.y))
        path.addLine(to: CGPoint(x: cursor.rect.width - cursor.margin, y: cursor.y))
        UIColor.black.setStroke()
        path.lineWidth = 0.5
        path.stroke()
        cursor.y += 10
    }

    @MainActor
    private static func drawText(_ text: String, font: UIFont, color: UIColor = .black, cursor: inout PDFCursor, padBelow: CGFloat) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        let attr = NSAttributedString(string: text, attributes: attrs)
        let bounding = attr.boundingRect(
            with: CGSize(width: cursor.contentWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        attr.draw(with: CGRect(x: cursor.margin, y: cursor.y, width: cursor.contentWidth, height: ceil(bounding.height)),
                  options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        cursor.y += ceil(bounding.height) + padBelow
    }
}
