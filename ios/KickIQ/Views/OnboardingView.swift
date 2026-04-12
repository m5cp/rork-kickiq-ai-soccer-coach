import SwiftUI

struct OnboardingBackground: View {
    var body: some View {
        ZStack {
            Color(hex: 0x070B14)
                .ignoresSafeArea()

            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [0.5, 0.5], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1]
                ],
                colors: [
                    Color(hex: 0x070B14), Color(hex: 0x0D1B2A), Color(hex: 0x070B14),
                    Color(hex: 0x0D1B2A), Color(hex: 0x13294B).opacity(0.3), Color(hex: 0x0D1B2A),
                    Color(hex: 0x070B14), Color(hex: 0x0A1628), Color(hex: 0x070B14)
                ]
            )
            .ignoresSafeArea()
        }
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
    @State private var stepAppeared: Bool = false

    private let totalSteps = 8

    var body: some View {
        ZStack {
            OnboardingBackground()

            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    progressBar
                    Spacer()
                    skipButton
                }
                .padding(.top, 12)
                .padding(.horizontal, 20)

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
        .preferredColorScheme(.dark)
        .onChange(of: currentStep) { _, _ in
            stepAppeared = false
            withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
                stepAppeared = true
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { stepAppeared = true }
        }
    }

    private var skipButton: some View {
        Button {
            completeOnboarding()
        } label: {
            Text("Skip")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 5)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [KickIQTheme.accent, KickIQTheme.accent.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, geo.size.width * (Double(currentStep + 1) / Double(totalSteps))), height: 5)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)
                    .shadow(color: KickIQTheme.accent.opacity(0.4), radius: 4, x: 0, y: 0)
            }
        }
        .frame(height: 5)
        .padding(.trailing, 16)
    }

    // MARK: - Position Step

    private var positionStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                stepHeader(title: "YOUR POSITION", subtitle: "Where do you play on the pitch?")

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(PlayerPosition.allCases) { pos in
                        Button {
                            position = pos
                        } label: {
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(position == pos ? KickIQTheme.accent.opacity(0.2) : Color.white.opacity(0.04))
                                        .frame(width: 52, height: 52)

                                    Image(systemName: pos.icon)
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundStyle(position == pos ? KickIQTheme.accent : .white.opacity(0.4))
                                }

                                Text(pos.rawValue)
                                    .font(.subheadline.weight(.black))
                                    .foregroundStyle(position == pos ? .white : .white.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(position == pos ? KickIQTheme.accent.opacity(0.12) : Color.white.opacity(0.04))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(position == pos ? KickIQTheme.accent.opacity(0.6) : Color.white.opacity(0.06), lineWidth: position == pos ? 1.5 : 0.5)
                                    )
                            )
                        }
                        .sensoryFeedback(.selection, trigger: position)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Age Step

    private var ageStep: some View {
        ScrollView {
            VStack(spacing: 24) {
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
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Skill Level Step

    private var skillLevelStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                stepHeader(title: "SKILL LEVEL", subtitle: "Be honest — we'll meet you where you are")

                VStack(spacing: 10) {
                    ForEach(SkillLevel.allCases) { level in
                        Button {
                            skillLevel = level
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(level.rawValue)
                                        .font(.headline.weight(.black))
                                        .foregroundStyle(skillLevel == level ? .white : .white.opacity(0.5))
                                    Text(level.description)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.white.opacity(0.35))
                                }
                                Spacer()
                                if skillLevel == level {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(KickIQTheme.accent)
                                        .font(.title3.weight(.bold))
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(skillLevel == level ? KickIQTheme.accent.opacity(0.12) : Color.white.opacity(0.04))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(skillLevel == level ? KickIQTheme.accent.opacity(0.6) : Color.white.opacity(0.06), lineWidth: skillLevel == level ? 1.5 : 0.5)
                                    )
                            )
                        }
                        .sensoryFeedback(.selection, trigger: skillLevel)
                    }
                }
                .padding(.horizontal, 20)
                .animation(.spring(response: 0.3), value: skillLevel)
            }
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Weakness Step

    private var weaknessStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                stepHeader(title: "BIGGEST WEAKNESS", subtitle: "What do you want to improve most?")

                VStack(spacing: 10) {
                    ForEach(WeaknessArea.allCases) { area in
                        Button {
                            weakness = area
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(weakness == area ? KickIQTheme.accent.opacity(0.15) : Color.white.opacity(0.04))
                                        .frame(width: 40, height: 40)

                                    Image(systemName: area.icon)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(weakness == area ? KickIQTheme.accent : .white.opacity(0.4))
                                }

                                Text(area.rawValue)
                                    .font(.headline.weight(.black))
                                    .foregroundStyle(weakness == area ? .white : .white.opacity(0.5))

                                Spacer()

                                if weakness == area {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(KickIQTheme.accent)
                                        .font(.title3.weight(.bold))
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(weakness == area ? KickIQTheme.accent.opacity(0.12) : Color.white.opacity(0.04))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(weakness == area ? KickIQTheme.accent.opacity(0.6) : Color.white.opacity(0.06), lineWidth: weakness == area ? 1.5 : 0.5)
                                    )
                            )
                        }
                        .sensoryFeedback(.selection, trigger: weakness)
                    }
                }
                .padding(.horizontal, 20)
                .animation(.spring(response: 0.3), value: weakness)
            }
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Pain Step

    private var painStep: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(KickIQTheme.accent.opacity(0.08))
                    .frame(width: 120, height: 120)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(KickIQTheme.accent)
                    .symbolEffect(.bounce, value: currentStep == 4)
            }

            VStack(spacing: 16) {
                Text("Most players\nnever improve.")
                    .font(.system(size: 30, weight: .black))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)

                Text("Because no one tells them what to fix.")
                    .font(.title3.weight(.bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(KickIQTheme.accent)

                Text("KickIQ is your AI coach.\nAlways watching. Always improving you.")
                    .font(.body.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.top, 8)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - How It Works Step

    private var howItWorksStep: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("HOW IT WORKS")
                .font(.system(size: 24, weight: .black).width(.compressed))
                .tracking(3)
                .foregroundStyle(.white)

            VStack(spacing: 16) {
                howItWorksRow(step: "1", icon: "video.fill", title: "RECORD", subtitle: "Film your training session")
                howItWorksRow(step: "2", icon: "brain.head.profile.fill", title: "ANALYZE", subtitle: "AI breaks down your technique")
                howItWorksRow(step: "3", icon: "chart.line.uptrend.xyaxis", title: "IMPROVE", subtitle: "Follow personalized drills")
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Social Proof Step

    private var socialProofStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                stepHeader(title: "PLAYERS LIKE YOU", subtitle: "See what KickIQ has done for them")

                VStack(spacing: 12) {
                    testimonialCard(name: "Marcus J.", age: "16", result: "Made varsity after 6 weeks of KickIQ training")
                    testimonialCard(name: "Sofia R.", age: "14", result: "Improved my first touch score from 4 to 8 in one month")
                    testimonialCard(name: "Aiden K.", age: "19", result: "Got scouted at a showcase after using KickIQ daily")
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Paywall Step

    private var paywallStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("UNLOCK KICKIQ")
                        .font(.system(size: 24, weight: .black).width(.compressed))
                        .tracking(3)
                        .foregroundStyle(.white)

                    Text("Your AI coach is ready")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.top, 24)

                VStack(spacing: 10) {
                    pricingCard(title: "Annual", price: "$99.99/yr", perWeek: "$1.92/week", badge: "BEST VALUE", isHighlighted: true, trialText: "3-day free trial")
                    pricingCard(title: "Monthly", price: "$19.99/mo", perWeek: "$4.99/week", badge: nil, isHighlighted: false, trialText: nil)
                    pricingCard(title: "Weekly", price: "$6.99/wk", perWeek: nil, badge: nil, isHighlighted: false, trialText: nil)
                }
                .padding(.horizontal, 20)

                Button {
                    completeOnboarding()
                } label: {
                    Text("Start Free Trial")
                        .font(.headline.weight(.black))
                        .foregroundStyle(KickIQTheme.onAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [KickIQTheme.accent, KickIQTheme.accent.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: .rect(cornerRadius: 16)
                        )
                        .shadow(color: KickIQTheme.accent.opacity(0.3), radius: 12, x: 0, y: 4)
                }
                .padding(.horizontal, 20)
                .sensoryFeedback(.impact(weight: .medium), trigger: currentStep)

                Button {
                    completeOnboarding()
                } label: {
                    Text("Restore Purchases")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white.opacity(0.4))
                }

                VStack(spacing: 4) {
                    Text("Cancel anytime. No commitment.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.3))
                    HStack(spacing: 12) {
                        Link("Privacy Policy", destination: URL(string: "https://termly.io")!)
                        Text("·").foregroundStyle(.white.opacity(0.2))
                        Link("Terms of Service", destination: URL(string: "https://termly.io")!)
                    }
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.3))
                }
                .padding(.bottom, 24)
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button {
            withAnimation(.spring(response: 0.4)) { currentStep += 1 }
        } label: {
            Text("Continue")
                .font(.headline.weight(.black))
                .foregroundStyle(KickIQTheme.onAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [KickIQTheme.accent, KickIQTheme.accent.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: .rect(cornerRadius: 16)
                )
                .shadow(color: KickIQTheme.accent.opacity(0.3), radius: 12, x: 0, y: 4)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .sensoryFeedback(.impact(weight: .medium), trigger: currentStep)
    }

    // MARK: - Helpers

    private func stepHeader(title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 24, weight: .black).width(.compressed))
                .tracking(3)
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.top, 24)
    }

    private func selectionRow(title: String, isSelected: Bool) -> some View {
        HStack {
            Text(title)
                .font(.headline.weight(.black))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(KickIQTheme.accent)
                    .font(.title3.weight(.bold))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelected ? KickIQTheme.accent.opacity(0.12) : Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelected ? KickIQTheme.accent.opacity(0.6) : Color.white.opacity(0.06), lineWidth: isSelected ? 1.5 : 0.5)
                )
        )
    }

    private func howItWorksRow(step: String, icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(KickIQTheme.accent.opacity(0.12))
                    .frame(width: 56, height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(KickIQTheme.accent.opacity(0.2), lineWidth: 1)
                    )

                Image(systemName: icon)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(KickIQTheme.accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("STEP \(step)")
                    .font(.system(size: 11, weight: .black))
                    .tracking(1.5)
                    .foregroundStyle(KickIQTheme.accent)
                Text(title)
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.45))
            }
            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.04), in: .rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
        )
    }

    private func testimonialCard(name: String, age: String, result: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(KickIQTheme.accent.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Text(String(name.prefix(1)))
                        .font(.headline.weight(.black))
                        .foregroundStyle(KickIQTheme.accent)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(name)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Age \(age)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.4))
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
                .foregroundStyle(.white.opacity(0.7))
                .italic()
        }
        .padding(16)
        .background(Color.white.opacity(0.04), in: .rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
        )
    }

    private func pricingCard(title: String, price: String, perWeek: String?, badge: String?, isHighlighted: Bool, trialText: String?) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.headline.weight(.black))
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
                        .foregroundStyle(.white.opacity(0.4))
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
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isHighlighted ? KickIQTheme.accent.opacity(0.1) : Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isHighlighted ? KickIQTheme.accent.opacity(0.5) : Color.white.opacity(0.06), lineWidth: isHighlighted ? 1.5 : 0.5)
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
