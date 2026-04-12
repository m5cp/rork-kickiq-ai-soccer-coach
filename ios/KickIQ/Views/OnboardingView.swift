import SwiftUI

struct SoccerBall: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var speed: CGFloat
    var opacity: Double
    var rotation: Double
    var direction: CGFloat
}

struct SoccerBallsBackground: View {
    @State private var balls: [SoccerBall] = []
    @State private var animating: Bool = false
    let screenWidth: CGFloat
    let screenHeight: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                for ball in balls {
                    let rect = CGRect(
                        x: ball.x - ball.size / 2,
                        y: ball.y - ball.size / 2,
                        width: ball.size,
                        height: ball.size
                    )
                    context.opacity = ball.opacity
                    context.drawLayer { ctx in
                        ctx.rotate(by: .degrees(ball.rotation))
                        let symbol = ctx.resolve(Image(systemName: "soccerball"))
                        ctx.draw(symbol, in: rect)
                    }
                }
            }
            .onChange(of: timeline.date) { _, _ in
                updateBalls()
            }
        }
        .foregroundStyle(KickIQTheme.accent.opacity(0.15))
        .onAppear {
            generateBalls()
        }
    }

    private func generateBalls() {
        balls = (0..<12).map { _ in
            SoccerBall(
                x: CGFloat.random(in: 0...screenWidth),
                y: CGFloat.random(in: -screenHeight...screenHeight * 2),
                size: CGFloat.random(in: 20...60),
                speed: CGFloat.random(in: 0.5...2.5),
                opacity: Double.random(in: 0.08...0.25),
                rotation: Double.random(in: 0...360),
                direction: CGFloat.random(in: -1...1)
            )
        }
    }

    private func updateBalls() {
        for i in balls.indices {
            balls[i].y -= balls[i].speed
            balls[i].x += balls[i].direction * 0.3
            balls[i].rotation += balls[i].speed * 2

            if balls[i].y < -balls[i].size {
                balls[i].y = screenHeight + balls[i].size
                balls[i].x = CGFloat.random(in: 0...screenWidth)
                balls[i].direction = CGFloat.random(in: -1...1)
            }
        }
    }
}

struct DynamicMeshBackground: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [Float(0.0 + 0.05 * sin(t * 0.5)), 0.5],
                    [Float(0.5 + 0.08 * cos(t * 0.7)), Float(0.5 + 0.06 * sin(t * 0.6))],
                    [Float(1.0 + 0.05 * sin(t * 0.4)), 0.5],
                    [0, 1], [0.5, 1], [1, 1]
                ],
                colors: [
                    Color(hex: 0x0A0E1A), Color(hex: 0x0D1B2A), Color(hex: 0x0A0E1A),
                    Color(hex: 0x13294B).opacity(0.8), KickIQTheme.accent.opacity(0.15), Color(hex: 0x13294B).opacity(0.6),
                    Color(hex: 0x0A0E1A), Color(hex: 0x0D1B2A), Color(hex: 0x0A0E1A)
                ]
            )
        }
        .ignoresSafeArea()
    }
}

struct OnboardingView: View {
    let storage: StorageService
    @State private var currentStep: Int = 0
    @State private var name: String = ""
    @State private var position: PlayerPosition = .midfielder
    @State private var ageRange: AgeRange = .sixteen18
    @State private var skillLevel: SkillLevel = .beginner
    @State private var weakness: WeaknessArea = .firstTouch
    @State private var appeared = false

    private let totalSteps = 8

    var body: some View {
        GeometryReader { geo in
            ZStack {
                DynamicMeshBackground()

                SoccerBallsBackground(
                    screenWidth: geo.size.width,
                    screenHeight: geo.size.height
                )

                VStack(spacing: 0) {
                    HStack {
                        progressBar
                        Spacer()
                        skipButton
                    }
                    .padding(.top, 12)
                    .padding(.horizontal, KickIQTheme.Spacing.md)

                    TabView(selection: $currentStep) {
                        positionStep.tag(0)
                        ageStep.tag(1)
                        skillLevelStep.tag(2)
                        weaknessStep.tag(3)
                        painStep.tag(4)
                        howItWorksStep.tag(5)
                        socialProofStep.tag(6)
                        paywallStep.tag(7)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.spring(response: 0.4), value: currentStep)

                    if currentStep < 7 {
                        continueButton
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
    }

    private var skipButton: some View {
        Button {
            completeOnboarding()
        } label: {
            Text("Skip")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(KickIQTheme.textSecondary)
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 4)

                Capsule()
                    .fill(KickIQTheme.accent)
                    .frame(width: geo.size.width * (Double(currentStep + 1) / Double(totalSteps)), height: 4)
                    .animation(.spring(response: 0.3), value: currentStep)
            }
        }
        .frame(width: 200, height: 4)
    }

    private var positionStep: some View {
        ScrollView {
            VStack(spacing: KickIQTheme.Spacing.lg) {
                stepHeader(title: "YOUR POSITION", subtitle: "Where do you play on the pitch?")

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(PlayerPosition.allCases) { pos in
                        Button {
                            position = pos
                        } label: {
                            VStack(spacing: 10) {
                                Image(systemName: pos.icon)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(position == pos ? KickIQTheme.accent : KickIQTheme.textSecondary)

                                Text(pos.rawValue)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(position == pos ? .white : KickIQTheme.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, KickIQTheme.Spacing.lg)
                            .background(
                                RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                                    .fill(position == pos ? KickIQTheme.accent.opacity(0.2) : Color.white.opacity(0.06))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                                            .stroke(position == pos ? KickIQTheme.accent : Color.clear, lineWidth: 2)
                                    )
                            )
                        }
                        .sensoryFeedback(.selection, trigger: position)
                    }
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
            }
            .padding(.bottom, KickIQTheme.Spacing.lg)
        }
        .scrollIndicators(.hidden)
    }

    private var ageStep: some View {
        ScrollView {
            VStack(spacing: KickIQTheme.Spacing.lg) {
                stepHeader(title: "YOUR AGE", subtitle: "This helps us calibrate feedback for you")

                VStack(spacing: 10) {
                    ForEach(AgeRange.allCases) { age in
                        Button {
                            ageRange = age
                        } label: {
                            selectionRow(title: age.rawValue, isSelected: ageRange == age)
                        }
                        .sensoryFeedback(.selection, trigger: ageRange)
                    }
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
            }
            .padding(.bottom, KickIQTheme.Spacing.lg)
        }
        .scrollIndicators(.hidden)
    }

    private var skillLevelStep: some View {
        ScrollView {
            VStack(spacing: KickIQTheme.Spacing.lg) {
                stepHeader(title: "SKILL LEVEL", subtitle: "Be honest — we'll meet you where you are")

                VStack(spacing: 10) {
                    ForEach(SkillLevel.allCases) { level in
                        Button {
                            skillLevel = level
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(level.rawValue)
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(skillLevel == level ? .white : KickIQTheme.textSecondary)
                                    Text(level.description)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(KickIQTheme.textSecondary.opacity(0.7))
                                }
                                Spacer()
                                if skillLevel == level {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(KickIQTheme.accent)
                                        .font(.title3.weight(.bold))
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(KickIQTheme.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: KickIQTheme.Radius.md)
                                    .fill(skillLevel == level ? KickIQTheme.accent.opacity(0.2) : Color.white.opacity(0.06))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: KickIQTheme.Radius.md)
                                            .stroke(skillLevel == level ? KickIQTheme.accent : Color.clear, lineWidth: 1.5)
                                    )
                            )
                        }
                        .sensoryFeedback(.selection, trigger: skillLevel)
                    }
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .animation(.spring(response: 0.3), value: skillLevel)
            }
            .padding(.bottom, KickIQTheme.Spacing.lg)
        }
        .scrollIndicators(.hidden)
    }

    private var weaknessStep: some View {
        ScrollView {
            VStack(spacing: KickIQTheme.Spacing.lg) {
                stepHeader(title: "BIGGEST WEAKNESS", subtitle: "What do you want to improve most?")

                VStack(spacing: 10) {
                    ForEach(WeaknessArea.allCases) { area in
                        Button {
                            weakness = area
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: area.icon)
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(weakness == area ? KickIQTheme.accent : KickIQTheme.textSecondary)
                                    .frame(width: 32)

                                Text(area.rawValue)
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(weakness == area ? .white : KickIQTheme.textSecondary)

                                Spacer()

                                if weakness == area {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(KickIQTheme.accent)
                                        .font(.title3.weight(.bold))
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(KickIQTheme.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: KickIQTheme.Radius.md)
                                    .fill(weakness == area ? KickIQTheme.accent.opacity(0.2) : Color.white.opacity(0.06))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: KickIQTheme.Radius.md)
                                            .stroke(weakness == area ? KickIQTheme.accent : Color.clear, lineWidth: 1.5)
                                    )
                            )
                        }
                        .sensoryFeedback(.selection, trigger: weakness)
                    }
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .animation(.spring(response: 0.3), value: weakness)
            }
            .padding(.bottom, KickIQTheme.Spacing.lg)
        }
        .scrollIndicators(.hidden)
    }

    private var painStep: some View {
        VStack(spacing: KickIQTheme.Spacing.xl) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(KickIQTheme.accent)
                .symbolEffect(.bounce, value: currentStep == 4)

            VStack(spacing: KickIQTheme.Spacing.md) {
                Text("Most players never improve\nbecause no one tells them\nwhat to fix.")
                    .font(.system(.title, design: .default, weight: .black))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)

                Text("KickIQ is your AI coach.\nAlways watching. Always improving you.")
                    .font(.body.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(KickIQTheme.textSecondary)
                    .padding(.top, KickIQTheme.Spacing.sm)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, KickIQTheme.Spacing.xl)
    }

    private var howItWorksStep: some View {
        VStack(spacing: KickIQTheme.Spacing.xl) {
            Spacer()

            Text("HOW IT WORKS")
                .font(.system(.title2, design: .default, weight: .black).width(.compressed))
                .tracking(2)
                .foregroundStyle(.white)

            VStack(spacing: KickIQTheme.Spacing.lg) {
                howItWorksRow(step: "1", icon: "video.fill", title: "Record", subtitle: "Film your training session")
                howItWorksRow(step: "2", icon: "brain.head.profile.fill", title: "Analyze", subtitle: "AI breaks down your technique")
                howItWorksRow(step: "3", icon: "chart.line.uptrend.xyaxis", title: "Improve", subtitle: "Follow personalized drills")
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, KickIQTheme.Spacing.lg)
    }

    private var socialProofStep: some View {
        ScrollView {
            VStack(spacing: KickIQTheme.Spacing.lg) {
                stepHeader(title: "PLAYERS LIKE YOU", subtitle: "See what KickIQ has done for them")

                VStack(spacing: KickIQTheme.Spacing.md) {
                    testimonialCard(name: "Marcus J.", age: "16", result: "Made varsity after 6 weeks of KickIQ training")
                    testimonialCard(name: "Sofia R.", age: "14", result: "Improved my first touch score from 4 to 8 in one month")
                    testimonialCard(name: "Aiden K.", age: "19", result: "Got scouted at a showcase after using KickIQ daily")
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
            }
            .padding(.bottom, KickIQTheme.Spacing.lg)
        }
        .scrollIndicators(.hidden)
    }

    private var paywallStep: some View {
        ScrollView {
            VStack(spacing: KickIQTheme.Spacing.lg) {
                VStack(spacing: KickIQTheme.Spacing.sm) {
                    Text("UNLOCK KICKIQ")
                        .font(.system(.title2, design: .default, weight: .black).width(.compressed))
                        .tracking(2)
                        .foregroundStyle(.white)

                    Text("Your AI coach is ready")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
                .padding(.top, KickIQTheme.Spacing.lg)

                VStack(spacing: 10) {
                    pricingCard(title: "Annual", price: "$99.99/yr", perWeek: "$1.92/week", badge: "BEST VALUE", isHighlighted: true, trialText: "3-day free trial")
                    pricingCard(title: "Monthly", price: "$19.99/mo", perWeek: "$4.99/week", badge: nil, isHighlighted: false, trialText: nil)
                    pricingCard(title: "Weekly", price: "$6.99/wk", perWeek: nil, badge: nil, isHighlighted: false, trialText: nil)
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)

                Button {
                    completeOnboarding()
                } label: {
                    Text("Start Free Trial")
                        .font(.headline.weight(.black))
                        .foregroundStyle(KickIQTheme.onAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, KickIQTheme.Spacing.md)
                        .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .sensoryFeedback(.impact(weight: .medium), trigger: currentStep)

                Button {
                    completeOnboarding()
                } label: {
                    Text("Restore Purchases")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(KickIQTheme.textSecondary)
                }

                VStack(spacing: 4) {
                    Text("Cancel anytime. No commitment.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KickIQTheme.textSecondary.opacity(0.6))
                    HStack(spacing: KickIQTheme.Spacing.md) {
                        Link("Privacy Policy", destination: URL(string: "https://termly.io")!)
                        Text("·").foregroundStyle(KickIQTheme.textSecondary.opacity(0.4))
                        Link("Terms of Service", destination: URL(string: "https://termly.io")!)
                    }
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(KickIQTheme.textSecondary.opacity(0.5))
                }
                .padding(.bottom, KickIQTheme.Spacing.lg)
            }
        }
        .scrollIndicators(.hidden)
    }

    private var continueButton: some View {
        Button {
            withAnimation(.spring(response: 0.4)) { currentStep += 1 }
        } label: {
            Text("Continue")
                .font(.headline.weight(.black))
                .foregroundStyle(KickIQTheme.onAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, KickIQTheme.Spacing.md)
                .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
        }
        .padding(.horizontal, KickIQTheme.Spacing.md + 4)
        .padding(.bottom, KickIQTheme.Spacing.md)
        .sensoryFeedback(.impact(weight: .medium), trigger: currentStep)
    }

    private func stepHeader(title: String, subtitle: String) -> some View {
        VStack(spacing: KickIQTheme.Spacing.sm) {
            Text(title)
                .font(.system(.title2, design: .default, weight: .black).width(.compressed))
                .tracking(2)
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(KickIQTheme.textSecondary)
        }
        .padding(.top, KickIQTheme.Spacing.lg)
    }

    private func selectionRow(title: String, isSelected: Bool) -> some View {
        HStack {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(isSelected ? .white : KickIQTheme.textSecondary)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(KickIQTheme.accent)
                    .font(.title3.weight(.bold))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(KickIQTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: KickIQTheme.Radius.md)
                .fill(isSelected ? KickIQTheme.accent.opacity(0.2) : Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: KickIQTheme.Radius.md)
                        .stroke(isSelected ? KickIQTheme.accent : Color.clear, lineWidth: 1.5)
                )
        )
    }

    private func howItWorksRow(step: String, icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: KickIQTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(KickIQTheme.accent.opacity(0.2))
                    .frame(width: 56, height: 56)
                Image(systemName: icon)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(KickIQTheme.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Step \(step)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(KickIQTheme.accent)
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KickIQTheme.textSecondary)
            }
            Spacer()
        }
        .padding(KickIQTheme.Spacing.md)
        .background(Color.white.opacity(0.06), in: .rect(cornerRadius: KickIQTheme.Radius.lg))
    }

    private func testimonialCard(name: String, age: String, result: String) -> some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            HStack(spacing: KickIQTheme.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(KickIQTheme.accent.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Text(String(name.prefix(1)))
                        .font(.headline.weight(.black))
                        .foregroundStyle(KickIQTheme.accent)
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text(name)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Age \(age)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
                Spacer()

                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(KickIQTheme.accent)
                    }
                }
            }

            Text("\"\(result)\"")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
                .italic()
        }
        .padding(KickIQTheme.Spacing.md)
        .background(Color.white.opacity(0.06), in: .rect(cornerRadius: KickIQTheme.Radius.lg))
    }

    private func pricingCard(title: String, price: String, perWeek: String?, badge: String?, isHighlighted: Bool, trialText: String?) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: KickIQTheme.Spacing.sm) {
                    Text(title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)

                    if let badge {
                        Text(badge)
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(KickIQTheme.onAccent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(KickIQTheme.accent, in: Capsule())
                    }
                }

                if let perWeek {
                    Text(perWeek)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KickIQTheme.textSecondary)
                }

                if let trialText {
                    Text(trialText)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(KickIQTheme.accent)
                }
            }

            Spacer()

            Text(price)
                .font(.title3.weight(.black))
                .foregroundStyle(.white)
        }
        .padding(KickIQTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                .fill(isHighlighted ? KickIQTheme.accent.opacity(0.15) : Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                        .stroke(isHighlighted ? KickIQTheme.accent : Color.white.opacity(0.08), lineWidth: isHighlighted ? 2 : 1)
                )
        )
    }

    private func completeOnboarding() {
        let profile = PlayerProfile(
            name: name.isEmpty ? "Player" : name.trimmingCharacters(in: .whitespaces),
            position: position,
            ageRange: ageRange,
            skillLevel: skillLevel,
            weakness: weakness
        )
        storage.saveProfile(profile)
        storage.completeOnboarding()
    }
}
