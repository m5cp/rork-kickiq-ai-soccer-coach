import SwiftUI

struct CoachTip: Identifiable {
    let id: String
    let icon: String
    let title: String
    let message: String
    let accentColor: Color
}

struct CoachTipsOverlay: View {
    let tips: [CoachTip]
    let onDismiss: () -> Void
    @State private var currentIndex: Int = 0
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .onTapGesture { advance() }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: KickIQTheme.Spacing.lg) {
                    tipIndicator

                    if currentIndex < tips.count {
                        let tip = tips[currentIndex]
                        tipContent(tip)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                            .id(tip.id)
                    }

                    actionButtons
                }
                .padding(KickIQTheme.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(KickIQTheme.accent.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .padding(.bottom, KickIQTheme.Spacing.xl)
                .scaleEffect(appeared ? 1 : 0.9)
                .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    private var tipIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<tips.count, id: \.self) { idx in
                Capsule()
                    .fill(idx == currentIndex ? KickIQTheme.accent : KickIQTheme.textSecondary.opacity(0.2))
                    .frame(width: idx == currentIndex ? 24 : 8, height: 4)
                    .animation(.spring(response: 0.3), value: currentIndex)
            }
        }
    }

    private func tipContent(_ tip: CoachTip) -> some View {
        VStack(spacing: KickIQTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(tip.accentColor.opacity(0.15))
                    .frame(width: 64, height: 64)
                Image(systemName: tip.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(tip.accentColor)
                    .symbolEffect(.bounce, value: currentIndex)
            }

            VStack(spacing: KickIQTheme.Spacing.sm) {
                Text(tip.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(KickIQTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(tip.message)
                    .font(.subheadline)
                    .foregroundStyle(KickIQTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: KickIQTheme.Spacing.md) {
            Button {
                onDismiss()
            } label: {
                Text("Skip")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(KickIQTheme.textSecondary)
            }

            Spacer()

            Button {
                advance()
            } label: {
                HStack(spacing: 6) {
                    Text(currentIndex < tips.count - 1 ? "Next" : "Got It")
                        .font(.subheadline.weight(.bold))
                    if currentIndex < tips.count - 1 {
                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.bold))
                    }
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(KickIQTheme.accent, in: Capsule())
            }
            .sensoryFeedback(.impact(weight: .light), trigger: currentIndex)
        }
    }

    private func advance() {
        if currentIndex < tips.count - 1 {
            withAnimation(.spring(response: 0.4)) {
                currentIndex += 1
            }
        } else {
            withAnimation(.easeOut(duration: 0.3)) {
                appeared = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onDismiss()
            }
        }
    }
}

enum CoachTipsData {
    static let teamFeatureTips: [CoachTip] = [
        CoachTip(
            id: "team_create",
            icon: "person.3.fill",
            title: "Create or Join a Team",
            message: "Tap the + button to create a team as a coach, or join one with a code from your coach. Teams let you train together.",
            accentColor: KickIQTheme.accent
        ),
        CoachTip(
            id: "team_assign",
            icon: "clipboard.fill",
            title: "Assign Drills",
            message: "Coaches can assign specific drills to individual players or the whole team. Players see assigned drills in the team view.",
            accentColor: .blue
        ),
        CoachTip(
            id: "team_challenges",
            icon: "trophy.fill",
            title: "Team Challenges",
            message: "Create challenges for your team! Set a drill, a target score, and see who rises to the top of the leaderboard.",
            accentColor: .orange
        ),
        CoachTip(
            id: "team_plans",
            icon: "doc.text.fill",
            title: "Training Plans",
            message: "Coaches can now upload custom training plans with drills, coaching cues, and focus areas for the whole team to follow.",
            accentColor: .purple
        ),
        CoachTip(
            id: "team_feed",
            icon: "bubble.left.fill",
            title: "Activity Feed",
            message: "See what's happening — drill completions, new challenges, and player achievements all show up in the team feed.",
            accentColor: .green
        )
    ]
}
