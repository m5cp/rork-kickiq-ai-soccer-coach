import SwiftUI

struct WatchTodayView: View {
    @State private var pedometer = WatchPedometerService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.25), lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: pedometer.goalProgress)
                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("\(pedometer.todaySteps)")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .contentTransition(.numericText())
                        Text("steps")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 120, height: 120)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Distance")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.2f mi", pedometer.todayDistanceMiles))
                            .font(.footnote.weight(.semibold))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Goal")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(Int(pedometer.goalProgress * 100))%")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding(.vertical, 4)
        }
        .onAppear { pedometer.loadToday() }
        .navigationTitle("Today")
    }
}
