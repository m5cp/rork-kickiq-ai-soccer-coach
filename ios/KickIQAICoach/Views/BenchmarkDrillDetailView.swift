import SwiftUI

struct BenchmarkDrillDetailView: View {
    let drill: BenchmarkDrill
    let storage: StorageService
    let benchmarkService: BenchmarkService
    @Environment(\.dismiss) private var dismiss
    @State private var scoreText: String = ""
    @State private var appeared = false
    @State private var showSuccess = false
    @State private var showSkipConfirm = false
    @FocusState private var isScoreFocused: Bool

    private var playerGender: PlayerGender {
        storage.profile?.gender ?? .male
    }

    private var existingResult: BenchmarkResult? {
        storage.benchmarkResults.first(where: { $0.benchmarkDrillID == drill.id })
    }

    private var isSkipped: Bool {
        existingResult?.isSkipped ?? false
    }

    private var scorePct: Double? {
        guard let latest = existingResult?.latestScore else { return nil }
        return BenchmarkService.scorePercentage(score: latest, drill: drill, gender: playerGender)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.lg) {
                    headerSection
                    instructionsSection
                    howToRecordSection
                    comparisonSection

                    if isSkipped {
                        skippedBanner
                    }

                    if let result = existingResult, !result.isSkipped, !result.attempts.isEmpty {
                        historySection(result)
                    }

                    recordScoreSection
                    skipSection
                }
                .padding(.horizontal, KickIQAICoachTheme.Spacing.md + 4)
                .padding(.bottom, KickIQAICoachTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQAICoachTheme.background.ignoresSafeArea())
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
        .sensoryFeedback(.success, trigger: showSuccess)
        .alert("Did Not Measure", isPresented: $showSkipConfirm) {
            Button("Skip This Test", role: .destructive) {
                storage.skipBenchmarkDrill(drillID: drill.id, category: drill.category, drillName: drill.name)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This test won't count toward your overall score. You can record a score later to un-skip it.")
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                HStack(spacing: 4) {
                    Image(systemName: drill.category.icon)
                        .font(.system(size: 11))
                    Text(drill.category.rawValue)
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(KickIQAICoachTheme.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(KickIQAICoachTheme.accent.opacity(0.15), in: Capsule())

                Spacer()

                if let pct = scorePct {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 10))
                        Text("\(Int(pct))%")
                            .font(.caption.weight(.black))
                    }
                    .foregroundStyle(pct >= 70 ? .green : pct >= 40 ? .orange : KickIQAICoachTheme.textSecondary)
                }
            }

            Text(drill.name)
                .font(.title2.weight(.black))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)

            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                Label("Unit: \(drill.unit)", systemImage: "number")
                Text("·")
                Text(drill.higherIsBetter ? "Higher is better" : "Lower is better")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(KickIQAICoachTheme.textSecondary)
        }
        .padding(.top, KickIQAICoachTheme.Spacing.md)
        .opacity(appeared ? 1 : 0)
    }

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: "list.bullet.clipboard.fill")
                    .font(.caption)
                Text("HOW TO DO IT")
                    .font(.caption.weight(.bold))
                    .tracking(1)
            }
            .foregroundStyle(KickIQAICoachTheme.accent)

            Text(drill.instructions)
                .font(.body.weight(.medium))
                .foregroundStyle(KickIQAICoachTheme.textPrimary.opacity(0.85))
                .lineSpacing(4)
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.4).delay(0.05), value: appeared)
    }

    private var howToRecordSection: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: "pencil.and.list.clipboard")
                    .font(.caption)
                Text("HOW TO RECORD")
                    .font(.caption.weight(.bold))
                    .tracking(1)
            }
            .foregroundStyle(.orange)

            Text(drill.howToRecord)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textPrimary.opacity(0.85))
                .lineSpacing(3)
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(Color.orange.opacity(0.06), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                .stroke(Color.orange.opacity(0.15), lineWidth: 1)
        )
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.4).delay(0.1), value: appeared)
    }

    @ViewBuilder
    private var comparisonSection: some View {
        if let gt = drill.genderThresholds {
            let genderLabel = playerGender == .female ? "Female" : "Male"
            let eliteVal = gt.elite(for: playerGender)
            let avgVal = gt.average(for: playerGender)

            VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                    Text("\(genderLabel.uppercased()) STANDARDS")
                        .font(.caption.weight(.bold))
                        .tracking(1)
                }
                .foregroundStyle(.cyan)

                HStack(spacing: 0) {
                    VStack(spacing: 4) {
                        Text("Average")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                        Text(formatThreshold(avgVal))
                            .font(.headline.weight(.black))
                            .foregroundStyle(KickIQAICoachTheme.textPrimary)
                        Text(drill.unit)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)

                    Rectangle()
                        .fill(KickIQAICoachTheme.divider)
                        .frame(width: 1, height: 40)

                    VStack(spacing: 4) {
                        Text("Elite")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(KickIQAICoachTheme.accent)
                        Text(formatThreshold(eliteVal))
                            .font(.headline.weight(.black))
                            .foregroundStyle(KickIQAICoachTheme.accent)
                        Text(drill.unit)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)

                    if let latest = existingResult?.latestScore, !isSkipped {
                        Rectangle()
                            .fill(KickIQAICoachTheme.divider)
                            .frame(width: 1, height: 40)

                        VStack(spacing: 4) {
                            Text("You")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.green)
                            Text(formatThreshold(latest))
                                .font(.headline.weight(.black))
                                .foregroundStyle(.green)
                            let comp = BenchmarkService.averageComparison(score: latest, drill: drill, gender: playerGender)
                            Text(comp)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(comp == "Above Average" ? .green : comp == "Below Average" ? .orange : KickIQAICoachTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, KickIQAICoachTheme.Spacing.sm)
            }
            .padding(KickIQAICoachTheme.Spacing.md)
            .background(Color.cyan.opacity(0.05), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                    .stroke(Color.cyan.opacity(0.15), lineWidth: 1)
            )
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.4).delay(0.12), value: appeared)
        }
    }

    private var skippedBanner: some View {
        HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            Image(systemName: "minus.circle.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Did Not Measure")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.orange)
                Text("This test is excluded from your overall score. Record a score below to include it.")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
            }
            Spacer()
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(Color.orange.opacity(0.08), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.4).delay(0.15), value: appeared)
    }

    private func historySection(_ result: BenchmarkResult) -> some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.caption)
                    Text("YOUR ATTEMPTS")
                        .font(.caption.weight(.bold))
                        .tracking(1)
                }
                .foregroundStyle(KickIQAICoachTheme.accent)

                Spacer()

                let trend = result.trend
                HStack(spacing: 3) {
                    Image(systemName: trend.icon)
                        .font(.system(size: 10, weight: .bold))
                    Text(trend.label)
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(trend == .improving ? .green : trend == .declining ? .orange : KickIQAICoachTheme.textSecondary)
            }

            if result.attempts.count > 1 {
                miniChart(result.attempts)
            }

            ForEach(result.attempts.suffix(5).reversed()) { attempt in
                HStack {
                    Text(attempt.date, style: .date)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)

                    Spacer()

                    Text("\(BenchmarkView.formatScore(attempt.score)) \(drill.unit)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)

                    let pct = BenchmarkService.scorePercentage(score: attempt.score, drill: drill, gender: playerGender)
                    Text("\(Int(pct))%")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(pct >= 70 ? .green : pct >= 40 ? .orange : KickIQAICoachTheme.textSecondary)
                        .frame(width: 36, alignment: .trailing)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.4).delay(0.15), value: appeared)
    }

    private func miniChart(_ attempts: [BenchmarkAttempt]) -> some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height: CGFloat = 50
            let scores = attempts.map(\.score)
            let minVal = (scores.min() ?? 0) * 0.9
            let maxVal = max((scores.max() ?? 1) * 1.1, minVal + 1)

            let points = scores.enumerated().map { index, score -> CGPoint in
                let x = scores.count > 1 ? width * CGFloat(index) / CGFloat(scores.count - 1) : width / 2
                let y = height - (height * (score - minVal) / (maxVal - minVal))
                return CGPoint(x: x, y: y)
            }

            ZStack {
                if points.count > 1 {
                    Path { path in
                        path.move(to: points[0])
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(KickIQAICoachTheme.accent, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                }

                ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                    Circle()
                        .fill(KickIQAICoachTheme.accent)
                        .frame(width: 5, height: 5)
                        .position(point)
                }
            }
        }
        .frame(height: 50)
    }

    private var recordScoreSection: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.md) {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                    .font(.caption)
                Text("RECORD NEW SCORE")
                    .font(.caption.weight(.bold))
                    .tracking(1)
            }
            .foregroundStyle(KickIQAICoachTheme.accent)
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: KickIQAICoachTheme.Spacing.md) {
                TextField("Enter score", text: $scoreText)
                    .keyboardType(.decimalPad)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    .focused($isScoreFocused)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(KickIQAICoachTheme.surface, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.md)
                            .stroke(isScoreFocused ? KickIQAICoachTheme.accent.opacity(0.5) : KickIQAICoachTheme.divider, lineWidth: 1)
                    )

                Text(drill.unit)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
            }

            if showSuccess {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Score recorded!")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.green)
                }
                .transition(.opacity.combined(with: .scale))
            }

            Button {
                recordScore()
            } label: {
                HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                    Image(systemName: "checkmark")
                    Text("Save Score")
                }
                .font(.headline)
                .foregroundStyle(canSave ? KickIQAICoachTheme.onAccent : KickIQAICoachTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, KickIQAICoachTheme.Spacing.md)
                .background(canSave ? KickIQAICoachTheme.accent : KickIQAICoachTheme.surface, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
            }
            .disabled(!canSave)
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.4).delay(0.2), value: appeared)
    }

    private var skipSection: some View {
        Button {
            showSkipConfirm = true
        } label: {
            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                Image(systemName: "minus.circle")
                Text("Did Not Measure")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.orange)
            .frame(maxWidth: .infinity)
            .padding(.vertical, KickIQAICoachTheme.Spacing.md)
            .background(Color.orange.opacity(0.08), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                    .stroke(Color.orange.opacity(0.2), lineWidth: 1)
            )
        }
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.4).delay(0.25), value: appeared)
    }

    private var canSave: Bool {
        guard let val = Double(scoreText.replacingOccurrences(of: ",", with: ".")), val > 0 else { return false }
        return true
    }

    private func recordScore() {
        guard let val = Double(scoreText.replacingOccurrences(of: ",", with: ".")), val > 0 else { return }
        storage.recordBenchmarkScore(drillID: drill.id, category: drill.category, drillName: drill.name, score: val)
        scoreText = ""
        isScoreFocused = false
        withAnimation(.spring(response: 0.3)) {
            showSuccess = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSuccess = false }
        }
    }

    private func formatThreshold(_ value: Double) -> String {
        if value == value.rounded() {
            return "\(Int(value))"
        }
        return String(format: "%.1f", value)
    }
}
