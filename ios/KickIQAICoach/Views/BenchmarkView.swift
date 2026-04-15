import SwiftUI

struct BenchmarkView: View {
    let storage: StorageService
    let customContentService: CustomContentService
    @State private var benchmarkService = BenchmarkService()
    @State private var appeared = false
    @State private var selectedDrill: BenchmarkDrill?
    @State private var scoreAnimated = false
    @State private var showImport = false
    @State private var showResults = false

    private var playerGender: PlayerGender {
        storage.profile?.gender ?? .male
    }

    private var playerRank: BenchmarkPlayerRank {
        let score = benchmarkService.overallScore(results: storage.benchmarkResults, gender: playerGender)
        return BenchmarkPlayerRank.rank(for: score)
    }

    private var overallPct: Double {
        benchmarkService.overallScore(results: storage.benchmarkResults, gender: playerGender)
    }

    private var completedCount: Int {
        storage.benchmarkResults.filter { !$0.isSkipped && $0.latestScore != nil }.count
    }

    private var totalCount: Int {
        benchmarkService.benchmarkDrills.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if storage.benchmarkResults.isEmpty {
                        introSection
                    } else {
                        scoreOverview
                    }

                    categorySection
                    if !customContentService.library.benchmarks.isEmpty {
                        customBenchmarksSection
                    }
                }
                .padding(.bottom, KickIQAICoachTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Benchmark")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    if !storage.benchmarkResults.isEmpty {
                        Button {
                            showResults = true
                        } label: {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundStyle(KickIQAICoachTheme.accent)
                        }
                    }
                    Button {
                        showImport = true
                    } label: {
                        Image(systemName: "doc.badge.plus")
                            .foregroundStyle(KickIQAICoachTheme.accent)
                    }
                }
            }
            .sheet(isPresented: $showImport) {
                PDFImportView(customContentService: customContentService)
            }
            .sheet(isPresented: $showResults) {
                BenchmarkResultsView(storage: storage)
            }
            .sheet(item: $selectedDrill) { drill in
                BenchmarkDrillDetailView(
                    drill: drill,
                    storage: storage,
                    benchmarkService: benchmarkService
                )
            }
        }
        .onAppear {
            let age = storage.profile?.ageRange ?? .fifteen18
            benchmarkService.loadDrills(for: age, gender: playerGender)
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) { scoreAnimated = true }
            }
        }
    }

    private var introSection: some View {
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

                Image(systemName: "chart.bar.doc.horizontal.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(KickIQAICoachTheme.accent)
                    .symbolEffect(.pulse, isActive: appeared)
            }

            VStack(spacing: 8) {
                Text("SKILL BENCHMARK")
                    .font(.system(.title3, design: .default, weight: .black))
                    .tracking(2)
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)

                Text("Test your skills with standardized drills.\nYour results drive personalized training.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: KickIQAICoachTheme.Spacing.md) {
                infoPill(icon: "figure.soccer", text: "\(totalCount) Tests")
                infoPill(icon: "chart.line.uptrend.xyaxis", text: "Track Progress")
                infoPill(icon: "star.fill", text: "Get Ranked")
            }
        }
        .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
        .padding(.vertical, KickIQAICoachTheme.Spacing.xl)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
    }

    private func infoPill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundStyle(KickIQAICoachTheme.accent)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(KickIQAICoachTheme.accent.opacity(0.12), in: Capsule())
    }

    private var scoreOverview: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.md) {
            HStack(spacing: KickIQAICoachTheme.Spacing.lg) {
                ZStack {
                    Circle()
                        .stroke(KickIQAICoachTheme.divider, lineWidth: 8)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: scoreAnimated ? overallPct / 100.0 : 0)
                        .stroke(
                            AngularGradient(
                                colors: [KickIQAICoachTheme.accent, KickIQAICoachTheme.accent.opacity(0.3), KickIQAICoachTheme.accent],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(Int(overallPct))")
                            .font(.system(size: 36, weight: .black))
                            .foregroundStyle(KickIQAICoachTheme.textPrimary)
                            .contentTransition(.numericText())
                        Text("/ 100")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: playerRank.icon)
                            .font(.subheadline)
                        Text(playerRank.rawValue.uppercased())
                            .font(.caption.weight(.black))
                            .tracking(1)
                    }
                    .foregroundStyle(KickIQAICoachTheme.accent)

                    Text("\(completedCount)/\(totalCount) tests done")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)

                    let weak = benchmarkService.weakestCategories(results: storage.benchmarkResults, gender: playerGender)
                    if let first = weak.first {
                        HStack(spacing: 4) {
                            Image(systemName: "target")
                                .font(.system(size: 10))
                            Text("Focus: \(first.rawValue)")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(.orange)
                    }

                    if let next = playerRank.nextRank {
                        Text("Next: \(next.rawValue)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.6))
                    }
                }

                Spacer()
            }
            .padding(KickIQAICoachTheme.Spacing.md)
            .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.xl))

            categoryScoreBars
        }
        .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
        .padding(.top, KickIQAICoachTheme.Spacing.sm)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
    }

    private var categoryScoreBars: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            Text("CATEGORY SCORES")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQAICoachTheme.accent)

            ForEach(BenchmarkCategory.allCases) { cat in
                let score = benchmarkService.categoryScore(results: storage.benchmarkResults, category: cat, gender: playerGender)
                HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                    Image(systemName: cat.icon)
                        .font(.caption)
                        .foregroundStyle(KickIQAICoachTheme.accent)
                        .frame(width: 18)

                    Text(cat.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                        .frame(width: 80, alignment: .leading)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(KickIQAICoachTheme.divider)
                                .frame(height: 6)
                            Capsule()
                                .fill(KickIQAICoachTheme.accent)
                                .frame(width: scoreAnimated ? geo.size.width * (score ?? 0) / 100.0 : 0, height: 6)
                        }
                    }
                    .frame(height: 6)

                    Text(score != nil ? "\(Int(score!))" : "—")
                        .font(.caption.weight(.black))
                        .foregroundStyle(score != nil ? KickIQAICoachTheme.textPrimary : KickIQAICoachTheme.textSecondary.opacity(0.4))
                        .frame(width: 28, alignment: .trailing)
                }
            }
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
    }

    private var categorySection: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.md) {
            ForEach(Array(BenchmarkCategory.allCases.enumerated()), id: \.element.id) { index, category in
                let drills = benchmarkService.benchmarkDrills.filter { $0.category == category }
                guard !drills.isEmpty else { return AnyView(EmptyView()) }

                return AnyView(
                    VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
                        HStack(spacing: 8) {
                            Image(systemName: category.icon)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(KickIQAICoachTheme.accent)
                            Text(category.rawValue.uppercased())
                                .font(.system(.caption, design: .default, weight: .black))
                                .tracking(1.5)
                                .foregroundStyle(KickIQAICoachTheme.textSecondary)
                        }
                        .padding(.horizontal, KickIQAICoachTheme.Spacing.md)

                        VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                            ForEach(drills) { drill in
                                benchmarkDrillRow(drill)
                            }
                        }
                        .padding(KickIQAICoachTheme.Spacing.md)
                        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.xl))
                        .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 15)
                    .animation(.spring(response: 0.4).delay(Double(index) * 0.06), value: appeared)
                )
            }
        }
        .padding(.top, KickIQAICoachTheme.Spacing.lg)
    }

    private func benchmarkDrillRow(_ drill: BenchmarkDrill) -> some View {
        let result = storage.benchmarkResults.first(where: { $0.benchmarkDrillID == drill.id })
        let isSkipped = result?.isSkipped ?? false
        let hasScore = result?.latestScore != nil
        let trend = result?.trend ?? .neutral

        return Button {
            selectedDrill = drill
        } label: {
            HStack(spacing: KickIQAICoachTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(isSkipped ? Color.orange.opacity(0.1) : hasScore ? KickIQAICoachTheme.accent.opacity(0.15) : KickIQAICoachTheme.surface)
                        .frame(width: 42, height: 42)

                    if isSkipped {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.orange)
                    } else if hasScore {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(KickIQAICoachTheme.accent)
                    } else {
                        Image(systemName: "circle")
                            .font(.system(size: 18))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.3))
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(drill.name)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)

                    if isSkipped {
                        Text("Did Not Measure")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                    } else if let score = result?.latestScore {
                        HStack(spacing: 6) {
                            Text("\(Self.formatScore(score)) \(drill.unit)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(KickIQAICoachTheme.accent)

                            let tier = BenchmarkService.tierForScore(score: score, drill: drill, gender: playerGender)
                            Text(tier.shortLabel)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(tierColor(tier))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(tierColor(tier).opacity(0.12), in: Capsule())

                            if result?.attempts.count ?? 0 >= 2 {
                                HStack(spacing: 2) {
                                    Image(systemName: trend.icon)
                                        .font(.system(size: 9, weight: .bold))
                                    Text(trend.label)
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .foregroundStyle(trend == .improving ? .green : trend == .declining ? .orange : KickIQAICoachTheme.textSecondary)
                            }
                        }
                    } else {
                        Text("Not tested yet")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.3))
            }
            .padding(KickIQAICoachTheme.Spacing.sm + 2)
            .background(
                RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.md)
                    .fill(isSkipped ? Color.orange.opacity(0.03) : hasScore ? KickIQAICoachTheme.accent.opacity(0.04) : Color.clear)
            )
        }
        .sensoryFeedback(.selection, trigger: selectedDrill?.id)
    }

    private var customBenchmarksSection: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
                HStack(spacing: 8) {
                    Image(systemName: "person.fill.badge.plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.orange)
                    Text("MY CUSTOM BENCHMARKS")
                        .font(.system(.caption, design: .default, weight: .black))
                        .tracking(1.5)
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }
                .padding(.horizontal, KickIQAICoachTheme.Spacing.md)

                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange.opacity(0.7))
                    Text("Custom benchmarks are not compared against peer averages")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.orange.opacity(0.7))
                }
                .padding(.horizontal, KickIQAICoachTheme.Spacing.md)

                VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                    let customBenchmarks = customContentService.allCustomBenchmarksAsBenchmarkDrills()
                    ForEach(customBenchmarks) { drill in
                        benchmarkDrillRow(drill)
                    }
                }
                .padding(KickIQAICoachTheme.Spacing.md)
                .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.xl))
                .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
            }
        }
        .padding(.top, KickIQAICoachTheme.Spacing.md)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.4).delay(0.3), value: appeared)
    }

    private func tierColor(_ tier: BenchmarkTier) -> Color {
        switch tier {
        case .recreational: .gray
        case .competitive: .orange
        case .academy: .cyan
        case .elite: .purple
        }
    }

    static func formatScore(_ score: Double) -> String {
        if score == score.rounded() {
            return "\(Int(score))"
        }
        return String(format: "%.1f", score)
    }
}
