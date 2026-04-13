import SwiftUI

struct AICoachView: View {
    let storage: StorageService
    @State private var coachService: AICoachService
    @State private var inputText: String = ""
    @State private var appeared = false
    @FocusState private var isInputFocused: Bool

    private let quickPrompts = [
        "How can I improve my weak foot?",
        "Give me a 20-min drill session",
        "Tips for game day preparation",
        "How do I read the game better?"
    ]

    init(storage: StorageService) {
        self.storage = storage
        let profile = storage.profile
        var benchmarkSummary = ""
        if !storage.benchmarkResults.isEmpty {
            let lines = storage.benchmarkResults.compactMap { result -> String? in
                guard let latest = result.latestScore else { return nil }
                return "- \(result.drillName) (\(result.category.rawValue)): \(BenchmarkView.formatScore(latest)) — \(result.trend.label)"
            }
            benchmarkSummary = lines.joined(separator: "\n")
        }
        _coachService = State(initialValue: AICoachService(
            playerName: profile?.name ?? "Player",
            position: profile?.position.rawValue ?? "Midfielder",
            skillLevel: profile?.skillLevel.rawValue ?? "Intermediate",
            weakness: profile?.weakness.rawValue ?? "First Touch",
            benchmarkSummary: benchmarkSummary
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                KickIQAICoachTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    if coachService.messages.isEmpty {
                        emptyState
                    } else {
                        messageList
                    }

                    inputBar
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
                        Text("AI COACH")
                            .font(.system(.subheadline, design: .default, weight: .black))
                            .tracking(1.5)
                            .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
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
                        Text("YOUR AI COACH")
                            .font(.system(.title3, design: .default, weight: .black))
                            .tracking(2)
                            .foregroundStyle(KickIQAICoachTheme.textPrimary)

                        Text("Ask me anything about soccer training,\ntechnique, drills, or game strategy.")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                            .multilineTextAlignment(.center)
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

            Text("Coach adapts to your profile automatically")
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

                Text(message.timestamp, style: .time)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.4))
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

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !coachService.isLoading
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
