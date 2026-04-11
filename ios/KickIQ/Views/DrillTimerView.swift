import SwiftUI
import AVFoundation
import Combine

struct DrillTimerView: View {
    let drill: Drill
    @Environment(\.dismiss) private var dismiss
    @State private var timeRemaining: Int = 0
    @State private var totalTime: Int = 0
    @State private var isRunning: Bool = false
    @State private var currentSet: Int = 1
    @State private var totalSets: Int = 1
    @State private var isResting: Bool = false
    @State private var timerActive: Bool = false
    @State private var showComplete: Bool = false
    @State private var repCount: Int = 0
    @State private var voiceEnabled: Bool = true
    @State private var lastSpokenCueIndex: Int = -1
    @State private var currentCueText: String = ""
    @State private var showCue: Bool = false

    private let restDuration: Int = 30
    private let synthesizer = AVSpeechSynthesizer()

    var body: some View {
        NavigationStack {
            VStack(spacing: KickIQTheme.Spacing.lg) {
                Spacer()

                timerRing
                timerLabel

                if showCue {
                    coachingCueBanner
                }

                repCounter
                setIndicator
                controlButtons

                Spacer()
            }
            .padding(.horizontal, KickIQTheme.Spacing.md)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle(drill.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        synthesizer.stopSpeaking(at: .immediate)
                        dismiss()
                    }
                    .foregroundStyle(KickIQTheme.accent)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        voiceEnabled.toggle()
                    } label: {
                        Image(systemName: voiceEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .foregroundStyle(voiceEnabled ? KickIQTheme.accent : KickIQTheme.textSecondary)
                    }
                }
            }
            .overlay {
                if showComplete {
                    completionOverlay
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
        .onAppear { setupTimer() }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            guard timerActive else { return }
            tick()
        }
        .onDisappear {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }

    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(KickIQTheme.divider, lineWidth: 12)
                .frame(width: 200, height: 200)

            Circle()
                .trim(from: 0, to: totalTime > 0 ? CGFloat(timeRemaining) / CGFloat(totalTime) : 0)
                .stroke(
                    isResting ? Color.blue : KickIQTheme.accent,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: timeRemaining)

            VStack(spacing: 4) {
                Text(timeString(timeRemaining))
                    .font(.system(size: 56, weight: .black, design: .monospaced))
                    .foregroundStyle(KickIQTheme.textPrimary)
                    .contentTransition(.numericText())

                Text(isResting ? "REST" : "WORK")
                    .font(.caption.weight(.black))
                    .tracking(2)
                    .foregroundStyle(isResting ? .blue : KickIQTheme.accent)
            }
        }
    }

    private var timerLabel: some View {
        VStack(spacing: KickIQTheme.Spacing.xs) {
            Text(drill.targetSkill)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KickIQTheme.accent)

            if !drill.reps.isEmpty {
                Text(drill.reps)
                    .font(.caption)
                    .foregroundStyle(KickIQTheme.textSecondary)
            }
        }
    }

    private var coachingCueBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "quote.bubble.fill")
                .font(.caption)
                .foregroundStyle(KickIQTheme.accent)

            Text(currentCueText)
                .font(.caption.weight(.semibold))
                .foregroundStyle(KickIQTheme.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, KickIQTheme.Spacing.md)
        .padding(.vertical, KickIQTheme.Spacing.sm + 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KickIQTheme.accent.opacity(0.1), in: .rect(cornerRadius: KickIQTheme.Radius.md))
        .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
    }

    private var repCounter: some View {
        HStack(spacing: KickIQTheme.Spacing.lg) {
            Button {
                if repCount > 0 {
                    repCount -= 1
                }
            } label: {
                Image(systemName: "minus")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(KickIQTheme.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(KickIQTheme.card, in: Circle())
            }

            VStack(spacing: 2) {
                Text("\(repCount)")
                    .font(.system(size: 32, weight: .black, design: .monospaced))
                    .foregroundStyle(KickIQTheme.textPrimary)
                    .contentTransition(.numericText())
                Text("REPS")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(KickIQTheme.textSecondary.opacity(0.6))
            }

            Button {
                repCount += 1
            } label: {
                Image(systemName: "plus")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(KickIQTheme.accent)
                    .frame(width: 44, height: 44)
                    .background(KickIQTheme.accent.opacity(0.15), in: Circle())
            }
            .sensoryFeedback(.impact(weight: .light), trigger: repCount)
        }
    }

    private var setIndicator: some View {
        HStack(spacing: KickIQTheme.Spacing.sm) {
            ForEach(1...totalSets, id: \.self) { set in
                Circle()
                    .fill(set < currentSet ? KickIQTheme.accent : set == currentSet ? KickIQTheme.accent.opacity(0.5) : KickIQTheme.divider)
                    .frame(width: 10, height: 10)
            }
        }
    }

    private var controlButtons: some View {
        HStack(spacing: KickIQTheme.Spacing.lg) {
            Button {
                resetTimer()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
                    .foregroundStyle(KickIQTheme.textSecondary)
                    .frame(width: 60, height: 60)
                    .background(KickIQTheme.card, in: Circle())
            }

            Button {
                if !timerActive {
                    timerActive = true
                    isRunning = true
                    if currentSet == 1 && timeRemaining == totalTime {
                        speak("Let's go! Set 1 of \(totalSets). \(drill.targetSkill).")
                    }
                } else {
                    timerActive = false
                    isRunning = false
                }
            } label: {
                Image(systemName: timerActive ? "pause.fill" : "play.fill")
                    .font(.title)
                    .foregroundStyle(.black)
                    .frame(width: 80, height: 80)
                    .background(KickIQTheme.accent, in: Circle())
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: isRunning)

            Button {
                skipToNext()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title2)
                    .foregroundStyle(KickIQTheme.textSecondary)
                    .frame(width: 60, height: 60)
                    .background(KickIQTheme.card, in: Circle())
            }
        }
    }

    private var completionOverlay: some View {
        ZStack {
            KickIQTheme.background.opacity(0.95).ignoresSafeArea()

            VStack(spacing: KickIQTheme.Spacing.lg) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(KickIQTheme.accent)

                Text("Drill Complete!")
                    .font(.title.weight(.black))
                    .foregroundStyle(KickIQTheme.textPrimary)

                Text("\(drill.name) — \(totalSets) sets finished")
                    .font(.subheadline)
                    .foregroundStyle(KickIQTheme.textSecondary)

                if repCount > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(.orange)
                        Text("\(repCount) reps logged")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(KickIQTheme.textPrimary)
                    }
                    .padding(.horizontal, KickIQTheme.Spacing.md)
                    .padding(.vertical, KickIQTheme.Spacing.sm)
                    .background(Color.orange.opacity(0.12), in: Capsule())
                }

                Button {
                    synthesizer.stopSpeaking(at: .immediate)
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, KickIQTheme.Spacing.md)
                        .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
                }
                .padding(.horizontal, KickIQTheme.Spacing.xl)
            }
        }
        .transition(.opacity)
        .sensoryFeedback(.success, trigger: showComplete)
    }

    private func setupTimer() {
        let parsed = parseDuration(drill.duration)
        let perSet = max(parsed / max(parseSets(), 1), 30)
        totalSets = parseSets()
        totalTime = perSet
        timeRemaining = perSet
    }

    private func parseDuration(_ duration: String) -> Int {
        let numbers = duration.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap { Int($0) }
        return (numbers.first ?? 10) * 60
    }

    private func parseSets() -> Int {
        let reps = drill.reps.lowercased()
        if let range = reps.range(of: #"\d+"#, options: .regularExpression) {
            return Int(reps[range]) ?? 3
        }
        return 3
    }

    private func tick() {
        guard timeRemaining > 0 else {
            handleSetTransition()
            return
        }

        timeRemaining -= 1

        if !isResting {
            if timeRemaining == 30 {
                speak("30 seconds left!")
            } else if timeRemaining == 10 {
                speak("10 seconds! Push through!")
            } else if timeRemaining == 3 {
                speak("3")
            } else if timeRemaining == 2 {
                speak("2")
            } else if timeRemaining == 1 {
                speak("1")
            }

            let cueInterval = max(totalTime / max(drill.coachingCues.count + 1, 2), 15)
            if !drill.coachingCues.isEmpty && timeRemaining > 5 && timeRemaining % cueInterval == 0 {
                let nextIndex = (lastSpokenCueIndex + 1) % drill.coachingCues.count
                let cue = drill.coachingCues[nextIndex]
                lastSpokenCueIndex = nextIndex
                showCoachingCue(cue)
                speak(cue)
            }
        } else {
            if timeRemaining == 5 {
                speak("Get ready!")
            }
        }
    }

    private func handleSetTransition() {
        if isResting {
            isResting = false
            totalTime = max(parseDuration(drill.duration) / max(parseSets(), 1), 30)
            timeRemaining = totalTime
            speak("Go! Set \(currentSet) of \(totalSets).")
        } else if currentSet < totalSets {
            currentSet += 1
            isResting = true
            totalTime = restDuration
            timeRemaining = restDuration
            speak("Rest. Next set in \(restDuration) seconds.")
        } else {
            timerActive = false
            speak("Great work! Drill complete.")
            withAnimation(.spring(response: 0.5)) { showComplete = true }
        }
    }

    private func resetTimer() {
        synthesizer.stopSpeaking(at: .immediate)
        timerActive = false
        isRunning = false
        currentSet = 1
        isResting = false
        repCount = 0
        lastSpokenCueIndex = -1
        withAnimation { showCue = false }
        setupTimer()
    }

    private func skipToNext() {
        timeRemaining = 0
    }

    private func speak(_ text: String) {
        guard voiceEnabled else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 1.05
        utterance.pitchMultiplier = 1.1
        utterance.volume = 0.9
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.stopSpeaking(at: .word)
        synthesizer.speak(utterance)
    }

    private func showCoachingCue(_ text: String) {
        withAnimation(.spring(response: 0.3)) {
            currentCueText = text
            showCue = true
        }
        Task {
            try? await Task.sleep(for: .seconds(4))
            withAnimation(.easeOut(duration: 0.3)) {
                showCue = false
            }
        }
    }

    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
