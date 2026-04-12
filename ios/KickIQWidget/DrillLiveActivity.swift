import ActivityKit
import SwiftUI
import WidgetKit

nonisolated struct DrillActivityAttributes: ActivityAttributes, Sendable {
    public struct ContentState: Codable, Hashable, Sendable {
        var timeRemaining: Int
        var totalTime: Int
        var currentSet: Int
        var totalSets: Int
        var isResting: Bool
        var isRunning: Bool
    }

    var drillName: String
    var targetSkill: String
}

struct DrillLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DrillActivityAttributes.self) { context in
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.drillName)
                            .font(.caption.weight(.bold))
                            .lineLimit(1)
                        Text(context.state.isResting ? "REST" : "WORK")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(context.state.isResting ? .blue : .orange)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timeString(context.state.timeRemaining))
                        .font(.system(size: 28, weight: .black, design: .monospaced))
                        .foregroundStyle(context.state.isResting ? .blue : .orange)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 12) {
                        progressBar(context: context)
                        Text("Set \(context.state.currentSet)/\(context.state.totalSets)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                HStack(spacing: 4) {
                    Image(systemName: context.state.isResting ? "pause.circle.fill" : "figure.soccer")
                        .font(.system(size: 13))
                        .foregroundStyle(context.state.isResting ? .blue : .orange)
                    Text(context.state.isResting ? "REST" : "GO")
                        .font(.system(size: 11, weight: .black))
                }
            } compactTrailing: {
                Text(timeString(context.state.timeRemaining))
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundStyle(context.state.isResting ? .blue : .orange)
            } minimal: {
                Image(systemName: "figure.soccer")
                    .foregroundStyle(.orange)
            }
        }
    }

    private func lockScreenView(context: ActivityViewContext<DrillActivityAttributes>) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "figure.soccer")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.orange)
                    Text("KICKIQ")
                        .font(.system(size: 10, weight: .black))
                        .tracking(1)
                        .foregroundStyle(.secondary)
                }

                Text(context.attributes.drillName)
                    .font(.subheadline.weight(.bold))
                    .lineLimit(1)

                Text(context.state.isResting ? "Rest Period" : context.attributes.targetSkill)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(context.state.isResting ? .blue : .orange)

                HStack(spacing: 6) {
                    ForEach(1...context.state.totalSets, id: \.self) { set in
                        Circle()
                            .fill(set < context.state.currentSet ? .orange : set == context.state.currentSet ? .orange.opacity(0.5) : Color(.systemGray4))
                            .frame(width: 8, height: 8)
                    }
                }
            }

            Spacer()

            VStack(spacing: 2) {
                Text(timeString(context.state.timeRemaining))
                    .font(.system(size: 36, weight: .black, design: .monospaced))
                    .foregroundStyle(context.state.isResting ? .blue : .orange)

                Text(context.state.isResting ? "REST" : "WORK")
                    .font(.system(size: 10, weight: .black))
                    .tracking(1.5)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
    }

    private func progressBar(context: ActivityViewContext<DrillActivityAttributes>) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray4))
                    .frame(height: 4)
                Capsule()
                    .fill(context.state.isResting ? .blue : .orange)
                    .frame(width: context.state.totalTime > 0 ? geo.size.width * CGFloat(context.state.timeRemaining) / CGFloat(context.state.totalTime) : 0, height: 4)
            }
        }
        .frame(height: 4)
    }

    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
