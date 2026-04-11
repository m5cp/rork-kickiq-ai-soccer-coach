import SwiftUI

struct OnboardingView: View {
    let storage: StorageService
    @State private var currentStep: Int = 0
    @State private var name: String = ""
    @State private var position: PlayerPosition = .midfielder
    @State private var ageRange: AgeRange = .sixteen18
    @State private var skillLevel: SkillLevel = .beginner
    @State private var weakness: WeaknessArea = .firstTouch
    @State private var appeared = false

    private let totalSteps = 9

    var body: some View {
        ZStack {
            KickIQTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    progressBar
                    
                    Button {
                        completeOnboarding()
                    } label: {
                        Text("Skip")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(KickIQTheme.textSecondary)
                    }
                }
                .padding(.top, 12)
                .padding(.horizontal, KickIQTheme.Spacing.md)

                TabView(selection: $currentStep) {
                    nameStep.tag(0)
                    positionStep.tag(1)
                    ageStep.tag(2)
                    skillLevelStep.tag(3)
                    weaknessStep.tag(4)
                    painStep.tag(5)
                    howItWorksStep.tag(6)
                    socialProofStep.tag(7)
                    paywallStep.tag(8)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.4), value: currentStep)

                if currentStep < 8 {
                    continueButton
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(KickIQTheme.divider)
                    .frame(height: 4)

                Capsule()
                    .fill(KickIQTheme.accent)
                    .frame(width: geo.size.width * (Double(currentStep + 1) / Double(totalSteps)), height: 4)
                    .animation(.spring(response: 0.3), value: currentStep)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Step 0: Name
    private var nameStep: some View {
        VStack(spacing: KickIQTheme.Spacing.xl) {
            Spacer()

            VStack(spacing: KickIQTheme.Spacing.md) {
                Image(systemName: "person.text.rectangle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(KickIQTheme.accent)
                    .symbolEffect(.bounce, value: currentStep == 0)

                Text("WHAT'S YOUR NAME?")
                    .font(.system(.title2, design: .default, weight: .black).width(.compressed))
                    .tracking(2)
                    .foregroundStyle(KickIQTheme.textPrimary)

                Text("So we can personalize your coaching")
                    .font(.subheadline)
                    .foregroundStyle(KickIQTheme.textSecondary)
            }

            TextField("", text: $name, prompt: Text("Enter your name").foregroundStyle(KickIQTheme.textSecondary.opacity(0.5)))
                .font(.title3.weight(.semibold))
                .foregroundStyle(KickIQTheme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.vertical, KickIQTheme.Spacing.md)
                .padding(.horizontal, KickIQTheme.Spacing.lg)
                .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                        .stroke(name.isEmpty ? KickIQTheme.divider : KickIQTheme.accent, lineWidth: 1.5)
                )
                .padding(.horizontal, KickIQTheme.Spacing.lg)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)

            if !name.trimmingCharacters(in: .whitespaces).isEmpty {
                Text("Welcome, \(name.trimmingCharacters(in: .whitespaces))!")
                    .font(.headline)
                    .foregroundStyle(KickIQTheme.accent)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, KickIQTheme.Spacing.xl)
        .animation(.spring(response: 0.3), value: name)
    }

    // MARK: - Step 1: Position
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
                                    .font(.system(size: 28))
                                    .foregroundStyle(position == pos ? KickIQTheme.accent : KickIQTheme.textSecondary)

                                Text(pos.rawValue)
                                    .font(.headline)
                                    .foregroundStyle(position == pos ? KickIQTheme.textPrimary : KickIQTheme.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, KickIQTheme.Spacing.lg)
                            .background(
                                RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                                    .fill(position == pos ? KickIQTheme.accent.opacity(0.15) : KickIQTheme.card)
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

    // MARK: - Step 2: Age
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

    // MARK: - Step 3: Skill Level
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
                                        .font(.headline)
                                        .foregroundStyle(skillLevel == level ? KickIQTheme.textPrimary : KickIQTheme.textSecondary)
                                    Text(level.description)
                                        .font(.caption)
                                        .foregroundStyle(KickIQTheme.textSecondary.opacity(0.7))
                                }
                                Spacer()
                                if skillLevel == level {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(KickIQTheme.accent)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(KickIQTheme.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: KickIQTheme.Radius.md)
                                    .fill(skillLevel == level ? KickIQTheme.accent.opacity(0.15) : KickIQTheme.card)
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

    // MARK: - Step 4: Weakness
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
                                    .font(.title3)
                                    .foregroundStyle(weakness == area ? KickIQTheme.accent : KickIQTheme.textSecondary)
                                    .frame(width: 32)

                                Text(area.rawValue)
                                    .font(.headline)
                                    .foregroundStyle(weakness == area ? KickIQTheme.textPrimary : KickIQTheme.textSecondary)

                                Spacer()

                                if weakness == area {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(KickIQTheme.accent)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(KickIQTheme.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: KickIQTheme.Radius.md)
                                    .fill(weakness == area ? KickIQTheme.accent.opacity(0.15) : KickIQTheme.card)
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

    // MARK: - Step 5: Pain Screen
    private var painStep: some View {
        VStack(spacing: KickIQTheme.Spacing.xl) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(KickIQTheme.accent)
                .symbolEffect(.bounce, value: currentStep == 5)

            VStack(spacing: KickIQTheme.Spacing.md) {
                Text("Most players never improve\nbecause no one tells them\nwhat to fix.")
                    .font(.system(.title, design: .default, weight: .black))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(KickIQTheme.textPrimary)

                Text("KickIQ is your AI coach.\nAlways watching. Always improving you.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(KickIQTheme.textSecondary)
                    .padding(.top, KickIQTheme.Spacing.sm)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, KickIQTheme.Spacing.xl)
    }

    // MARK: - Step 6: How It Works
    private var howItWorksStep: some View {
        VStack(spacing: KickIQTheme.Spacing.xl) {
            Spacer()

            Text("HOW IT WORKS")
                .font(.system(.title2, design: .default, weight: .black).width(.compressed))
                .tracking(2)
                .foregroundStyle(KickIQTheme.textPrimary)

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

    // MARK: - Step 7: Social Proof
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

    // MARK: - Step 8: Paywall
    private var paywallStep: some View {
        ScrollView {
            VStack(spacing: KickIQTheme.Spacing.lg) {
                VStack(spacing: KickIQTheme.Spacing.sm) {
                    Text("UNLOCK KICKIQ")
                        .font(.system(.title2, design: .default, weight: .black).width(.compressed))
                        .tracking(2)
                        .foregroundStyle(KickIQTheme.textPrimary)

                    Text("Your AI coach is ready")
                        .font(.subheadline)
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
                        .font(.headline)
                        .foregroundStyle(.black)
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
                        .font(.subheadline)
                        .foregroundStyle(KickIQTheme.textSecondary)
                }

                VStack(spacing: 4) {
                    Text("Cancel anytime. No commitment.")
                        .font(.caption)
                        .foregroundStyle(KickIQTheme.textSecondary.opacity(0.6))
                    HStack(spacing: KickIQTheme.Spacing.md) {
                        Link("Privacy Policy", destination: URL(string: "https://termly.io")!)
                        Text("·").foregroundStyle(KickIQTheme.textSecondary.opacity(0.4))
                        Link("Terms of Service", destination: URL(string: "https://termly.io")!)
                    }
                    .font(.caption2)
                    .foregroundStyle(KickIQTheme.textSecondary.opacity(0.5))
                }
                .padding(.bottom, KickIQTheme.Spacing.lg)
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
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, KickIQTheme.Spacing.md)
                .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
        }
        .padding(.horizontal, KickIQTheme.Spacing.md + 4)
        .padding(.bottom, KickIQTheme.Spacing.md)
        .sensoryFeedback(.impact(weight: .medium), trigger: currentStep)
    }

    // MARK: - Helpers
    private func stepHeader(title: String, subtitle: String) -> some View {
        VStack(spacing: KickIQTheme.Spacing.sm) {
            Text(title)
                .font(.system(.title2, design: .default, weight: .black).width(.compressed))
                .tracking(2)
                .foregroundStyle(KickIQTheme.textPrimary)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(KickIQTheme.textSecondary)
        }
        .padding(.top, KickIQTheme.Spacing.lg)
    }

    private func selectionRow(title: String, isSelected: Bool) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(isSelected ? KickIQTheme.textPrimary : KickIQTheme.textSecondary)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(KickIQTheme.accent)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(KickIQTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: KickIQTheme.Radius.md)
                .fill(isSelected ? KickIQTheme.accent.opacity(0.15) : KickIQTheme.card)
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
                    .fill(KickIQTheme.accent.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(KickIQTheme.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Step \(step)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(KickIQTheme.accent)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(KickIQTheme.textPrimary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(KickIQTheme.textSecondary)
            }
            Spacer()
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
    }

    private func testimonialCard(name: String, age: String, result: String) -> some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            HStack(spacing: KickIQTheme.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(KickIQTheme.accent.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Text(String(name.prefix(1)))
                        .font(.headline)
                        .foregroundStyle(KickIQTheme.accent)
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text(name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KickIQTheme.textPrimary)
                    Text("Age \(age)")
                        .font(.caption)
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
                Spacer()

                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(KickIQTheme.accent)
                    }
                }
            }

            Text("\"\(result)\"")
                .font(.subheadline)
                .foregroundStyle(KickIQTheme.textPrimary.opacity(0.85))
                .italic()
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
    }

    private func pricingCard(title: String, price: String, perWeek: String?, badge: String?, isHighlighted: Bool, trialText: String?) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: KickIQTheme.Spacing.sm) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(KickIQTheme.textPrimary)

                    if let badge {
                        Text(badge)
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(KickIQTheme.accent, in: Capsule())
                    }
                }

                if let perWeek {
                    Text(perWeek)
                        .font(.caption)
                        .foregroundStyle(KickIQTheme.textSecondary)
                }

                if let trialText {
                    Text(trialText)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(KickIQTheme.accent)
                }
            }

            Spacer()

            Text(price)
                .font(.title3.weight(.bold))
                .foregroundStyle(KickIQTheme.textPrimary)
        }
        .padding(KickIQTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                .fill(isHighlighted ? KickIQTheme.accent.opacity(0.12) : KickIQTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                        .stroke(isHighlighted ? KickIQTheme.accent : KickIQTheme.divider, lineWidth: isHighlighted ? 2 : 1)
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
