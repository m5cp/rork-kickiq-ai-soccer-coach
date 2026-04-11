import SwiftUI
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

    private let restDuration: Int = 30

    var body: some View {
        NavigationStack {
            VStack(spacing: KickIQTheme.Spacing.lg) {
                Spacer()

                timerRing
                timerLabel
                setIndicator
                controlButtons

                Spacer()
                Spacer()
            }
            .padding(.horizontal, KickIQTheme.Spacing.md)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle(drill.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(KickIQTheme.accent)
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
                timerActive.toggle()
                isRunning = timerActive
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
        if timeRemaining > 0 {
            timeRemaining -= 1
            if timeRemaining == 3 || timeRemaining == 2 || timeRemaining == 1 {
                // Haptic cue for countdown
            }
        } else {
            if isResting {
                isResting = false
                totalTime = max(parseDuration(drill.duration) / max(parseSets(), 1), 30)
                timeRemaining = totalTime
            } else if currentSet < totalSets {
                currentSet += 1
                isResting = true
                totalTime = restDuration
                timeRemaining = restDuration
            } else {
                timerActive = false
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
}
