import SwiftUI

struct AICoachView: View {
    let storage: StorageService
    let isPremium: Bool
    var storeVM: StoreViewModel
    @State private var coachService: AICoachService
    @State private var inputText: String = ""
    @State private var appeared = false
    @State private var showTokenPacks = false
    @State private var showPaywall = false
    @FocusState private var isInputFocused: Bool
    @State private var safety = AgeSafetyService.shared
    @State private var reportingMessage: CoachMessage?

    private let playerPrompts = [
        "What should I work on today?",
        "Give me a 20-min drill session",
        "How are my benchmark scores?",
        "Tips for game day preparation"
    ]

    private let coachPrompts = [
        "Build a 45-min pressing session for U14",
        "Design a preseason week focused on fitness",
        "Give me 3 drills for improving transitions",
        "How should I periodize a 12-week season?"
    ]

    private var isCoach: Bool {
        storage.profile?.position == .coachTrainer
    }

    private var quickPrompts: [String] {
        isCoach ? coachPrompts : playerPrompts
    }

    init(storage: StorageService, isPremium: Bool = false, storeVM: StoreViewModel) {
        self.storage = storage
        self.isPremium = isPremium
        self.storeVM = storeVM
        _coachService = State(initialValue: AICoachService(storage: storage, isPremium: isPremium))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                KickIQAICoachTheme.background.ignoresSafeArea()

                if !safety.isChatAllowed {
                    chatLockedView
                } else {
                    VStack(spacing: 0) {
                        if coachService.messages.isEmpty {
                            emptyState
                        } else {
                            messageList
                        }

                        inputBar
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(KickIQAICoachTheme.accent.opacity(0.2))
                                .frame(width: 30, height: 30)
                            Image(systemName: "brain.head.profile.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(KickIQAICoachTheme.accent)
                        }
                        VStack(alignment: .leading, spacing: 0) {
                            Text("AI COACH")
                                .font(.system(.subheadline, design: .default, weight: .black))
                                .tracking(1.5)
                                .foregroundStyle(KickIQAICoachTheme.textPrimary)
                            Text(isCoach ? "Coach mode" : "Player mode")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(0.8)
                                .foregroundStyle(KickIQAICoachTheme.accent)
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 10) {
                        Button {
                            showTokenPacks = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 10))
                                Text(coachService.formattedTokensRemaining)
                                    .font(.system(size: 11, weight: .black))
                                Text(isPremium ? "PRO" : "FREE")
                                    .font(.system(size: 8, weight: .black))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(isPremium ? Color.yellow.opacity(0.3) : Color.gray.opacity(0.3), in: .rect(cornerRadius: 3))
                            }
                            .foregroundStyle(coachService.tokensRemaining <= 30 ? .red : .orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(KickIQAICoachTheme.surface, in: Capsule())
                        }

                        if !coachService.messages.isEmpty {
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    coachService.clearHistory()
                                }
                            } label: {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showTokenPacks) {
                TokenPacksView(storage: storage, storeVM: storeVM, showSubscriptionUpsell: !isPremium)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(store: storeVM)
            }
            .sheet(item: $reportingMessage) { message in
                ReportContentSheet(contextLabel: "AI Coach response") { _ in
                    if let index = coachService.messages.firstIndex(where: { $0.id == message.id }) {
                        coachService.messages.remove(at: index)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
            if !coachService.hasShownOnboarding && coachService.messages.isEmpty {
                coachService.startOnboardingConversation()
            }
        }
    }

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: KickIQAICoachTheme.Spacing.xl) {
                Spacer().frame(height: 20)

                VStack(spacing: KickIQAICoachTheme.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [KickIQAICoachTheme.accent.opacity(0.2), KickIQAICoachTheme.accent.opacity(0.02)],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 70
                                )
                            )
                            .frame(width: 120, height: 120)

                        Circle()
                            .stroke(KickIQAICoachTheme.accent.opacity(0.2), lineWidth: 1.5)
                            .frame(width: 100, height: 100)

                        Image(systemName: "brain.head.profile.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(KickIQAICoachTheme.accent)
                            .symbolEffect(.pulse, isActive: appeared)
                    }

                    VStack(spacing: 8) {
                        HStack(spacing: 5) {
                            Image(systemName: isCoach ? "clipboard.fill" : "figure.soccer")
                                .font(.system(size: 9, weight: .bold))
                            Text(isCoach ? "COACH MODE" : "PLAYER MODE")
                                .font(.system(size: 10, weight: .black))
                                .tracking(1.2)
                        }
                        .foregroundStyle(KickIQAICoachTheme.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(KickIQAICoachTheme.accent.opacity(0.12), in: Capsule())
                        .overlay(Capsule().stroke(KickIQAICoachTheme.accent.opacity(0.3), lineWidth: 1))

                        Text(isCoach ? "YOUR AI ASSISTANT" : "YOUR AI COACH")
                            .font(.system(.title3, design: .default, weight: .black))
                            .tracking(2)
                            .foregroundStyle(KickIQAICoachTheme.textPrimary)

                        Text(isCoach
                            ? "Session design, periodization, and\nplayer insights. Ask me anything."
                            : "I know your scores, your streaks, and\nyour weak spots. Ask me anything.")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 6) {
                            Image(systemName: isPremium ? "crown.fill" : "person.fill")
                                .font(.system(size: 10))
                            Text(isPremium ? "Premium · 750 tokens/day" : "Free · 100 tokens/day")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundStyle(isPremium ? .yellow : KickIQAICoachTheme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background((isPremium ? Color.yellow : KickIQAICoachTheme.textSecondary).opacity(0.12), in: Capsule())
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 15)

                VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
                    Text("TRY ASKING")
                        .font(.caption.weight(.bold))
                        .tracking(1)
                        .foregroundStyle(KickIQAICoachTheme.accent)
                        .padding(.leading, 4)

                    ForEach(quickPrompts, id: \.self) { prompt in
                        Button {
                            inputText = prompt
                            Task { await sendMessage() }
                        } label: {
                            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                                Image(systemName: "sparkle")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(KickIQAICoachTheme.accent)

                                Text(prompt)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(KickIQAICoachTheme.textPrimary)

                                Spacer()

                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.body)
                                    .foregroundStyle(KickIQAICoachTheme.accent.opacity(0.5))
                            }
                            .padding(KickIQAICoachTheme.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.md)
                                    .fill(KickIQAICoachTheme.card)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.md)
                                            .stroke(KickIQAICoachTheme.accent.opacity(0.1), lineWidth: 1)
                                    )
                            )
                        }
                    }
                }
                .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(.spring(response: 0.5).delay(0.15), value: appeared)

                coachInfoCard
                    .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5).delay(0.25), value: appeared)
            }
            .padding(.bottom, KickIQAICoachTheme.Spacing.lg)
        }
        .scrollIndicators(.hidden)
    }

    private var coachInfoCard: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                infoChip(icon: "figure.soccer", text: storage.profile?.position.rawValue ?? "Player")
                infoChip(icon: "chart.bar.fill", text: storage.profile?.skillLevel.rawValue ?? "Intermediate")
                infoChip(icon: "target", text: storage.profile?.weakness.rawValue ?? "First Touch")
            }

            Text("Coach remembers your scores and adapts over time")
                .font(.caption.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.5))
        }
    }

    private func infoChip(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
            Text(text)
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundStyle(KickIQAICoachTheme.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(KickIQAICoachTheme.surface, in: Capsule())
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: KickIQAICoachTheme.Spacing.md) {
                    ForEach(coachService.messages) { message in
                        messageBubble(message)
                            .id(message.id)
                    }

                    if coachService.isLoading {
                        typingIndicator
                            .id("typing")
                    }
                }
                .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                .padding(.vertical, KickIQAICoachTheme.Spacing.md)
            }
            .scrollIndicators(.hidden)
            .onChange(of: coachService.messages.count) { _, _ in
                withAnimation(.spring(response: 0.3)) {
                    if coachService.isLoading {
                        proxy.scrollTo("typing", anchor: .bottom)
                    } else if let last = coachService.messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: coachService.isLoading) { _, loading in
                if loading {
                    withAnimation(.spring(response: 0.3)) {
                        proxy.scrollTo("typing", anchor: .bottom)
                    }
                }
            }
        }
    }

    private func messageBubble(_ message: CoachMessage) -> some View {
        HStack(alignment: .top, spacing: 10) {
            if message.role == .coach {
                ZStack {
                    Circle()
                        .fill(KickIQAICoachTheme.accent.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: "brain.head.profile.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(message.role == .user ? KickIQAICoachTheme.onAccent : KickIQAICoachTheme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        message.role == .user
                            ? AnyShapeStyle(KickIQAICoachTheme.accent)
                            : AnyShapeStyle(KickIQAICoachTheme.card),
                        in: RoundedRectangle(
                            cornerRadius: 18,
                            style: .continuous
                        )
                    )
                    .if(message.role == .coach) { view in
                        view.overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(KickIQAICoachTheme.accent.opacity(0.08), lineWidth: 1)
                        )
                    }

                if message.role == .coach && !message.content.contains("no tokens used") {
                    Button {
                        reportingMessage = message
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "flag.fill").font(.system(size: 9, weight: .bold))
                            Text("Report").font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.5))
                    }
                }
                if message.role == .coach && message.content.contains("no tokens used") && coachService.lastFailedUserText != nil {
                    Button {
                        Task { await coachService.retryLastMessage() }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11, weight: .bold))
                            Text("Retry")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(KickIQAICoachTheme.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(KickIQAICoachTheme.accent.opacity(0.15), in: Capsule())
                    }
                } else {
                    Text(message.timestamp, style: .time)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.4))
                }
            }
            .frame(maxWidth: 300, alignment: message.role == .user ? .trailing : .leading)

            if message.role == .user {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }

    private var typingIndicator: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(KickIQAICoachTheme.accent.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(KickIQAICoachTheme.accent)
                    .symbolEffect(.pulse, isActive: true)
            }

            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(KickIQAICoachTheme.accent.opacity(0.6))
                        .frame(width: 7, height: 7)
                        .offset(y: coachService.isLoading ? -4 : 0)
                        .animation(
                            .easeInOut(duration: 0.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.15),
                            value: coachService.isLoading
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(KickIQAICoachTheme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            if coachService.isAtLimit {
                tokenLimitBanner
            }

            Divider()
                .overlay(KickIQAICoachTheme.divider)

            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                TextField("Ask your coach...", text: $inputText, axis: .vertical)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    .lineLimit(1...4)
                    .focused($isInputFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        Task { await sendMessage() }
                    }
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") { isInputFocused = false }
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(KickIQAICoachTheme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(isInputFocused ? KickIQAICoachTheme.accent.opacity(0.4) : KickIQAICoachTheme.divider.opacity(0.5), lineWidth: 1)
                    )

                Button {
                    Task { await sendMessage() }
                } label: {
                    ZStack {
                        Circle()
                            .fill(canSend ? KickIQAICoachTheme.accent : KickIQAICoachTheme.accent.opacity(0.3))
                            .frame(width: 38, height: 38)
                        Image(systemName: "arrow.up")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(canSend ? KickIQAICoachTheme.onAccent : KickIQAICoachTheme.onAccent.opacity(0.5))
                    }
                }
                .disabled(!canSend)
                .sensoryFeedback(.impact(weight: .medium), trigger: coachService.messages.count)
            }
            .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
            .padding(.vertical, KickIQAICoachTheme.Spacing.sm + 2)
        }
        .background(.ultraThinMaterial)
    }

    private var tokenLimitBanner: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                Image(systemName: "bolt.trianglebadge.exclamationmark.fill")
                    .font(.subheadline)
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Out of tokens")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    Text(isPremium ? "Daily budget used · resets at midnight" : "Free plan: 100 tokens/day")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }

                Spacer()
            }

            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                Button {
                    showTokenPacks = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                        Text("Buy Tokens")
                            .font(.caption.weight(.black))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(.orange, in: .rect(cornerRadius: 8))
                }

                if !isPremium {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 10))
                            Text("Go Pro · 7.5x More")
                                .font(.caption.weight(.black))
                        }
                        .foregroundStyle(KickIQAICoachTheme.onAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(KickIQAICoachTheme.accent, in: .rect(cornerRadius: 8))
                    }
                }
            }
        }
        .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
        .padding(.vertical, KickIQAICoachTheme.Spacing.sm + 2)
        .background(.orange.opacity(0.08))
    }

    private var chatLockedView: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle().fill(KickIQAICoachTheme.accent.opacity(0.1)).frame(width: 120, height: 120)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundStyle(KickIQAICoachTheme.accent)
            }
            VStack(spacing: 10) {
                Text("AI Coach Locked")
                    .font(.title2.weight(.black))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                Text("A parent or guardian needs to turn on AI Coach in Parental Controls before you can chat.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            Text("Settings → Parental Controls")
                .font(.caption.weight(.bold))
                .foregroundStyle(KickIQAICoachTheme.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(KickIQAICoachTheme.accent.opacity(0.1), in: Capsule())
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !coachService.isLoading && !coachService.isAtLimit
    }

    private func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !coachService.isLoading else { return }
        inputText = ""
        isInputFocused = false
        await coachService.sendMessage(text)
    }
}

private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
