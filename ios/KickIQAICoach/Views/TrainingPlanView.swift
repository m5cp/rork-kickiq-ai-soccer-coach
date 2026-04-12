import SwiftUI

struct TrainingPlanView: View {
    let storage: StorageService
    @Environment(\.dismiss) private var dismiss
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var appeared = false
    @State private var expandedDay: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQAICoachTheme.Spacing.md + 4) {
                    if let plan = storage.trainingPlan {
                        planHeader(plan)
                        ForEach(plan.days) { day in
                            dayCard(day)
                        }
                        regenerateButton
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                .padding(.bottom, KickIQAICoachTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQAICoachTheme.background.ignoresSafeArea())
            .navigationTitle("Training Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.background)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
        }
    }

    private func planHeader(_ plan: TrainingPlan) -> some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("YOUR PLAN")
                        .font(.caption.weight(.bold))
                        .tracking(1)
                        .foregroundStyle(KickIQAICoachTheme.accent)
                    Text("Personalized Weekly Schedule")
                        .font(.headline)
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                }
                Spacer()
                Text("Created \(plan.createdAt, format: .dateTime.month(.abbreviated).day())")
                    .font(.caption2)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
            }

            Text(plan.summary)
                .font(.subheadline)
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
                .lineSpacing(3)
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
    }

    private func dayCard(_ day: TrainingPlanDay) -> some View {
        let isExpanded = expandedDay == day.id

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    expandedDay = isExpanded ? nil : day.id
                }
            } label: {
                HStack(spacing: KickIQAICoachTheme.Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.sm)
                            .fill(day.restDay ? Color.blue.opacity(0.15) : KickIQAICoachTheme.accent.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: day.restDay ? "bed.double.fill" : "figure.soccer")
                            .font(.title3)
                            .foregroundStyle(day.restDay ? .blue : KickIQAICoachTheme.accent)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(day.dayLabel)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(KickIQAICoachTheme.textPrimary)
                        Text(day.focus)
                            .font(.caption)
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    }

                    Spacer()

                    if !day.restDay {
                        Text("\(day.drills.count) drills")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(KickIQAICoachTheme.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(KickIQAICoachTheme.accent.opacity(0.15), in: Capsule())
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.3))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .padding(KickIQAICoachTheme.Spacing.md)

            if isExpanded && !day.restDay {
                VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
                    ForEach(day.drills) { drill in
                        HStack(alignment: .top, spacing: KickIQAICoachTheme.Spacing.sm) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundStyle(KickIQAICoachTheme.accent)
                                .padding(.top, 6)

                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(drill.name)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                                    Spacer()
                                    Text(drill.duration)
                                        .font(.caption2)
                                        .foregroundStyle(KickIQAICoachTheme.accent)
                                }
                                Text(drill.description)
                                    .font(.caption2)
                                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
                .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                .padding(.bottom, KickIQAICoachTheme.Spacing.md)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
    }

    private var emptyState: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.lg) {
            Spacer().frame(height: 40)

            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(KickIQAICoachTheme.accent.opacity(0.5))

            VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                Text("No Training Plan Yet")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)

                Text("Generate a personalized weekly training plan based on your analysis results and weak areas.")
                    .font(.subheadline)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            generateButton
        }
        .frame(maxWidth: .infinity)
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
                Text(isGenerating ? "Generating Plan..." : "Generate AI Training Plan")
            }
            .font(.headline)
            .foregroundStyle(KickIQAICoachTheme.onAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, KickIQAICoachTheme.Spacing.md)
            .background(KickIQAICoachTheme.accent, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        }
        .disabled(isGenerating)
    }

    private var regenerateButton: some View {
        Button {
            Task { await generatePlan() }
        } label: {
            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                if isGenerating {
                    ProgressView()
                        .tint(KickIQAICoachTheme.accent)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                Text(isGenerating ? "Regenerating..." : "Regenerate Plan")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(KickIQAICoachTheme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(KickIQAICoachTheme.accent.opacity(0.15), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
        }
        .disabled(isGenerating)
    }

    private func generatePlan() async {
        isGenerating = true
        errorMessage = nil

        let position = storage.profile?.position ?? .midfielder
        let weakness = storage.profile?.weakness ?? .firstTouch
        let skillLevel = storage.profile?.skillLevel ?? .intermediate
        let weakSkills = storage.weakestSkills
        let latestScore = storage.sessions.first?.overallScore ?? 0
        let goalSessions = storage.weeklyGoal?.sessionsPerWeek ?? 3

        let weakSkillNames = weakSkills.map(\.rawValue).joined(separator: ", ")

        let prompt = """
        You are an expert soccer coach creating a personalized 7-day training plan.

        Player Profile:
        - Position: \(position.rawValue)
        - Skill Level: \(skillLevel.rawValue)
        - Weakness: \(weakness.rawValue)
        - Weakest Skills: \(weakSkillNames.isEmpty ? "Not assessed yet" : weakSkillNames)
        - Current Score: \(latestScore)/100
        - Weekly Goal: \(goalSessions) sessions per week

        Create a 7-day training plan (Monday-Sunday). Include \(goalSessions) training days and \(7 - goalSessions) rest/recovery days.

        Respond ONLY with valid JSON:
        {
            "summary": "Brief overview of the plan focus",
            "days": [
                {
                    "dayLabel": "Monday",
                    "focus": "Ball Control & First Touch",
                    "restDay": false,
                    "drills": [
                        {"name": "Drill Name", "description": "How to do it", "duration": "15 min", "difficulty": "Intermediate", "targetSkill": "Ball Control", "reps": "3x10"}
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

        Each training day should have 3-4 drills. Target the weakest skills more heavily.
        """

        do {
            let toolkitURL = Config.EXPO_PUBLIC_TOOLKIT_URL
            guard !toolkitURL.isEmpty else {
                generateFallbackPlan(position: position, weakness: weakness, goalSessions: goalSessions)
                isGenerating = false
                return
            }

            let url = URL(string: "\(toolkitURL)/agent/chat")!
            let messages: [[String: Any]] = [
                ["role": "user", "content": prompt]
            ]
            let body: [String: Any] = ["messages": messages]
            let jsonData = try JSONSerialization.data(withJSONObject: body)

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            request.timeoutInterval = 60

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                generateFallbackPlan(position: position, weakness: weakness, goalSessions: goalSessions)
                isGenerating = false
                return
            }

            let responseText = String(data: data, encoding: .utf8) ?? ""
            let jsonString = extractJSON(from: responseText)

            guard let jsonResponseData = jsonString.data(using: .utf8) else {
                generateFallbackPlan(position: position, weakness: weakness, goalSessions: goalSessions)
                isGenerating = false
                return
            }

            let aiPlan = try JSONDecoder().decode(AIPlanResponse.self, from: jsonResponseData)

            let days = aiPlan.days.map { day in
                TrainingPlanDay(
                    dayLabel: day.dayLabel,
                    focus: day.focus,
                    drills: (day.drills ?? []).map { d in
                        Drill(name: d.name, description: d.description, duration: d.duration, targetSkill: d.targetSkill, reps: d.reps ?? "")
                    },
                    restDay: day.restDay
                )
            }

            let plan = TrainingPlan(days: days, summary: aiPlan.summary)
            storage.saveTrainingPlan(plan)
        } catch {
            generateFallbackPlan(position: position, weakness: weakness, goalSessions: goalSessions)
        }

        isGenerating = false
    }

    private func extractJSON(from text: String) -> String {
        if let start = text.firstIndex(of: "{"),
           let end = text.lastIndex(of: "}") {
            return String(text[start...end])
        }
        return text
    }

    private func generateFallbackPlan(position: PlayerPosition, weakness: WeaknessArea, goalSessions: Int) {
        let dayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        let trainingDays = Set((0..<goalSessions).map { $0 * (7 / max(goalSessions, 1)) }.map { min($0, 6) })

        let days = dayNames.enumerated().map { index, name in
            let isTraining = trainingDays.contains(index)
            return TrainingPlanDay(
                dayLabel: name,
                focus: isTraining ? "\(weakness.rawValue) Focus" : "Rest & Recovery",
                drills: isTraining ? [
                    Drill(name: "\(weakness.rawValue) Builder", description: "Focused practice on your weakest area with progressive difficulty.", duration: "15 min", targetSkill: weakness.rawValue, reps: "3x10"),
                    Drill(name: "Position-Specific Work", description: "Drills tailored to your \(position.rawValue) role.", duration: "20 min", targetSkill: position.skills.first?.rawValue ?? "Movement", reps: "4x8"),
                    Drill(name: "Conditioning Circuit", description: "High intensity interval training with ball work.", duration: "10 min", targetSkill: "Movement", reps: "4 intervals")
                ] : [],
                restDay: !isTraining
            )
        }

        let plan = TrainingPlan(days: days, summary: "A balanced \(goalSessions)-day training week focused on improving your \(weakness.rawValue.lowercased()) as a \(position.rawValue.lowercased()).")
        storage.saveTrainingPlan(plan)
    }
}

nonisolated struct AIPlanResponse: Codable, Sendable {
    let summary: String
    let days: [AIPlanDay]
}

nonisolated struct AIPlanDay: Codable, Sendable {
    let dayLabel: String
    let focus: String
    let restDay: Bool
    let drills: [AIPlanDrill]?
}

nonisolated struct AIPlanDrill: Codable, Sendable {
    let name: String
    let description: String
    let duration: String
    let targetSkill: String
    let reps: String?
}
