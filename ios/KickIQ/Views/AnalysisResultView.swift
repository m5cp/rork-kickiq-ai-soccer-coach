import SwiftUI

struct AnalysisResultView: View {
    let session: TrainingSession
    let storage: StorageService
    let onDismiss: () -> Void
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var appeared = false
    @State private var scoreAppeared = false
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    @State private var showSessionNotes = false
    @State private var showQRShare = false

    private var isIPad: Bool { sizeClass == .regular }

    var body: some View {
        ScrollView {
            if isIPad {
                iPadResultLayout
            } else {
                iPhoneResultLayout
            }
        }
        .scrollIndicators(.hidden)
        .background(KickIQTheme.background.ignoresSafeArea())
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { scoreAppeared = true }
            }
        }
        .sensoryFeedback(.success, trigger: appeared)
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheetView(image: image)
            }
        }
        .sheet(isPresented: $showSessionNotes) {
            SessionNotesSheet(sessionID: session.id, storage: storage)
        }
        .sheet(isPresented: $showQRShare) {
            QRCodeShareSheet(
                payload: QRCodeService.payloadFromSession(session),
                title: "Share Analysis",
                subtitle: "Let your teammate scan to see your results"
            )
        }
    }

    private var iPhoneResultLayout: some View {
        VStack(spacing: KickIQTheme.Spacing.md + 4) {
            headerSection
            videoQualityBanner
            overallScoreSection
            strengthsSection
            needsImprovementSection
            skillBreakdownSection
            coachingPointsSection
            nextSessionFocusSection
            feedbackSection
            drillsSection
            sessionNotesButton
            sharePromptBanner
            actionButtons
        }
        .padding(.horizontal, KickIQTheme.Spacing.md)
        .padding(.bottom, KickIQTheme.Spacing.xl)
    }

    private var iPadResultLayout: some View {
        VStack(spacing: KickIQTheme.Spacing.lg) {
            headerSection
            videoQualityBanner

            HStack(alignment: .top, spacing: KickIQTheme.Spacing.lg) {
                VStack(spacing: KickIQTheme.Spacing.md + 4) {
                    overallScoreSection
                    strengthsSection
                    needsImprovementSection
                    feedbackSection
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: KickIQTheme.Spacing.md + 4) {
                    skillBreakdownSection
                    coachingPointsSection
                    nextSessionFocusSection
                }
                .frame(maxWidth: .infinity)
            }

            drillsSection
            sessionNotesButton

            HStack(spacing: KickIQTheme.Spacing.md) {
                sharePromptBanner
                    .frame(maxWidth: .infinity)
                actionButtons
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, KickIQTheme.Spacing.lg)
        .padding(.bottom, KickIQTheme.Spacing.xl)
        .frame(maxWidth: AdaptiveLayout.iPadWideMaxContentWidth)
        .frame(maxWidth: .infinity)
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: KickIQTheme.Spacing.xs) {
                Text("SESSION COMPLETE")
                    .font(.caption.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(KickIQTheme.accent)

                Text("Analysis Results")
                    .font(.system(.title, design: .default, weight: .bold))
                    .foregroundStyle(KickIQTheme.textPrimary)
            }
            Spacer()

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(KickIQTheme.textSecondary.opacity(0.5))
            }
        }
        .padding(.top, KickIQTheme.Spacing.md)
        .opacity(appeared ? 1 : 0)
    }

    // MARK: - Video Quality Banner

    @ViewBuilder
    private var videoQualityBanner: some View {
        if let vq = session.videoQuality, vq.rating == "Poor" || vq.rating == "Fair" {
            VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
                HStack(spacing: 6) {
                    Image(systemName: vq.rating == "Poor" ? "exclamationmark.triangle.fill" : "info.circle.fill")
                        .font(.caption)
                        .foregroundStyle(vq.rating == "Poor" ? .red : .yellow)
                    Text("VIDEO QUALITY: \(vq.rating.uppercased())")
                        .font(.caption.weight(.bold))
                        .tracking(1)
                        .foregroundStyle(vq.rating == "Poor" ? .red.opacity(0.9) : .yellow.opacity(0.9))
                }

                if !vq.issues.isEmpty {
                    ForEach(vq.issues, id: \.self) { issue in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.red.opacity(0.6))
                                .padding(.top, 2)
                            Text(issue)
                                .font(.caption)
                                .foregroundStyle(KickIQTheme.textSecondary)
                        }
                    }
                }

                if !vq.tips.isEmpty {
                    ForEach(vq.tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(KickIQTheme.accent)
                                .padding(.top, 2)
                            Text(tip)
                                .font(.caption)
                                .foregroundStyle(KickIQTheme.accent.opacity(0.9))
                        }
                    }
                }
            }
            .padding(KickIQTheme.Spacing.md)
            .background(
                (vq.rating == "Poor" ? Color.red : Color.yellow).opacity(0.08),
                in: .rect(cornerRadius: KickIQTheme.Radius.lg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                    .stroke((vq.rating == "Poor" ? Color.red : Color.yellow).opacity(0.2), lineWidth: 1)
            )
            .opacity(appeared ? 1 : 0)
        }
    }

    private var overallScoreSection: some View {
        VStack(spacing: KickIQTheme.Spacing.md) {
            ZStack {
                Circle()
                    .stroke(KickIQTheme.divider, lineWidth: 10)
                    .frame(width: 130, height: 130)

                Circle()
                    .trim(from: 0, to: scoreAppeared ? Double(session.overallScore) / 100.0 : 0)
                    .stroke(
                        AngularGradient(
                            colors: [KickIQTheme.accent, KickIQTheme.accent.opacity(0.4), KickIQTheme.accent],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 130, height: 130)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(session.overallScore)")
                        .font(.system(size: 44, weight: .black, design: .default))
                        .foregroundStyle(KickIQTheme.textPrimary)
                    Text("/ 100")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
                .scaleEffect(scoreAppeared ? 1 : 0.5)
                .opacity(scoreAppeared ? 1 : 0)
            }

            Text("Session Score")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KickIQTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, KickIQTheme.Spacing.lg)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.xl))
    }

    // MARK: - Strengths

    @ViewBuilder
    private var strengthsSection: some View {
        if let sf = session.structuredFeedback, !sf.strengths.isEmpty {
            VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    Text("STRENGTHS")
                        .font(.caption.weight(.bold))
                        .tracking(1)
                        .foregroundStyle(.green)
                }

                ForEach(sf.strengths, id: \.self) { strength in
                    HStack(alignment: .top, spacing: KickIQTheme.Spacing.sm) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.green)
                            .padding(.top, 3)
                        Text(strength)
                            .font(.subheadline)
                            .foregroundStyle(KickIQTheme.textPrimary.opacity(0.85))
                            .lineSpacing(3)
                    }
                }
            }
            .padding(KickIQTheme.Spacing.md)
            .background(Color.green.opacity(0.06), in: .rect(cornerRadius: KickIQTheme.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                    .stroke(Color.green.opacity(0.15), lineWidth: 1)
            )
            .opacity(appeared ? 1 : 0)
        }
    }

    // MARK: - Needs Improvement

    @ViewBuilder
    private var needsImprovementSection: some View {
        if let sf = session.structuredFeedback, !sf.needsImprovement.isEmpty {
            VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(KickIQTheme.accent)
                    Text("NEEDS IMPROVEMENT")
                        .font(.caption.weight(.bold))
                        .tracking(1)
                        .foregroundStyle(KickIQTheme.accent)
                }

                ForEach(sf.needsImprovement, id: \.self) { item in
                    HStack(alignment: .top, spacing: KickIQTheme.Spacing.sm) {
                        Image(systemName: "arrow.forward")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(KickIQTheme.accent)
                            .padding(.top, 3)
                        Text(item)
                            .font(.subheadline)
                            .foregroundStyle(KickIQTheme.textPrimary.opacity(0.85))
                            .lineSpacing(3)
                    }
                }
            }
            .padding(KickIQTheme.Spacing.md)
            .background(KickIQTheme.accent.opacity(0.06), in: .rect(cornerRadius: KickIQTheme.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                    .stroke(KickIQTheme.accent.opacity(0.15), lineWidth: 1)
            )
            .opacity(appeared ? 1 : 0)
        }
    }

    // MARK: - Skill Breakdown

    private var skillBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SKILL BREAKDOWN")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQTheme.accent)

            ForEach(Array(session.skillScores.enumerated()), id: \.element.id) { index, score in
                VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
                    HStack(spacing: KickIQTheme.Spacing.sm) {
                        Image(systemName: score.category.icon)
                            .font(.caption)
                            .foregroundStyle(KickIQTheme.accent)
                            .frame(width: 20)

                        Text(score.category.rawValue)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(KickIQTheme.textPrimary.opacity(0.8))

                        Spacer()

                        if let confidence = score.confidence {
                            Image(systemName: confidence.icon)
                                .font(.system(size: 11))
                                .foregroundStyle(confidenceColor(confidence))
                        }

                        Text("\(score.score)/10")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(KickIQTheme.textPrimary)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(KickIQTheme.divider)
                                .frame(height: 6)

                            Capsule()
                                .fill(KickIQTheme.accent)
                                .frame(width: scoreAppeared ? geo.size.width * score.percentage : 0, height: 6)
                                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(index) * 0.1), value: scoreAppeared)
                        }
                    }
                    .frame(height: 6)

                    if let observed = score.observedAction, !observed.isEmpty {
                        HStack(alignment: .top, spacing: 4) {
                            Image(systemName: "eye.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(.blue.opacity(0.7))
                            Text(observed)
                                .font(.caption)
                                .foregroundStyle(KickIQTheme.textSecondary)
                                .italic()
                        }
                    }

                    if !score.feedback.isEmpty {
                        Text(score.feedback)
                            .font(.caption)
                            .foregroundStyle(KickIQTheme.textSecondary)
                    }

                    if !score.tip.isEmpty {
                        HStack(alignment: .top, spacing: 4) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(KickIQTheme.accent)
                            Text(score.tip)
                                .font(.caption)
                                .foregroundStyle(KickIQTheme.accent.opacity(0.9))
                        }
                    }

                    if let confidence = score.confidence, confidence == .low {
                        HStack(spacing: 4) {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(.yellow.opacity(0.7))
                            Text("Low confidence — skill not clearly visible in clip")
                                .font(.system(size: 10))
                                .foregroundStyle(.yellow.opacity(0.7))
                        }
                    }
                }
                .padding(KickIQTheme.Spacing.sm)
                .background(KickIQTheme.surface, in: .rect(cornerRadius: KickIQTheme.Radius.sm))
            }
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
    }

    // MARK: - Coaching Points

    @ViewBuilder
    private var coachingPointsSection: some View {
        if let sf = session.structuredFeedback, !sf.coachingPoints.isEmpty {
            VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
                HStack(spacing: 6) {
                    Image(systemName: "clipboard.fill")
                        .foregroundStyle(KickIQTheme.accent)
                    Text("KEY COACHING POINTS")
                        .font(.caption.weight(.bold))
                        .tracking(1)
                        .foregroundStyle(KickIQTheme.accent)
                }

                ForEach(Array(sf.coachingPoints.enumerated()), id: \.offset) { index, point in
                    HStack(alignment: .top, spacing: KickIQTheme.Spacing.sm) {
                        Text("\(index + 1)")
                            .font(.caption2.weight(.black))
                            .foregroundStyle(.black)
                            .frame(width: 20, height: 20)
                            .background(KickIQTheme.accent, in: Circle())

                        Text(point)
                            .font(.subheadline)
                            .foregroundStyle(KickIQTheme.textPrimary.opacity(0.85))
                            .lineSpacing(3)
                    }
                }
            }
            .padding(KickIQTheme.Spacing.md)
            .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
            .opacity(appeared ? 1 : 0)
        }
    }

    // MARK: - Next Session Focus

    @ViewBuilder
    private var nextSessionFocusSection: some View {
        if let sf = session.structuredFeedback, !sf.nextSessionFocus.isEmpty {
            VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
                HStack(spacing: 6) {
                    Image(systemName: "target")
                        .foregroundStyle(KickIQTheme.accent)
                    Text("NEXT SESSION FOCUS")
                        .font(.caption.weight(.bold))
                        .tracking(1)
                        .foregroundStyle(KickIQTheme.accent)
                }

                Text(sf.nextSessionFocus)
                    .font(.subheadline)
                    .foregroundStyle(KickIQTheme.textPrimary.opacity(0.85))
                    .lineSpacing(4)
            }
            .padding(KickIQTheme.Spacing.md)
            .background(
                KickIQTheme.accent.opacity(0.04),
                in: .rect(cornerRadius: KickIQTheme.Radius.lg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                    .stroke(KickIQTheme.accent.opacity(0.2), lineWidth: 1)
            )
            .opacity(appeared ? 1 : 0)
        }
    }

    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: KickIQTheme.Spacing.sm) {
                Image(systemName: "quote.opening")
                    .foregroundStyle(KickIQTheme.accent)
                Text("COACH FEEDBACK")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(KickIQTheme.accent)
            }

            Text(session.feedback)
                .font(.body)
                .foregroundStyle(KickIQTheme.textPrimary.opacity(0.85))
                .lineSpacing(4)
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
    }

    private var drillsSection: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            Text("RECOMMENDED DRILLS")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQTheme.accent)

            ForEach(session.drills) { drill in
                HStack(alignment: .top, spacing: KickIQTheme.Spacing.sm) {
                    Image(systemName: "figure.run")
                        .font(.subheadline)
                        .foregroundStyle(KickIQTheme.accent)
                        .frame(width: 28, height: 28)
                        .background(KickIQTheme.accent.opacity(0.15), in: .rect(cornerRadius: KickIQTheme.Radius.sm))

                    VStack(alignment: .leading, spacing: KickIQTheme.Spacing.xs) {
                        HStack {
                            Text(drill.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(KickIQTheme.textPrimary)
                            Spacer()
                            Text(drill.duration)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(KickIQTheme.accent)
                                .padding(.horizontal, KickIQTheme.Spacing.sm)
                                .padding(.vertical, 3)
                                .background(KickIQTheme.accent.opacity(0.15), in: Capsule())
                        }
                        Text(drill.description)
                            .font(.caption)
                            .foregroundStyle(KickIQTheme.textSecondary)

                        HStack(spacing: KickIQTheme.Spacing.sm) {
                            Text(drill.difficulty.rawValue)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(KickIQTheme.textSecondary)
                            Text("·")
                                .foregroundStyle(KickIQTheme.textSecondary.opacity(0.4))
                            Text(drill.targetSkill)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(KickIQTheme.accent)
                        }

                        if !drill.coachingCues.isEmpty {
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(drill.coachingCues, id: \.self) { cue in
                                    HStack(alignment: .top, spacing: 4) {
                                        Text("•")
                                            .font(.caption2)
                                            .foregroundStyle(KickIQTheme.accent.opacity(0.6))
                                        Text(cue)
                                            .font(.caption2)
                                            .foregroundStyle(KickIQTheme.textSecondary)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(KickIQTheme.Spacing.sm)
                .background(KickIQTheme.surface, in: .rect(cornerRadius: KickIQTheme.Radius.md))
            }
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
    }

    private var sessionNotesButton: some View {
        let noteCount = storage.notesForSession(session.id).count

        return Button {
            showSessionNotes = true
        } label: {
            HStack(spacing: KickIQTheme.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: KickIQTheme.Radius.sm)
                        .fill(KickIQTheme.accent.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "note.text")
                        .font(.title3)
                        .foregroundStyle(KickIQTheme.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Session Journal")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KickIQTheme.textPrimary)
                    Text(noteCount > 0 ? "\(noteCount) note\(noteCount > 1 ? "s" : "") added" : "Add notes about this session")
                        .font(.caption)
                        .foregroundStyle(KickIQTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(KickIQTheme.textSecondary.opacity(0.3))
            }
            .padding(KickIQTheme.Spacing.md)
            .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
        }
        .opacity(appeared ? 1 : 0)
    }

    private var sharePromptBanner: some View {
        VStack(spacing: KickIQTheme.Spacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 10))
                Text("KICKIQ ATHLETE")
                    .font(.system(size: 10, weight: .black))
                    .tracking(1.5)
            }
            .foregroundStyle(KickIQTheme.accent)

            Text("Share your results and show your squad what you're working on")
                .font(.caption)
                .foregroundStyle(KickIQTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.accent.opacity(0.08), in: .rect(cornerRadius: KickIQTheme.Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                .stroke(KickIQTheme.accent.opacity(0.2), lineWidth: 1)
        )
        .opacity(appeared ? 1 : 0)
    }

    private var actionButtons: some View {
        VStack(spacing: KickIQTheme.Spacing.sm) {
            HStack(spacing: KickIQTheme.Spacing.sm) {
                Button {
                    generateShareCard()
                } label: {
                    HStack(spacing: KickIQTheme.Spacing.sm) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KickIQTheme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(KickIQTheme.accent.opacity(0.15), in: .rect(cornerRadius: KickIQTheme.Radius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: KickIQTheme.Radius.md)
                            .stroke(KickIQTheme.accent.opacity(0.3), lineWidth: 1)
                    )
                }

                Button {
                    showQRShare = true
                } label: {
                    HStack(spacing: KickIQTheme.Spacing.sm) {
                        Image(systemName: "qrcode")
                        Text("QR Code")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KickIQTheme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(KickIQTheme.accent.opacity(0.15), in: .rect(cornerRadius: KickIQTheme.Radius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: KickIQTheme.Radius.md)
                            .stroke(KickIQTheme.accent.opacity(0.3), lineWidth: 1)
                    )
                }
            }

            Button {
                onDismiss()
            } label: {
                HStack(spacing: KickIQTheme.Spacing.sm) {
                    Image(systemName: "plus")
                    Text("New Session")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.md))
            }
        }
        .opacity(appeared ? 1 : 0)
    }

    private func confidenceColor(_ level: ConfidenceLevel) -> Color {
        switch level {
        case .high: .green
        case .medium: .yellow
        case .low: .red.opacity(0.7)
        }
    }

    @MainActor
    private func generateShareCard() {
        if let image = ShareCardGenerator.generateImage(
            type: .analysis(session),
            playerName: storage.profile?.name ?? "Player",
            position: storage.profile?.position ?? .midfielder,
            streakCount: storage.streakCount,
            skillScore: storage.skillScore
        ) {
            shareImage = image
            showShareSheet = true
        }
    }
}

struct ShareSheetView: UIViewControllerRepresentable {
    let image: UIImage

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [image], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
