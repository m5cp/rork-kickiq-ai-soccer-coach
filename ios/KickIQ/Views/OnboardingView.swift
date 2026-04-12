import SwiftUI
import RevenueCat

struct OnboardingView: View {
    let storage: StorageService
    @State private var store = StoreViewModel.shared
    @State private var currentStep: Int = 0
    @State private var name: String = ""
    @State private var position: PlayerPosition = .midfielder
    @State private var ageRange: AgeRange = .sixteen18
    @State private var skillLevel: SkillLevel = .beginner
    @State private var weakness: WeaknessArea = .firstTouch
    @State private var userRole: UserRole = .player
    @State private var appeared = false
    @State private var selectedPackage: Package?

    private var isCoachPath: Bool { userRole == .coach }

    private var totalSteps: Int { isCoachPath ? 7 : 10 }

    private var currentStepTags: [Int] {
        if isCoachPath {
            return Array(0..<7)
        } else {
            return Array(0..<10)
        }
    }

    private var showContinueButton: Bool {
        currentStep < (totalSteps - 1)
    }

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
                    if isCoachPath {
                        nameStep.tag(0)
                        roleStep.tag(1)
                        coachValueStep.tag(2)
                        coachFeaturesStep.tag(3)
                        coachSetupStep.tag(4)
                        coachSocialProofStep.tag(5)
                        coachPaywallStep.tag(6)
                    } else {
                        nameStep.tag(0)
                        roleStep.tag(1)
                        positionStep.tag(2)
                        ageStep.tag(3)
                        skillLevelStep.tag(4)
                        weaknessStep.tag(5)
                        painStep.tag(6)
                        howItWorksStep.tag(7)
                        socialProofStep.tag(8)
                        playerPaywallStep.tag(9)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.4), value: currentStep)

                if showContinueButton {
                    continueButton
                }
            }
        }
        .onChange(of: userRole) { _, newRole in
            if currentStep > 1 {
                withAnimation(.spring(response: 0.3)) {
                    currentStep = 1
                }
            }
            selectedPackage = nil
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

                Text("So we can personalize your experience")
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

    // MARK: - Step 1: Role
    private var roleStep: some View {
        ScrollView {
            VStack(spacing: KickIQTheme.Spacing.lg) {
                stepHeader(title: "I AM A...", subtitle: "This helps us tailor your experience")

                VStack(spacing: 12) {
                    ForEach(UserRole.allCases) { role in
                        Button {
                            userRole = role
                        } label: {
                            HStack(spacing: KickIQTheme.Spacing.md) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(userRole == role ? KickIQTheme.accent.opacity(0.2) : KickIQTheme.card)
                                        .frame(width: 52, height: 52)
                                    Image(systemName: role.icon)
                                        .font(.title2)
                                        .foregroundStyle(userRole == role ? KickIQTheme.accent : KickIQTheme.textSecondary)
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(role.rawValue)
                                        .font(.headline)
                                        .foregroundStyle(userRole == role ? KickIQTheme.textPrimary : KickIQTheme.textSecondary)
                                    Text(role.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(KickIQTheme.textSecondary)
                                }

                                Spacer()

                                if userRole == role {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(KickIQTheme.accent)
                                }
                            }
                            .padding(KickIQTheme.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                                    .fill(userRole == role ? KickIQTheme.accent.opacity(0.08) : KickIQTheme.card)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                                            .stroke(userRole == role ? KickIQTheme.accent : Color.clear, lineWidth: 1.5)
                                    )
                            )
                        }
                        .sensoryFeedback(.selection, trigger: userRole)
                    }
                }

                if userRole == .coach {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .font(.caption)
                            .foregroundStyle(KickIQTheme.accent)
                        Text("Coach path: manage teams, assign drills, track every player")
                            .font(.caption)
                            .foregroundStyle(KickIQTheme.textSecondary)
                    }
                    .padding(KickIQTheme.Spacing.sm + 2)
                    .background(KickIQTheme.accent.opacity(0.08), in: .rect(cornerRadius: KickIQTheme.Radius.sm))
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.horizontal, KickIQTheme.Spacing.md + 4)
            .padding(.bottom, KickIQTheme.Spacing.xl)
        }
        .scrollIndicators(.hidden)
        .animation(.spring(response: 0.3), value: userRole)
    }

    // MARK: - Coach Path Step 2: Value Proposition
    private var coachValueStep: some View {
        VStack(spacing: KickIQTheme.Spacing.xl) {
            Spacer()

            Image(systemName: "whistle.fill")
                .font(.system(size: 56))
                .foregroundStyle(KickIQTheme.accent)
                .symbolEffect(.bounce, value: currentStep == 2)

            VStack(spacing: KickIQTheme.Spacing.md) {
                Text("YOUR TEAM.\nYOUR DATA.\nYOUR EDGE.")
                    .font(.system(.title, design: .default, weight: .black))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(KickIQTheme.textPrimary)

                Text("Stop guessing. KickIQ gives you AI-powered\ninsights on every player, every session.")
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

    // MARK: - Coach Path Step 3: Features
    private var coachFeaturesStep: some View {
        ScrollView {
            VStack(spacing: KickIQTheme.Spacing.lg) {
                stepHeader(title: "WHAT YOU GET", subtitle: "Built for coaches who want to win")

                VStack(spacing: KickIQTheme.Spacing.md) {
                    coachFeatureRow(icon: "person.3.fill", title: "Unlimited Players", subtitle: "Invite your entire roster — no player limits, ever", free: true)
                    coachFeatureRow(icon: "list.clipboard.fill", title: "Custom Drill Plans", subtitle: "Build & assign training plans to individuals or the team", free: true)
                    coachFeatureRow(icon: "chart.bar.doc.horizontal.fill", title: "Team Reports", subtitle: "See who's improving, who needs work, export to PDF", free: true)
                    coachFeatureRow(icon: "brain.head.profile.fill", title: "AI Video Analysis", subtitle: "AI breaks down each player's technique automatically", free: false)
                    coachFeatureRow(icon: "bubble.left.and.bubble.right.fill", title: "AI Coach Chat", subtitle: "Ask the AI for drill ideas, session plans, injury tips", free: false)
                    coachFeatureRow(icon: "square.and.arrow.up.fill", title: "Data Export", subtitle: "Export player stats, reports, and progress data", free: true)
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
            }
            .padding(.bottom, KickIQTheme.Spacing.lg)
        }
        .scrollIndicators(.hidden)
    }

    private func coachFeatureRow(icon: String, title: String, subtitle: String, free: Bool) -> some View {
        HStack(spacing: KickIQTheme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(KickIQTheme.accent.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(KickIQTheme.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(KickIQTheme.textPrimary)
                    if free {
                        Text("FREE")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.15), in: Capsule())
                    } else {
                        Text("PRO")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(KickIQTheme.accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(KickIQTheme.accent.opacity(0.15), in: Capsule())
                    }
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(KickIQTheme.textSecondary)
            }

            Spacer()
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
    }

    // MARK: - Coach Path Step 4: What You Can Set Up
    private var coachSetupStep: some View {
        VStack(spacing: KickIQTheme.Spacing.xl) {
            Spacer()

            Text("SET UP IN MINUTES")
                .font(.system(.title2, design: .default, weight: .black).width(.compressed))
                .tracking(2)
                .foregroundStyle(KickIQTheme.textPrimary)

            VStack(spacing: KickIQTheme.Spacing.lg) {
                howItWorksRow(step: "1", icon: "person.crop.rectangle.stack.fill", title: "Create Team", subtitle: "Set up your team and invite players via QR code")
                howItWorksRow(step: "2", icon: "list.clipboard.fill", title: "Assign Drills", subtitle: "Build plans and push them to any player")
                howItWorksRow(step: "3", icon: "chart.line.uptrend.xyaxis", title: "Track Progress", subtitle: "Watch the whole team improve with real data")
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, KickIQTheme.Spacing.lg)
    }

    // MARK: - Coach Path Step 5: Social Proof
    private var coachSocialProofStep: some View {
        ScrollView {
            VStack(spacing: KickIQTheme.Spacing.lg) {
                stepHeader(title: "COACHES LOVE KICKIQ", subtitle: "See what other coaches are saying")

                VStack(spacing: KickIQTheme.Spacing.md) {
                    coachTestimonialCard(name: "Coach Davis", team: "U16 Academy", result: "Replaced three spreadsheets and a WhatsApp group. My players actually follow their drill plans now.")
                    coachTestimonialCard(name: "Coach Ramirez", team: "Club Premier", result: "The AI analysis spotted a footwork issue in my striker I'd been missing for weeks. Game changer.")
                    coachTestimonialCard(name: "Coach Patel", team: "High School Varsity", result: "Parents love seeing their kid's progress reports. Saves me hours of paperwork every week.")
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
            }
            .padding(.bottom, KickIQTheme.Spacing.lg)
        }
        .scrollIndicators(.hidden)
    }

    private func coachTestimonialCard(name: String, team: String, result: String) -> some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            HStack(spacing: KickIQTheme.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(KickIQTheme.accent.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "whistle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(KickIQTheme.accent)
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text(name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KickIQTheme.textPrimary)
                    Text(team)
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

    // MARK: - Coach Paywall Step
    private var coachPaywallStep: some View {
        ScrollView {
            VStack(spacing: KickIQTheme.Spacing.lg) {
                VStack(spacing: KickIQTheme.Spacing.sm) {
                    Text("UNLOCK COACH PRO")
                        .font(.system(.title2, design: .default, weight: .black).width(.compressed))
                        .tracking(2)
                        .foregroundStyle(KickIQTheme.textPrimary)

                    Text("Free coaching tools + AI power")
                        .font(.subheadline)
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
                .padding(.top, KickIQTheme.Spacing.lg)

                coachFreeVsProComparison

                if let current = store.offerings?.current {
                    VStack(spacing: 10) {
                        ForEach(sortedOnboardingPackages(current.availablePackages), id: \.identifier) { package in
                            onboardingPricingCard(package: package, isCoach: true)
                        }
                    }
                    .padding(.horizontal, KickIQTheme.Spacing.md)

                    Button {
                        guard let pkg = selectedPackage else {
                            completeOnboarding()
                            return
                        }
                        Task { await store.purchase(package: pkg) }
                    } label: {
                        Group {
                            if store.isPurchasing {
                                ProgressView().tint(.black)
                            } else {
                                Text(onboardingSubscribeText)
                                    .font(.headline)
                                    .foregroundStyle(.black)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, KickIQTheme.Spacing.md)
                        .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
                    }
                    .disabled(store.isPurchasing)
                    .padding(.horizontal, KickIQTheme.Spacing.md)
                    .sensoryFeedback(.impact(weight: .medium), trigger: store.isPurchasing)
                } else if store.isLoading {
                    ProgressView()
                        .padding(.vertical, KickIQTheme.Spacing.xl)
                } else {
                    coachFallbackPricing

                    Button {
                        completeOnboarding()
                    } label: {
                        Text("Continue Free")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, KickIQTheme.Spacing.md)
                            .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
                    }
                    .padding(.horizontal, KickIQTheme.Spacing.md)
                }

                paywallFooter
            }
        }
        .scrollIndicators(.hidden)
        .onChange(of: store.isPremium) { _, isPremium in
            if isPremium { completeOnboarding() }
        }
    }

    private var coachFreeVsProComparison: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                comparisonItem(icon: "person.3.fill", title: "Players", free: "Unlimited", pro: "Unlimited")
                comparisonItem(icon: "list.clipboard.fill", title: "Drill Plans", free: "Unlimited", pro: "Unlimited")
            }
            HStack(spacing: 10) {
                comparisonItem(icon: "brain.head.profile.fill", title: "AI Chat", free: "10/day", pro: "Up to 500/day")
                comparisonItem(icon: "video.fill", title: "AI Analysis", free: "2/day", pro: "Up to 100/day")
            }
            HStack(spacing: 10) {
                comparisonItem(icon: "chart.bar.doc.horizontal.fill", title: "Reports", free: "Basic", pro: "Full + Export")
                comparisonItem(icon: "square.and.arrow.up.fill", title: "Data Export", free: "CSV", pro: "CSV + PDF")
            }
        }
        .padding(.horizontal, KickIQTheme.Spacing.md)
    }

    private func comparisonItem(icon: String, title: String, free: String, pro: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(KickIQTheme.accent)
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(KickIQTheme.textPrimary)
            }

            HStack(spacing: 4) {
                Circle()
                    .fill(KickIQTheme.textSecondary.opacity(0.3))
                    .frame(width: 6, height: 6)
                Text(free)
                    .font(.system(size: 10))
                    .foregroundStyle(KickIQTheme.textSecondary)
            }

            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.green)
                Text(pro)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(KickIQTheme.textPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(KickIQTheme.Spacing.sm + 4)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
    }

    private var coachFallbackPricing: some View {
        VStack(spacing: 10) {
            pricingCard(title: "Annual", price: "$149.99/yr", perWeek: "$2.88/week", badge: "BEST VALUE", isHighlighted: true, trialText: "7-day free trial, then $149.99/year")
            pricingCard(title: "Monthly", price: "$24.99/mo", perWeek: "$6.25/week", badge: nil, isHighlighted: false, trialText: nil)
            pricingCard(title: "Weekly", price: "$9.99/wk", perWeek: nil, badge: nil, isHighlighted: false, trialText: nil)
        }
        .padding(.horizontal, KickIQTheme.Spacing.md)
    }

    // MARK: - Player Path Steps (2-8)
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

    private var painStep: some View {
        VStack(spacing: KickIQTheme.Spacing.xl) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(KickIQTheme.accent)
                .symbolEffect(.bounce, value: currentStep == 6)

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

    // MARK: - Player Paywall Step
    private var playerPaywallStep: some View {
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

                playerFreeVsProGrid

                if let current = store.offerings?.current {
                    VStack(spacing: 10) {
                        ForEach(sortedOnboardingPackages(current.availablePackages), id: \.identifier) { package in
                            onboardingPricingCard(package: package, isCoach: false)
                        }
                    }
                    .padding(.horizontal, KickIQTheme.Spacing.md)

                    Button {
                        guard let pkg = selectedPackage else {
                            completeOnboarding()
                            return
                        }
                        Task { await store.purchase(package: pkg) }
                    } label: {
                        Group {
                            if store.isPurchasing {
                                ProgressView().tint(.black)
                            } else {
                                Text(onboardingSubscribeText)
                                    .font(.headline)
                                    .foregroundStyle(.black)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, KickIQTheme.Spacing.md)
                        .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
                    }
                    .disabled(store.isPurchasing)
                    .padding(.horizontal, KickIQTheme.Spacing.md)
                    .sensoryFeedback(.impact(weight: .medium), trigger: store.isPurchasing)
                } else if store.isLoading {
                    ProgressView()
                        .padding(.vertical, KickIQTheme.Spacing.xl)
                } else {
                    VStack(spacing: 10) {
                        pricingCard(title: "Annual", price: "$99.99/yr", perWeek: "$1.92/week", badge: "BEST VALUE", isHighlighted: true, trialText: "3-day free trial, then $99.99/year")
                        pricingCard(title: "Monthly", price: "$19.99/mo", perWeek: "$4.99/week", badge: nil, isHighlighted: false, trialText: nil)
                        pricingCard(title: "Weekly", price: "$6.99/wk", perWeek: nil, badge: nil, isHighlighted: false, trialText: nil)
                    }
                    .padding(.horizontal, KickIQTheme.Spacing.md)

                    Button {
                        completeOnboarding()
                    } label: {
                        Text("Continue Free")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, KickIQTheme.Spacing.md)
                            .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
                    }
                    .padding(.horizontal, KickIQTheme.Spacing.md)
                }

                paywallFooter
            }
        }
        .scrollIndicators(.hidden)
        .onChange(of: store.isPremium) { _, isPremium in
            if isPremium { completeOnboarding() }
        }
    }

    private var playerFreeVsProGrid: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                comparisonItem(icon: "brain.head.profile.fill", title: "AI Chat", free: "10/day", pro: "Up to 500/day")
                comparisonItem(icon: "video.fill", title: "Video Analysis", free: "2/day", pro: "Up to 100/day")
            }
            HStack(spacing: 10) {
                comparisonItem(icon: "figure.soccer", title: "Custom Drills", free: "Basic", pro: "Advanced + AI")
                comparisonItem(icon: "chart.line.uptrend.xyaxis", title: "Progress", free: "7-day", pro: "Full History")
            }
        }
        .padding(.horizontal, KickIQTheme.Spacing.md)
    }

    // MARK: - Shared Paywall Components
    private var paywallFooter: some View {
        VStack(spacing: KickIQTheme.Spacing.sm) {
            HStack(spacing: KickIQTheme.Spacing.lg) {
                Button {
                    Task { await store.restore() }
                } label: {
                    Text("Restore Purchases")
                        .font(.subheadline)
                        .foregroundStyle(KickIQTheme.textSecondary)
                }

                Button {
                    completeOnboarding()
                } label: {
                    Text("Continue Free")
                        .font(.subheadline)
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
            }

            VStack(spacing: 4) {
                if let pkg = selectedPackage {
                    Text(onboardingBillingDisclosure(for: pkg))
                        .font(.caption2)
                        .foregroundStyle(KickIQTheme.textSecondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, KickIQTheme.Spacing.md)
                }
                HStack(spacing: KickIQTheme.Spacing.md) {
                    NavigationLink("Privacy Policy") {
                        LegalPageView(page: .privacyPolicy)
                    }
                    Text("·").foregroundStyle(KickIQTheme.textSecondary.opacity(0.4))
                    NavigationLink("Terms of Service") {
                        LegalPageView(page: .termsOfUse)
                    }
                }
                .font(.caption2)
                .foregroundStyle(KickIQTheme.textSecondary.opacity(0.5))
            }
            .padding(.bottom, KickIQTheme.Spacing.lg)
        }
    }

    private func sortedOnboardingPackages(_ packages: [Package]) -> [Package] {
        let order = ["$rc_annual", "$rc_monthly", "$rc_weekly"]
        return packages.sorted { a, b in
            let ai = order.firstIndex(of: a.identifier) ?? 99
            let bi = order.firstIndex(of: b.identifier) ?? 99
            return ai < bi
        }
    }

    private func onboardingPricingCard(package: Package, isCoach: Bool) -> some View {
        let isSelected = selectedPackage?.identifier == package.identifier
        let isAnnual = package.identifier == "$rc_annual"
        let product = package.storeProduct

        return Button {
            withAnimation(.spring(response: 0.3)) {
                selectedPackage = package
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: KickIQTheme.Spacing.sm) {
                        Text(product.localizedTitle)
                            .font(.headline)
                            .foregroundStyle(KickIQTheme.textPrimary)

                        if isAnnual {
                            Text("BEST VALUE")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(KickIQTheme.accent, in: Capsule())
                        }
                    }

                    Text(tierDescription(for: package, isCoach: isCoach))
                        .font(.caption2)
                        .foregroundStyle(KickIQTheme.textSecondary)

                    if let intro = product.introductoryDiscount {
                        Text(onboardingIntroText(intro, price: product.localizedPriceString, package: package))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(KickIQTheme.accent)
                    }
                }

                Spacer()

                Text(product.localizedPriceString)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(KickIQTheme.textPrimary)
            }
            .padding(KickIQTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                    .fill(isSelected ? KickIQTheme.accent.opacity(0.12) : KickIQTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                            .stroke(isSelected ? KickIQTheme.accent : KickIQTheme.divider, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .sensoryFeedback(.selection, trigger: isSelected)
        .onAppear {
            if isAnnual && selectedPackage == nil {
                selectedPackage = package
            }
        }
    }

    private func tierDescription(for package: Package, isCoach: Bool) -> String {
        if isCoach {
            switch package.identifier {
            case "$rc_annual": return "500 AI chats/day · 100 analyses · Full reports"
            case "$rc_monthly": return "150 AI chats/day · 30 analyses · Full reports"
            case "$rc_weekly": return "50 AI chats/day · 10 analyses · Basic reports"
            default: return ""
            }
        } else {
            switch package.identifier {
            case "$rc_annual": return "500 AI chats/day · 100 analyses · All features"
            case "$rc_monthly": return "150 AI chats/day · 30 analyses · All features"
            case "$rc_weekly": return "50 AI chats/day · 10 analyses · All features"
            default: return ""
            }
        }
    }

    private func onboardingIntroText(_ discount: StoreProductDiscount, price: String, package: Package) -> String {
        let value = discount.subscriptionPeriod.value
        let unit: String
        switch discount.subscriptionPeriod.unit {
        case .day: unit = value == 1 ? "day" : "days"
        case .week: unit = value == 1 ? "week" : "weeks"
        case .month: unit = value == 1 ? "month" : "months"
        case .year: unit = value == 1 ? "year" : "years"
        @unknown default: unit = "period"
        }
        let suffix: String
        switch package.identifier {
        case "$rc_annual": suffix = "/year"
        case "$rc_monthly": suffix = "/month"
        case "$rc_weekly": suffix = "/week"
        default: suffix = ""
        }
        return "\(value)-\(unit) free trial, then \(price)\(suffix)"
    }

    private var onboardingSubscribeText: String {
        guard let pkg = selectedPackage else { return "Continue" }
        if pkg.storeProduct.introductoryDiscount != nil {
            return "Start Free Trial"
        }
        return "Subscribe Now"
    }

    private func onboardingBillingDisclosure(for package: Package) -> String {
        let price = package.storeProduct.localizedPriceString
        let suffix: String
        switch package.identifier {
        case "$rc_annual": suffix = "year"
        case "$rc_monthly": suffix = "month"
        case "$rc_weekly": suffix = "week"
        default: suffix = "period"
        }
        if let intro = package.storeProduct.introductoryDiscount {
            let value = intro.subscriptionPeriod.value
            let unit: String
            switch intro.subscriptionPeriod.unit {
            case .day: unit = value == 1 ? "day" : "days"
            case .week: unit = value == 1 ? "week" : "weeks"
            case .month: unit = value == 1 ? "month" : "months"
            case .year: unit = value == 1 ? "year" : "years"
            @unknown default: unit = "period"
            }
            return "After the \(value)-\(unit) free trial, auto-renews at \(price)/\(suffix). Cancel anytime in Settings > Subscriptions at least 24 hours before the trial ends."
        }
        return "Auto-renews at \(price)/\(suffix). Cancel anytime in Settings > Subscriptions."
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
            name: name.isEmpty ? (isCoachPath ? "Coach" : "Player") : name.trimmingCharacters(in: .whitespaces),
            position: position,
            ageRange: ageRange,
            skillLevel: skillLevel,
            weakness: weakness,
            userRole: userRole
        )
        storage.saveProfile(profile)
        storage.completeOnboarding()
    }
}
