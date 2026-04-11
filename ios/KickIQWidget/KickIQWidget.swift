import WidgetKit
import SwiftUI

nonisolated struct KickIQEntry: TimelineEntry {
    let date: Date
    let streakCount: Int
    let skillScore: Int
    let playerName: String
    let xpPoints: Int
    let playerLevel: String
    let drillsCompleted: Int
}

nonisolated struct KickIQProvider: TimelineProvider {
    private let suiteName = "group.app.rork.kickiq.shared"

    func placeholder(in context: Context) -> KickIQEntry {
        KickIQEntry(
            date: .now,
            streakCount: 7,
            skillScore: 72,
            playerName: "Player",
            xpPoints: 250,
            playerLevel: "Club Player",
            drillsCompleted: 15
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (KickIQEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<KickIQEntry>) -> Void) {
        let entry = readEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func readEntry() -> KickIQEntry {
        let defaults = UserDefaults(suiteName: suiteName)
        return KickIQEntry(
            date: .now,
            streakCount: defaults?.integer(forKey: "widget_streak") ?? 0,
            skillScore: defaults?.integer(forKey: "widget_skill_score") ?? 0,
            playerName: defaults?.string(forKey: "widget_player_name") ?? "Player",
            xpPoints: defaults?.integer(forKey: "widget_xp") ?? 0,
            playerLevel: defaults?.string(forKey: "widget_player_level") ?? "Rookie",
            drillsCompleted: defaults?.integer(forKey: "widget_drills_completed") ?? 0
        )
    }
}

struct KickIQWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: KickIQEntry

    private let accentColor = Color(red: 1.0, green: 0.6, blue: 0.0)
    private let cardColor = Color(white: 0.10)
    private let bgColor = Color(white: 0.04)

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            largeWidget
        }
    }

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text("KICKIQ")
                    .font(.system(size: 9, weight: .bold, design: .default).width(.compressed))
                    .tracking(2)
                    .foregroundStyle(accentColor)
                Spacer()
            }

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(entry.streakCount > 0 ? accentColor : .gray.opacity(0.4))
                Text("\(entry.streakCount)")
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(.white)
            }

            Text("day streak")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))

            Spacer()

            HStack(spacing: 4) {
                Circle()
                    .fill(accentColor)
                    .frame(width: 6, height: 6)
                Text("\(entry.skillScore)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
                Text("skill score")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .containerBackground(bgColor, for: .widget)
    }

    private var mediumWidget: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("KICKIQ")
                    .font(.system(size: 9, weight: .bold, design: .default).width(.compressed))
                    .tracking(2)
                    .foregroundStyle(accentColor)

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(entry.streakCount > 0 ? accentColor : .gray.opacity(0.4))
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(entry.streakCount)")
                            .font(.system(size: 28, weight: .black))
                            .foregroundStyle(.white)
                        Text("day streak")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                Text(motivationalText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
            }

            Spacer()

            VStack(spacing: 12) {
                statBox(value: "\(entry.skillScore)", label: "SCORE", icon: "chart.line.uptrend.xyaxis")
                statBox(value: "\(entry.drillsCompleted)", label: "DRILLS", icon: "figure.soccer")
            }
        }
        .containerBackground(bgColor, for: .widget)
    }

    private var motivationalText: String {
        if entry.streakCount == 0 {
            return "Start your streak today, \(entry.playerName)!"
        } else if entry.streakCount >= 30 {
            return "\(entry.playerName) — unstoppable!"
        } else if entry.streakCount >= 7 {
            return "On fire, \(entry.playerName)! Keep pushing."
        } else {
            return "Nice work, \(entry.playerName)! Don't stop."
        }
    }

    private var largeWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("KICKIQ")
                    .font(.system(size: 10, weight: .bold, design: .default).width(.compressed))
                    .tracking(2)
                    .foregroundStyle(accentColor)
                Spacer()
                Text(entry.playerLevel.uppercased())
                    .font(.system(size: 9, weight: .black))
                    .tracking(1)
                    .foregroundStyle(accentColor.opacity(0.7))
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(entry.streakCount > 0 ? accentColor : .gray.opacity(0.4))
                        Text("\(entry.streakCount)")
                            .font(.system(size: 36, weight: .black))
                            .foregroundStyle(.white)
                    }
                    Text("day streak")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                skillScoreRing
            }

            Divider()
                .background(.white.opacity(0.1))

            HStack(spacing: 0) {
                largeStatItem(icon: "star.fill", value: "\(entry.xpPoints)", label: "XP")
                largeStatItem(icon: "figure.soccer", value: "\(entry.drillsCompleted)", label: "Drills")
                largeStatItem(icon: "chart.line.uptrend.xyaxis", value: "\(entry.skillScore)", label: "Score")
            }

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(accentColor)
                Text(motivationalText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
            }
        }
        .containerBackground(bgColor, for: .widget)
    }

    private var skillScoreRing: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.08), lineWidth: 6)
                .frame(width: 64, height: 64)

            Circle()
                .trim(from: 0, to: Double(entry.skillScore) / 100.0)
                .stroke(accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: 64, height: 64)
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Text("\(entry.skillScore)")
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(.white)
                Text("/100")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }

    private func statBox(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(accentColor)
            Text(value)
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(cardColor, in: .rect(cornerRadius: 10))
    }

    private func largeStatItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(accentColor)
            Text(value)
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }
}

struct KickIQWidget: Widget {
    let kind: String = "KickIQWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: KickIQProvider()) { entry in
            KickIQWidgetView(entry: entry)
        }
        .configurationDisplayName("KickIQ Stats")
        .description("See your training streak, skill score, and XP at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .containerBackgroundRemovable(false)
    }
}
