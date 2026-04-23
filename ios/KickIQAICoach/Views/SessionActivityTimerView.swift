import SwiftUI
import Combine
import ActivityKit

struct SessionActivityTimerView: View {
    let activity: SessionActivity
    let sessionTitle: String
    var onComplete: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var timeRemaining: Int = 0
    @State private var totalTime: Int = 0
    @State private var timerActive: Bool = false
    @State private var isResting: Bool = false
    @State private var showComplete: Bool = false
    @State private var audio = AudioCueService()
    @State private var pedometer = PedometerService.shared
    @State private var liveActivity: Activity<DrillActivityAttributes>?

    private let restDuration: Int = 30

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQAICoachTheme.Spacing.lg) {
                    timerRing
                        .padding(.top, KickIQAICoachTheme.Spacing.md)
                    header
                    stepsChip
                    controlButtons
                    infoPanel
                }
                .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                .padding(.bottom, 40)
            }
            .background(KickIQAICoachTheme.background.ignoresSafeArea())
            .navigationTitle(activity.displayTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { finish() }
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
        .onAppear {
            setupTimer()
            pedometer.beginLiveSession()
            startLiveActivity()
        }
        .onDisappear {
            pedometer.endLiveSession()
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
                .stroke(KickIQAICoachTheme.divider, lineWidth: 14)
                .frame(width: 240, height: 240)

            Circle()
                .trim(from: 0, to: totalTime > 0 ? CGFloat(timeRemaining) / CGFloat(totalTime) : 0)
                .stroke(
                    isResting ? Color.blue : KickIQAICoachTheme.accent,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .frame(width: 240, height: 240)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: timeRemaining)

            VStack(spacing: 4) {
                Text(timeString(timeRemaining))
                    .font(.system(size: 60, weight: .black, design: .monospaced))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    .contentTransition(.numericText())

                Text(isResting ? "REST" : "WORK")
                    .font(.caption.weight(.black))
                    .tracking(2)
                    .foregroundStyle(isResting ? .blue : KickIQAICoachTheme.accent)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text(sessionTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
            if !activity.fieldSize.isEmpty || !activity.playerNumbers.isEmpty {
                Text("\(activity.fieldSize) · \(activity.playerNumbers)")
                    .font(.subheadline)
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var stepsChip: some View {
        HStack(spacing: 6) {
            Image(systemName: "figure.walk")
            Text("\(pedometer.liveSessionSteps) steps")
                .contentTransition(.numericText())
            if pedometer.liveSessionDistance > 0 {
                Text("·")
                Text(String(format: "%.2f mi", pedometer.liveSessionDistance / 1609.34))
            }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(KickIQAICoachTheme.accent)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(KickIQAICoachTheme.accent.opacity(0.12), in: Capsule())
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
            } label: {
                Image(systemName: timerActive ? "pause.fill" : "play.fill")
                    .font(.title)
                    .foregroundStyle(KickIQAICoachTheme.onAccent)
                    .frame(width: 84, height: 84)
                    .background(KickIQAICoachTheme.accent, in: Circle())
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: timerActive)

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

    private var infoPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !activity.instructions.isEmpty {
                infoBlock(title: "Instructions", body: activity.instructions)
            }
            if !activity.setupDescription.isEmpty {
                infoBlock(title: "Setup", body: activity.setupDescription)
            }
            if !activity.phases.isEmpty {
                listBlock(title: "Phases", items: activity.phases, symbol: "flag.fill")
            }
            if !activity.coachingPoints.isEmpty {
                listBlock(title: "Coaching Points", items: activity.coachingPoints, symbol: "checkmark.circle.fill")
            }
        }
    }

    private func infoBlock(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption2.weight(.black))
                .tracking(1)
                .foregroundStyle(KickIQAICoachTheme.accent)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: 14))
    }

    private func listBlock(title: String, items: [String], symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption2.weight(.black))
                .tracking(1)
                .foregroundStyle(KickIQAICoachTheme.accent)
            ForEach(items.indices, id: \.self) { idx in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: symbol)
                        .font(.caption)
                        .foregroundStyle(KickIQAICoachTheme.accent)
                        .padding(.top, 3)
                    Text(items[idx])
                        .font(.subheadline)
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: 14))
    }

    private var completionOverlay: some View {
        ZStack {
            KickIQAICoachTheme.background.opacity(0.95).ignoresSafeArea()
            VStack(spacing: KickIQAICoachTheme.Spacing.lg) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(KickIQAICoachTheme.accent)
                Text("Activity Complete!")
                    .font(.title.weight(.black))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                Text("\(pedometer.liveSessionSteps) steps logged")
                    .font(.subheadline)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                Button {
                    finish()
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
        let seconds = max(activity.duration, 1) * 60
        totalTime = seconds
        timeRemaining = seconds
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
            timerActive = false
            audio.playComplete()
            endLiveActivity()
            withAnimation(.spring(response: 0.5)) { showComplete = true }
        }
    }

    private func resetTimer() {
        timerActive = false
        setupTimer()
    }

    private func skipToNext() {
        timeRemaining = 0
    }

    private func finish() {
        onComplete?()
        dismiss()
    }

    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = DrillActivityAttributes(drillName: activity.displayTitle, targetSkill: sessionTitle)
        let state = DrillActivityAttributes.ContentState(
            timeRemaining: timeRemaining,
            totalTime: totalTime,
            currentSet: 1,
            totalSets: 1,
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
            currentSet: 1,
            totalSets: 1,
            isResting: isResting,
            isRunning: timerActive
        )
        Task { await liveActivity.update(.init(state: state, staleDate: nil)) }
    }

    private func endLiveActivity() {
        guard let liveActivity else { return }
        let finalState = DrillActivityAttributes.ContentState(
            timeRemaining: 0,
            totalTime: totalTime,
            currentSet: 1,
            totalSets: 1,
            isResting: false,
            isRunning: false
        )
        Task {
            await liveActivity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
        }
        self.liveActivity = nil
    }
}
