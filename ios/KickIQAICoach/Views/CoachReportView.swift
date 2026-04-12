import SwiftUI

struct CoachReportView: View {
    let storage: StorageService
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var reportPDF: URL?
    @State private var isGenerating = false

    private var playerName: String { storage.profile?.name ?? "Player" }
    private var position: PlayerPosition { storage.profile?.position ?? .midfielder }
    private var skillLevel: SkillLevel { storage.profile?.skillLevel ?? .beginner }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQAICoachTheme.Spacing.md + 4) {
                    reportHeader
                    playerInfoCard
                    if let latest = storage.sessions.first {
                        currentAssessmentCard(latest)
                        skillBreakdownCard(latest)
                        drillRecommendationsCard(latest)
                    }
                    if storage.sessions.count >= 2 {
                        progressSummaryCard
                    }
                    streakAndCommitmentCard
                    coachNotesCard
                    exportButton
                }
                .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                .padding(.bottom, KickIQAICoachTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQAICoachTheme.background.ignoresSafeArea())
            .navigationTitle("Coach Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = reportPDF {
                    ShareSheetURLView(url: url)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.background)
    }

    private var reportHeader: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("KICKIQ")
                        .font(.system(.caption, design: .default, weight: .black).width(.compressed))
                        .tracking(3)
                        .foregroundStyle(KickIQAICoachTheme.accent)
                    Text("ATHLETE REPORT")
                        .font(.system(.caption2, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.5))
                }
                Spacer()
                Text(Date.now, format: .dateTime.month(.wide).day().year())
                    .font(.caption)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
            }

            Rectangle()
                .fill(KickIQAICoachTheme.accent)
                .frame(height: 2)
        }
        .padding(.top, KickIQAICoachTheme.Spacing.sm)
    }

    private var playerInfoCard: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.md) {
            Text("PLAYER INFORMATION")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQAICoachTheme.accent)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: KickIQAICoachTheme.Spacing.sm) {
                infoCell(label: "Name", value: playerName)
                infoCell(label: "Position", value: position.rawValue)
                infoCell(label: "Skill Level", value: skillLevel.rawValue)
                infoCell(label: "Focus Area", value: storage.profile?.weakness.rawValue ?? "—")
                infoCell(label: "Total Sessions", value: "\(storage.analysisCount)")
                infoCell(label: "Player Level", value: storage.playerLevel.rawValue)
            }
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
    }

    private func infoCell(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.6))
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(KickIQAICoachTheme.Spacing.sm)
        .background(KickIQAICoachTheme.surface, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.sm))
    }

    private func currentAssessmentCard(_ session: TrainingSession) -> some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.md) {
            HStack {
                Text("CURRENT ASSESSMENT")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(KickIQAICoachTheme.accent)
                Spacer()
                Text(session.date, format: .dateTime.month(.abbreviated).day().year())
                    .font(.caption2)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
            }

            HStack {
                VStack(spacing: 4) {
                    Text("\(session.overallScore)")
                        .font(.system(size: 48, weight: .black))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    Text("OVERALL SCORE")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(KickIQAICoachTheme.divider)
                    .frame(width: 1, height: 60)

                VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                    if let best = session.skillScores.max(by: { $0.score < $1.score }) {
                        miniScore(label: "Strongest", skill: best.category.rawValue, score: best.score, color: .green)
                    }
                    if let worst = session.skillScores.min(by: { $0.score < $1.score }) {
                        miniScore(label: "Weakest", skill: worst.category.rawValue, score: worst.score, color: .orange)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            Text(session.feedback)
                .font(.caption)
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
                .lineSpacing(3)
                .padding(KickIQAICoachTheme.Spacing.sm)
                .background(KickIQAICoachTheme.surface, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.sm))
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
    }

    private func miniScore(label: String, skill: String, score: Int, color: Color) -> some View {
        VStack(spacing: 1) {
            Text(label.uppercased())
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.5))
            Text(skill)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
            Text("\(score)/10")
                .font(.caption.weight(.black))
                .foregroundStyle(color)
        }
    }

    private func skillBreakdownCard(_ session: TrainingSession) -> some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.md) {
            Text("DETAILED SKILL BREAKDOWN")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQAICoachTheme.accent)

            ForEach(session.skillScores) { score in
                VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
                    HStack {
                        Image(systemName: score.category.icon)
                            .font(.caption)
                            .foregroundStyle(KickIQAICoachTheme.accent)
                            .frame(width: 20)
                        Text(score.category.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KickIQAICoachTheme.textPrimary)
                        Spacer()
                        Text("\(score.score)/10")
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(scoreColor(score.score))
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(KickIQAICoachTheme.divider).frame(height: 6)
                            Capsule().fill(scoreColor(score.score)).frame(width: geo.size.width * score.percentage, height: 6)
                        }
                    }
                    .frame(height: 6)

                    if !score.feedback.isEmpty {
                        Text("Assessment: \(score.feedback)")
                            .font(.caption)
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    }
                    if !score.tip.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(KickIQAICoachTheme.accent)
                            Text("Tip: \(score.tip)")
                                .font(.caption)
                                .foregroundStyle(KickIQAICoachTheme.accent.opacity(0.9))
                        }
                    }
                }
                .padding(KickIQAICoachTheme.Spacing.sm)
                .background(KickIQAICoachTheme.surface, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.sm))
            }
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 8...10: .green
        case 5...7: KickIQAICoachTheme.accent
        default: .red
        }
    }

    private func drillRecommendationsCard(_ session: TrainingSession) -> some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.md) {
            Text("RECOMMENDED TRAINING PLAN")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQAICoachTheme.accent)

            ForEach(Array(session.drills.enumerated()), id: \.element.id) { index, drill in
                VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
                    HStack {
                        Text("\(index + 1)")
                            .font(.caption.weight(.black))
                            .foregroundStyle(KickIQAICoachTheme.onAccent)
                            .frame(width: 22, height: 22)
                            .background(KickIQAICoachTheme.accent, in: Circle())

                        Text(drill.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KickIQAICoachTheme.textPrimary)

                        Spacer()

                        Text(drill.duration)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(KickIQAICoachTheme.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(KickIQAICoachTheme.accent.opacity(0.15), in: Capsule())
                    }

                    Text(drill.description)
                        .font(.caption)
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                        .lineSpacing(2)

                    HStack(spacing: KickIQAICoachTheme.Spacing.md) {
                        Label(drill.difficulty.rawValue, systemImage: "speedometer")
                        Label(drill.targetSkill, systemImage: "target")
                        if !drill.reps.isEmpty {
                            Label(drill.reps, systemImage: "repeat")
                        }
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)

                    if !drill.coachingCues.isEmpty {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Coaching Cues:")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(KickIQAICoachTheme.accent)
                            ForEach(drill.coachingCues, id: \.self) { cue in
                                HStack(alignment: .top, spacing: 4) {
                                    Text("•")
                                        .font(.caption)
                                    Text(cue)
                                        .font(.caption)
                                }
                                .foregroundStyle(KickIQAICoachTheme.textSecondary)
                            }
                        }
                    }
                }
                .padding(KickIQAICoachTheme.Spacing.sm + 2)
                .background(KickIQAICoachTheme.surface, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.sm))
            }
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
    }

    private var progressSummaryCard: some View {
        let sessions = storage.sessions
        let first = sessions.last!
        let latest = sessions.first!
        let improvement = latest.overallScore - first.overallScore
        let weeks = max(1, Calendar.current.dateComponents([.weekOfYear], from: first.date, to: latest.date).weekOfYear ?? 1)

        return VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.md) {
            Text("PROGRESS SUMMARY")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQAICoachTheme.accent)

            HStack(spacing: 0) {
                progressStat(value: "\(improvement > 0 ? "+" : "")\(improvement)", label: "Score Change", color: improvement >= 0 ? .green : .red)
                Rectangle().fill(KickIQAICoachTheme.divider).frame(width: 1, height: 40)
                progressStat(value: "\(sessions.count)", label: "Sessions", color: KickIQAICoachTheme.accent)
                Rectangle().fill(KickIQAICoachTheme.divider).frame(width: 1, height: 40)
                progressStat(value: "\(weeks)w", label: "Training Period", color: KickIQAICoachTheme.accent)
            }

            VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
                Text("Session History")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)

                ForEach(sessions.prefix(5)) { session in
                    HStack {
                        Text(session.date, format: .dateTime.month(.abbreviated).day())
                            .font(.caption.weight(.medium))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                            .frame(width: 60, alignment: .leading)

                        Text(session.position.rawValue)
                            .font(.caption)
                            .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.6))

                        Spacer()

                        Text("\(session.overallScore)/100")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    }
                    .padding(.vertical, 3)
                }

                if sessions.count > 5 {
                    Text("+ \(sessions.count - 5) more sessions")
                        .font(.caption2)
                        .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.5))
                }
            }
            .padding(KickIQAICoachTheme.Spacing.sm)
            .background(KickIQAICoachTheme.surface, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.sm))
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
    }

    private func progressStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.title3.weight(.black))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var streakAndCommitmentCard: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.md) {
            Text("COMMITMENT & CONSISTENCY")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQAICoachTheme.accent)

            HStack(spacing: 0) {
                progressStat(value: "\(storage.streakCount)", label: "Current Streak", color: KickIQAICoachTheme.accent)
                Rectangle().fill(KickIQAICoachTheme.divider).frame(width: 1, height: 40)
                progressStat(value: "\(storage.maxStreak)", label: "Best Streak", color: .green)
                Rectangle().fill(KickIQAICoachTheme.divider).frame(width: 1, height: 40)
                progressStat(value: "\(storage.xpPoints)", label: "Total XP", color: KickIQAICoachTheme.accent)
                Rectangle().fill(KickIQAICoachTheme.divider).frame(width: 1, height: 40)
                progressStat(value: "\(storage.completedDrillIDs.count)", label: "Drills Done", color: .green)
            }
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
    }

    private var coachNotesCard: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.md) {
            Text("NOTES FOR COACH")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQAICoachTheme.accent)

            VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
                noteItem("This report was generated by KickIQAICoach's AI analysis system based on training video assessments.")
                noteItem("Skill scores are AI-estimated and should be validated by in-person observation.")
                noteItem("Drill recommendations are tailored to the player's identified weaknesses.")
                noteItem("The player has completed \(storage.analysisCount) total analysis sessions.")
                if storage.streakCount > 3 {
                    noteItem("The player has maintained a \(storage.streakCount)-day training streak, showing strong commitment.")
                }
            }
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
    }

    private func noteItem(_ text: String) -> some View {
        HStack(alignment: .top, spacing: KickIQAICoachTheme.Spacing.sm) {
            Image(systemName: "info.circle.fill")
                .font(.caption2)
                .foregroundStyle(KickIQAICoachTheme.accent)
                .padding(.top, 2)
            Text(text)
                .font(.caption)
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
                .lineSpacing(2)
        }
    }

    private var exportButton: some View {
        Button {
            generateAndSharePDF()
        } label: {
            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                if isGenerating {
                    ProgressView()
                        .tint(.black)
                } else {
                    Image(systemName: "square.and.arrow.up")
                }
                Text(isGenerating ? "Generating..." : "Export & Send to Coach")
            }
            .font(.headline)
            .foregroundStyle(KickIQAICoachTheme.onAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, KickIQAICoachTheme.Spacing.md)
            .background(KickIQAICoachTheme.accent, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        }
        .disabled(isGenerating)
    }

    @MainActor
    private func generateAndSharePDF() {
        isGenerating = true

        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))

        let data = pdfRenderer.pdfData { context in
            context.beginPage()
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .black),
                .foregroundColor: UIColor.label
            ]
            let accentUIColor = UIColor(KickIQAICoachTheme.accent)
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                .foregroundColor: accentUIColor
            ]
            let bodyAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                .foregroundColor: UIColor.secondaryLabel
            ]
            let boldAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                .foregroundColor: UIColor.label
            ]

            var y: CGFloat = 40

            "KICKIQ ATHLETE REPORT".draw(at: CGPoint(x: 40, y: y), withAttributes: attrs)
            y += 36

            let dateStr = Date.now.formatted(.dateTime.month(.wide).day().year())
            dateStr.draw(at: CGPoint(x: 40, y: y), withAttributes: bodyAttrs)
            y += 30

            let line = UIBezierPath()
            line.move(to: CGPoint(x: 40, y: y))
            line.addLine(to: CGPoint(x: 572, y: y))
            accentUIColor.setStroke()
            line.lineWidth = 2
            line.stroke()
            y += 20

            "PLAYER INFORMATION".draw(at: CGPoint(x: 40, y: y), withAttributes: titleAttrs)
            y += 22
            "Name: \(playerName)".draw(at: CGPoint(x: 40, y: y), withAttributes: boldAttrs)
            y += 18
            "Position: \(position.rawValue)".draw(at: CGPoint(x: 40, y: y), withAttributes: boldAttrs)
            "Skill Level: \(skillLevel.rawValue)".draw(at: CGPoint(x: 300, y: y), withAttributes: boldAttrs)
            y += 18
            "Focus Area: \(storage.profile?.weakness.rawValue ?? "—")".draw(at: CGPoint(x: 40, y: y), withAttributes: boldAttrs)
            "Total Sessions: \(storage.analysisCount)".draw(at: CGPoint(x: 300, y: y), withAttributes: boldAttrs)
            y += 30

            if let session = storage.sessions.first {
                "CURRENT ASSESSMENT".draw(at: CGPoint(x: 40, y: y), withAttributes: titleAttrs)
                y += 22
                "Overall Score: \(session.overallScore)/100".draw(at: CGPoint(x: 40, y: y), withAttributes: attrs)
                y += 34
                "Date: \(session.date.formatted(.dateTime.month(.abbreviated).day().year()))".draw(at: CGPoint(x: 40, y: y), withAttributes: bodyAttrs)
                y += 24

                "SKILL BREAKDOWN".draw(at: CGPoint(x: 40, y: y), withAttributes: titleAttrs)
                y += 22

                for score in session.skillScores {
                    if y > 720 {
                        context.beginPage()
                        y = 40
                    }
                    "\(score.category.rawValue): \(score.score)/10".draw(at: CGPoint(x: 40, y: y), withAttributes: boldAttrs)
                    y += 16
                    if !score.feedback.isEmpty {
                        let feedbackRect = CGRect(x: 60, y: y, width: 492, height: 30)
                        score.feedback.draw(in: feedbackRect, withAttributes: bodyAttrs)
                        y += 20
                    }
                    if !score.tip.isEmpty {
                        let tipRect = CGRect(x: 60, y: y, width: 492, height: 30)
                        "Tip: \(score.tip)".draw(in: tipRect, withAttributes: bodyAttrs)
                        y += 20
                    }
                    y += 6
                }

                y += 10
                if y > 680 {
                    context.beginPage()
                    y = 40
                }

                "COACH FEEDBACK".draw(at: CGPoint(x: 40, y: y), withAttributes: titleAttrs)
                y += 22
                let feedbackRect = CGRect(x: 40, y: y, width: 532, height: 100)
                session.feedback.draw(in: feedbackRect, withAttributes: bodyAttrs)
                y += 80

                if !session.drills.isEmpty {
                    if y > 620 {
                        context.beginPage()
                        y = 40
                    }
                    "RECOMMENDED DRILLS".draw(at: CGPoint(x: 40, y: y), withAttributes: titleAttrs)
                    y += 22

                    for (i, drill) in session.drills.enumerated() {
                        if y > 700 {
                            context.beginPage()
                            y = 40
                        }
                        "\(i + 1). \(drill.name) (\(drill.duration))".draw(at: CGPoint(x: 40, y: y), withAttributes: boldAttrs)
                        y += 16
                        let drillRect = CGRect(x: 60, y: y, width: 492, height: 40)
                        drill.description.draw(in: drillRect, withAttributes: bodyAttrs)
                        y += 30
                    }
                }
            }

            y += 20
            if y > 700 {
                context.beginPage()
                y = 40
            }

            "COMMITMENT".draw(at: CGPoint(x: 40, y: y), withAttributes: titleAttrs)
            y += 22
            "Current Streak: \(storage.streakCount) days".draw(at: CGPoint(x: 40, y: y), withAttributes: boldAttrs)
            "Best Streak: \(storage.maxStreak) days".draw(at: CGPoint(x: 300, y: y), withAttributes: boldAttrs)
            y += 18
            "Drills Completed: \(storage.completedDrillIDs.count)".draw(at: CGPoint(x: 40, y: y), withAttributes: boldAttrs)
            "XP Earned: \(storage.xpPoints)".draw(at: CGPoint(x: 300, y: y), withAttributes: boldAttrs)
            y += 30

            let footer = "Generated by KickIQAICoach — AI-Powered Soccer Coaching • contact@m5cairo.com"
            let footerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9, weight: .medium),
                .foregroundColor: UIColor.tertiaryLabel
            ]
            footer.draw(at: CGPoint(x: 40, y: 760), withAttributes: footerAttrs)
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("KickIQAICoach_Report_\(playerName.replacingOccurrences(of: " ", with: "_")).pdf")
        try? data.write(to: tempURL)
        reportPDF = tempURL
        isGenerating = false
        showShareSheet = true
    }
}

struct ShareSheetURLView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
