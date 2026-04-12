import WidgetKit
import SwiftUI

nonisolated struct KickIQEntry: TimelineEntry {
    let date: Date
    let streakCount: Int
    let skillScore: Int
    let drillsDone: Int
    let xpPoints: Int
    let playerLevel: String
    let playerName: String
    let weeklyMinutes: Int
    let weeklyGoal: Int
    let weeklyCompleted: Int
}

nonisolated struct KickIQProvider: TimelineProvider {
    private let suiteName = "group.app.rork.kickiq"

    func placeholder(in context: Context) -> KickIQEntry {
        KickIQEntry(date: .now, streakCount: 5, skillScore: 72, drillsDone: 12, xpPoints: 350, playerLevel: "Club Player", playerName: "Player", weeklyMinutes: 45, weeklyGoal: 3, weeklyCompleted: 2)
    }

    func getSnapshot(in context: Context, completion: @escaping (KickIQEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<KickIQEntry>) -> Void) {
        let entry = readEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func readEntry() -> KickIQEntry {
        let shared = UserDefaults(suiteName: suiteName)
        return KickIQEntry(
            date: .now,
            streakCount: shared?.integer(forKey: "widget_streak") ?? 0,
            skillScore: shared?.integer(forKey: "widget_score") ?? 0,
            drillsDone: shared?.integer(forKey: "widget_drills_done") ?? 0,
            xpPoints: shared?.integer(forKey: "widget_xp") ?? 0,
            playerLevel: shared?.string(forKey: "widget_level") ?? "Rookie",
            playerName: shared?.string(forKey: "widget_name") ?? "Player",
            weeklyMinutes: shared?.integer(forKey: "widget_weekly_minutes") ?? 0,
            weeklyGoal: shared?.integer(forKey: "widget_weekly_goal") ?? 3,
            weeklyCompleted: shared?.integer(forKey: "widget_weekly_completed") ?? 0
        )
    }
}

struct KickIQWidgetSmallView: View {
    var entry: KickIQEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "soccerball")
                    .font(.system(size: 12, weight: .bold))
                Text("KICKIQ")
                    .font(.system(size: 11, weight: .black))
                    .tracking(1)
            }
            .foregroundStyle(.secondary)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.orange)
                Text("\(entry.streakCount)")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(.primary)
            }

            Text("day streak")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                HStack(spacing: 2) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 8))
                    Text("\(entry.skillScore)")
                        .font(.system(size: 10, weight: .black))
                }
                HStack(spacing: 2) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 8))
                    Text("\(entry.xpPoints)")
                        .font(.system(size: 10, weight: .black))
                }
            }
            .foregroundStyle(.secondary)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct KickIQWidgetMediumView: View {
    var entry: KickIQEntry

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "soccerball")
                        .font(.system(size: 11, weight: .bold))
                    Text("KICKIQ")
                        .font(.system(size: 10, weight: .black))
                        .tracking(1)
                }
                .foregroundStyle(.secondary)

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(entry.streakCount)")
                            .font(.system(size: 28, weight: .black))
                        Text("day streak")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                }

                Text("Hey \(entry.playerName)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 10) {
                statBox(icon: "chart.bar.fill", value: "\(entry.skillScore)", label: "Score")
                statBox(icon: "checkmark.circle.fill", value: "\(entry.drillsDone)", label: "Drills")
                statBox(icon: "bolt.fill", value: "\(entry.xpPoints)", label: "XP")
            }

            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 4)
                        .frame(width: 50, height: 50)
                    Circle()
                        .trim(from: 0, to: entry.weeklyGoal > 0 ? min(Double(entry.weeklyCompleted) / Double(entry.weeklyGoal), 1.0) : 0)
                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                    Text("\(entry.weeklyCompleted)/\(entry.weeklyGoal)")
                        .font(.system(size: 10, weight: .black))
                }

                Text("Weekly")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private func statBox(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 12, weight: .black))
                Text(label)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct KickIQWidgetView: View {
    @Environment(\.widgetFamily) var family
    var entry: KickIQEntry

    var body: some View {
        switch family {
        case .systemSmall:
            KickIQWidgetSmallView(entry: entry)
        case .systemMedium:
            KickIQWidgetMediumView(entry: entry)
        default:
            KickIQWidgetMediumView(entry: entry)
        }
    }
}

struct KickIQWidget: Widget {
    let kind: String = "KickIQWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: KickIQProvider()) { entry in
            KickIQWidgetView(entry: entry)
        }
        .configurationDisplayName("KickIQ Training")
        .description("Track your streak, skill score, and weekly progress.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .containerBackgroundRemovable(false)
    }
}
