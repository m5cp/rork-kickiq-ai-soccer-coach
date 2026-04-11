import Foundation

@Observable
@MainActor
class BenchmarkService {
    private(set) var benchmarks: [DrillBenchmark] = []
    private(set) var results: [BenchmarkResult] = []

    private let resultsKey = "kickiq_benchmark_results"

    init() {
        loadResults()
        buildBenchmarks()
    }

    func benchmarks(for drillID: String) -> [DrillBenchmark] {
        benchmarks.filter { $0.drillID == drillID }
    }

    func benchmarks(for drillID: String, level: BenchmarkLevel) -> [DrillBenchmark] {
        benchmarks.filter { $0.drillID == drillID && $0.level == level }
    }

    func benchmarksByLevel(for drillID: String) -> [(level: BenchmarkLevel, benchmarks: [DrillBenchmark])] {
        let drillBenchmarks = benchmarks(for: drillID)
        return BenchmarkLevel.allCases.compactMap { level in
            let filtered = drillBenchmarks.filter { $0.level == level }
            guard !filtered.isEmpty else { return nil }
            return (level: level, benchmarks: filtered)
        }
    }

    func results(for benchmarkID: String) -> [BenchmarkResult] {
        results.filter { $0.benchmarkID == benchmarkID }.sorted { $0.date > $1.date }
    }

    func bestResult(for benchmarkID: String) -> BenchmarkResult? {
        results(for: benchmarkID).max { $0.achievedValue < $1.achievedValue }
    }

    func logResult(benchmarkID: String, drillID: String, achievedValue: Double) {
        let result = BenchmarkResult(
            benchmarkID: benchmarkID,
            drillID: drillID,
            achievedValue: achievedValue
        )
        results.append(result)
        saveResults()
    }

    func currentLevel(for drillID: String) -> BenchmarkLevel? {
        let drillBenchmarks = benchmarks(for: drillID)
        guard !drillBenchmarks.isEmpty else { return nil }

        let passedLevels = BenchmarkLevel.allCases.filter { level in
            let levelBenchmarks = drillBenchmarks.filter { $0.level == level }
            guard !levelBenchmarks.isEmpty else { return false }
            return levelBenchmarks.allSatisfy { benchmark in
                guard let best = bestResult(for: benchmark.id) else { return false }
                return best.achievedValue >= benchmark.targetValue
            }
        }

        return passedLevels.max { $0.sortOrder < $1.sortOrder }
    }

    func nextLevel(for drillID: String) -> BenchmarkLevel? {
        guard let current = currentLevel(for: drillID) else {
            return .developing
        }
        switch current {
        case .developing: return .emerging
        case .emerging: return .competitive
        case .competitive: return .advanced
        case .advanced: return nil
        }
    }

    func progress(for drillID: String, level: BenchmarkLevel) -> Double {
        let levelBenchmarks = benchmarks(for: drillID).filter { $0.level == level }
        guard !levelBenchmarks.isEmpty else { return 0 }

        let passed = levelBenchmarks.filter { benchmark in
            guard let best = bestResult(for: benchmark.id) else { return false }
            return best.achievedValue >= benchmark.targetValue
        }.count

        return Double(passed) / Double(levelBenchmarks.count)
    }

    private func saveResults() {
        guard let data = try? JSONEncoder().encode(results) else { return }
        UserDefaults.standard.set(data, forKey: resultsKey)
    }

    private func loadResults() {
        guard let data = UserDefaults.standard.data(forKey: resultsKey),
              let decoded = try? JSONDecoder().decode([BenchmarkResult].self, from: data) else { return }
        results = decoded
    }

    private func buildBenchmarks() {
        benchmarks = Self.dribblingBenchmarks
            + Self.turningBenchmarks
            + Self.strikingBenchmarks
            + Self.receivingBenchmarks
            + Self.jugglingBenchmarks
            + Self.ballControlBenchmarks
    }

    private static let dribblingBenchmarks: [DrillBenchmark] = {
        let drillTag = "dribbling"
        return [
            DrillBenchmark(drillID: drillTag, level: .developing, metricType: .touches, targetValue: 30, timeWindow: 20, label: "30 touches in 20s"),
            DrillBenchmark(drillID: drillTag, level: .developing, metricType: .time, targetValue: 25, label: "Complete cone pattern in 25s"),
            DrillBenchmark(drillID: drillTag, level: .emerging, metricType: .touches, targetValue: 45, timeWindow: 20, label: "45 touches in 20s"),
            DrillBenchmark(drillID: drillTag, level: .emerging, metricType: .time, targetValue: 20, label: "Complete cone pattern in 20s"),
            DrillBenchmark(drillID: drillTag, level: .competitive, metricType: .touches, targetValue: 60, timeWindow: 20, label: "60 touches in 20s"),
            DrillBenchmark(drillID: drillTag, level: .competitive, metricType: .time, targetValue: 16, label: "Complete cone pattern in 16s"),
            DrillBenchmark(drillID: drillTag, level: .advanced, metricType: .touches, targetValue: 75, timeWindow: 20, label: "75 touches in 20s"),
            DrillBenchmark(drillID: drillTag, level: .advanced, metricType: .time, targetValue: 13, label: "Complete cone pattern in 13s"),
        ]
    }()

    private static let turningBenchmarks: [DrillBenchmark] = {
        let drillTag = "turning"
        return [
            DrillBenchmark(drillID: drillTag, level: .developing, metricType: .reps, targetValue: 6, timeWindow: 30, label: "6 clean turns in 30s"),
            DrillBenchmark(drillID: drillTag, level: .developing, metricType: .completions, targetValue: 5, label: "5 successful turn types"),
            DrillBenchmark(drillID: drillTag, level: .emerging, metricType: .reps, targetValue: 10, timeWindow: 30, label: "10 clean turns in 30s"),
            DrillBenchmark(drillID: drillTag, level: .emerging, metricType: .time, targetValue: 4, label: "Turn and accelerate in 4s"),
            DrillBenchmark(drillID: drillTag, level: .competitive, metricType: .reps, targetValue: 14, timeWindow: 30, label: "14 clean turns in 30s"),
            DrillBenchmark(drillID: drillTag, level: .competitive, metricType: .time, targetValue: 3, label: "Turn and accelerate in 3s"),
            DrillBenchmark(drillID: drillTag, level: .advanced, metricType: .reps, targetValue: 18, timeWindow: 30, label: "18 clean turns in 30s"),
            DrillBenchmark(drillID: drillTag, level: .advanced, metricType: .time, targetValue: 2.5, label: "Turn and accelerate in 2.5s"),
        ]
    }()

    private static let strikingBenchmarks: [DrillBenchmark] = {
        let drillTag = "striking"
        return [
            DrillBenchmark(drillID: drillTag, level: .developing, metricType: .completions, targetValue: 5, label: "5 on-target strikes out of 10"),
            DrillBenchmark(drillID: drillTag, level: .developing, metricType: .contacts, targetValue: 15, timeWindow: 60, label: "15 wall contacts in 60s"),
            DrillBenchmark(drillID: drillTag, level: .emerging, metricType: .completions, targetValue: 7, label: "7 on-target strikes out of 10"),
            DrillBenchmark(drillID: drillTag, level: .emerging, metricType: .contacts, targetValue: 25, timeWindow: 60, label: "25 wall contacts in 60s"),
            DrillBenchmark(drillID: drillTag, level: .competitive, metricType: .completions, targetValue: 8, label: "8 on-target strikes out of 10"),
            DrillBenchmark(drillID: drillTag, level: .competitive, metricType: .contacts, targetValue: 35, timeWindow: 60, label: "35 wall contacts in 60s"),
            DrillBenchmark(drillID: drillTag, level: .advanced, metricType: .completions, targetValue: 9, label: "9 on-target strikes out of 10"),
            DrillBenchmark(drillID: drillTag, level: .advanced, metricType: .contacts, targetValue: 45, timeWindow: 60, label: "45 wall contacts in 60s"),
        ]
    }()

    private static let receivingBenchmarks: [DrillBenchmark] = {
        let drillTag = "receiving"
        return [
            DrillBenchmark(drillID: drillTag, level: .developing, metricType: .completions, targetValue: 6, label: "6 clean first touches out of 10"),
            DrillBenchmark(drillID: drillTag, level: .developing, metricType: .passes, targetValue: 15, timeWindow: 60, label: "15 wall passes in 60s"),
            DrillBenchmark(drillID: drillTag, level: .emerging, metricType: .completions, targetValue: 8, label: "8 clean first touches out of 10"),
            DrillBenchmark(drillID: drillTag, level: .emerging, metricType: .passes, targetValue: 25, timeWindow: 60, label: "25 wall passes in 60s"),
            DrillBenchmark(drillID: drillTag, level: .competitive, metricType: .completions, targetValue: 9, label: "9 clean first touches out of 10"),
            DrillBenchmark(drillID: drillTag, level: .competitive, metricType: .passes, targetValue: 35, timeWindow: 60, label: "35 wall passes in 60s"),
            DrillBenchmark(drillID: drillTag, level: .advanced, metricType: .completions, targetValue: 10, label: "10 clean first touches out of 10"),
            DrillBenchmark(drillID: drillTag, level: .advanced, metricType: .passes, targetValue: 45, timeWindow: 60, label: "45 wall passes in 60s"),
        ]
    }()

    private static let jugglingBenchmarks: [DrillBenchmark] = {
        let drillTag = "juggling"
        return [
            DrillBenchmark(drillID: drillTag, level: .developing, metricType: .consecutiveCount, targetValue: 10, label: "10 consecutive juggles"),
            DrillBenchmark(drillID: drillTag, level: .developing, metricType: .touches, targetValue: 30, timeWindow: 30, label: "30 touches in 30s"),
            DrillBenchmark(drillID: drillTag, level: .emerging, metricType: .consecutiveCount, targetValue: 30, label: "30 consecutive juggles"),
            DrillBenchmark(drillID: drillTag, level: .emerging, metricType: .touches, targetValue: 50, timeWindow: 30, label: "50 touches in 30s"),
            DrillBenchmark(drillID: drillTag, level: .competitive, metricType: .consecutiveCount, targetValue: 75, label: "75 consecutive juggles"),
            DrillBenchmark(drillID: drillTag, level: .competitive, metricType: .touches, targetValue: 70, timeWindow: 30, label: "70 touches in 30s"),
            DrillBenchmark(drillID: drillTag, level: .advanced, metricType: .consecutiveCount, targetValue: 150, label: "150 consecutive juggles"),
            DrillBenchmark(drillID: drillTag, level: .advanced, metricType: .touches, targetValue: 90, timeWindow: 30, label: "90 touches in 30s"),
        ]
    }()

    private static let ballControlBenchmarks: [DrillBenchmark] = {
        let drillTag = "ballcontrol"
        return [
            DrillBenchmark(drillID: drillTag, level: .developing, metricType: .touches, targetValue: 25, timeWindow: 20, label: "25 controlled touches in 20s"),
            DrillBenchmark(drillID: drillTag, level: .developing, metricType: .completions, targetValue: 5, label: "5 clean surface changes out of 8"),
            DrillBenchmark(drillID: drillTag, level: .emerging, metricType: .touches, targetValue: 40, timeWindow: 20, label: "40 controlled touches in 20s"),
            DrillBenchmark(drillID: drillTag, level: .emerging, metricType: .completions, targetValue: 7, label: "7 clean surface changes out of 8"),
            DrillBenchmark(drillID: drillTag, level: .competitive, metricType: .touches, targetValue: 55, timeWindow: 20, label: "55 controlled touches in 20s"),
            DrillBenchmark(drillID: drillTag, level: .competitive, metricType: .time, targetValue: 15, label: "Complete figure-8 pattern in 15s"),
            DrillBenchmark(drillID: drillTag, level: .advanced, metricType: .touches, targetValue: 70, timeWindow: 20, label: "70 controlled touches in 20s"),
            DrillBenchmark(drillID: drillTag, level: .advanced, metricType: .time, targetValue: 12, label: "Complete figure-8 pattern in 12s"),
        ]
    }()
}
