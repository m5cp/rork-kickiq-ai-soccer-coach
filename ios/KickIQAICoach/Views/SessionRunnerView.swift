import SwiftUI
import Combine
import ActivityKit

struct SessionRunnerView: View {
    let session: CoachSession

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0
    @State private var timeRemaining: Int = 0
    @State private var totalTime: Int = 0
    @State private var timerActive: Bool = false
    @State private var isResting: Bool = false
    @State private var showComplete: Bool = false
    @State private var audio = AudioCueService()
    @State private var pedometer = PedometerService.shared
    @State private var liveActivity: Activity<DrillActivityAttributes>?

    private let restBetween: Int = 45

    private var currentActivity: SessionActivity? {
        guard currentIndex < session.activities.count else { return nil }
        return session.activities[currentIndex]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQAICoachTheme.Spacing.lg) {
                    progressHeader
                    timerRing
                    activityHeader
                    stepsChip
                    controls
                    if !isResting { infoPanel }
                }
                .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                .padding(.bottom, 40)
            }
            .background(KickIQAICoachTheme.background.ignoresSafeArea())
            .navigationTitle(session.displayTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("End") { finish() }
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
            .overlay { if showComplete { completionOverlay } }
        }
        .onAppear {
            loadCurrent()
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

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Activity \(min(currentIndex + 1, session.activities.count)) of \(session.activities.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                Spacer()
                Text(isResting ? "REST" : "WORK")
                    .font(.caption.weight(.black))
                    .tracking(1.5)
                    .foregroundStyle(isResting ? .blue : KickIQAICoachTheme.accent)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(KickIQAICoachTheme.divider)
                    Capsule().fill(KickIQAICoachTheme.accent)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 6)
        }
    }

    private var progress: CGFloat {
        guard !session.activities.isEmpty else { return 0 }
        return CGFloat(currentIndex) / CGFloat(session.activities.count)
    }

    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(KickIQAICoachTheme.divider, lineWidth: 14)
                .frame(width: 240, height: 240)
            Circle()
                .trim(from: 0, to: totalTime > 0 ? CGFloat(timeRemaining) / CGFloat(totalTime) : 0)
                .stroke(isResting ? Color.blue : KickIQAICoachTheme.accent, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .frame(width: 240, height: 240)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: timeRemaining)
            VStack(spacing: 4) {
                Text(timeString(timeRemaining))
                    .font(.system(size: 60, weight: .black, design: .monospaced))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    .contentTransition(.numericText())
                Text(isResting ? "UP NEXT" : currentActivity?.displayTitle ?? "")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 40)
            }
        }
    }

    private var activityHeader: some View {
        Group {
            if let a = currentActivity {
                VStack(spacing: 4) {
                    Text(isResting ? "Next: \(a.displayTitle)" : a.displayTitle)
                        .font(.headline)
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                        .multilineTextAlignment(.center)
                    if !a.fieldSize.isEmpty || !a.playerNumbers.isEmpty {
                        Text("\(a.fieldSize) · \(a.playerNumbers)")
                            .font(.caption)
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    }
                }
            }
        }
    }

    private var stepsChip: some View {
        HStack(spacing: 6) {
            Image(systemName: "figure.walk")
            Text("\(pedometer.liveSessionSteps) steps")
                .contentTransition(.numericText())
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(KickIQAICoachTheme.accent)
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(KickIQAICoachTheme.accent.opacity(0.12), in: Capsule())
    }

    private var controls: some View {
        HStack(spacing: KickIQAICoachTheme.Spacing.lg) {
            Button {
                reset()
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
                skip()
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
        Group {
            if let a = currentActivity {
                VStack(alignment: .leading, spacing: 14) {
                    if !a.instructions.isEmpty {
                        block(title: "Instructions", body: a.instructions)
                    }
                    if !a.phases.isEmpty {
                        listBlock(title: "Phases", items: a.phases, symbol: "flag.fill")
                    }
                    if !a.coachingPoints.isEmpty {
                        listBlock(title: "Coaching Points", items: a.coachingPoints, symbol: "checkmark.circle.fill")
                    }
                }
            }
        }
    }

    private func block(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption2.weight(.black)).tracking(1)
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
                .font(.caption2.weight(.black)).tracking(1)
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
                Image(systemName: "trophy.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(KickIQAICoachTheme.accent)
                Text("Session Complete!")
                    .font(.title.weight(.black))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                Text("\(session.activities.count) activities · \(pedometer.liveSessionSteps) steps")
                    .font(.subheadline)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                Button { finish() } label: {
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

    private func loadCurrent() {
        guard let a = currentActivity else { return }
        isResting = false
        totalTime = max(a.duration, 1) * 60
        timeRemaining = totalTime
    }

    private func loadRest() {
        isResting = true
        totalTime = restBetween
        timeRemaining = restBetween
        audio.playRestStart()
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
            advance()
        }
    }

    private func advance() {
        if isResting {
            loadCurrent()
            audio.playGo()
        } else {
            if currentIndex + 1 < session.activities.count {
                currentIndex += 1
                loadRest()
            } else {
                timerActive = false
                audio.playComplete()
                endLiveActivity()
                withAnimation(.spring(response: 0.5)) { showComplete = true }
            }
        }
    }

    private func reset() {
        timerActive = false
        loadCurrent()
    }

    private func skip() {
        timeRemaining = 0
    }

    private func finish() {
        dismiss()
    }

    private func timeString(_ s: Int) -> String {
        String(format: "%d:%02d", s / 60, s % 60)
    }

    private func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = DrillActivityAttributes(drillName: currentActivity?.displayTitle ?? session.displayTitle, targetSkill: session.displayGameMoment)
        let state = DrillActivityAttributes.ContentState(
            timeRemaining: timeRemaining, totalTime: totalTime,
            currentSet: currentIndex + 1, totalSets: session.activities.count,
            isResting: isResting, isRunning: timerActive
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
            timeRemaining: timeRemaining, totalTime: totalTime,
            currentSet: currentIndex + 1, totalSets: session.activities.count,
            isResting: isResting, isRunning: timerActive
        )
        Task { await liveActivity.update(.init(state: state, staleDate: nil)) }
    }

    private func endLiveActivity() {
        guard let liveActivity else { return }
        let finalState = DrillActivityAttributes.ContentState(
            timeRemaining: 0, totalTime: totalTime,
            currentSet: session.activities.count, totalSets: session.activities.count,
            isResting: false, isRunning: false
        )
        Task { await liveActivity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .immediate) }
        self.liveActivity = nil
    }
}
