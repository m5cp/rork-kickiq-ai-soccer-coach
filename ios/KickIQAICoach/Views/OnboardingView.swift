import SwiftUI
import RevenueCat

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
    @State private var storeVM = StoreViewModel()
    @State private var currentStep: Int = 0
    @State private var position: PlayerPosition = .midfielder
    @State private var ageRange: AgeRange = .fifteen18
    @State private var skillLevel: SkillLevel = .beginner
    @State private var selectedWeaknesses: Set<WeaknessArea> = [.firstTouch]
    @State private var selectedConditioning: Set<ConditioningFocus> = []
    @State private var stepAppeared: Bool = false
    @State private var selectedPlanIndex: Int = 0
    @State private var isPurchasing: Bool = false
    @State private var isRestoring: Bool = false
    @State private var showLegalPage: LegalPage?

    private let totalSteps = 8

    var body: some View {
        ZStack {
            OnboardingBackground()

            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    if currentStep > 0 {
                        backButton
                    }
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
                    conditioningStep.tag(4)
                    painStep.tag(5)
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
        .sheet(item: $showLegalPage) { page in
            NavigationStack {
                LegalPageView(page: page)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showLegalPage = nil }
                                .fontWeight(.bold)
                        }
                    }
            }
        }
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

    private var backButton: some View {
        Button {
            withAnimation(.spring(response: 0.4)) { currentStep -= 1 }
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.06), in: Circle())
        }
        .sensoryFeedback(.selection, trigger: currentStep)
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
                            colors: [KickIQAICoachTheme.accent, KickIQAICoachTheme.accent.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, geo.size.width * (Double(currentStep + 1) / Double(totalSteps))), height: 5)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)
                    .shadow(color: KickIQAICoachTheme.accent.opacity(0.4), radius: 4, x: 0, y: 0)
            }
        }
        .frame(height: 5)
        .padding(.horizontal, 8)
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
                                        .fill(position == pos ? KickIQAICoachTheme.accent.opacity(0.2) : Color.white.opacity(0.04))
                                        .frame(width: 52, height: 52)

                                    Image(systemName: pos.icon)
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundStyle(position == pos ? KickIQAICoachTheme.accent : .white.opacity(0.4))
                                }

                                Text(pos.rawValue)
                                    .font(.subheadline.weight(.black))
                                    .foregroundStyle(position == pos ? .white : .white.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(position == pos ? KickIQAICoachTheme.accent.opacity(0.12) : Color.white.opacity(0.04))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(position == pos ? KickIQAICoachTheme.accent.opacity(0.6) : Color.white.opacity(0.06), lineWidth: position == pos ? 1.5 : 0.5)
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
                                        .foregroundStyle(KickIQAICoachTheme.accent)
                                        .font(.title3.weight(.bold))
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(skillLevel == level ? KickIQAICoachTheme.accent.opacity(0.12) : Color.white.opacity(0.04))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(skillLevel == level ? KickIQAICoachTheme.accent.opacity(0.6) : Color.white.opacity(0.06), lineWidth: skillLevel == level ? 1.5 : 0.5)
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

    // MARK: - Weakness Step (Multi-Select)

    private var weaknessStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                stepHeader(title: "SKILL WEAKNESSES", subtitle: "Select all that apply")

                VStack(spacing: 10) {
                    ForEach(WeaknessArea.allCases) { area in
                        let isSelected = selectedWeaknesses.contains(area)
                        Button {
                            if isSelected {
                                selectedWeaknesses.remove(area)
                            } else {
                                selectedWeaknesses.insert(area)
                            }
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(isSelected ? KickIQAICoachTheme.accent : .white.opacity(0.25), lineWidth: 2)
                                        .frame(width: 24, height: 24)

                                    if isSelected {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(KickIQAICoachTheme.accent)
                                            .frame(width: 24, height: 24)

                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .black))
                                            .foregroundStyle(.white)
                                    }
                                }

                                Image(systemName: area.icon)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(isSelected ? KickIQAICoachTheme.accent : .white.opacity(0.4))
                                    .frame(width: 24)

                                Text(area.rawValue)
                                    .font(.headline.weight(.black))
                                    .foregroundStyle(isSelected ? .white : .white.opacity(0.5))

                                Spacer()
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isSelected ? KickIQAICoachTheme.accent.opacity(0.12) : Color.white.opacity(0.04))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(isSelected ? KickIQAICoachTheme.accent.opacity(0.6) : Color.white.opacity(0.06), lineWidth: isSelected ? 1.5 : 0.5)
                                    )
                            )
                        }
                        .sensoryFeedback(.selection, trigger: selectedWeaknesses.count)
                    }
                }
                .padding(.horizontal, 20)
                .animation(.spring(response: 0.3), value: selectedWeaknesses)
            }
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Conditioning Step (Multi-Select)

    private var conditioningStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                stepHeader(title: "CONDITIONING", subtitle: "Select all that apply")

                VStack(spacing: 10) {
                    ForEach(ConditioningFocus.allCases) { focus in
                        let isSelected = selectedConditioning.contains(focus)
                        Button {
                            if isSelected {
                                selectedConditioning.remove(focus)
                            } else {
                                selectedConditioning.insert(focus)
                            }
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(isSelected ? KickIQAICoachTheme.accent : .white.opacity(0.25), lineWidth: 2)
                                        .frame(width: 24, height: 24)

                                    if isSelected {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(KickIQAICoachTheme.accent)
                                            .frame(width: 24, height: 24)

                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .black))
                                            .foregroundStyle(.white)
                                    }
                                }

                                Image(systemName: focus.icon)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(isSelected ? KickIQAICoachTheme.accent : .white.opacity(0.4))
                                    .frame(width: 24)

                                Text(focus.rawValue)
                                    .font(.headline.weight(.black))
                                    .foregroundStyle(isSelected ? .white : .white.opacity(0.5))

                                Spacer()
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isSelected ? KickIQAICoachTheme.accent.opacity(0.12) : Color.white.opacity(0.04))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(isSelected ? KickIQAICoachTheme.accent.opacity(0.6) : Color.white.opacity(0.06), lineWidth: isSelected ? 1.5 : 0.5)
                                    )
                            )
                        }
                        .sensoryFeedback(.selection, trigger: selectedConditioning.count)
                    }
                }
                .padding(.horizontal, 20)
                .animation(.spring(response: 0.3), value: selectedConditioning)
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
                    .fill(KickIQAICoachTheme.accent.opacity(0.08))
                    .frame(width: 120, height: 120)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(KickIQAICoachTheme.accent)
                    .symbolEffect(.bounce, value: currentStep == 5)
            }

            VStack(spacing: 16) {
                Text("Most players\nnever improve.")
                    .font(.system(size: 30, weight: .black))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)

                Text("Because no one tells them what to fix.")
                    .font(.title3.weight(.bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(KickIQAICoachTheme.accent)

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
                    paywallPlanCard(index: 0, title: "Annual", price: "$99.99/yr", perWeek: "$1.92/week", badge: "BEST VALUE", trialText: "3-day free trial")
                    paywallPlanCard(index: 1, title: "Monthly", price: "$19.99/mo", perWeek: "$4.99/week", badge: nil, trialText: nil)
                    paywallPlanCard(index: 2, title: "Weekly", price: "$6.99/wk", perWeek: nil, badge: nil, trialText: nil)
                }
                .padding(.horizontal, 20)

                Button {
                    Task { await handleSubscribe() }
                } label: {
                    Group {
                        if isPurchasing {
                            ProgressView()
                                .tint(KickIQAICoachTheme.onAccent)
                        } else {
                            Text(selectedPlanIndex == 0 ? "Start Free Trial" : "Subscribe")
                                .font(.headline.weight(.black))
                        }
                    }
                    .foregroundStyle(KickIQAICoachTheme.onAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [KickIQAICoachTheme.accent, KickIQAICoachTheme.accent.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: .rect(cornerRadius: 16)
                    )
                    .shadow(color: KickIQAICoachTheme.accent.opacity(0.3), radius: 12, x: 0, y: 4)
                }
                .disabled(isPurchasing || isRestoring)
                .padding(.horizontal, 20)
                .sensoryFeedback(.impact(weight: .medium), trigger: isPurchasing)

                Button {
                    Task { await handleRestore() }
                } label: {
                    Group {
                        if isRestoring {
                            ProgressView()
                                .tint(.white.opacity(0.4))
                        } else {
                            Text("Restore Purchases")
                        }
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.4))
                }
                .disabled(isPurchasing || isRestoring)

                Button {
                    completeOnboarding()
                } label: {
                    Text("Continue without subscribing")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.25))
                }
                .disabled(isPurchasing || isRestoring)

                VStack(spacing: 4) {
                    Text("Cancel anytime. No commitment.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.3))
                    HStack(spacing: 12) {
                        Button("Privacy Policy") { showLegalPage = .privacyPolicy }
                        Text("·").foregroundStyle(.white.opacity(0.2))
                        Button("Terms of Service") { showLegalPage = .termsOfUse }
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
        let isDisabled: Bool = {
            switch currentStep {
            case 3: return selectedWeaknesses.isEmpty
            default: return false
            }
        }()

        return Button {
            withAnimation(.spring(response: 0.4)) { currentStep += 1 }
        } label: {
            Text("Continue")
                .font(.headline.weight(.black))
                .foregroundStyle(isDisabled ? .white.opacity(0.3) : KickIQAICoachTheme.onAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: isDisabled
                            ? [Color.white.opacity(0.1), Color.white.opacity(0.06)]
                            : [KickIQAICoachTheme.accent, KickIQAICoachTheme.accent.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: .rect(cornerRadius: 16)
                )
                .shadow(color: isDisabled ? .clear : KickIQAICoachTheme.accent.opacity(0.3), radius: 12, x: 0, y: 4)
        }
        .disabled(isDisabled)
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
                    .foregroundStyle(KickIQAICoachTheme.accent)
                    .font(.title3.weight(.bold))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelected ? KickIQAICoachTheme.accent.opacity(0.12) : Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelected ? KickIQAICoachTheme.accent.opacity(0.6) : Color.white.opacity(0.06), lineWidth: isSelected ? 1.5 : 0.5)
                )
        )
    }

    private func testimonialCard(name: String, age: String, result: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(KickIQAICoachTheme.accent.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Text(String(name.prefix(1)))
                        .font(.headline.weight(.black))
                        .foregroundStyle(KickIQAICoachTheme.accent)
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
                            .foregroundStyle(KickIQAICoachTheme.accent)
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

    private func paywallPlanCard(index: Int, title: String, price: String, perWeek: String?, badge: String?, trialText: String?) -> some View {
        let isSelected = selectedPlanIndex == index
        return Button {
            selectedPlanIndex = index
        } label: {
            HStack {
                ZStack {
                    Circle()
                        .stroke(isSelected ? KickIQAICoachTheme.accent : Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(KickIQAICoachTheme.accent)
                            .frame(width: 14, height: 14)
                            .transition(.scale)
                    }
                }
                .animation(.spring(response: 0.25), value: isSelected)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline.weight(.black))
                            .foregroundStyle(.white)

                        if let badge {
                            Text(badge)
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(KickIQAICoachTheme.onAccent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(KickIQAICoachTheme.accent, in: Capsule())
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
                            .foregroundStyle(KickIQAICoachTheme.accent)
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
                    .fill(isSelected ? KickIQAICoachTheme.accent.opacity(0.1) : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? KickIQAICoachTheme.accent.opacity(0.5) : Color.white.opacity(0.06), lineWidth: isSelected ? 1.5 : 0.5)
                    )
            )
        }
        .sensoryFeedback(.selection, trigger: selectedPlanIndex)
    }

    private func handleSubscribe() async {
        guard let offerings = storeVM.offerings,
              let defaultOffering = offerings.current else {
            completeOnboarding()
            return
        }

        let planIdentifiers = ["$rc_annual", "$rc_monthly", "$rc_weekly"]
        let targetID = planIdentifiers[selectedPlanIndex]
        guard let package = defaultOffering.availablePackages.first(where: { $0.identifier == targetID }) else {
            completeOnboarding()
            return
        }

        isPurchasing = true
        await storeVM.purchase(package: package)
        isPurchasing = false
        completeOnboarding()
    }

    private func handleRestore() async {
        isRestoring = true
        await storeVM.restore()
        isRestoring = false
        if storeVM.isPremium {
            completeOnboarding()
        }
    }

    private func completeOnboarding() {
        let weaknessArray = Array(selectedWeaknesses)
        let conditioningArray = Array(selectedConditioning)
        let profile = PlayerProfile(
            name: "Player",
            position: position,
            ageRange: ageRange,
            skillLevel: skillLevel,
            weakness: weaknessArray.first ?? .firstTouch,
            weaknesses: weaknessArray.isEmpty ? [.firstTouch] : weaknessArray,
            conditioningPreferences: conditioningArray,
            gender: .male
        )
        storage.saveProfile(profile)
        storage.completeOnboarding()
    }
}
