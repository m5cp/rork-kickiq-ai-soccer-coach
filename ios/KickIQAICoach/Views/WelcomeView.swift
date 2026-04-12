import SwiftUI

struct WelcomeView: View {
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.5
    @State private var ringOpacity: Double = 0
    @State private var particlesVisible: Bool = false

    var body: some View {
        ZStack {
            Color(hex: 0x070B14)
                .ignoresSafeArea()

            welcomeBackground

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(KickIQAICoachTheme.accent.opacity(0.08))
                        .frame(width: 220, height: 220)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)

                    Circle()
                        .stroke(KickIQAICoachTheme.accent.opacity(0.15), lineWidth: 1.5)
                        .frame(width: 180, height: 180)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [KickIQAICoachTheme.accent.opacity(0.3), KickIQAICoachTheme.accent.opacity(0.05), .clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .opacity(glowOpacity)

                    Image(systemName: "soccerball")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundStyle(KickIQAICoachTheme.accent)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                        .shadow(color: KickIQAICoachTheme.accent.opacity(0.5), radius: 20, x: 0, y: 0)
                }

                Spacer()
                    .frame(height: 48)

                VStack(spacing: 12) {
                    Text("KICKIQ")
                        .font(.system(size: 42, weight: .black, design: .default).width(.compressed))
                        .tracking(6)
                        .foregroundStyle(.white)
                        .offset(y: titleOffset)
                        .opacity(titleOpacity)

                    Text("YOUR AI SOCCER COACH")
                        .font(.system(size: 14, weight: .heavy))
                        .tracking(4)
                        .foregroundStyle(KickIQAICoachTheme.accent)
                        .opacity(subtitleOpacity)
                }

                Spacer()

                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Circle().fill(KickIQAICoachTheme.accent).frame(width: 4, height: 4)
                        Circle().fill(KickIQAICoachTheme.accent.opacity(0.5)).frame(width: 4, height: 4)
                        Circle().fill(KickIQAICoachTheme.accent.opacity(0.3)).frame(width: 4, height: 4)
                    }
                    .opacity(subtitleOpacity)
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear { startAnimations() }
    }

    private var welcomeBackground: some View {
        ZStack {
            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [0.5, 0.5], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1]
                ],
                colors: [
                    Color(hex: 0x070B14), Color(hex: 0x0A1628), Color(hex: 0x070B14),
                    Color(hex: 0x0D1B2A), Color(hex: 0x13294B).opacity(0.4), Color(hex: 0x0D1B2A),
                    Color(hex: 0x070B14), Color(hex: 0x0A1628), Color(hex: 0x070B14)
                ]
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [KickIQAICoachTheme.accent.opacity(0.06), .clear],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
        }
    }

    private func startAnimations() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }

        withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.15)) {
            ringScale = 1.0
            ringOpacity = 1.0
        }

        withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
            glowOpacity = 1.0
        }

        withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.5)) {
            titleOffset = 0
            titleOpacity = 1.0
        }

        withAnimation(.easeOut(duration: 0.8).delay(0.8)) {
            subtitleOpacity = 1.0
        }
    }
}
