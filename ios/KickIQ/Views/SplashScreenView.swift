import SwiftUI

struct SplashScreenView: View {
    @State private var phase: SplashPhase = .initial
    @State private var ballY: CGFloat = -600
    @State private var ballRotation: Double = 0
    @State private var ballScale: Double = 0.3
    @State private var impactScale: Double = 0
    @State private var ringScale: Double = 0
    @State private var ringOpacity: Double = 0
    @State private var ring2Scale: Double = 0
    @State private var ring2Opacity: Double = 0
    @State private var logoOpacity: Double = 0
    @State private var logoOffset: CGFloat = 30
    @State private var taglineOpacity: Double = 0
    @State private var taglineOffset: CGFloat = 20
    @State private var meshPhase: Double = 0
    @State private var streakLineWidths: [CGFloat] = Array(repeating: 0, count: 6)
    @State private var particleOffsets: [CGSize] = (0..<12).map { _ in .zero }
    @State private var particleOpacities: [Double] = Array(repeating: 0, count: 12)
    @State private var glowPulse: Bool = false

    private enum SplashPhase {
        case initial, ballDrop, impact, reveal, complete
    }

    var body: some View {
        ZStack {
            backgroundLayer

            streakLines

            particleLayer

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(KickIQTheme.accent.opacity(0.2))
                        .frame(width: 200, height: 200)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)
                        .blur(radius: 8)

                    Circle()
                        .stroke(KickIQTheme.accent.opacity(0.3), lineWidth: 2)
                        .frame(width: 160, height: 160)
                        .scaleEffect(ring2Scale)
                        .opacity(ring2Opacity)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [KickIQTheme.accent.opacity(0.4), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(impactScale)
                        .opacity(impactScale > 0 ? 0.6 : 0)

                    Image(systemName: "soccerball")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [KickIQTheme.accent, KickIQTheme.accent.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(ballRotation))
                        .scaleEffect(ballScale)
                        .offset(y: ballY)
                        .shadow(color: KickIQTheme.accent.opacity(0.5), radius: glowPulse ? 30 : 15, y: 4)
                }
                .frame(height: 200)

                Spacer().frame(height: 40)

                VStack(spacing: 12) {
                    Text("KickIQ")
                        .font(.system(size: 48, weight: .black, design: .default))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [KickIQTheme.textPrimary, KickIQTheme.textPrimary.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .opacity(logoOpacity)
                        .offset(y: logoOffset)

                    Text("TRAIN SMARTER. PLAY HARDER.")
                        .font(.system(size: 12, weight: .heavy, design: .default))
                        .tracking(4)
                        .foregroundStyle(KickIQTheme.accent.opacity(0.9))
                        .opacity(taglineOpacity)
                        .offset(y: taglineOffset)
                }

                Spacer()

                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Capsule()
                            .fill(KickIQTheme.accent.opacity(0.5 + Double(i) * 0.15))
                            .frame(width: i == 1 ? 24 : 8, height: 4)
                            .opacity(taglineOpacity)
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            runSequence()
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            KickIQTheme.background

            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    .init(0, 0), .init(0.5, 0), .init(1, 0),
                    .init(0, 0.5), .init(Float(0.5 + sin(meshPhase) * 0.1), Float(0.5 + cos(meshPhase) * 0.1)), .init(1, 0.5),
                    .init(0, 1), .init(0.5, 1), .init(1, 1)
                ],
                colors: [
                    .clear, KickIQTheme.accent.opacity(0.03), .clear,
                    KickIQTheme.accent.opacity(0.02), KickIQTheme.accent.opacity(0.08), KickIQTheme.accent.opacity(0.02),
                    .clear, KickIQTheme.accent.opacity(0.04), .clear
                ]
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    meshPhase = .pi * 2
                }
            }
        }
    }

    private var streakLines: some View {
        Canvas { context, size in
            let centerX = size.width / 2
            let centerY = size.height * 0.38
            let angles: [Double] = [-70, -40, -10, 10, 40, 70]

            for (i, angle) in angles.enumerated() {
                let length = streakLineWidths[i]
                guard length > 0 else { continue }
                let radians = angle * .pi / 180
                let startRadius: CGFloat = 90
                let endRadius = startRadius + length

                let startX = centerX + cos(radians) * startRadius
                let startY = centerY + sin(radians) * startRadius
                let endX = centerX + cos(radians) * endRadius
                let endY = centerY + sin(radians) * endRadius

                var path = Path()
                path.move(to: CGPoint(x: startX, y: startY))
                path.addLine(to: CGPoint(x: endX, y: endY))

                context.stroke(
                    path,
                    with: .linearGradient(
                        Gradient(colors: [KickIQTheme.accent.opacity(0.5), KickIQTheme.accent.opacity(0)]),
                        startPoint: CGPoint(x: startX, y: startY),
                        endPoint: CGPoint(x: endX, y: endY)
                    ),
                    lineWidth: 2
                )
            }
        }
        .allowsHitTesting(false)
    }

    private var particleLayer: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { i in
                Circle()
                    .fill(KickIQTheme.accent)
                    .frame(width: CGFloat.random(in: 2...5), height: CGFloat.random(in: 2...5))
                    .offset(particleOffsets[i])
                    .opacity(particleOpacities[i])
            }
        }
        .allowsHitTesting(false)
    }

    private func runSequence() {
        withAnimation(.easeIn(duration: 0.5)) {
            ballY = 0
            ballRotation = 540
            ballScale = 1.1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                ballScale = 1.0
                impactScale = 1.5
            }

            withAnimation(.easeOut(duration: 0.5)) {
                ringScale = 2.0
                ringOpacity = 0.6
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.05)) {
                ring2Scale = 1.8
                ring2Opacity = 0.4
            }

            for i in 0..<6 {
                withAnimation(.easeOut(duration: 0.4).delay(Double(i) * 0.03)) {
                    streakLineWidths[i] = CGFloat.random(in: 40...80)
                }
            }

            for i in 0..<12 {
                let angle = Double(i) * (360.0 / 12.0) * .pi / 180
                let distance = CGFloat.random(in: 60...140)
                withAnimation(.easeOut(duration: 0.6).delay(Double.random(in: 0...0.1))) {
                    particleOffsets[i] = CGSize(
                        width: cos(angle) * distance,
                        height: sin(angle) * distance - 100
                    )
                    particleOpacities[i] = 0.7
                }
                withAnimation(.easeIn(duration: 0.3).delay(0.5)) {
                    particleOpacities[i] = 0
                }
            }

            withAnimation(.easeOut(duration: 0.6).delay(0.15)) {
                ringOpacity = 0
                ring2Opacity = 0
                impactScale = 0
            }

            for i in 0..<6 {
                withAnimation(.easeOut(duration: 0.3).delay(0.3 + Double(i) * 0.02)) {
                    streakLineWidths[i] = 0
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                logoOpacity = 1.0
                logoOffset = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                taglineOpacity = 1.0
                taglineOffset = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }
}
