import SwiftUI
import AVFoundation
import Combine

struct SkillAssessmentView: View {
    let storage: StorageService
    @Environment(\.dismiss) private var dismiss
    @State private var challenges: [AssessmentChallenge] = []
    @State private var currentIndex: Int = 0
    @State private var phase: AssessmentPhase = .intro
    @State private var scores: [Int] = []
    @State private var countdownValue: Int = 3
    @State private var timerValue: Int = 0
    @State private var timerActive: Bool = false
    @State private var repCount: Int = 0
    @State private var assessmentSession: SkillAssessmentSession?

    private let synthesizer = AVSpeechSynthesizer()

    var body: some View {
        NavigationStack {
            ZStack {
                KickIQTheme.background.ignoresSafeArea()

                switch phase {
                case .intro:
                    introView
                case .countdown:
                    countdownView
                case .active:
                    activeView
                case .scoring:
                    scoringView
                case .results:
                    resultsView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        synthesizer.stopSpeaking(at: .immediate)
                        dismiss()
                    }
                    .foregroundStyle(KickIQTheme.textSecondary)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
        .onAppear {
            let position = storage.profile?.position ?? .midfielder
            challenges = AssessmentChallengeLibrary.challenges(for: position)
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            guard timerActive else { return }
            if phase == .countdown {
                tickCountdown()
            } else if phase == .active {
                tickTimer()
            }
        }
        .onDisappear {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }

    private var currentChallenge: AssessmentChallenge? {
        guard currentIndex < challenges.count else { return nil }
        return challenges[currentIndex]
    }

    private var introView: some View {
        VStack(spacing: KickIQTheme.Spacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(KickIQTheme.accent.opacity(0.15))
                    .frame(width: 100, height: 100)
                Image(systemName: "clipboard.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(KickIQTheme.accent)
            }

            VStack(spacing: KickIQTheme.Spacing.sm) {
                Text("Skill Assessment")
                    .font(.title.weight(.black))
                    .foregroundStyle(KickIQTheme.textPrimary)

                Text("Test \(challenges.count) skills with timed challenges.\nResults help personalize your training.")
                    .font(.subheadline)
                    .foregroundStyle(KickIQTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: KickIQTheme.Spacing.sm) {
                ForEach(challenges) { challenge in
                    HStack(spacing: KickIQTheme.Spacing.sm) {
                        Image(systemName: challenge.icon)
                            .font(.caption)
                            .foregroundStyle(KickIQTheme.accent)
                            .frame(width: 24)
                        Text(challenge.skill.rawValue)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(KickIQTheme.textPrimary)
                        Spacer()
                        Text("\(challenge.duration)s")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(KickIQTheme.textSecondary)
                    }
                    .padding(.horizontal, KickIQTheme.Spacing.md)
                    .padding(.vertical, KickIQTheme.Spacing.sm)
                    .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
                }
            }
            .padding(.horizontal, KickIQTheme.Spacing.lg)

            Spacer()

            Button {
                startAssessment()
            } label: {
                Text("Begin Assessment")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, KickIQTheme.Spacing.md)
                    .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
            }
            .padding(.horizontal, KickIQTheme.Spacing.lg)
            .padding(.bottom, KickIQTheme.Spacing.lg)
        }
    }

    private var countdownView: some View {
        VStack(spacing: KickIQTheme.Spacing.lg) {
            Spacer()

            if let challenge = currentChallenge {
                VStack(spacing: KickIQTheme.Spacing.sm) {
                    Text("NEXT UP")
                        .font(.caption.weight(.bold))
                        .tracking(2)
                        .foregroundStyle(KickIQTheme.accent)

                    Text(challenge.name)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(KickIQTheme.textPrimary)

                    Text(challenge.instruction)
                        .font(.subheadline)
                        .foregroundStyle(KickIQTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, KickIQTheme.Spacing.lg)
                }
            }

            Text("\(countdownValue)")
                .font(.system(size: 96, weight: .black, design: .monospaced))
                .foregroundStyle(KickIQTheme.accent)
                .contentTransition(.numericText())

            Text("Get Ready!")
                .font(.headline)
                .foregroundStyle(KickIQTheme.textSecondary)

            Spacer()
        }
    }

    private var activeView: some View {
        VStack(spacing: KickIQTheme.Spacing.lg) {
            if let challenge = currentChallenge {
                HStack {
                    Text("\(currentIndex + 1)/\(challenges.count)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(KickIQTheme.textSecondary)
                    Spacer()
                    Text(challenge.skill.rawValue)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(KickIQTheme.accent)
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)

                Spacer()

                ZStack {
                    Circle()
                        .stroke(KickIQTheme.divider, lineWidth: 10)
                        .frame(width: 180, height: 180)

                    Circle()
                        .trim(from: 0, to: challenge.duration > 0 ? CGFloat(timerValue) / CGFloat(challenge.duration) : 0)
                        .stroke(KickIQTheme.accent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 180, height: 180)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: timerValue)

                    VStack(spacing: 2) {
                        Text(timeString(timerValue))
                            .font(.system(size: 48, weight: .black, design: .monospaced))
                            .foregroundStyle(KickIQTheme.textPrimary)
                            .contentTransition(.numericText())
                        Text("remaining")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(KickIQTheme.textSecondary)
                    }
                }

                Text(challenge.name)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(KickIQTheme.textPrimary)

                Text(challenge.instruction)
                    .font(.caption)
                    .foregroundStyle(KickIQTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, KickIQTheme.Spacing.lg)

                HStack(spacing: KickIQTheme.Spacing.lg) {
                    Button {
                        if repCount > 0 { repCount -= 1 }
                    } label: {
                        Image(systemName: "minus")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(KickIQTheme.textSecondary)
                            .frame(width: 48, height: 48)
                            .background(KickIQTheme.card, in: Circle())
                    }

                    VStack(spacing: 2) {
                        Text("\(repCount)")
                            .font(.system(size: 36, weight: .black, design: .monospaced))
                            .foregroundStyle(KickIQTheme.textPrimary)
                            .contentTransition(.numericText())
                        Text(challenge.unit.uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1.5)
                            .foregroundStyle(KickIQTheme.textSecondary.opacity(0.6))
                    }
                    .frame(width: 80)

                    Button {
                        repCount += 1
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(KickIQTheme.accent)
                            .frame(width: 48, height: 48)
                            .background(KickIQTheme.accent.opacity(0.15), in: Circle())
                    }
                    .sensoryFeedback(.impact(weight: .light), trigger: repCount)
                }

                Spacer()
            }
        }
    }

    private var scoringView: some View {
        VStack(spacing: KickIQTheme.Spacing.lg) {
            Spacer()

            if let challenge = currentChallenge {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green)

                Text("Time's Up!")
                    .font(.title2.weight(.black))
                    .foregroundStyle(KickIQTheme.textPrimary)

                VStack(spacing: 4) {
                    Text(challenge.name)
                        .font(.headline)
                        .foregroundStyle(KickIQTheme.textPrimary)

                    HStack(spacing: 4) {
                        Text("\(repCount)")
                            .font(.title.weight(.black))
                            .foregroundStyle(KickIQTheme.accent)
                        Text(challenge.unit)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(KickIQTheme.textSecondary)
                    }
                }

                HStack(spacing: KickIQTheme.Spacing.lg) {
                    Button {
                        if repCount > 0 { repCount -= 1 }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(KickIQTheme.textSecondary)
                    }

                    Text("\(repCount)")
                        .font(.system(size: 28, weight: .black))
                        .foregroundStyle(KickIQTheme.textPrimary)
                        .frame(width: 60)

                    Button {
                        repCount += 1
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(KickIQTheme.accent)
                    }
                }

                Spacer()

                Button {
                    confirmScore()
                } label: {
                    Text(currentIndex < challenges.count - 1 ? "Next Challenge" : "See Results")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, KickIQTheme.Spacing.md)
                        .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
                }
                .padding(.horizontal, KickIQTheme.Spacing.lg)
                .padding(.bottom, KickIQTheme.Spacing.lg)
            }
        }
    }

    private var resultsView: some View {
        ScrollView {
            VStack(spacing: KickIQTheme.Spacing.lg) {
                VStack(spacing: KickIQTheme.Spacing.sm) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)

                    Text("Assessment Complete")
                        .font(.title2.weight(.black))
                        .foregroundStyle(KickIQTheme.textPrimary)

                    if let session = assessmentSession {
                        Text("Overall Score: \(session.overallScore)")
                            .font(.headline)
                            .foregroundStyle(KickIQTheme.accent)
                    }
                }
                .padding(.top, KickIQTheme.Spacing.lg)

                if let session = assessmentSession {
                    ForEach(Array(session.results.enumerated()), id: \.element.id) { index, result in
                        HStack(spacing: KickIQTheme.Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(scoreColor(result.score).opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Text("\(result.score)")
                                    .font(.headline.weight(.black))
                                    .foregroundStyle(scoreColor(result.score))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.skill)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(KickIQTheme.textPrimary)
                                Text(result.challengeName)
                                    .font(.caption)
                                    .foregroundStyle(KickIQTheme.textSecondary)
                            }

                            Spacer()

                            Text(scoreLabel(result.score))
                                .font(.caption.weight(.bold))
                                .foregroundStyle(scoreColor(result.score))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(scoreColor(result.score).opacity(0.12), in: Capsule())
                        }
                        .padding(KickIQTheme.Spacing.md)
                        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
                    }
                    .padding(.horizontal, KickIQTheme.Spacing.md)
                }

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, KickIQTheme.Spacing.md)
                        .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
                }
                .padding(.horizontal, KickIQTheme.Spacing.lg)
                .padding(.bottom, KickIQTheme.Spacing.lg)
            }
        }
        .scrollIndicators(.hidden)
    }

    private func startAssessment() {
        currentIndex = 0
        scores = []
        repCount = 0
        startCountdown()
    }

    private func startCountdown() {
        countdownValue = 3
        phase = .countdown
        timerActive = true
        if let challenge = currentChallenge {
            speak("Get ready. \(challenge.name)")
        }
    }

    private func tickCountdown() {
        if countdownValue > 1 {
            withAnimation(.spring(response: 0.3)) {
                countdownValue -= 1
            }
        } else {
            timerActive = false
            startChallenge()
        }
    }

    private func startChallenge() {
        guard let challenge = currentChallenge else { return }
        repCount = 0
        timerValue = challenge.duration
        phase = .active
        timerActive = true
        speak("Go!")
    }

    private func tickTimer() {
        if timerValue > 1 {
            timerValue -= 1
            if timerValue == 10 {
                speak("10 seconds!")
            } else if timerValue == 3 {
                speak("3, 2, 1")
            }
        } else {
            timerActive = false
            timerValue = 0
            speak("Time! Enter your count.")
            withAnimation(.spring(response: 0.4)) {
                phase = .scoring
            }
        }
    }

    private func confirmScore() {
        let normalizedScore = normalizeScore(repCount, for: currentChallenge)
        scores.append(normalizedScore)

        if currentIndex < challenges.count - 1 {
            currentIndex += 1
            repCount = 0
            startCountdown()
        } else {
            finishAssessment()
        }
    }

    private func finishAssessment() {
        var results: [AssessmentResult] = []
        for (i, challenge) in challenges.enumerated() {
            guard i < scores.count else { break }
            results.append(AssessmentResult(
                skill: challenge.skill.rawValue,
                challengeName: challenge.name,
                score: scores[i]
            ))
        }

        let session = SkillAssessmentSession(results: results)
        assessmentSession = session
        saveAssessment(session)
        speak("Assessment complete. Great work!")

        withAnimation(.spring(response: 0.5)) {
            phase = .results
        }
    }

    private func normalizeScore(_ rawCount: Int, for challenge: AssessmentChallenge?) -> Int {
        guard let challenge = challenge else { return 0 }
        if challenge.unit == "rating" {
            return min(max(rawCount, 0), 10)
        }
        let maxExpected: Double
        switch challenge.duration {
        case 20: maxExpected = 25
        case 30: maxExpected = 35
        default: maxExpected = 20
        }
        let normalized = min(Double(rawCount) / maxExpected, 1.0) * 10
        return min(Int(normalized.rounded()), 10)
    }

    private func saveAssessment(_ session: SkillAssessmentSession) {
        var saved = loadSavedAssessments()
        saved.insert(session, at: 0)
        if saved.count > 12 { saved = Array(saved.prefix(12)) }
        if let data = try? JSONEncoder().encode(saved) {
            UserDefaults.standard.set(data, forKey: "kickiq_assessments")
        }

        storage.xpPoints += 50
        UserDefaults.standard.set(storage.xpPoints, forKey: "kickiq_xp")
    }

    private func loadSavedAssessments() -> [SkillAssessmentSession] {
        guard let data = UserDefaults.standard.data(forKey: "kickiq_assessments"),
              let decoded = try? JSONDecoder().decode([SkillAssessmentSession].self, from: data) else {
            return []
        }
        return decoded
    }

    private func scoreColor(_ score: Int) -> Color {
        if score >= 8 { return .green }
        if score >= 5 { return .orange }
        return .red
    }

    private func scoreLabel(_ score: Int) -> String {
        if score >= 9 { return "Elite" }
        if score >= 7 { return "Strong" }
        if score >= 5 { return "Average" }
        if score >= 3 { return "Developing" }
        return "Needs Work"
    }

    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 1.05
        utterance.pitchMultiplier = 1.1
        utterance.volume = 0.9
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.stopSpeaking(at: .word)
        synthesizer.speak(utterance)
    }

    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

nonisolated enum AssessmentPhase: Sendable {
    case intro
    case countdown
    case active
    case scoring
    case results
}
