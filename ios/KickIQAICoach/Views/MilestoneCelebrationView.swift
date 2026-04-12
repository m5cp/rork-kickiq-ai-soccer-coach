import SwiftUI

struct MilestoneCelebrationView: View {
    let badge: MilestoneBadge
    let onDismiss: () -> Void
    @State private var appeared = false
    @State private var iconBounce = false
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    let playerName: String
    let position: PlayerPosition
    let streakCount: Int
    let skillScore: Int

    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: KickIQAICoachTheme.Spacing.lg) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(KickIQAICoachTheme.accent.opacity(0.15))
                        .frame(width: 120, height: 120)
                        .scaleEffect(appeared ? 1.2 : 0.5)
                        .opacity(appeared ? 0.6 : 0)

                    Circle()
                        .fill(KickIQAICoachTheme.accent.opacity(0.08))
                        .frame(width: 160, height: 160)
                        .scaleEffect(appeared ? 1.3 : 0.3)
                        .opacity(appeared ? 0.4 : 0)

                    Image(systemName: badge.icon)
                        .font(.system(size: 56))
                        .foregroundStyle(KickIQAICoachTheme.accent)
                        .scaleEffect(appeared ? 1 : 0.1)
                        .symbolEffect(.bounce, value: iconBounce)
                }

                VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                    Text("MILESTONE UNLOCKED")
                        .font(.caption.weight(.black))
                        .tracking(3)
                        .foregroundStyle(KickIQAICoachTheme.accent)
                        .opacity(appeared ? 1 : 0)

                    Text(badge.rawValue)
                        .font(.system(.title, design: .default, weight: .black))
                        .foregroundStyle(.white)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)

                    Text(badge.requirement)
                        .font(.subheadline)
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                        .opacity(appeared ? 1 : 0)
                }

                HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                    Button {
                        generateShareCard()
                    } label: {
                        HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KickIQAICoachTheme.accent)
                        .padding(.horizontal, KickIQAICoachTheme.Spacing.lg)
                        .padding(.vertical, 14)
                        .background(KickIQAICoachTheme.accent.opacity(0.15), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.md)
                                .stroke(KickIQAICoachTheme.accent.opacity(0.3), lineWidth: 1)
                        )
                    }

                    Button {
                        onDismiss()
                    } label: {
                        Text("Continue")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KickIQAICoachTheme.onAccent)
                            .padding(.horizontal, KickIQAICoachTheme.Spacing.lg)
                            .padding(.vertical, 14)
                            .background(KickIQAICoachTheme.accent, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                Spacer()
                Spacer()
            }
            .padding(.horizontal, KickIQAICoachTheme.Spacing.lg)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                appeared = true
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(400))
                iconBounce.toggle()
            }
        }
        .sensoryFeedback(.success, trigger: appeared)
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheetView(image: image)
            }
        }
    }

    @MainActor
    private func generateShareCard() {
        if let image = ShareCardGenerator.generateImage(
            type: .milestone(badge),
            playerName: playerName,
            position: position,
            streakCount: streakCount,
            skillScore: skillScore
        ) {
            shareImage = image
            showShareSheet = true
        }
    }
}
