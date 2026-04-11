import SwiftUI
import AVFoundation
import Combine

struct WorkoutSessionView: View {
    let dailyPlan: DailyPlan
    let storage: StorageService
    @Environment(\.dismiss) private var dismiss
    @State private var currentDrillIndex: Int = 0
    @State private var timeRemaining: Int = 0
    @State private var totalTime: Int = 0
    @State private var isRunning: Bool = false
    @State private var isResting: Bool = false
    @State private var showSummary: Bool = false
    @State private var completedDrillIDs: Set<String> = []
    @State private var sessionStartTime: Date = .now
    @State private var voiceEnabled: Bool = true
    @State private var currentCueText: String = ""
    @State private var showCue: Bool = false
    @State private var lastCueIndex: Int = -1
    @State private var pulseScale: CGFloat = 1.0

    private let synthesizer = AVSpeechSynthesizer()
    private let restDuration: Int = 30

    private var drills: [SmartDrill] { dailyPlan.drills }
    private var currentDrill: SmartDrill? {
        guard currentDrillIndex < drills.count else { return nil }
        return drills[currentDrillIndex]
    }
    private var progress: Double {
        guard !drills.isEmpty else { return 0 }
        return Double(currentDrillIndex) / Double(drills.count)
    }

    var body: some View {
        ZStack {
            KickIQTheme.background.ignoresSafeArea()

            if showSummary {
                summaryView
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
            } else {
                sessionContent
            }
        }
        .onAppear {
            sessionStartTime = .now
            setupDrillTimer()
        }
        .onDisappear {
            synthesizer.stopSpeaking(at: .immediate)
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            guard isRunning else { return }
            tick()
        }
    }

    // MARK: - Session Content

    private var sessionContent: some View {
        VStack(spacing: 0) {
            sessionHeader
            Spacer()
            timerDisplay
            if showCue {
                cueBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
            drillInfo
            controls
        }
        .padding(.horizontal, KickIQTheme.Spacing.md)
        .animation(.spring(response: 0.4), value: showCue)
    }

    private var sessionHeader: some View {
        VStack(spacing: KickIQTheme.Spacing.sm) {
            HStack {
                Button {
                    synthesizer.stopSpeaking(at: .immediate)
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundStyle(KickIQTheme.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(KickIQTheme.card, in: Circle())
                }

                Spacer()

                VStack(spacing: 2) {
                    Text("DAY \(dailyPlan.dayNumber)")
                        .font(.system(size: 10, weight: .black))
                        .tracking(1.5)
                        .foregroundStyle(KickIQTheme.accent)
                    Text(dailyPlan.focus)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KickIQTheme.textSecondary)
                }

                Spacer()

                Button {
                    voiceEnabled.toggle()
                } label: {
                    Image(systemName: voiceEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.headline)
                        .foregroundStyle(voiceEnabled ? KickIQTheme.accent : KickIQTheme.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(KickIQTheme.card, in: Circle())
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(KickIQTheme.divider)
                        .frame(height: 4)
                    Capsule()
                        .fill(KickIQTheme.accent)
                        .frame(width: max(0, geo.size.width * progress), height: 4)
                        .animation(.spring(response: 0.4), value: currentDrillIndex)
                }
            }
            .frame(height: 4)

            HStack {
                Text("\(currentDrillIndex + 1) of \(drills.count)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(KickIQTheme.textSecondary)
                Spacer()
                Text("\(completedDrillIDs.count) completed")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.green)
            }
        }
        .padding(.top, KickIQTheme.Spacing.sm)
    }

    private var timerDisplay: some View {
        let ringSize: CGFloat = 220

        return ZStack {
            Circle()
                .stroke(KickIQTheme.divider, lineWidth: 10)
                .frame(width: ringSize, height: ringSize)

            Circle()
                .trim(from: 0, to: totalTime > 0 ? CGFloat(timeRemaining) / CGFloat(totalTime) : 0)
                .stroke(
                    isResting ? Color.blue : KickIQTheme.accent,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: ringSize, height: ringSize)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: timeRemaining)

            VStack(spacing: 4) {
                Text(timeString(timeRemaining))
                    .font(.system(size: 64, weight: .black, design: .monospaced))
                    .foregroundStyle(KickIQTheme.textPrimary)
                    .contentTransition(.numericText())

                Text(isResting ? "REST" : "WORK")
                    .font(.system(size: 12, weight: .black))
                    .tracking(3)
                    .foregroundStyle(isResting ? .blue : KickIQTheme.accent)
            }
            .scaleEffect(pulseScale)
        }
    }

    private var cueBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "quote.bubble.fill")
                .font(.caption)
                .foregroundStyle(KickIQTheme.accent)
            Text(currentCueText)
                .font(.caption.weight(.semibold))
                .foregroundStyle(KickIQTheme.textPrimary)
                .lineLimit(2)
        }
        .padding(.horizontal, KickIQTheme.Spacing.md)
        .padding(.vertical, KickIQTheme.Spacing.sm + 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KickIQTheme.accent.opacity(0.1), in: .rect(cornerRadius: KickIQTheme.Radius.md))
        .padding(.top, KickIQTheme.Spacing.sm)
    }

    private var drillInfo: some View {
        VStack(spacing: KickIQTheme.Spacing.sm) {
            if let drill = currentDrill {
                Text(drill.name)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(KickIQTheme.textPrimary)
                    .multilineTextAlignment(.center)

                HStack(spacing: KickIQTheme.Spacing.md) {
                    HStack(spacing: 4) {
                        Image(systemName: "target")
                            .font(.system(size: 11))
                        Text(drill.targetSkill)
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(KickIQTheme.accent)

                    if !drill.reps.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "repeat")
                                .font(.system(size: 11))
                            Text(drill.reps)
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(KickIQTheme.textSecondary)
                    }
                }

                Text(drill.description)
                    .font(.caption)
                    .foregroundStyle(KickIQTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, KickIQTheme.Spacing.md)
            }
        }
        .padding(.bottom, KickIQTheme.Spacing.md)
    }

    private var controls: some View {
        VStack(spacing: KickIQTheme.Spacing.md) {
            HStack(spacing: KickIQTheme.Spacing.xl) {
                Button {
                    if currentDrillIndex > 0 {
                        currentDrillIndex -= 1
                        isResting = false
                        lastCueIndex = -1
                        setupDrillTimer()
                    }
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.title2)
                        .foregroundStyle(currentDrillIndex > 0 ? KickIQTheme.textSecondary : KickIQTheme.textSecondary.opacity(0.3))
                        .frame(width: 56, height: 56)
                        .background(KickIQTheme.card, in: Circle())
                }
                .disabled(currentDrillIndex == 0)

                Button {
                    isRunning.toggle()
                    if isRunning && currentDrillIndex == 0 && timeRemaining == totalTime {
                        speak("Let's go! \(dailyPlan.focus). \(drills.count) drills today.")
                    }
                } label: {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
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
                        .frame(width: 56, height: 56)
                        .background(KickIQTheme.card, in: Circle())
                }
            }

            Button {
                markCurrentComplete()
            } label: {
                let isAlreadyDone = currentDrill.map { completedDrillIDs.contains($0.id) } ?? false
                HStack(spacing: KickIQTheme.Spacing.sm) {
                    Image(systemName: isAlreadyDone ? "checkmark.circle.fill" : "checkmark.circle")
                        .font(.subheadline.weight(.semibold))
                    Text(isAlreadyDone ? "Completed" : "Mark Complete")
                        .font(.subheadline.weight(.bold))
                }
                .foregroundStyle(isAlreadyDone ? .green : KickIQTheme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    (isAlreadyDone ? Color.green : KickIQTheme.accent).opacity(0.15),
                    in: .rect(cornerRadius: KickIQTheme.Radius.lg)
                )
            }
            .sensoryFeedback(.success, trigger: completedDrillIDs.count)
        }
        .padding(.bottom, KickIQTheme.Spacing.lg)
    }

    // MARK: - Summary

    private var summaryView: some View {
        let elapsed = Int(Date.now.timeIntervalSince(sessionStartTime))

        return ScrollView {
            VStack(spacing: KickIQTheme.Spacing.xl) {
                Spacer().frame(height: KickIQTheme.Spacing.lg)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(KickIQTheme.accent)

                Text("Session Complete!")
                    .font(.system(.title, design: .default, weight: .black))
                    .foregroundStyle(KickIQTheme.textPrimary)

                Text(dailyPlan.focus)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(KickIQTheme.textSecondary)

                HStack(spacing: 0) {
                    summaryStatItem(value: "\(completedDrillIDs.count)/\(drills.count)", label: "Drills", icon: "figure.soccer")
                    Divider().frame(height: 32).overlay(KickIQTheme.divider)
                    summaryStatItem(value: formatElapsed(elapsed), label: "Duration", icon: "clock")
                    Divider().frame(height: 32).overlay(KickIQTheme.divider)
                    summaryStatItem(value: "+\(completedDrillIDs.count * 25)", label: "XP Earned", icon: "star.fill")
                }
                .padding(.vertical, KickIQTheme.Spacing.md)
                .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))

                VStack(spacing: KickIQTheme.Spacing.sm) {
                    ForEach(Array(drills.enumerated()), id: \.element.id) { index, drill in
                        HStack(spacing: KickIQTheme.Spacing.sm) {
                            Image(systemName: completedDrillIDs.contains(drill.id) ? "checkmark.circle.fill" : "circle")
                                .font(.subheadline)
                                .foregroundStyle(completedDrillIDs.contains(drill.id) ? .green : KickIQTheme.textSecondary.opacity(0.4))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(drill.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(KickIQTheme.textPrimary)
                                Text(drill.targetSkill)
                                    .font(.caption2)
                                    .foregroundStyle(KickIQTheme.textSecondary)
                            }

                            Spacer()

                            Text(drill.duration)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(KickIQTheme.textSecondary)
                        }
                        .padding(.vertical, KickIQTheme.Spacing.sm)
                        .padding(.horizontal, KickIQTheme.Spacing.md)
                        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
                    }
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
            }
            .padding(.horizontal, KickIQTheme.Spacing.md)
            .padding(.bottom, KickIQTheme.Spacing.xl)
        }
        .scrollIndicators(.hidden)
    }

    private func summaryStatItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(KickIQTheme.accent)
                Text(value)
                    .font(.headline.weight(.black))
                    .foregroundStyle(KickIQTheme.textPrimary)
            }
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(KickIQTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Timer Logic

    private func setupDrillTimer() {
        guard let drill = currentDrill else { return }
        let seconds = parseDuration(drill.duration)
        totalTime = max(seconds, 30)
        timeRemaining = totalTime
        isResting = false
    }

    private func tick() {
        guard timeRemaining > 0 else {
            handleTransition()
            return
        }

        timeRemaining -= 1

        if !isResting {
            if timeRemaining == 30 { speak("30 seconds left!") }
            else if timeRemaining == 10 { speak("10 seconds! Push through!") }
            else if timeRemaining == 3 { speak("3") }
            else if timeRemaining == 2 { speak("2") }
            else if timeRemaining == 1 { speak("1") }

            if let drill = currentDrill, !drill.coachingCues.isEmpty {
                let interval = max(totalTime / max(drill.coachingCues.count + 1, 2), 15)
                if timeRemaining > 5 && timeRemaining % interval == 0 {
                    let nextIdx = (lastCueIndex + 1) % drill.coachingCues.count
                    let cue = drill.coachingCues[nextIdx]
                    lastCueIndex = nextIdx
                    showCoachCue(cue)
                    speak(cue)
                }
            }
        } else {
            if timeRemaining == 5 { speak("Get ready!") }
        }
    }

    private func handleTransition() {
        if isResting {
            isResting = false
            setupDrillTimer()
            if let drill = currentDrill {
                speak("Go! \(drill.name).")
            }
        } else {
            if currentDrillIndex < drills.count - 1 {
                markCurrentComplete()
                currentDrillIndex += 1
                lastCueIndex = -1
                isResting = true
                totalTime = restDuration
                timeRemaining = restDuration
                if let next = currentDrill {
                    speak("Rest. Up next: \(next.name).")
                }
                withAnimation(.spring(response: 0.3)) {
                    pulseScale = 1.05
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.3)) {
                        pulseScale = 1.0
                    }
                }
            } else {
                markCurrentComplete()
                isRunning = false
                speak("Great work! Session complete.")
                withAnimation(.spring(response: 0.5)) { showSummary = true }
            }
        }
    }

    private func skipToNext() {
        timeRemaining = 0
    }

    private func markCurrentComplete() {
        guard let drill = currentDrill else { return }
        if !completedDrillIDs.contains(drill.id) {
            completedDrillIDs.insert(drill.id)
            storage.completeDrill(drill.asDrill)
            if var plan = storage.smartTrainingPlan {
                for dayIndex in plan.days.indices {
                    for drillIndex in plan.days[dayIndex].drills.indices {
                        if plan.days[dayIndex].drills[drillIndex].id == drill.id {
                            plan.days[dayIndex].drills[drillIndex].isCompleted = true
                        }
                    }
                }
                storage.saveSmartTrainingPlan(plan)
            }
        }
    }

    private func parseDuration(_ duration: String) -> Int {
        let numbers = duration.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap { Int($0) }
        return (numbers.first ?? 5) * 60
    }

    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func formatElapsed(_ seconds: Int) -> String {
        if seconds >= 3600 {
            return "\(seconds / 3600)h \((seconds % 3600) / 60)m"
        }
        return "\(seconds / 60)m"
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

    private func showCoachCue(_ text: String) {
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
}
