import SwiftUI

struct SplashScreenView: View {
    @State private var ballY: CGFloat = -500
    @State private var ballRotation: Double = 0
    @State private var ballScale: Double = 0.2
    @State private var ballGlow: Bool = false
    @State private var impactFlash: Double = 0
    @State private var shockwaveScale: Double = 0
    @State private var shockwaveOpacity: Double = 0
    @State private var shockwave2Scale: Double = 0
    @State private var shockwave2Opacity: Double = 0
    @State private var shockwave3Scale: Double = 0
    @State private var shockwave3Opacity: Double = 0
    @State private var logoOpacity: Double = 0
    @State private var logoScale: Double = 0.6
    @State private var taglineOpacity: Double = 0
    @State private var taglineOffset: CGFloat = 25
    @State private var meshPhase: Double = 0
    @State private var meshIntensity: Double = 0
    @State private var particleSystem: [SplashParticle] = []
    @State private var streakTrails: [StreakTrail] = []
    @State private var orbitalRingRotation: Double = 0
    @State private var orbitalRingOpacity: Double = 0
    @State private var bottomIndicatorOpacity: Double = 0
    @State private var energyPulse: Bool = false
    @State private var letterReveal: [Bool] = Array(repeating: false, count: 6)
    @State private var hexGridOpacity: Double = 0

    var body: some View {
        ZStack {
            backgroundLayer

            hexPatternLayer

            streakTrailLayer

            particleSystemLayer

            orbitalRings

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [KickIQTheme.accent.opacity(0.35), KickIQTheme.accent.opacity(0.05), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 130
                            )
                        )
                        .frame(width: 260, height: 260)
                        .scaleEffect(shockwaveScale)
                        .opacity(shockwaveOpacity)

                    Circle()
                        .stroke(KickIQTheme.accent.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 180, height: 180)
                        .scaleEffect(shockwave2Scale)
                        .opacity(shockwave2Opacity)

                    Circle()
                        .stroke(KickIQTheme.accent.opacity(0.2), lineWidth: 1)
                        .frame(width: 220, height: 220)
                        .scaleEffect(shockwave3Scale)
                        .opacity(shockwave3Opacity)

                    Circle()
                        .fill(KickIQTheme.accent.opacity(impactFlash))
                        .frame(width: 300, height: 300)
                        .blur(radius: 60)

                    ZStack {
                        Image(systemName: "soccerball")
                            .font(.system(size: 85, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, KickIQTheme.accent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .blur(radius: ballGlow ? 12 : 0)
                            .opacity(0.5)

                        Image(systemName: "soccerball")
                            .font(.system(size: 85, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white.opacity(0.95), KickIQTheme.accent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .rotationEffect(.degrees(ballRotation))
                    .scaleEffect(ballScale)
                    .offset(y: ballY)
                    .shadow(color: KickIQTheme.accent.opacity(energyPulse ? 0.7 : 0.3), radius: energyPulse ? 40 : 20, y: 0)
                }
                .frame(height: 220)

                Spacer().frame(height: 36)

                VStack(spacing: 14) {
                    HStack(spacing: 2) {
                        ForEach(Array("KICKIQ".enumerated()), id: \.offset) { index, char in
                            Text(String(char))
                                .font(.system(size: 52, weight: .black, design: .default))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, KickIQTheme.accent.opacity(0.8)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .opacity(letterReveal[index] ? 1 : 0)
                                .scaleEffect(letterReveal[index] ? 1 : 0.3)
                                .offset(y: letterReveal[index] ? 0 : 20)
                        }
                    }
                    .opacity(logoOpacity)
                    .scaleEffect(logoScale)

                    Text("TRAIN SMARTER. PLAY HARDER.")
                        .font(.system(size: 11, weight: .heavy, design: .default))
                        .tracking(5)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [KickIQTheme.accent, KickIQTheme.accent.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(taglineOpacity)
                        .offset(y: taglineOffset)
                }

                Spacer()

                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { i in
                        Capsule()
                            .fill(KickIQTheme.accent)
                            .frame(width: i == 1 ? 28 : 6, height: 3)
                            .opacity(0.4 + Double(i) * 0.2)
                    }
                }
                .opacity(bottomIndicatorOpacity)
                .padding(.bottom, 50)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            runSequence()
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            Color.black

            MeshGradient(
                width: 4,
                height: 4,
                points: [
                    .init(0, 0), .init(0.33, 0), .init(0.67, 0), .init(1, 0),
                    .init(0, 0.33),
                    .init(Float(0.33 + sin(meshPhase) * 0.05), Float(0.33 + cos(meshPhase * 1.3) * 0.05)),
                    .init(Float(0.67 + cos(meshPhase * 0.8) * 0.04), Float(0.33 + sin(meshPhase * 1.1) * 0.04)),
                    .init(1, 0.33),
                    .init(0, 0.67),
                    .init(Float(0.33 + cos(meshPhase * 1.2) * 0.06), Float(0.67 + sin(meshPhase * 0.9) * 0.05)),
                    .init(Float(0.67 + sin(meshPhase * 1.1) * 0.05), Float(0.67 + cos(meshPhase * 1.4) * 0.06)),
                    .init(1, 0.67),
                    .init(0, 1), .init(0.33, 1), .init(0.67, 1), .init(1, 1)
                ],
                colors: [
                    .clear, .clear, .clear, .clear,
                    .clear,
                    KickIQTheme.accent.opacity(0.04 * meshIntensity),
                    KickIQTheme.accent.opacity(0.02 * meshIntensity),
                    .clear,
                    .clear,
                    KickIQTheme.accent.opacity(0.06 * meshIntensity),
                    KickIQTheme.accent.opacity(0.1 * meshIntensity),
                    .clear,
                    .clear, KickIQTheme.accent.opacity(0.03 * meshIntensity), .clear, .clear
                ]
            )
        }
    }

    // MARK: - Hex Pattern

    private var hexPatternLayer: some View {
        Canvas { context, size in
            let spacing: CGFloat = 40
            let rows = Int(size.height / spacing) + 1
            let cols = Int(size.width / spacing) + 1

            for row in 0..<rows {
                for col in 0..<cols {
                    let xOff: CGFloat = row.isMultiple(of: 2) ? spacing / 2 : 0
                    let x = CGFloat(col) * spacing + xOff
                    let y = CGFloat(row) * spacing

                    let center = CGPoint(x: size.width / 2, y: size.height * 0.4)
                    let dist = hypot(x - center.x, y - center.y)
                    let maxDist: CGFloat = 300
                    guard dist < maxDist else { continue }

                    let alpha = (1 - dist / maxDist) * 0.12 * hexGridOpacity
                    context.opacity = alpha

                    let dotSize: CGFloat = 1.5
                    let rect = CGRect(x: x - dotSize / 2, y: y - dotSize / 2, width: dotSize, height: dotSize)
                    context.fill(Circle().path(in: rect), with: .color(KickIQTheme.accent))
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Streak Trails

    private var streakTrailLayer: some View {
        Canvas { context, size in
            for trail in streakTrails {
                let startX = size.width / 2 + cos(trail.angle) * trail.startRadius
                let startY = size.height * 0.4 + sin(trail.angle) * trail.startRadius
                let endX = size.width / 2 + cos(trail.angle) * (trail.startRadius + trail.length)
                let endY = size.height * 0.4 + sin(trail.angle) * (trail.startRadius + trail.length)

                var path = Path()
                path.move(to: CGPoint(x: startX, y: startY))
                path.addLine(to: CGPoint(x: endX, y: endY))

                context.stroke(
                    path,
                    with: .linearGradient(
                        Gradient(colors: [
                            KickIQTheme.accent.opacity(trail.opacity * 0.8),
                            KickIQTheme.accent.opacity(0)
                        ]),
                        startPoint: CGPoint(x: startX, y: startY),
                        endPoint: CGPoint(x: endX, y: endY)
                    ),
                    lineWidth: trail.width
                )
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Particle System

    private var particleSystemLayer: some View {
        ZStack {
            ForEach(particleSystem) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .blur(radius: particle.size > 3 ? 1 : 0)
                    .offset(particle.offset)
                    .opacity(particle.opacity)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Orbital Rings

    private var orbitalRings: some View {
        ZStack {
            Ellipse()
                .stroke(KickIQTheme.accent.opacity(0.15), lineWidth: 0.8)
                .frame(width: 280, height: 100)
                .rotationEffect(.degrees(orbitalRingRotation))
                .rotation3DEffect(.degrees(60), axis: (x: 1, y: 0, z: 0))

            Ellipse()
                .stroke(KickIQTheme.accent.opacity(0.1), lineWidth: 0.6)
                .frame(width: 320, height: 120)
                .rotationEffect(.degrees(-orbitalRingRotation * 0.7))
                .rotation3DEffect(.degrees(55), axis: (x: 1, y: 0.2, z: 0))
        }
        .opacity(orbitalRingOpacity)
        .offset(y: -40)
        .allowsHitTesting(false)
    }

    // MARK: - Animation Sequence

    private func runSequence() {
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            meshPhase = .pi * 2
        }

        withAnimation(.easeIn(duration: 0.55)) {
            ballY = 0
            ballRotation = 720
            ballScale = 1.15
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            triggerImpact()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            revealLogo()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                taglineOpacity = 1
                taglineOffset = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.easeOut(duration: 0.5)) {
                bottomIndicatorOpacity = 1
            }

            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                energyPulse = true
            }

            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                orbitalRingRotation = 360
            }
        }
    }

    private func triggerImpact() {
        withAnimation(.spring(response: 0.15, dampingFraction: 0.35)) {
            ballScale = 1.0
        }

        withAnimation(.easeOut(duration: 0.15)) {
            impactFlash = 0.5
            meshIntensity = 1.5
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.15)) {
            impactFlash = 0
        }
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            meshIntensity = 1.0
        }

        withAnimation(.easeOut(duration: 0.6)) {
            shockwaveScale = 2.5
            shockwaveOpacity = 0.7
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
            shockwaveOpacity = 0
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.08)) {
            shockwave2Scale = 2.2
            shockwave2Opacity = 0.5
        }
        withAnimation(.easeOut(duration: 0.35).delay(0.35)) {
            shockwave2Opacity = 0
        }

        withAnimation(.easeOut(duration: 0.55).delay(0.15)) {
            shockwave3Scale = 2.8
            shockwave3Opacity = 0.3
        }
        withAnimation(.easeOut(duration: 0.3).delay(0.4)) {
            shockwave3Opacity = 0
        }

        spawnStreakTrails()
        spawnParticles()

        withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
            orbitalRingOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
            hexGridOpacity = 1
        }

        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.5)) {
            ballGlow = true
        }
    }

    private func spawnStreakTrails() {
        let count = 10
        var trails: [StreakTrail] = []
        for i in 0..<count {
            let angle = Double(i) * (360.0 / Double(count)) * .pi / 180 + Double.random(in: -0.2...0.2)
            trails.append(StreakTrail(
                angle: angle,
                startRadius: 70,
                length: 0,
                width: CGFloat.random(in: 1...2.5),
                opacity: 0
            ))
        }
        streakTrails = trails

        for i in 0..<count {
            let targetLength = CGFloat.random(in: 50...120)
            withAnimation(.easeOut(duration: 0.4).delay(Double(i) * 0.02)) {
                streakTrails[i].length = targetLength
                streakTrails[i].opacity = Double.random(in: 0.4...0.8)
            }
            withAnimation(.easeIn(duration: 0.3).delay(0.35 + Double(i) * 0.02)) {
                streakTrails[i].opacity = 0
                streakTrails[i].startRadius = 70 + targetLength
                streakTrails[i].length = 0
            }
        }
    }

    private func spawnParticles() {
        var particles: [SplashParticle] = []
        for i in 0..<20 {
            let angle = Double(i) * (360.0 / 20.0) * .pi / 180 + Double.random(in: -0.3...0.3)
            let distance = CGFloat.random(in: 80...200)
            let size = CGFloat.random(in: 1.5...5)
            particles.append(SplashParticle(
                id: i,
                offset: .zero,
                targetOffset: CGSize(
                    width: cos(angle) * distance,
                    height: sin(angle) * distance - 60
                ),
                size: size,
                opacity: 0,
                color: i % 3 == 0 ? .white.opacity(0.9) : KickIQTheme.accent
            ))
        }
        particleSystem = particles

        for i in 0..<20 {
            withAnimation(.easeOut(duration: Double.random(in: 0.5...0.8)).delay(Double.random(in: 0...0.1))) {
                particleSystem[i].offset = particleSystem[i].targetOffset
                particleSystem[i].opacity = Double.random(in: 0.5...1.0)
            }
            withAnimation(.easeIn(duration: 0.4).delay(Double.random(in: 0.5...0.7))) {
                particleSystem[i].opacity = 0
            }
        }
    }

    private func revealLogo() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            logoOpacity = 1
            logoScale = 1
        }

        for i in 0..<6 {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6).delay(Double(i) * 0.06)) {
                letterReveal[i] = true
            }
        }
    }
}

// MARK: - Models

private struct SplashParticle: Identifiable {
    let id: Int
    var offset: CGSize
    var targetOffset: CGSize
    var size: CGFloat
    var opacity: Double
    var color: Color
}

private struct StreakTrail {
    var angle: Double
    var startRadius: CGFloat
    var length: CGFloat
    var width: CGFloat
    var opacity: Double
}
