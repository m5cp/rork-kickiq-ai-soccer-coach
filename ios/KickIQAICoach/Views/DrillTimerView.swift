import SwiftUI
import Combine
import ActivityKit

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
    @State private var audio = AudioCueService()
    @State private var liveActivity: Activity<DrillActivityAttributes>?

    private let restDuration: Int = 30

    var body: some View {
        NavigationStack {
            VStack(spacing: KickIQAICoachTheme.Spacing.lg) {
                Spacer()

                timerRing
                timerLabel
                setIndicator
                controlButtons

                Spacer()
                Spacer()
            }
            .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
            .background(KickIQAICoachTheme.background.ignoresSafeArea())
            .navigationTitle(drill.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        audio.toggleMute()
                    } label: {
                        Image(systemName: audio.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(audio.isMuted ? KickIQAICoachTheme.textSecondary : KickIQAICoachTheme.accent)
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
        .presentationBackground(.background)
        .onAppear {
            setupTimer()
            startLiveActivity()
        }
        .onDisappear {
            endLiveActivity()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            guard timerActive else { return }
            tick()
        }
    }

    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(KickIQAICoachTheme.divider, lineWidth: 12)
                .frame(width: 200, height: 200)

            Circle()
                .trim(from: 0, to: totalTime > 0 ? CGFloat(timeRemaining) / CGFloat(totalTime) : 0)
                .stroke(
                    isResting ? Color.blue : KickIQAICoachTheme.accent,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: timeRemaining)

            VStack(spacing: 4) {
                Text(timeString(timeRemaining))
                    .font(.system(size: 56, weight: .black, design: .monospaced))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    .contentTransition(.numericText())

                Text(isResting ? "REST" : "WORK")
                    .font(.caption.weight(.black))
                    .tracking(2)
                    .foregroundStyle(isResting ? .blue : KickIQAICoachTheme.accent)
            }
        }
    }

    private var timerLabel: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.xs) {
            Text(drill.targetSkill)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.accent)

            if !drill.reps.isEmpty {
                Text(drill.reps)
                    .font(.caption)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
            }
        }
    }

    private var setIndicator: some View {
        HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            ForEach(1...totalSets, id: \.self) { set in
                Circle()
                    .fill(set < currentSet ? KickIQAICoachTheme.accent : set == currentSet ? KickIQAICoachTheme.accent.opacity(0.5) : KickIQAICoachTheme.divider)
                    .frame(width: 10, height: 10)
            }
        }
    }

    private var controlButtons: some View {
        HStack(spacing: KickIQAICoachTheme.Spacing.lg) {
            Button {
                resetTimer()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    .frame(width: 60, height: 60)
                    .background(KickIQAICoachTheme.card, in: Circle())
            }

            Button {
                timerActive.toggle()
                isRunning = timerActive
            } label: {
                Image(systemName: timerActive ? "pause.fill" : "play.fill")
                    .font(.title)
                    .foregroundStyle(KickIQAICoachTheme.onAccent)
                    .frame(width: 80, height: 80)
                    .background(KickIQAICoachTheme.accent, in: Circle())
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: isRunning)

            Button {
                skipToNext()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title2)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    .frame(width: 60, height: 60)
                    .background(KickIQAICoachTheme.card, in: Circle())
            }
        }
    }

    private var completionOverlay: some View {
        ZStack {
            KickIQAICoachTheme.background.opacity(0.95).ignoresSafeArea()

            VStack(spacing: KickIQAICoachTheme.Spacing.lg) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(KickIQAICoachTheme.accent)

                Text("Drill Complete!")
                    .font(.title.weight(.black))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)

                Text("\(drill.name) — \(totalSets) sets finished")
                    .font(.subheadline)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(KickIQAICoachTheme.onAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, KickIQAICoachTheme.Spacing.md)
                        .background(KickIQAICoachTheme.accent, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
                }
                .padding(.horizontal, KickIQAICoachTheme.Spacing.xl)
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
        if timeRemaining > 0 {
            timeRemaining -= 1
            if timeRemaining == 3 || timeRemaining == 2 || timeRemaining == 1 {
                audio.playCountdownBeep()
            } else if timeRemaining == 0 {
                audio.playFinalBeep()
            }
            updateLiveActivity()
        } else {
            if isResting {
                isResting = false
                totalTime = max(parseDuration(drill.duration) / max(parseSets(), 1), 30)
                timeRemaining = totalTime
                audio.playGo()
                updateLiveActivity()
            } else if currentSet < totalSets {
                currentSet += 1
                isResting = true
                totalTime = restDuration
                timeRemaining = restDuration
                audio.playRestStart()
                updateLiveActivity()
            } else {
                timerActive = false
                audio.playComplete()
                endLiveActivity()
                withAnimation(.spring(response: 0.5)) { showComplete = true }
            }
        }
    }

    private func resetTimer() {
        timerActive = false
        isRunning = false
        currentSet = 1
        isResting = false
        setupTimer()
    }

    private func skipToNext() {
        timeRemaining = 0
    }

    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = DrillActivityAttributes(drillName: drill.name, targetSkill: drill.targetSkill)
        let state = DrillActivityAttributes.ContentState(
            timeRemaining: timeRemaining,
            totalTime: totalTime,
            currentSet: currentSet,
            totalSets: totalSets,
            isResting: isResting,
            isRunning: timerActive
        )
        do {
            liveActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {}
    }

    private func updateLiveActivity() {
        guard let liveActivity else { return }
        let state = DrillActivityAttributes.ContentState(
            timeRemaining: timeRemaining,
            totalTime: totalTime,
            currentSet: currentSet,
            totalSets: totalSets,
            isResting: isResting,
            isRunning: timerActive
        )
        Task {
            await liveActivity.update(.init(state: state, staleDate: nil))
        }
    }

    private func endLiveActivity() {
        guard let liveActivity else { return }
        let finalState = DrillActivityAttributes.ContentState(
            timeRemaining: 0,
            totalTime: totalTime,
            currentSet: totalSets,
            totalSets: totalSets,
            isResting: false,
            isRunning: false
        )
        Task {
            await liveActivity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
        }
        self.liveActivity = nil
    }
}
