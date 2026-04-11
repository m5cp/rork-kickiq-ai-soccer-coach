import UIKit
import PDFKit

struct PlanPDFExporter {
    static func generatePDF(for plan: SavedPlan) -> URL? {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 40
        let contentWidth = pageWidth - margin * 2

        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        let data = pdfRenderer.pdfData { context in
            var currentY: CGFloat = 0

            func startNewPage() {
                context.beginPage()
                currentY = margin
            }

            func ensureSpace(_ needed: CGFloat) {
                if currentY + needed > pageHeight - margin {
                    startNewPage()
                }
            }

            func drawText(_ text: String, font: UIFont, color: UIColor, x: CGFloat, maxWidth: CGFloat) -> CGFloat {
                let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                let rect = CGRect(x: x, y: currentY, width: maxWidth, height: .greatestFiniteMagnitude)
                let boundingRect = (text as NSString).boundingRect(with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
                (text as NSString).draw(in: rect, withAttributes: attributes)
                return boundingRect.height
            }

            startNewPage()

            let titleFont = UIFont.systemFont(ofSize: 22, weight: .heavy)
            let subtitleFont = UIFont.systemFont(ofSize: 12, weight: .semibold)
            let bodyFont = UIFont.systemFont(ofSize: 11, weight: .regular)
            let headingFont = UIFont.systemFont(ofSize: 14, weight: .bold)
            let smallFont = UIFont.systemFont(ofSize: 10, weight: .medium)

            let darkColor = UIColor(white: 0.15, alpha: 1)
            let accentColor = UIColor(red: 0.45, green: 0.73, blue: 0.87, alpha: 1)
            let grayColor = UIColor(white: 0.5, alpha: 1)

            let h = drawText("KickIQ Training Plan", font: titleFont, color: darkColor, x: margin, maxWidth: contentWidth)
            currentY += h + 6

            let h2 = drawText(plan.title, font: subtitleFont, color: accentColor, x: margin, maxWidth: contentWidth)
            currentY += h2 + 4

            let summaryLine = "\(plan.weekCount) weeks · \(plan.sessionDuration.label) sessions · \(plan.totalDays) training days · \(plan.totalDrills) total drills"
            let h3 = drawText(summaryLine, font: smallFont, color: grayColor, x: margin, maxWidth: contentWidth)
            currentY += h3 + 4

            let focusLine = "Focus: \(plan.focusAreas.joined(separator: ", "))"
            let h4 = drawText(focusLine, font: smallFont, color: grayColor, x: margin, maxWidth: contentWidth)
            currentY += h4 + 4

            let dateLine = "Created: \(plan.createdAt.formatted(.dateTime.month(.wide).day().year()))"
            let h5 = drawText(dateLine, font: smallFont, color: grayColor, x: margin, maxWidth: contentWidth)
            currentY += h5 + 16

            let lineY = currentY
            UIColor(white: 0.85, alpha: 1).setStroke()
            let linePath = UIBezierPath()
            linePath.move(to: CGPoint(x: margin, y: lineY))
            linePath.addLine(to: CGPoint(x: pageWidth - margin, y: lineY))
            linePath.lineWidth = 0.5
            linePath.stroke()
            currentY += 16

            let grouped = Dictionary(grouping: plan.days, by: \.weekNumber)
            let sortedWeeks = grouped.keys.sorted()

            for week in sortedWeeks {
                guard let days = grouped[week] else { continue }

                ensureSpace(30)
                let wh = drawText("WEEK \(week)", font: headingFont, color: darkColor, x: margin, maxWidth: contentWidth)
                currentY += wh + 10

                for day in days {
                    let dayHeader = "Day \(day.dayNumber) — \(day.focus) (\(day.intensity.rawValue), \(day.duration.label))"
                    ensureSpace(20 + CGFloat(day.drills.count) * 16)
                    let dh = drawText(dayHeader, font: subtitleFont, color: darkColor, x: margin + 8, maxWidth: contentWidth - 8)
                    currentY += dh + 6

                    for drill in day.drills {
                        ensureSpace(16)
                        let drillLine = "  •  \(drill.name) — \(drill.duration)\(drill.reps.isEmpty ? "" : " · \(drill.reps)")"
                        let dl = drawText(drillLine, font: bodyFont, color: grayColor, x: margin + 16, maxWidth: contentWidth - 16)
                        currentY += dl + 3
                    }

                    currentY += 8
                }

                currentY += 8
            }
        }

        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "KickIQ_\(plan.title.replacingOccurrences(of: " ", with: "_")).pdf"
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            return nil
        }
    }
}
