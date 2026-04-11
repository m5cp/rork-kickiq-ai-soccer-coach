import SwiftUI

struct AICoachChatView: View {
    let storage: StorageService
    @Environment(\.dismiss) private var dismiss
    @State private var chatService = AIChatService()
    @State private var tokenService = ChatTokenService.shared
    @State private var inputText: String = ""
    @State private var showTokenStore = false
    @State private var appeared = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                tokenBar
                Divider().overlay(KickIQTheme.divider)

                if chatService.messages.isEmpty {
                    welcomeState
                } else {
                    messagesList
                }

                if let reason = tokenService.limitReason {
                    limitBanner(reason)
                }

                inputBar
            }
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle("AI Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(KickIQTheme.accent)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            chatService.clearChat()
                        } label: {
                            Label("New Session", systemImage: "arrow.counterclockwise")
                        }
                        Button {
                            showTokenStore = true
                        } label: {
                            Label("Get More Tokens", systemImage: "plus.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(KickIQTheme.accent)
                    }
                }
            }
            .sheet(isPresented: $showTokenStore) {
                TokenStoreSheet(tokenService: tokenService)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
        }
    }

    private var tokenBar: some View {
        HStack(spacing: KickIQTheme.Spacing.md) {
            HStack(spacing: 5) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(KickIQTheme.accent)
                Text("Session: \(max(0, 20 - tokenService.sessionMessageCount))/20")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(KickIQTheme.textSecondary)
            }

            Spacer()

            HStack(spacing: 5) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(KickIQTheme.accent)
                Text("Today: \(max(0, 60 - tokenService.dailyMessageCount))/60")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(KickIQTheme.textSecondary)
            }

            if tokenService.bonusTokens > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.yellow)
                    Text("+\(tokenService.bonusTokens)")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.yellow)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.yellow.opacity(0.15), in: Capsule())
            }
        }
        .padding(.horizontal, KickIQTheme.Spacing.md)
        .padding(.vertical, KickIQTheme.Spacing.sm + 2)
        .background(KickIQTheme.card)
    }

    private var welcomeState: some View {
        ScrollView {
            VStack(spacing: KickIQTheme.Spacing.lg) {
                Spacer().frame(height: 40)

                ZStack {
                    Circle()
                        .fill(KickIQTheme.accent.opacity(0.12))
                        .frame(width: 80, height: 80)
                    Image(systemName: "brain.head.profile.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(KickIQTheme.accent)
                }

                VStack(spacing: KickIQTheme.Spacing.sm) {
                    Text("KickIQ Coach")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(KickIQTheme.textPrimary)
                    Text("Your personal AI soccer coach.\nAsk about drills, technique, or get\nfeedback on your progress.")
                        .font(.subheadline)
                        .foregroundStyle(KickIQTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: KickIQTheme.Spacing.sm) {
                    suggestionChip("What should I work on today?")
                    suggestionChip("Explain my latest analysis results")
                    suggestionChip("Give me a drill for my weak foot")
                    suggestionChip("How can I improve my first touch?")
                }
                .padding(.horizontal, KickIQTheme.Spacing.lg)
            }
            .opacity(appeared ? 1 : 0)
        }
        .scrollIndicators(.hidden)
    }

    private func suggestionChip(_ text: String) -> some View {
        Button {
            inputText = text
            sendCurrentMessage()
        } label: {
            HStack(spacing: KickIQTheme.Spacing.sm) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundStyle(KickIQTheme.accent)
                Text(text)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(KickIQTheme.textPrimary)
                Spacer()
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(KickIQTheme.accent.opacity(0.5))
            }
            .padding(KickIQTheme.Spacing.md)
            .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
        }
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: KickIQTheme.Spacing.md) {
                    ForEach(chatService.messages) { message in
                        messageBubble(message)
                            .id(message.id)
                    }

                    if chatService.isResponding {
                        typingIndicator
                            .id("typing")
                    }
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .padding(.vertical, KickIQTheme.Spacing.md)
            }
            .scrollIndicators(.hidden)
            .onChange(of: chatService.messages.count) { _, _ in
                withAnimation(.spring(response: 0.3)) {
                    if chatService.isResponding {
                        proxy.scrollTo("typing", anchor: .bottom)
                    } else if let last = chatService.messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: chatService.isResponding) { _, responding in
                if responding {
                    withAnimation(.spring(response: 0.3)) {
                        proxy.scrollTo("typing", anchor: .bottom)
                    }
                }
            }
        }
    }

    private func messageBubble(_ message: ChatMessage) -> some View {
        HStack(alignment: .top, spacing: KickIQTheme.Spacing.sm) {
            if message.role == .user {
                Spacer(minLength: 48)
            } else {
                ZStack {
                    Circle()
                        .fill(message.isError ? Color.red.opacity(0.15) : KickIQTheme.accent.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: message.isError ? "exclamationmark.triangle.fill" : "brain.head.profile.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(message.isError ? .red : KickIQTheme.accent)
                }
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.subheadline)
                    .foregroundStyle(message.role == .user ? .white : (message.isError ? .red : KickIQTheme.textPrimary))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        message.role == .user
                            ? KickIQTheme.accent
                            : (message.isError ? Color.red.opacity(0.1) : KickIQTheme.card),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                    .textSelection(.enabled)

                Text(message.timestamp, format: .dateTime.hour().minute())
                    .font(.system(size: 10))
                    .foregroundStyle(KickIQTheme.textSecondary.opacity(0.4))
            }

            if message.role == .user {
                ZStack {
                    Circle()
                        .fill(KickIQTheme.accent.opacity(0.3))
                        .frame(width: 28, height: 28)
                    Image(systemName: "person.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(KickIQTheme.accent)
                }
            } else {
                Spacer(minLength: 48)
            }
        }
    }

    private var typingIndicator: some View {
        HStack(spacing: KickIQTheme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(KickIQTheme.accent.opacity(0.15))
                    .frame(width: 28, height: 28)
                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(KickIQTheme.accent)
                    .symbolEffect(.pulse, isActive: true)
            }

            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(KickIQTheme.textSecondary.opacity(0.4))
                        .frame(width: 7, height: 7)
                        .scaleEffect(chatService.isResponding ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.2),
                            value: chatService.isResponding
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(KickIQTheme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            Spacer()
        }
    }

    private func limitBanner(_ reason: String) -> some View {
        HStack(spacing: KickIQTheme.Spacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.subheadline)
                .foregroundStyle(.orange)

            Text(reason)
                .font(.caption)
                .foregroundStyle(KickIQTheme.textSecondary)

            Spacer()

            Button {
                if tokenService.sessionMessageCount >= 20 {
                    chatService.clearChat()
                } else {
                    showTokenStore = true
                }
            } label: {
                Text(tokenService.sessionMessageCount >= 20 ? "New Session" : "Get Tokens")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(KickIQTheme.accent, in: Capsule())
            }
        }
        .padding(.horizontal, KickIQTheme.Spacing.md)
        .padding(.vertical, KickIQTheme.Spacing.sm + 2)
        .background(Color.orange.opacity(0.08))
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider().overlay(KickIQTheme.divider)
            HStack(spacing: KickIQTheme.Spacing.sm) {
                TextField("Ask your AI coach...", text: $inputText, axis: .vertical)
                    .font(.subheadline)
                    .lineLimit(1...4)
                    .focused($isInputFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(KickIQTheme.card, in: Capsule())
                    .onSubmit { sendCurrentMessage() }

                Button {
                    sendCurrentMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(canSend ? KickIQTheme.accent : KickIQTheme.textSecondary.opacity(0.3))
                }
                .disabled(!canSend)
                .sensoryFeedback(.impact(weight: .medium), trigger: chatService.messages.count)
            }
            .padding(.horizontal, KickIQTheme.Spacing.md)
            .padding(.vertical, KickIQTheme.Spacing.sm + 2)
        }
        .background(KickIQTheme.background)
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !chatService.isResponding
        && tokenService.canSendMessage
    }

    private func sendCurrentMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, tokenService.canSendMessage else { return }
        inputText = ""
        isInputFocused = false
        Task {
            await chatService.sendMessage(text, storage: storage)
        }
    }
}

struct TokenStoreSheet: View {
    let tokenService: ChatTokenService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQTheme.Spacing.lg) {
                    VStack(spacing: KickIQTheme.Spacing.sm) {
                        ZStack {
                            Circle()
                                .fill(KickIQTheme.accent.opacity(0.12))
                                .frame(width: 72, height: 72)
                            Image(systemName: "bolt.circle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(KickIQTheme.accent)
                        }

                        Text("Chat Tokens")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(KickIQTheme.textPrimary)

                        Text("Get more messages to chat with your AI coach")
                            .font(.subheadline)
                            .foregroundStyle(KickIQTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, KickIQTheme.Spacing.md)

                    VStack(spacing: KickIQTheme.Spacing.sm) {
                        currentBalanceCard
                        tokenPackage(tokens: 20, price: "$0.99", label: "Starter Pack", icon: "bolt.fill")
                        tokenPackage(tokens: 50, price: "$1.99", label: "Training Pack", icon: "bolt.circle.fill", popular: true)
                        tokenPackage(tokens: 120, price: "$3.99", label: "Pro Pack", icon: "bolt.shield.fill")
                    }

                    VStack(spacing: KickIQTheme.Spacing.xs) {
                        Text("FREE DAILY ALLOWANCE")
                            .font(.caption.weight(.bold))
                            .tracking(1)
                            .foregroundStyle(KickIQTheme.textSecondary.opacity(0.5))
                        Text("20 messages per session · 60 messages per day")
                            .font(.caption)
                            .foregroundStyle(KickIQTheme.textSecondary.opacity(0.4))
                        Text("Bonus tokens carry over and never expire")
                            .font(.caption)
                            .foregroundStyle(KickIQTheme.textSecondary.opacity(0.4))
                    }
                    .padding(.top, KickIQTheme.Spacing.sm)
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .padding(.bottom, KickIQTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle("Token Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(KickIQTheme.accent)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
    }

    private var currentBalanceCard: some View {
        HStack(spacing: KickIQTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Current Balance")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(KickIQTheme.textSecondary)
                HStack(spacing: 6) {
                    Text("\(tokenService.bonusTokens)")
                        .font(.title.weight(.black))
                        .foregroundStyle(KickIQTheme.textPrimary)
                    Text("bonus tokens")
                        .font(.subheadline)
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Daily Left")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(KickIQTheme.textSecondary)
                Text("\(max(0, 60 - tokenService.dailyMessageCount))")
                    .font(.title.weight(.black))
                    .foregroundStyle(KickIQTheme.accent)
            }
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
    }

    private func tokenPackage(tokens: Int, price: String, label: String, icon: String, popular: Bool = false) -> some View {
        Button {
            tokenService.addBonusTokens(tokens)
            dismiss()
        } label: {
            HStack(spacing: KickIQTheme.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(KickIQTheme.accent.opacity(popular ? 0.25 : 0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(KickIQTheme.accent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(label)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(KickIQTheme.textPrimary)
                        if popular {
                            Text("BEST VALUE")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(KickIQTheme.accent, in: Capsule())
                        }
                    }
                    Text("\(tokens) extra messages")
                        .font(.caption)
                        .foregroundStyle(KickIQTheme.textSecondary)
                }

                Spacer()

                Text(price)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(KickIQTheme.accent)
            }
            .padding(KickIQTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                    .fill(KickIQTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                            .stroke(popular ? KickIQTheme.accent.opacity(0.4) : Color.clear, lineWidth: 1.5)
                    )
            )
        }
    }
}
