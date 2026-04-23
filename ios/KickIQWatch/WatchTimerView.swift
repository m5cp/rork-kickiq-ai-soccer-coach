import SwiftUI
import Combine

struct WatchTimerView: View {
    @State private var pedometer = WatchPedometerService.shared
    @State private var selectedMinutes: Int = 15
    @State private var timeRemaining: Int = 0
    @State private var totalTime: Int = 0
    @State private var timerActive: Bool = false
    @State private var showComplete: Bool = false

    private let presets: [Int] = [5, 10, 15, 20, 30, 45]

    var body: some View {
        Group {
            if totalTime == 0 {
                presetPicker
            } else {
                runningTimer
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            guard timerActive else { return }
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timerActive = false
                showComplete = true
                pedometer.endLiveSession()
            }
        }
    }

    private var presetPicker: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("Drill Timer")
                    .font(.headline)
                ForEach(presets, id: \.self) { mins in
                    Button {
                        start(minutes: mins)
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("\(mins) min")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .foregroundStyle(.white)
                        .padding(.vertical, 10).padding(.horizontal, 12)
                        .background(Color.orange, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var runningTimer: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.25), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: totalTime > 0 ? CGFloat(timeRemaining) / CGFloat(totalTime) : 0)
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timeRemaining)
                VStack(spacing: 2) {
                    Text(timeString(timeRemaining))
                        .font(.system(size: 24, weight: .black, design: .monospaced))
                        .contentTransition(.numericText())
                    Text("\(pedometer.liveSessionSteps) steps")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
            .frame(width: 120, height: 120)

            HStack(spacing: 10) {
                Button {
                    timerActive.toggle()
                } label: {
                    Image(systemName: timerActive ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(Color.orange, in: Circle())
                }
                .buttonStyle(.plain)

                Button {
                    stop()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(Color.gray, in: Circle())
                }
                .buttonStyle(.plain)
            }

            if showComplete {
                Label("Complete", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption.weight(.semibold))
            }
        }
    }

    private func start(minutes: Int) {
        totalTime = minutes * 60
        timeRemaining = totalTime
        timerActive = true
        showComplete = false
        pedometer.beginLiveSession()
    }

    private func stop() {
        timerActive = false
        totalTime = 0
        timeRemaining = 0
        pedometer.endLiveSession()
    }

    private func timeString(_ s: Int) -> String {
        String(format: "%d:%02d", s / 60, s % 60)
    }
}
