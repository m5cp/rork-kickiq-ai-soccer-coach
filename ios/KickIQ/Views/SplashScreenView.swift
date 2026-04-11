import SwiftUI

struct SplashScreenView: View {
    @State private var ballOffset: CGFloat = -UIScreen.main.bounds.width
    @State private var ballRotation: Double = 0
    @State private var ballScale: Double = 0.6
    @State private var logoOpacity: Double = 0
    @State private var logoScale: Double = 0.8
    @State private var taglineOpacity: Double = 0
    @State private var taglineOffset: CGFloat = 20
    @State private var particlesVisible: Bool = false
    @State private var glowOpacity: Double = 0

    var body: some View {
        ZStack {
            KickIQTheme.background
                .ignoresSafeArea()

            backgroundGlow

            particleField

            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(KickIQTheme.accent.opacity(glowOpacity * 0.15))
                        .frame(width: 160, height: 160)
                        .blur(radius: 40)

                    Image(systemName: "soccerball")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundStyle(KickIQTheme.accentGradient)
                        .rotationEffect(.degrees(ballRotation))
                        .scaleEffect(ballScale)
                        .offset(x: ballOffset)
                        .shadow(color: KickIQTheme.accent.opacity(0.4), radius: 20, y: 8)
                }

                VStack(spacing: 10) {
                    Text("KickIQ")
                        .font(.system(size: 42, weight: .black, design: .default))
                        .foregroundStyle(KickIQTheme.textPrimary)
                        .opacity(logoOpacity)
                        .scaleEffect(logoScale)

                    Text("TRAIN SMARTER. PLAY HARDER.")
                        .font(.system(size: 13, weight: .bold, design: .default))
                        .tracking(3)
                        .foregroundStyle(KickIQTheme.accent)
                        .opacity(taglineOpacity)
                        .offset(y: taglineOffset)
                }

                Spacer()

                HStack(spacing: 6) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(KickIQTheme.accent)
                            .frame(width: 6, height: 6)
                            .opacity(taglineOpacity)
                            .scaleEffect(taglineOpacity)
                            .animation(.spring(response: 0.4).delay(1.4 + Double(i) * 0.1), value: taglineOpacity)
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            runAnimation()
        }
    }

    private var backgroundGlow: some View {
        ZStack {
            RadialGradient(
                colors: [KickIQTheme.accent.opacity(0.08), .clear],
                center: .center,
                startRadius: 20,
                endRadius: 300
            )
            .opacity(glowOpacity)
            .ignoresSafeArea()

            Circle()
                .fill(KickIQTheme.accent.opacity(0.05))
                .frame(width: 500, height: 500)
                .blur(radius: 80)
                .offset(y: -100)
                .opacity(glowOpacity)
        }
    }

    private var particleField: some View {
        Canvas { context, size in
            guard particlesVisible else { return }
            let particleCount = 12
            for i in 0..<particleCount {
                let fraction = Double(i) / Double(particleCount)
                let x = size.width * (0.1 + fraction * 0.8)
                let y = size.height * (0.2 + sin(fraction * .pi * 3) * 0.3)
                let diameter: CGFloat = CGFloat(3 + sin(fraction * .pi * 2) * 2)
                let rect = CGRect(x: x - diameter / 2, y: y - diameter / 2, width: diameter, height: diameter)
                context.opacity = 0.15 + sin(fraction * .pi) * 0.15
                context.fill(Path(ellipseIn: rect), with: .color(KickIQTheme.accent))
            }
        }
        .ignoresSafeArea()
        .opacity(particlesVisible ? 1 : 0)
        .animation(.easeIn(duration: 0.8).delay(0.6), value: particlesVisible)
    }

    private func runAnimation() {
        withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.1)) {
            ballOffset = 0
            ballRotation = 720
            ballScale = 1.0
        }

        withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
            glowOpacity = 1.0
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.6)) {
            logoOpacity = 1.0
            logoScale = 1.0
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.9)) {
            taglineOpacity = 1.0
            taglineOffset = 0
        }

        particlesVisible = true
    }
}
