import SwiftUI

enum ShareCardType {
    case analysis(TrainingSession)
    case progress(score: Int, improvement: Int, weeks: Int)
    case milestone(MilestoneBadge)
    case streak(Int)
}

@MainActor
struct ShareCardGenerator {
    static func generateImage(
        type: ShareCardType,
        playerName: String,
        position: PlayerPosition,
        streakCount: Int,
        skillScore: Int
    ) -> UIImage? {
        let content: AnyView
        switch type {
        case .analysis(let session):
            content = AnyView(AnalysisShareCard(session: session, playerName: playerName))
        case .progress(let score, let improvement, let weeks):
            content = AnyView(ProgressShareCardPremium(playerName: playerName, position: position, score: score, improvement: improvement, weeks: weeks, streak: streakCount))
        case .milestone(let badge):
            content = AnyView(MilestoneShareCard(badge: badge, playerName: playerName, position: position, streak: streakCount, score: skillScore))
        case .streak(let days):
            content = AnyView(StreakShareCard(playerName: playerName, position: position, days: days, score: skillScore))
        }

        let renderer = ImageRenderer(content: content)
        renderer.scale = 3
        return renderer.uiImage
    }
}

// MARK: - Analysis Share Card

struct AnalysisShareCard: View {
    let session: TrainingSession
    let playerName: String

    private var bestSkill: SkillScore? {
        session.skillScores.max(by: { $0.score < $1.score })
    }

    private var worstSkill: SkillScore? {
        session.skillScores.min(by: { $0.score < $1.score })
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("KICKIQ")
                            .font(.system(size: 11, weight: .black, design: .default).width(.compressed))
                            .tracking(4)
                            .foregroundStyle(Color(hex: 0xFF6D00))
                        Text("SESSION REPORT")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    Spacer()
                    Text(session.date, format: .dateTime.month(.abbreviated).day().year())
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.35))
                }

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(playerName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)

                        athleteBadge
                    }

                    Spacer()

                    VStack(spacing: 0) {
                        Text("\(session.overallScore)")
                            .font(.system(size: 52, weight: .black))
                            .foregroundStyle(.white)
                        Text("/ 100")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }

                Rectangle()
                    .fill(LinearGradient(colors: [Color(hex: 0xFF6D00), Color(hex: 0xFF6D00).opacity(0)], startPoint: .leading, endPoint: .trailing))
                    .frame(height: 1.5)

                VStack(spacing: 7) {
                    ForEach(session.skillScores) { score in
                        HStack(spacing: 8) {
                            Image(systemName: score.category.icon)
                                .font(.system(size: 9))
                                .foregroundStyle(Color(hex: 0xFF6D00))
                                .frame(width: 14)

                            Text(score.category.rawValue)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))
                                .frame(width: 85, alignment: .leading)

                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color(white: 0.2))
                                    .frame(height: 5)

                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: 0xFF6D00).opacity(0.6), Color(hex: 0xFF6D00)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: 100 * score.percentage, height: 5)
                            }
                            .frame(width: 100)

                            Text("\(score.score)")
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(.white)
                                .frame(width: 18, alignment: .trailing)
                        }
                    }
                }

                if let top = worstSkill {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9, weight: .bold))
                        Text("Focus area: \(top.category.rawValue)")
                            .font(.system(size: 11, weight: .bold))
                        if !top.tip.isEmpty {
                            Text("— \(top.tip)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color(hex: 0xFF6D00).opacity(0.7))
                                .lineLimit(1)
                        }
                    }
                    .foregroundStyle(Color(hex: 0xFF6D00))
                }
            }
            .padding(20)
            .background(Color(hex: 0x0A0A0A))

            HStack {
                HStack(spacing: 4) {
                    Image(systemName: session.position.icon)
                        .font(.system(size: 9))
                    Text(session.position.rawValue.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1)
                }
                .foregroundStyle(.black.opacity(0.7))

                Spacer()

                Text("kickiq.app")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.black.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color(hex: 0xFF6D00))
        }
        .frame(width: 320)
        .clipShape(.rect(cornerRadius: 16))
    }

    private var athleteBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 8))
            Text("KICKIQ ATHLETE")
                .font(.system(size: 9, weight: .black))
                .tracking(1.5)
        }
        .foregroundStyle(Color(hex: 0xFF6D00))
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color(hex: 0xFF6D00).opacity(0.15), in: Capsule())
    }
}

// MARK: - Progress Share Card

struct ProgressShareCardPremium: View {
    let playerName: String
    let position: PlayerPosition
    let score: Int
    let improvement: Int
    let weeks: Int
    let streak: Int

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("KICKIQ")
                            .font(.system(size: 11, weight: .black, design: .default).width(.compressed))
                            .tracking(4)
                            .foregroundStyle(Color(hex: 0xFF6D00))
                        Text("PROGRESS REPORT")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    Spacer()
                }

                HStack(alignment: .bottom, spacing: 0) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(playerName)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)

                        athleteBadge
                    }
                    Spacer()
                }

                HStack(spacing: 20) {
                    statBlock(value: "\(score)", label: "SKILL SCORE", large: true)

                    if improvement > 0 {
                        statBlock(value: "+\(improvement)", label: "POINTS GAINED", accent: true)
                    }

                    if streak > 0 {
                        statBlock(value: "\(streak)", label: "DAY STREAK", icon: "flame.fill")
                    }
                }

                if improvement > 0 {
                    Rectangle()
                        .fill(Color(white: 0.15))
                        .frame(height: 1)

                    Text("I've improved \(improvement) points in \(weeks) week\(weeks == 1 ? "" : "s") with KickIQ")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(20)
            .background(Color(hex: 0x0A0A0A))

            HStack {
                HStack(spacing: 4) {
                    Image(systemName: position.icon)
                        .font(.system(size: 9))
                    Text(position.rawValue.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1)
                }
                .foregroundStyle(.black.opacity(0.7))

                Spacer()

                Text("kickiq.app")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.black.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color(hex: 0xFF6D00))
        }
        .frame(width: 320)
        .clipShape(.rect(cornerRadius: 16))
    }

    private func statBlock(value: String, label: String, large: Bool = false, accent: Bool = false, icon: String? = nil) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 3) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: large ? 16 : 12))
                        .foregroundStyle(Color(hex: 0xFF6D00))
                }
                Text(value)
                    .font(.system(size: large ? 36 : 24, weight: .black))
                    .foregroundStyle(accent ? Color(hex: 0xFF6D00) : .white)
            }
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
    }

    private var athleteBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 8))
            Text("KICKIQ ATHLETE")
                .font(.system(size: 9, weight: .black))
                .tracking(1.5)
        }
        .foregroundStyle(Color(hex: 0xFF6D00))
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color(hex: 0xFF6D00).opacity(0.15), in: Capsule())
    }
}

// MARK: - Milestone Share Card

struct MilestoneShareCard: View {
    let badge: MilestoneBadge
    let playerName: String
    let position: PlayerPosition
    let streak: Int
    let score: Int

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                Text("KICKIQ")
                    .font(.system(size: 11, weight: .black, design: .default).width(.compressed))
                    .tracking(4)
                    .foregroundStyle(Color(hex: 0xFF6D00))
                    .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    Circle()
                        .fill(Color(hex: 0xFF6D00).opacity(0.1))
                        .frame(width: 90, height: 90)

                    Circle()
                        .fill(Color(hex: 0xFF6D00).opacity(0.05))
                        .frame(width: 120, height: 120)

                    Image(systemName: badge.icon)
                        .font(.system(size: 40))
                        .foregroundStyle(Color(hex: 0xFF6D00))
                }

                VStack(spacing: 4) {
                    Text("MILESTONE UNLOCKED")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.35))

                    Text(badge.rawValue)
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(.white)
                }

                HStack(spacing: 6) {
                    Text(playerName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))

                    Text("·")
                        .foregroundStyle(.white.opacity(0.2))

                    athleteBadge
                }

                HStack(spacing: 24) {
                    VStack(spacing: 2) {
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: 0xFF6D00))
                            Text("\(streak)")
                                .font(.system(size: 20, weight: .black))
                                .foregroundStyle(.white)
                        }
                        Text("STREAK")
                            .font(.system(size: 8, weight: .bold))
                            .tracking(1)
                            .foregroundStyle(.white.opacity(0.3))
                    }

                    Rectangle()
                        .fill(Color(white: 0.2))
                        .frame(width: 1, height: 30)

                    VStack(spacing: 2) {
                        Text("\(score)")
                            .font(.system(size: 20, weight: .black))
                            .foregroundStyle(.white)
                        Text("SKILL SCORE")
                            .font(.system(size: 8, weight: .bold))
                            .tracking(1)
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
            }
            .padding(20)
            .background(Color(hex: 0x0A0A0A))

            HStack {
                HStack(spacing: 4) {
                    Image(systemName: position.icon)
                        .font(.system(size: 9))
                    Text(position.rawValue.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1)
                }
                .foregroundStyle(.black.opacity(0.7))

                Spacer()

                Text("kickiq.app")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.black.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color(hex: 0xFF6D00))
        }
        .frame(width: 300)
        .clipShape(.rect(cornerRadius: 16))
    }

    private var athleteBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 8))
            Text("KICKIQ ATHLETE")
                .font(.system(size: 9, weight: .black))
                .tracking(1.5)
        }
        .foregroundStyle(Color(hex: 0xFF6D00))
    }
}

// MARK: - Streak Share Card

struct StreakShareCard: View {
    let playerName: String
    let position: PlayerPosition
    let days: Int
    let score: Int

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                Text("KICKIQ")
                    .font(.system(size: 11, weight: .black, design: .default).width(.compressed))
                    .tracking(4)
                    .foregroundStyle(Color(hex: 0xFF6D00))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "flame.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: 0xFF6D00), Color(hex: 0xE65100)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                VStack(spacing: 2) {
                    Text("\(days)")
                        .font(.system(size: 56, weight: .black))
                        .foregroundStyle(.white)
                    Text("DAY STREAK")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(3)
                        .foregroundStyle(.white.opacity(0.35))
                }

                HStack(spacing: 6) {
                    Text(playerName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))

                    Text("·")
                        .foregroundStyle(.white.opacity(0.2))

                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 8))
                        Text("KICKIQ ATHLETE")
                            .font(.system(size: 9, weight: .black))
                            .tracking(1.5)
                    }
                    .foregroundStyle(Color(hex: 0xFF6D00))
                }

                VStack(spacing: 2) {
                    Text("\(score)")
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(Color(hex: 0xFF6D00))
                    Text("SKILL SCORE")
                        .font(.system(size: 8, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
            .padding(20)
            .background(Color(hex: 0x0A0A0A))

            HStack {
                HStack(spacing: 4) {
                    Image(systemName: position.icon)
                        .font(.system(size: 9))
                    Text(position.rawValue.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1)
                }
                .foregroundStyle(.black.opacity(0.7))

                Spacer()

                Text("kickiq.app")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.black.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color(hex: 0xFF6D00))
        }
        .frame(width: 280)
        .clipShape(.rect(cornerRadius: 16))
    }
}
