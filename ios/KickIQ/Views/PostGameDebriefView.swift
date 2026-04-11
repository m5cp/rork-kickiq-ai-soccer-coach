import SwiftUI

struct PostGameDebriefView: View {
    let storage: StorageService
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep: DebriefStep = .howDidItGo
    @State private var gameRating: Int = 3
    @State private var whatWentWell: String = ""
    @State private var whatWentWrong: String = ""
    @State private var specificMoments: String = ""
    @State private var isGenerating: Bool = false
    @State private var aiResponse: String = ""
    @State private var appeared: Bool = false

    private enum DebriefStep: Int, CaseIterable {
        case howDidItGo = 0
        case whatWorked = 1
        case struggles = 2
        case moments = 3
        case generating = 4
        case results = 5
    }

    var body: some View {
        NavigationStack {
            ZStack {
                KickIQTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    progressIndicator
                        .padding(.top, KickIQTheme.Spacing.sm)

                    ScrollView {
                        VStack(spacing: KickIQTheme.Spacing.lg) {
                            stepContent
                        }
                        .padding(.horizontal, KickIQTheme.Spacing.md)
                        .padding(.bottom, KickIQTheme.Spacing.xl)
                    }
                    .scrollIndicators(.hidden)

                    if currentStep != .generating && currentStep != .results {
                        continueButton
                    }
                }
            }
            .navigationTitle("Post-Game Debrief")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
    }

    private var progressIndicator: some View {
        let total = DebriefStep.allCases.count
        let current = currentStep.rawValue + 1

        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(KickIQTheme.divider)
                    .frame(height: 4)
                Capsule()
                    .fill(KickIQTheme.accent)
                    .frame(width: geo.size.width * Double(current) / Double(total), height: 4)
                    .animation(.spring(response: 0.3), value: currentStep)
            }
        }
        .frame(height: 4)
        .padding(.horizontal, KickIQTheme.Spacing.md)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .howDidItGo:
            ratingStep
        case .whatWorked:
            textInputStep(
                icon: "hand.thumbsup.fill",
                title: "WHAT WENT WELL?",
                subtitle: "What did you feel confident about?",
                placeholder: "e.g. My passing was accurate, I won most headers...",
                text: $whatWentWell
            )
        case .struggles:
            textInputStep(
                icon: "exclamationmark.triangle.fill",
                title: "WHAT WAS TOUGH?",
                subtitle: "Where did you struggle?",
                placeholder: "e.g. Lost the ball under pressure, couldn't finish chances...",
                text: $whatWentWrong
            )
        case .moments:
            textInputStep(
                icon: "lightbulb.fill",
                title: "KEY MOMENTS",
                subtitle: "Any specific plays or situations that stood out?",
                placeholder: "e.g. Missed a 1v1 with the keeper in the 70th minute...",
                text: $specificMoments
            )
        case .generating:
            generatingView
        case .results:
            resultsView
        }
    }

    private var ratingStep: some View {
        VStack(spacing: KickIQTheme.Spacing.xl) {
            Spacer().frame(height: KickIQTheme.Spacing.lg)

            Image(systemName: "soccerball")
                .font(.system(size: 56))
                .foregroundStyle(KickIQTheme.accent)
                .symbolEffect(.bounce, value: appeared)

            VStack(spacing: KickIQTheme.Spacing.sm) {
                Text("HOW DID THE GAME GO?")
                    .font(.system(.title3, design: .default, weight: .black).width(.compressed))
                    .tracking(2)
                    .foregroundStyle(KickIQTheme.textPrimary)

                Text("Rate your overall performance")
                    .font(.subheadline)
                    .foregroundStyle(KickIQTheme.textSecondary)
            }

            HStack(spacing: KickIQTheme.Spacing.md) {
                ForEach(1...5, id: \.self) { rating in
                    Button {
                        gameRating = rating
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: rating <= gameRating ? "star.fill" : "star")
                                .font(.system(size: 32))
                                .foregroundStyle(rating <= gameRating ? KickIQTheme.accent : KickIQTheme.textSecondary.opacity(0.3))

                            Text(ratingLabel(rating))
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(rating == gameRating ? KickIQTheme.accent : KickIQTheme.textSecondary.opacity(0.5))
                        }
                    }
                    .sensoryFeedback(.selection, trigger: gameRating)
                }
            }
            .padding(.vertical, KickIQTheme.Spacing.md)
        }
    }

    private func textInputStep(icon: String, title: String, subtitle: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(spacing: KickIQTheme.Spacing.lg) {
            Spacer().frame(height: KickIQTheme.Spacing.md)

            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(KickIQTheme.accent)

            VStack(spacing: KickIQTheme.Spacing.sm) {
                Text(title)
                    .font(.system(.title3, design: .default, weight: .black).width(.compressed))
                    .tracking(2)
                    .foregroundStyle(KickIQTheme.textPrimary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(KickIQTheme.textSecondary)
            }

            TextField("", text: text, prompt: Text(placeholder).foregroundStyle(KickIQTheme.textSecondary.opacity(0.4)), axis: .vertical)
                .font(.body)
                .foregroundStyle(KickIQTheme.textPrimary)
                .lineLimit(4...8)
                .padding(KickIQTheme.Spacing.md)
                .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                        .stroke(KickIQTheme.divider, lineWidth: 1)
                )
        }
    }

    private var generatingView: some View {
        VStack(spacing: KickIQTheme.Spacing.xl) {
            Spacer().frame(height: KickIQTheme.Spacing.xxl)

            ProgressView()
                .controlSize(.large)
                .tint(KickIQTheme.accent)

            VStack(spacing: KickIQTheme.Spacing.sm) {
                Text("Analyzing Your Game")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(KickIQTheme.textPrimary)

                Text("Your AI coach is building a personalized drill plan...")
                    .font(.subheadline)
                    .foregroundStyle(KickIQTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
    }

    private var resultsView: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.lg) {
            VStack(spacing: KickIQTheme.Spacing.sm) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(KickIQTheme.accent)

                Text("Your Debrief")
                    .font(.title2.weight(.black))
                    .foregroundStyle(KickIQTheme.textPrimary)
            }
            .frame(maxWidth: .infinity)

            Text(aiResponse)
                .font(.body)
                .foregroundStyle(KickIQTheme.textPrimary.opacity(0.9))
                .lineSpacing(4)
                .padding(KickIQTheme.Spacing.md)
                .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, KickIQTheme.Spacing.md)
                    .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
            }
        }
    }

    private var continueButton: some View {
        Button {
            advanceStep()
        } label: {
            Text("Continue")
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, KickIQTheme.Spacing.md)
                .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
        }
        .padding(.horizontal, KickIQTheme.Spacing.md)
        .padding(.bottom, KickIQTheme.Spacing.md)
        .sensoryFeedback(.impact(weight: .medium), trigger: currentStep)
    }

    private func advanceStep() {
        switch currentStep {
        case .howDidItGo:
            withAnimation(.spring(response: 0.4)) { currentStep = .whatWorked }
        case .whatWorked:
            withAnimation(.spring(response: 0.4)) { currentStep = .struggles }
        case .struggles:
            withAnimation(.spring(response: 0.4)) { currentStep = .moments }
        case .moments:
            withAnimation(.spring(response: 0.4)) { currentStep = .generating }
            generateDebrief()
        case .generating, .results:
            break
        }
    }

    private func generateDebrief() {
        Task {
            isGenerating = true
            do {
                let response = try await callDebriefAI()
                aiResponse = response
                withAnimation(.spring(response: 0.5)) { currentStep = .results }
            } catch {
                aiResponse = buildFallbackResponse()
                withAnimation(.spring(response: 0.5)) { currentStep = .results }
            }
            isGenerating = false
        }
    }

    private func callDebriefAI() async throws -> String {
        let toolkitURL = Config.EXPO_PUBLIC_TOOLKIT_URL
        guard !toolkitURL.isEmpty else {
            return buildFallbackResponse()
        }

        let url = URL(string: "\(toolkitURL)/agent/chat")!
        let profile = storage.profile
        let position = profile?.position.rawValue ?? "Unknown"
        let weakness = profile?.weakness.rawValue ?? "Unknown"
        let name = profile?.name ?? "Player"

        let systemPrompt = """
        You are KickIQ Coach. A player just finished a game and is doing a post-game debrief. Based on their self-assessment, provide:
        1. A brief analysis of their performance
        2. 3-5 specific drills they should do this week to address their struggles
        3. Encouragement based on what went well

        Keep it concise, actionable, and athlete-friendly. Format with clear sections.
        """

        let userMessage = """
        Player: \(name), Position: \(position), Weakness area: \(weakness)
        Game rating: \(gameRating)/5
        What went well: \(whatWentWell.isEmpty ? "Not specified" : whatWentWell)
        What was tough: \(whatWentWrong.isEmpty ? "Not specified" : whatWentWrong)
        Key moments: \(specificMoments.isEmpty ? "Not specified" : specificMoments)
        """

        let body: [String: Any] = [
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userMessage]
            ]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let secretKey = Config.EXPO_PUBLIC_RORK_TOOLKIT_SECRET_KEY
        if !secretKey.isEmpty {
            request.setValue("Bearer \(secretKey)", forHTTPHeaderField: "Authorization")
        }
        let appKey = ConfigHelper.value(forKey: "EXPO_PUBLIC_RORK_APP_KEY")
        if !appKey.isEmpty {
            request.setValue(appKey, forHTTPHeaderField: "x-app-key")
        }
        let projectId = Config.EXPO_PUBLIC_PROJECT_ID
        if !projectId.isEmpty {
            request.setValue(projectId, forHTTPHeaderField: "x-project-id")
        }
        request.httpBody = jsonData
        request.timeoutInterval = 60

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return buildFallbackResponse()
        }

        let responseText = String(data: data, encoding: .utf8) ?? ""
        let parsed = parseResponseText(responseText)
        return parsed.isEmpty ? buildFallbackResponse() : parsed
    }

    private func parseResponseText(_ response: String) -> String {
        if response.contains("data: ") {
            var collected = ""
            let lines = response.components(separatedBy: "\n")
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard trimmed.hasPrefix("data: ") else { continue }
                let payload = String(trimmed.dropFirst(6))
                if payload == "[DONE]" { break }
                guard let data = payload.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { continue }
                if let text = json["text"] as? String { collected += text }
                else if let delta = json["delta"] as? [String: Any], let content = delta["content"] as? String { collected += content }
                else if let choices = json["choices"] as? [[String: Any]], let first = choices.first, let d = first["delta"] as? [String: Any], let content = d["content"] as? String { collected += content }
                else if let content = json["content"] as? String { collected += content }
                else if let type = json["type"] as? String, type == "content_block_delta", let delta = json["delta"] as? [String: Any], let text = delta["text"] as? String { collected += text }
            }
            return collected.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let data = response.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let text = json["text"] as? String { return text }
            if let content = json["content"] as? String { return content }
            if let message = json["message"] as? String { return message }
        }

        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("{") || trimmed.hasPrefix("[") { return "" }
        return trimmed
    }

    private func buildFallbackResponse() -> String {
        let position = storage.profile?.position.rawValue ?? "Player"
        let weakness = storage.profile?.weakness.rawValue ?? "overall skills"

        var response = "**Game Analysis (\(gameRating)/5)**\n\n"

        if !whatWentWell.isEmpty {
            response += "**Strengths:** Great to hear about your confidence in \(whatWentWell.prefix(60)). Keep building on this.\n\n"
        }

        if !whatWentWrong.isEmpty {
            response += "**Areas to Work On:** Based on your struggles with \(whatWentWrong.prefix(60)), here are drills to focus on:\n\n"
        } else {
            response += "**Recommended Drills for \(position)s:**\n\n"
        }

        response += "1. **Quick Feet Circuit** — 10 min of cone work to sharpen your \(weakness)\n"
        response += "2. **Pressure Training** — Work on receiving and turning under simulated pressure\n"
        response += "3. **1v1 Box Drill** — Improve your decision-making in tight spaces\n\n"

        if gameRating >= 4 {
            response += "Strong performance! Keep this momentum going in training this week."
        } else if gameRating >= 3 {
            response += "Solid effort. Focus on the drills above this week and you'll see improvement."
        } else {
            response += "Every player has tough games. The drills above will help you bounce back stronger."
        }

        return response
    }

    private func ratingLabel(_ rating: Int) -> String {
        switch rating {
        case 1: "Rough"
        case 2: "Okay"
        case 3: "Solid"
        case 4: "Great"
        case 5: "Elite"
        default: ""
        }
    }
}
