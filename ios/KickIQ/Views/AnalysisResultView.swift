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
            VStack(spacing: KickIQTheme.Spacing.md + 4) {
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
            .padding(.horizontal, KickIQTheme.Spacing.md)
            .padding(.bottom, KickIQTheme.Spacing.xl)
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

                    if !score.feedback.isEmpty {
                        Text(score.feedback)
                            .font(.caption)
                            .foregroundStyle(KickIQTheme.textSecondary)
                    }
                    if !score.tip.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(KickIQTheme.accent)
                            Text(score.tip)
                                .font(.caption)
                                .foregroundStyle(KickIQTheme.accent.opacity(0.9))
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

    private var strengthsWeaknessesSection: some View {
        HStack(alignment: .top, spacing: KickIQTheme.Spacing.sm) {
            if !session.strengths.isEmpty {
                VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
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
                                .foregroundStyle(KickIQTheme.textPrimary.opacity(0.85))
                                .lineSpacing(2)
                        }
                    }
                }
                .padding(KickIQTheme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.06), in: .rect(cornerRadius: KickIQTheme.Radius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                        .stroke(Color.green.opacity(0.15), lineWidth: 1)
                )
            }

            if !session.weaknesses.isEmpty {
                VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
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
                                .foregroundStyle(KickIQTheme.textPrimary.opacity(0.85))
                                .lineSpacing(2)
                        }
                    }
                }
                .padding(KickIQTheme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.06), in: .rect(cornerRadius: KickIQTheme.Radius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                        .stroke(Color.orange.opacity(0.15), lineWidth: 1)
                )
            }
        }
        .opacity(appeared ? 1 : 0)
    }

    private var coachingPointsSection: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: "figure.soccer")
                    .font(.caption)
                Text("COACHING PRIORITIES")
                    .font(.caption.weight(.bold))
                    .tracking(1)
            }
            .foregroundStyle(KickIQTheme.accent)

            ForEach(Array(session.coachingPoints.enumerated()), id: \.offset) { index, point in
                HStack(alignment: .top, spacing: KickIQTheme.Spacing.sm) {
                    Text("\(index + 1)")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(KickIQTheme.onAccent)
                        .frame(width: 22, height: 22)
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
                            .lineLimit(2)

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
                onDismiss()
            } label: {
                HStack(spacing: KickIQTheme.Spacing.sm) {
                    Image(systemName: "plus")
                    Text("New Session")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KickIQTheme.onAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.md))
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

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [image], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
