import SwiftUI

struct AnalysisResultView: View {
    let session: TrainingSession
    let storage: StorageService
    let onDismiss: () -> Void
    @State private var appeared = false
    @State private var scoreAppeared = false
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    @State private var showSessionNotes = false

    var body: some View {
        ScrollView {
            VStack(spacing: KickIQAICoachTheme.Spacing.md + 4) {
                headerSection
                overallScoreSection
                skillBreakdownSection
                if !session.strengths.isEmpty || !session.weaknesses.isEmpty {
                    strengthsWeaknessesSection
                }
                if !session.coachingPoints.isEmpty {
                    coachingPointsSection
                }
                feedbackSection
                drillsSection
                sessionNotesButton
                sharePromptBanner
                actionButtons
            }
            .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
            .padding(.bottom, KickIQAICoachTheme.Spacing.xl)
        }
        .scrollIndicators(.hidden)
        .background(KickIQAICoachTheme.background.ignoresSafeArea())
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
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.xs) {
                Text("SESSION COMPLETE")
                    .font(.caption.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(KickIQAICoachTheme.accent)

                Text("Analysis Results")
                    .font(.system(.title, design: .default, weight: .bold))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
            }
            Spacer()

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.5))
            }
        }
        .padding(.top, KickIQAICoachTheme.Spacing.md)
        .opacity(appeared ? 1 : 0)
    }

    private var overallScoreSection: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.md) {
            ZStack {
                Circle()
                    .stroke(KickIQAICoachTheme.divider, lineWidth: 10)
                    .frame(width: 130, height: 130)

                Circle()
                    .trim(from: 0, to: scoreAppeared ? Double(session.overallScore) / 100.0 : 0)
                    .stroke(
                        AngularGradient(
                            colors: [KickIQAICoachTheme.accent, KickIQAICoachTheme.accent.opacity(0.4), KickIQAICoachTheme.accent],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 130, height: 130)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(session.overallScore)")
                        .font(.system(size: 44, weight: .black, design: .default))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    Text("/ 100")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }
                .scaleEffect(scoreAppeared ? 1 : 0.5)
                .opacity(scoreAppeared ? 1 : 0)
            }

            Text("Session Score")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, KickIQAICoachTheme.Spacing.lg)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.xl))
    }

    private var skillBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SKILL BREAKDOWN")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQAICoachTheme.accent)

            ForEach(Array(session.skillScores.enumerated()), id: \.element.id) { index, score in
                VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
                    HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                        Image(systemName: score.category.icon)
                            .font(.caption)
                            .foregroundStyle(KickIQAICoachTheme.accent)
                            .frame(width: 20)

                        Text(score.category.rawValue)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(KickIQAICoachTheme.textPrimary.opacity(0.8))

                        Spacer()

                        Text("\(score.score)/10")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(KickIQAICoachTheme.divider)
                                .frame(height: 6)

                            Capsule()
                                .fill(KickIQAICoachTheme.accent)
                                .frame(width: scoreAppeared ? geo.size.width * score.percentage : 0, height: 6)
                                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(index) * 0.1), value: scoreAppeared)
                        }
                    }
                    .frame(height: 6)

                    if !score.feedback.isEmpty {
                        Text(score.feedback)
                            .font(.caption)
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    }
                    if !score.tip.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(KickIQAICoachTheme.accent)
                            Text(score.tip)
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
        .opacity(appeared ? 1 : 0)
    }

    private var strengthsWeaknessesSection: some View {
        HStack(alignment: .top, spacing: KickIQAICoachTheme.Spacing.sm) {
            if !session.strengths.isEmpty {
                VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                        Text("STRENGTHS")
                            .font(.caption.weight(.bold))
                            .tracking(1)
                            .foregroundStyle(.green)
                    }

                    ForEach(session.strengths, id: \.self) { strength in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.green)
                                .padding(.top, 3)
                            Text(strength)
                                .font(.caption)
                                .foregroundStyle(KickIQAICoachTheme.textPrimary.opacity(0.85))
                                .lineSpacing(2)
                        }
                    }
                }
                .padding(KickIQAICoachTheme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.06), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                        .stroke(Color.green.opacity(0.15), lineWidth: 1)
                )
            }

            if !session.weaknesses.isEmpty {
                VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Text("WORK ON")
                            .font(.caption.weight(.bold))
                            .tracking(1)
                            .foregroundStyle(.orange)
                    }

                    ForEach(session.weaknesses, id: \.self) { weakness in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.orange)
                                .padding(.top, 3)
                            Text(weakness)
                                .font(.caption)
                                .foregroundStyle(KickIQAICoachTheme.textPrimary.opacity(0.85))
                                .lineSpacing(2)
                        }
                    }
                }
                .padding(KickIQAICoachTheme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.06), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                        .stroke(Color.orange.opacity(0.15), lineWidth: 1)
                )
            }
        }
        .opacity(appeared ? 1 : 0)
    }

    private var coachingPointsSection: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: "figure.soccer")
                    .font(.caption)
                Text("COACHING PRIORITIES")
                    .font(.caption.weight(.bold))
                    .tracking(1)
            }
            .foregroundStyle(KickIQAICoachTheme.accent)

            ForEach(Array(session.coachingPoints.enumerated()), id: \.offset) { index, point in
                HStack(alignment: .top, spacing: KickIQAICoachTheme.Spacing.sm) {
                    Text("\(index + 1)")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(KickIQAICoachTheme.onAccent)
                        .frame(width: 22, height: 22)
                        .background(KickIQAICoachTheme.accent, in: Circle())

                    Text(point)
                        .font(.subheadline)
                        .foregroundStyle(KickIQAICoachTheme.textPrimary.opacity(0.85))
                        .lineSpacing(3)
                }
            }
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
    }

    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                Image(systemName: "quote.opening")
                    .foregroundStyle(KickIQAICoachTheme.accent)
                Text("COACH FEEDBACK")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(KickIQAICoachTheme.accent)
            }

            Text(session.feedback)
                .font(.body)
                .foregroundStyle(KickIQAICoachTheme.textPrimary.opacity(0.85))
                .lineSpacing(4)
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
    }

    private var drillsSection: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            Text("RECOMMENDED DRILLS")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQAICoachTheme.accent)

            ForEach(session.drills) { drill in
                HStack(alignment: .top, spacing: KickIQAICoachTheme.Spacing.sm) {
                    Image(systemName: "figure.run")
                        .font(.subheadline)
                        .foregroundStyle(KickIQAICoachTheme.accent)
                        .frame(width: 28, height: 28)
                        .background(KickIQAICoachTheme.accent.opacity(0.15), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.sm))

                    VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.xs) {
                        HStack {
                            Text(drill.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(KickIQAICoachTheme.textPrimary)
                            Spacer()
                            Text(drill.duration)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(KickIQAICoachTheme.accent)
                                .padding(.horizontal, KickIQAICoachTheme.Spacing.sm)
                                .padding(.vertical, 3)
                                .background(KickIQAICoachTheme.accent.opacity(0.15), in: Capsule())
                        }
                        Text(drill.description)
                            .font(.caption)
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                            .lineLimit(2)

                        HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                            Text(drill.difficulty.rawValue)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(KickIQAICoachTheme.textSecondary)
                            Text("·")
                                .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.4))
                            Text(drill.targetSkill)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(KickIQAICoachTheme.accent)
                        }
                    }
                }
                .padding(KickIQAICoachTheme.Spacing.sm)
                .background(KickIQAICoachTheme.surface, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
            }
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
    }

    private var sessionNotesButton: some View {
        let noteCount = storage.notesForSession(session.id).count

        return Button {
            showSessionNotes = true
        } label: {
            HStack(spacing: KickIQAICoachTheme.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.sm)
                        .fill(KickIQAICoachTheme.accent.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "note.text")
                        .font(.title3)
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Session Journal")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    Text(noteCount > 0 ? "\(noteCount) note\(noteCount > 1 ? "s" : "") added" : "Add notes about this session")
                        .font(.caption)
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.3))
            }
            .padding(KickIQAICoachTheme.Spacing.md)
            .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        }
        .opacity(appeared ? 1 : 0)
    }

    private var sharePromptBanner: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 10))
                Text("KICKIQ ATHLETE")
                    .font(.system(size: 10, weight: .black))
                    .tracking(1.5)
            }
            .foregroundStyle(KickIQAICoachTheme.accent)

            Text("Share your results and show your squad what you're working on")
                .font(.caption)
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.accent.opacity(0.08), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                .stroke(KickIQAICoachTheme.accent.opacity(0.2), lineWidth: 1)
        )
        .opacity(appeared ? 1 : 0)
    }

    private var actionButtons: some View {
        HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            Button {
                generateShareCard()
            } label: {
                HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(KickIQAICoachTheme.accent.opacity(0.15), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.md)
                        .stroke(KickIQAICoachTheme.accent.opacity(0.3), lineWidth: 1)
                )
            }

            Button {
                onDismiss()
            } label: {
                HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                    Image(systemName: "plus")
                    Text("New Session")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.onAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(KickIQAICoachTheme.accent, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
            }
        }
        .opacity(appeared ? 1 : 0)
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
    var caption: String? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        var items: [Any] = [image]
        if let caption { items.append(caption) }
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        vc.completionWithItemsHandler = { _, completed, _, _ in
            if completed {
                Task { @MainActor in
                    AnalyticsService.shared.track(.shareCompleted)
                }
            }
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
