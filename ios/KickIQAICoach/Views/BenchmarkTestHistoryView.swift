import SwiftUI

struct BenchmarkTestHistoryView: View {
    let drill: BenchmarkDrill
    let storage: StorageService
    let benchmarkService: BenchmarkService
    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false
    @State private var scoreText: String = ""
    @State private var showSuccess = false
    @FocusState private var isScoreFocused: Bool

    private var playerGender: PlayerGender {
        storage.profile?.gender ?? .male
    }

    private var result: BenchmarkResult? {
        storage.benchmarkResults.first(where: { $0.benchmarkDrillID == drill.id })
    }

    private var allAttempts: [BenchmarkAttempt] {
        result?.attempts ?? []
    }

    private var bestScore: Double? {
        guard let r = result, !r.isSkipped else { return nil }
        if drill.higherIsBetter {
            return r.attempts.map(\.score).max()
        } else {
            return r.attempts.map(\.score).min()
        }
    }

    private var latestPct: Double? {
        guard let latest = result?.latestScore else { return nil }
        return BenchmarkService.scorePercentage(score: latest, drill: drill, gender: playerGender)
    }

    private var bestPct: Double? {
        guard let best = bestScore else { return nil }
        return BenchmarkService.scorePercentage(score: best, drill: drill, gender: playerGender)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.lg) {
                    drillHeader
                    if !allAttempts.isEmpty {
                        statsRow
                        progressChart
                        peerComparison
                        attemptTimeline
                    } else {
                        noDataState
                    }
                    recordSection
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
    }

    // MARK: - Header

    private var drillHeader: some View {
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

                if let pct = latestPct {
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
                Text("·")
                Text("\(allAttempts.count) attempt\(allAttempts.count == 1 ? "" : "s")")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(KickIQAICoachTheme.textSecondary)
        }
        .padding(.top, KickIQAICoachTheme.Spacing.md)
        .opacity(appeared ? 1 : 0)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statBlock(label: "Latest", value: result?.latestScore, pct: latestPct)
            Rectangle().fill(KickIQAICoachTheme.divider).frame(width: 1, height: 44)
            statBlock(label: "Best", value: bestScore, pct: bestPct)
            Rectangle().fill(KickIQAICoachTheme.divider).frame(width: 1, height: 44)
            statBlock(label: "Attempts", value: Double(allAttempts.count), pct: nil, isCount: true)
            Rectangle().fill(KickIQAICoachTheme.divider).frame(width: 1, height: 44)
            trendBlock
        }
        .padding(.vertical, KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.4).delay(0.05), value: appeared)
    }

    private func statBlock(label: String, value: Double?, pct: Double?, isCount: Bool = false) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
            if let v = value {
                Text(isCount ? "\(Int(v))" : BenchmarkView.formatScore(v))
                    .font(.headline.weight(.black))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
            } else {
                Text("—")
                    .font(.headline.weight(.black))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.4))
            }
            if let p = pct {
                Text("\(Int(p))%")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(p >= 70 ? .green : p >= 40 ? .orange : KickIQAICoachTheme.textSecondary)
            } else if !isCount {
                Text("")
                    .font(.system(size: 9))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var trendBlock: some View {
        let trend = result?.trend ?? .neutral
        return VStack(spacing: 3) {
            Text("Trend")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
            Image(systemName: trend.icon)
                .font(.headline.weight(.bold))
                .foregroundStyle(trend == .improving ? .green : trend == .declining ? .orange : KickIQAICoachTheme.textSecondary)
            Text(trend.label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(trend == .improving ? .green : trend == .declining ? .orange : KickIQAICoachTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Progress Chart

    private var progressChart: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.caption)
                Text("PROGRESS OVER TIME")
                    .font(.caption.weight(.bold))
                    .tracking(1)
            }
            .foregroundStyle(KickIQAICoachTheme.accent)

            if allAttempts.count >= 2 {
                let improvement = improvementSummary
                if !improvement.isEmpty {
                    Text(improvement)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }
            }

            progressChartCanvas
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.4).delay(0.1), value: appeared)
    }

    private var progressChartCanvas: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height: CGFloat = 80
            let scores = allAttempts.map(\.score)
            let minVal = (scores.min() ?? 0) * 0.85
            let maxVal = max((scores.max() ?? 1) * 1.15, minVal + 1)

            let points = scores.enumerated().map { index, score -> CGPoint in
                let x = scores.count > 1 ? width * CGFloat(index) / CGFloat(scores.count - 1) : width / 2
                let y = height - (height * (score - minVal) / (maxVal - minVal))
                return CGPoint(x: x, y: y)
            }

            ZStack {
                if points.count > 1 {
                    Path { path in
                        path.move(to: CGPoint(x: points[0].x, y: height))
                        path.addLine(to: points[0])
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                        path.addLine(to: CGPoint(x: points.last!.x, y: height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [KickIQAICoachTheme.accent.opacity(0.25), KickIQAICoachTheme.accent.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    Path { path in
                        path.move(to: points[0])
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(KickIQAICoachTheme.accent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                }

                ForEach(Array(points.enumerated()), id: \.offset) { idx, point in
                    Circle()
                        .fill(idx == points.count - 1 ? KickIQAICoachTheme.accent : KickIQAICoachTheme.accent.opacity(0.6))
                        .frame(width: idx == points.count - 1 ? 7 : 5, height: idx == points.count - 1 ? 7 : 5)
                        .position(point)
                }
            }
        }
        .frame(height: 80)
    }

    // MARK: - Peer Comparison

    @ViewBuilder
    private var peerComparison: some View {
        if let gt = drill.genderThresholds {
            let genderLabel = playerGender == .female ? "Female" : "Male"
            let eliteVal = gt.elite(for: playerGender)
            let avgVal = gt.average(for: playerGender)

            VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                    Text("\(genderLabel.uppercased()) PEER COMPARISON")
                        .font(.caption.weight(.bold))
                        .tracking(1)
                }
                .foregroundStyle(.cyan)

                if let latest = result?.latestScore, !allAttempts.isEmpty {
                    comparisonBar(latest: latest, average: avgVal, elite: eliteVal)
                }

                HStack(spacing: 0) {
                    VStack(spacing: 3) {
                        Text("Average")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                        Text(formatThreshold(avgVal))
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    }
                    .frame(maxWidth: .infinity)

                    Rectangle().fill(KickIQAICoachTheme.divider).frame(width: 1, height: 30)

                    VStack(spacing: 3) {
                        Text("Elite")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(KickIQAICoachTheme.accent)
                        Text(formatThreshold(eliteVal))
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(KickIQAICoachTheme.accent)
                    }
                    .frame(maxWidth: .infinity)

                    if let latest = result?.latestScore {
                        Rectangle().fill(KickIQAICoachTheme.divider).frame(width: 1, height: 30)
                        VStack(spacing: 3) {
                            Text("You")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.green)
                            Text(formatThreshold(latest))
                                .font(.subheadline.weight(.black))
                                .foregroundStyle(.green)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    if let best = bestScore, best != result?.latestScore {
                        Rectangle().fill(KickIQAICoachTheme.divider).frame(width: 1, height: 30)
                        VStack(spacing: 3) {
                            Text("PR")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.purple)
                            Text(formatThreshold(best))
                                .font(.subheadline.weight(.black))
                                .foregroundStyle(.purple)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(KickIQAICoachTheme.Spacing.md)
            .background(Color.cyan.opacity(0.05), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                    .stroke(Color.cyan.opacity(0.15), lineWidth: 1)
            )
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.4).delay(0.15), value: appeared)
        }
    }

    private func comparisonBar(latest: Double, average: Double, elite: Double) -> some View {
        GeometryReader { geo in
            let width = geo.size.width
            let range = drill.higherIsBetter
                ? (0.0...elite * 1.2)
                : (elite * 0.8...average * 1.3)
            let rangeWidth = range.upperBound - range.lowerBound
            guard rangeWidth > 0 else { return AnyView(EmptyView()) }

            func xPos(_ val: Double) -> CGFloat {
                CGFloat((val - range.lowerBound) / rangeWidth) * width
            }

            return AnyView(
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(KickIQAICoachTheme.divider)
                        .frame(height: 6)

                    Circle()
                        .fill(.orange)
                        .frame(width: 8, height: 8)
                        .position(x: xPos(average), y: 3)

                    Circle()
                        .fill(KickIQAICoachTheme.accent)
                        .frame(width: 8, height: 8)
                        .position(x: xPos(elite), y: 3)

                    Circle()
                        .fill(.green)
                        .frame(width: 10, height: 10)
                        .position(x: xPos(latest), y: 3)
                }
            )
        }
        .frame(height: 10)
    }

    // MARK: - Attempt Timeline

    private var attemptTimeline: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: "calendar.badge.clock")
                    .font(.caption)
                Text("ALL ATTEMPTS")
                    .font(.caption.weight(.bold))
                    .tracking(1)
            }
            .foregroundStyle(KickIQAICoachTheme.accent)

            ForEach(Array(allAttempts.reversed().enumerated()), id: \.element.id) { index, attempt in
                let attemptNum = allAttempts.count - index
                let pct = BenchmarkService.scorePercentage(score: attempt.score, drill: drill, gender: playerGender)
                let isBest = attempt.score == bestScore
                let prevAttempt: BenchmarkAttempt? = index < allAttempts.count - 1 ? allAttempts[allAttempts.count - 1 - (index + 1)] : nil
                let delta: Double? = prevAttempt.map { attempt.score - $0.score }

                HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                    VStack(spacing: 0) {
                        Circle()
                            .fill(isBest ? Color.purple : KickIQAICoachTheme.accent)
                            .frame(width: 8, height: 8)
                        if index < allAttempts.count - 1 {
                            Rectangle()
                                .fill(KickIQAICoachTheme.divider)
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                        }
                    }
                    .frame(width: 14)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Attempt #\(attemptNum)")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(KickIQAICoachTheme.textPrimary)

                            if isBest {
                                Text("PR")
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundStyle(.purple)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Color.purple.opacity(0.15), in: Capsule())
                            }

                            Spacer()

                            Text("\(BenchmarkView.formatScore(attempt.score)) \(drill.unit)")
                                .font(.subheadline.weight(.black))
                                .foregroundStyle(KickIQAICoachTheme.textPrimary)
                        }

                        HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                            Text(attempt.date, format: .dateTime.month(.abbreviated).day().year().hour().minute())
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(KickIQAICoachTheme.textSecondary)

                            Spacer()

                            Text("\(Int(pct))% of elite")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(pct >= 70 ? .green : pct >= 40 ? .orange : KickIQAICoachTheme.textSecondary)

                            if let d = delta {
                                let improved = drill.higherIsBetter ? d > 0 : d < 0
                                let same = d == 0
                                HStack(spacing: 2) {
                                    Image(systemName: same ? "arrow.right" : improved ? "arrow.up.right" : "arrow.down.right")
                                        .font(.system(size: 8, weight: .bold))
                                    Text(same ? "—" : (d > 0 ? "+\(BenchmarkView.formatScore(d))" : BenchmarkView.formatScore(d)))
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .foregroundStyle(same ? KickIQAICoachTheme.textSecondary : improved ? .green : .orange)
                            }
                        }
                    }
                    .padding(KickIQAICoachTheme.Spacing.sm + 2)
                    .background(
                        isBest ? Color.purple.opacity(0.04) : KickIQAICoachTheme.surface,
                        in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md)
                    )
                    .overlay(
                        isBest ? RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.md).stroke(Color.purple.opacity(0.2), lineWidth: 1) : nil
                    )
                }
                .padding(.leading, 2)
            }
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.4).delay(0.2), value: appeared)
    }

    // MARK: - Record Section

    private var recordSection: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.md) {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                    .font(.caption)
                Text("RECORD NEW ATTEMPT")
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
                    Text("Score recorded! +15 XP")
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
                    Text("Save Attempt")
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
        .animation(.spring(response: 0.4).delay(0.25), value: appeared)
    }

    // MARK: - No Data

    private var noDataState: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.md) {
            Image(systemName: "chart.bar.xaxis.ascending")
                .font(.system(size: 40))
                .foregroundStyle(KickIQAICoachTheme.accent.opacity(0.4))
            Text("No attempts recorded yet")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
            Text("Record your first score below to start tracking.")
                .font(.caption)
                .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, KickIQAICoachTheme.Spacing.xl)
    }

    // MARK: - Helpers

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

    private var improvementSummary: String {
        guard allAttempts.count >= 2 else { return "" }
        let first = allAttempts.first!.score
        let last = allAttempts.last!.score
        let diff = last - first
        if diff == 0 { return "Consistent performance across \(allAttempts.count) attempts" }
        let improved = drill.higherIsBetter ? diff > 0 : diff < 0
        let absFormatted = BenchmarkView.formatScore(abs(diff))
        if improved {
            return "Improved by \(absFormatted) \(drill.unit) over \(allAttempts.count) attempts"
        } else {
            return "Declined by \(absFormatted) \(drill.unit) — time to refocus"
        }
    }
}
