import SwiftUI

struct PlanGeneratorSheet: View {
    let storage: StorageService
    let planType: GeneratedPlanType
    let onPlanGenerated: (GeneratedPlan) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var weeks: Int = 4
    @State private var daysPerWeek: Int = 5
    @State private var minutesPerSession: Int = 45
    @State private var selectedSkillFocuses: Set<String> = []
    @State private var selectedConditioningFocuses: Set<String> = []
    @State private var isGenerating = false
    @State private var appeared = false

    private var focusOptions: [String] {
        if planType == .skills {
            return (storage.profile?.position.skills ?? SkillCategory.allCases).map(\.rawValue)
        } else {
            return ConditioningFocus.allCases.map(\.rawValue)
        }
    }

    private var selectedFocuses: Set<String> {
        planType == .skills ? selectedSkillFocuses : selectedConditioningFocuses
    }

    private var canGenerate: Bool {
        !selectedFocuses.isEmpty && !isGenerating
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQAICoachTheme.Spacing.lg) {
                    headerSection
                    durationSection
                    frequencySection
                    sessionTimeSection
                    focusSection
                    generateButton
                }
                .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                .padding(.bottom, KickIQAICoachTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQAICoachTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.body.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.background)
        .onAppear {
            if planType == .skills {
                selectedSkillFocuses = Set(focusOptions)
            } else {
                selectedConditioningFocuses = Set(focusOptions)
            }
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
        }
    }

    private var headerSection: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(KickIQAICoachTheme.accent.opacity(0.15))
                    .frame(width: 64, height: 64)
                Image(systemName: planType == .skills ? "figure.soccer" : "heart.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(KickIQAICoachTheme.accent)
            }

            Text("GENERATE \(planType.rawValue.uppercased()) PLAN")
                .font(.caption.weight(.black))
                .tracking(2)
                .foregroundStyle(KickIQAICoachTheme.accent)

            Text("Build your personalized\n\(planType == .skills ? "skills training" : "conditioning") program")
                .font(.title3.weight(.bold))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, KickIQAICoachTheme.Spacing.md)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            Label("PLAN DURATION", systemImage: "calendar")
                .font(.caption.weight(.black))
                .tracking(1)
                .foregroundStyle(KickIQAICoachTheme.accent)

            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                Text("\(weeks)")
                    .font(.system(size: 36, weight: .black))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    .contentTransition(.numericText())
                    .frame(width: 50)

                Text(weeks == 1 ? "week" : "weeks")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)

                Spacer()

                HStack(spacing: KickIQAICoachTheme.Spacing.md) {
                    Button {
                        if weeks > 1 { withAnimation(.spring(response: 0.3)) { weeks -= 1 } }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(weeks > 1 ? KickIQAICoachTheme.accent : KickIQAICoachTheme.textSecondary.opacity(0.3))
                    }
                    .disabled(weeks <= 1)

                    Button {
                        if weeks < 12 { withAnimation(.spring(response: 0.3)) { weeks += 1 } }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(weeks < 12 ? KickIQAICoachTheme.accent : KickIQAICoachTheme.textSecondary.opacity(0.3))
                    }
                    .disabled(weeks >= 12)
                }
            }
            .sensoryFeedback(.selection, trigger: weeks)
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.4).delay(0.05), value: appeared)
    }

    private var frequencySection: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            Label("DAYS PER WEEK", systemImage: "repeat")
                .font(.caption.weight(.black))
                .tracking(1)
                .foregroundStyle(KickIQAICoachTheme.accent)

            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                Text("\(daysPerWeek)")
                    .font(.system(size: 36, weight: .black))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    .contentTransition(.numericText())
                    .frame(width: 50)

                Text(daysPerWeek == 1 ? "day" : "days")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)

                Spacer()

                HStack(spacing: KickIQAICoachTheme.Spacing.md) {
                    Button {
                        if daysPerWeek > 3 { withAnimation(.spring(response: 0.3)) { daysPerWeek -= 1 } }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(daysPerWeek > 3 ? KickIQAICoachTheme.accent : KickIQAICoachTheme.textSecondary.opacity(0.3))
                    }
                    .disabled(daysPerWeek <= 3)

                    Button {
                        if daysPerWeek < 7 { withAnimation(.spring(response: 0.3)) { daysPerWeek += 1 } }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(daysPerWeek < 7 ? KickIQAICoachTheme.accent : KickIQAICoachTheme.textSecondary.opacity(0.3))
                    }
                    .disabled(daysPerWeek >= 7)
                }
            }
            .sensoryFeedback(.selection, trigger: daysPerWeek)

            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { day in
                    let index = ["M", "T", "W", "T", "F", "S", "S"].firstIndex(of: day) ?? 0
                    Circle()
                        .fill(index < daysPerWeek ? KickIQAICoachTheme.accent : KickIQAICoachTheme.divider)
                        .frame(width: 28, height: 28)
                        .overlay {
                            Text(day)
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(index < daysPerWeek ? KickIQAICoachTheme.onAccent : KickIQAICoachTheme.textSecondary)
                        }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.4).delay(0.1), value: appeared)
    }

    private var sessionTimeSection: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            Label("TIME PER SESSION", systemImage: "clock.fill")
                .font(.caption.weight(.black))
                .tracking(1)
                .foregroundStyle(KickIQAICoachTheme.accent)

            let timeOptions = [15, 30, 45, 60, 90]
            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                ForEach(timeOptions, id: \.self) { mins in
                    Button {
                        withAnimation(.spring(response: 0.3)) { minutesPerSession = mins }
                    } label: {
                        Text("\(mins)m")
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(minutesPerSession == mins ? KickIQAICoachTheme.onAccent : KickIQAICoachTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(minutesPerSession == mins ? KickIQAICoachTheme.accent : KickIQAICoachTheme.surface, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
                    }
                }
            }
            .sensoryFeedback(.selection, trigger: minutesPerSession)
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.4).delay(0.15), value: appeared)
    }

    private var focusSection: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            HStack {
                Label("FOCUS AREAS", systemImage: "target")
                    .font(.caption.weight(.black))
                    .tracking(1)
                    .foregroundStyle(KickIQAICoachTheme.accent)
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        if selectedFocuses.count == focusOptions.count {
                            if planType == .skills { selectedSkillFocuses.removeAll() } else { selectedConditioningFocuses.removeAll() }
                        } else {
                            if planType == .skills { selectedSkillFocuses = Set(focusOptions) } else { selectedConditioningFocuses = Set(focusOptions) }
                        }
                    }
                } label: {
                    Text(selectedFocuses.count == focusOptions.count ? "Deselect All" : "Select All")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: KickIQAICoachTheme.Spacing.sm)], spacing: KickIQAICoachTheme.Spacing.sm) {
                ForEach(focusOptions, id: \.self) { focus in
                    let isSelected = selectedFocuses.contains(focus)
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            if planType == .skills {
                                if isSelected { selectedSkillFocuses.remove(focus) } else { selectedSkillFocuses.insert(focus) }
                            } else {
                                if isSelected { selectedConditioningFocuses.remove(focus) } else { selectedConditioningFocuses.insert(focus) }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: iconFor(focus))
                                .font(.system(size: 12))
                            Text(focus)
                                .font(.caption.weight(.bold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(isSelected ? KickIQAICoachTheme.onAccent : KickIQAICoachTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 8)
                        .background(isSelected ? KickIQAICoachTheme.accent : KickIQAICoachTheme.surface, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
                    }
                    .sensoryFeedback(.selection, trigger: isSelected)
                }
            }
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.4).delay(0.2), value: appeared)
    }

    private var generateButton: some View {
        Button {
            Task { await generatePlan() }
        } label: {
            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                if isGenerating {
                    ProgressView()
                        .tint(KickIQAICoachTheme.onAccent)
                } else {
                    Image(systemName: "sparkles")
                }
                Text(isGenerating ? "Generating Plan..." : "Generate \(planType.rawValue) Plan")
            }
            .font(.headline.weight(.black))
            .foregroundStyle(KickIQAICoachTheme.onAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(canGenerate ? KickIQAICoachTheme.accent : KickIQAICoachTheme.textSecondary.opacity(0.3), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        }
        .disabled(!canGenerate)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.4).delay(0.25), value: appeared)
    }

    private func iconFor(_ focus: String) -> String {
        if let skill = SkillCategory.allCases.first(where: { $0.rawValue == focus }) {
            return skill.icon
        }
        if let cond = ConditioningFocus.allCases.first(where: { $0.rawValue == focus }) {
            return cond.icon
        }
        return "circle.fill"
    }

    private func generatePlan() async {
        isGenerating = true

        let position = storage.profile?.position ?? .midfielder
        let skillLevel = storage.profile?.skillLevel ?? .intermediate
        let focuses = Array(selectedFocuses)

        let config = PlanConfig(
            planType: planType,
            weeks: weeks,
            daysPerWeek: daysPerWeek,
            minutesPerSession: minutesPerSession,
            focusAreas: focuses
        )

        let focusNames = focuses.joined(separator: ", ")
        let prompt = """
        You are an expert soccer coach creating a personalized \(planType.rawValue.lowercased()) training plan.

        Player Profile:
        - Position: \(position.rawValue)
        - Skill Level: \(skillLevel.rawValue)
        - Plan Type: \(planType.rawValue)

        Plan Configuration:
        - Duration: \(weeks) weeks
        - Training Days Per Week: \(daysPerWeek)
        - Time Per Session: \(minutesPerSession) minutes
        - Focus Areas: \(focusNames)

        Create a \(weeks)-week \(planType.rawValue.lowercased()) plan. Each week has 7 days, with \(daysPerWeek) training days and \(7 - daysPerWeek) rest days.

        Respond ONLY with valid JSON:
        {
            "summary": "Brief overview of the plan",
            "weeks": [
                {
                    "weekNumber": 1,
                    "days": [
                        {
                            "dayLabel": "Monday",
                            "focus": "\(planType == .skills ? "Ball Control & First Touch" : "Speed & Agility")",
                            "restDay": false,
                            "drills": [
                                {"name": "Drill Name", "description": "How to do it", "duration": "15 min", "difficulty": "\(skillLevel.rawValue)", "targetSkill": "\(focuses.first ?? "General")", "reps": "3x10"}
                            ]
                        },
                        {
                            "dayLabel": "Tuesday",
                            "focus": "Rest & Recovery",
                            "restDay": true,
                            "drills": []
                        }
                    ]
                }
            ]
        }

        Each training day should have 3-5 drills totaling approximately \(minutesPerSession) minutes.
        Distribute the focus areas across the training days. Progressive overload across weeks.
        \(planType == .conditioning ? "Include warm-up and cool-down in each session." : "Target the focus skills with varied drill types.")
        """

        do {
            let toolkitURL = Config.EXPO_PUBLIC_TOOLKIT_URL
            guard !toolkitURL.isEmpty else {
                let plan = generateFallbackPlan(config: config, position: position)
                storage.saveGeneratedPlan(plan)
                onPlanGenerated(plan)
                isGenerating = false
                dismiss()
                return
            }

            let url = URL(string: "\(toolkitURL)/agent/chat")!
            let messages: [[String: Any]] = [["role": "user", "content": prompt]]
            let body: [String: Any] = ["messages": messages]
            let jsonData = try JSONSerialization.data(withJSONObject: body)

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            request.timeoutInterval = 90

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let plan = generateFallbackPlan(config: config, position: position)
                storage.saveGeneratedPlan(plan)
                onPlanGenerated(plan)
                isGenerating = false
                dismiss()
                return
            }

            let responseText = String(data: data, encoding: .utf8) ?? ""
            let jsonString = extractJSON(from: responseText)

            guard let jsonResponseData = jsonString.data(using: .utf8) else {
                let plan = generateFallbackPlan(config: config, position: position)
                storage.saveGeneratedPlan(plan)
                onPlanGenerated(plan)
                isGenerating = false
                dismiss()
                return
            }

            let aiResponse = try JSONDecoder().decode(AIGeneratedPlanResponse.self, from: jsonResponseData)

            let planWeeks = aiResponse.weeks.map { week in
                GeneratedPlanWeek(
                    weekNumber: week.weekNumber,
                    days: week.days.map { day in
                        TrainingPlanDay(
                            dayLabel: day.dayLabel,
                            focus: day.focus,
                            drills: (day.drills ?? []).map { d in
                                Drill(name: d.name, description: d.description, duration: d.duration, targetSkill: d.targetSkill, reps: d.reps ?? "")
                            },
                            restDay: day.restDay
                        )
                    }
                )
            }

            let plan = GeneratedPlan(config: config, weeks: planWeeks, summary: aiResponse.summary)
            storage.saveGeneratedPlan(plan)
            onPlanGenerated(plan)
        } catch {
            let plan = generateFallbackPlan(config: config, position: position)
            storage.saveGeneratedPlan(plan)
            onPlanGenerated(plan)
        }

        isGenerating = false
        dismiss()
    }

    private func extractJSON(from text: String) -> String {
        if let start = text.firstIndex(of: "{"),
           let end = text.lastIndex(of: "}") {
            return String(text[start...end])
        }
        return text
    }

    private func generateFallbackPlan(config: PlanConfig, position: PlayerPosition) -> GeneratedPlan {
        let dayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        let focuses = config.focusAreas

        var planWeeks: [GeneratedPlanWeek] = []

        for weekNum in 1...config.weeks {
            let days: [TrainingPlanDay] = dayNames.enumerated().map { index, name in
                let isTraining = index < config.daysPerWeek
                let focusArea = focuses.isEmpty ? "General" : focuses[index % focuses.count]

                return TrainingPlanDay(
                    dayLabel: name,
                    focus: isTraining ? focusArea : "Rest & Recovery",
                    drills: isTraining ? generateFallbackDrills(focus: focusArea, minutes: config.minutesPerSession, weekNum: weekNum) : [],
                    restDay: !isTraining
                )
            }
            planWeeks.append(GeneratedPlanWeek(weekNumber: weekNum, days: days))
        }

        return GeneratedPlan(
            config: config,
            weeks: planWeeks,
            summary: "A \(config.weeks)-week \(config.planType.rawValue.lowercased()) program training \(config.daysPerWeek) days per week, \(config.minutesPerSession) minutes per session. Focused on: \(focuses.joined(separator: ", "))."
        )
    }

    private func generateFallbackDrills(focus: String, minutes: Int, weekNum: Int) -> [Drill] {
        let drillCount = max(2, minutes / 15)
        let perDrillTime = minutes / drillCount

        return (1...drillCount).map { i in
            Drill(
                name: "\(focus) Drill \(i) — Week \(weekNum)",
                description: "Progressive \(focus.lowercased()) training exercise. Increase intensity in later weeks.",
                duration: "\(perDrillTime) min",
                targetSkill: focus,
                reps: "\(2 + weekNum) sets of \(8 + weekNum)"
            )
        }
    }
}

nonisolated struct AIGeneratedPlanResponse: Codable, Sendable {
    let summary: String
    let weeks: [AIGeneratedPlanWeek]
}

nonisolated struct AIGeneratedPlanWeek: Codable, Sendable {
    let weekNumber: Int
    let days: [AIPlanDay]
}
