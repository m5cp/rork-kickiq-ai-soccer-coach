import Foundation

nonisolated enum BenchmarkLevel: String, Codable, CaseIterable, Sendable, Identifiable {
    case developing = "Developing"
    case emerging = "Emerging"
    case competitive = "Competitive"
    case advanced = "Advanced"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .developing: "seedling"
        case .emerging: "leaf.fill"
        case .competitive: "flame.fill"
        case .advanced: "trophy.fill"
        }
    }

    var color: String {
        switch self {
        case .developing: "green"
        case .emerging: "yellow"
        case .competitive: "orange"
        case .advanced: "red"
        }
    }

    var sortOrder: Int {
        switch self {
        case .developing: 0
        case .emerging: 1
        case .competitive: 2
        case .advanced: 3
        }
    }
}

nonisolated enum BenchmarkMetricType: String, Codable, CaseIterable, Sendable, Identifiable {
    case touches = "Touches"
    case passes = "Passes"
    case time = "Time"
    case contacts = "Contacts"
    case completions = "Completions"
    case distance = "Distance"
    case reps = "Reps"
    case consecutiveCount = "Consecutive Count"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .touches: "hand.point.up.fill"
        case .passes: "arrow.right.arrow.left"
        case .time: "clock.fill"
        case .contacts: "circle.dotted"
        case .completions: "checkmark.circle.fill"
        case .distance: "ruler.fill"
        case .reps: "repeat"
        case .consecutiveCount: "arrow.up.right"
        }
    }

    var unit: String {
        switch self {
        case .touches: "touches"
        case .passes: "passes"
        case .time: "seconds"
        case .contacts: "contacts"
        case .completions: "completed"
        case .distance: "yards"
        case .reps: "reps"
        case .consecutiveCount: "in a row"
        }
    }
}

nonisolated struct DrillBenchmark: Codable, Sendable, Identifiable {
    let id: String
    let drillID: String
    let level: BenchmarkLevel
    let metricType: BenchmarkMetricType
    let targetValue: Double
    let timeWindow: Int?
    let label: String

    init(
        id: String = UUID().uuidString,
        drillID: String,
        level: BenchmarkLevel,
        metricType: BenchmarkMetricType,
        targetValue: Double,
        timeWindow: Int? = nil,
        label: String = ""
    ) {
        self.id = id
        self.drillID = drillID
        self.level = level
        self.metricType = metricType
        self.targetValue = targetValue
        self.timeWindow = timeWindow
        self.label = label.isEmpty ? DrillBenchmark.defaultLabel(metric: metricType, target: targetValue, timeWindow: timeWindow) : label
    }

    var formattedTarget: String {
        if metricType == .time {
            let seconds = Int(targetValue)
            if seconds >= 60 {
                let min = seconds / 60
                let sec = seconds % 60
                return sec > 0 ? "\(min)m \(sec)s" : "\(min)m"
            }
            return "\(seconds)s"
        }
        if targetValue == targetValue.rounded() {
            return "\(Int(targetValue))"
        }
        return String(format: "%.1f", targetValue)
    }

    var fullDescription: String {
        if let window = timeWindow {
            return "\(formattedTarget) \(metricType.unit) in \(window)s"
        }
        return "\(formattedTarget) \(metricType.unit)"
    }

    private static func defaultLabel(metric: BenchmarkMetricType, target: Double, timeWindow: Int?) -> String {
        let targetStr = target == target.rounded() ? "\(Int(target))" : String(format: "%.1f", target)
        if let window = timeWindow {
            return "\(targetStr) \(metric.unit) in \(window)s"
        }
        return "\(targetStr) \(metric.unit)"
    }
}

nonisolated struct BenchmarkResult: Codable, Sendable, Identifiable {
    let id: String
    let benchmarkID: String
    let drillID: String
    let achievedValue: Double
    let date: Date
    let passed: Bool

    init(
        id: String = UUID().uuidString,
        benchmarkID: String,
        drillID: String,
        achievedValue: Double,
        date: Date = .now
    ) {
        self.id = id
        self.benchmarkID = benchmarkID
        self.drillID = drillID
        self.achievedValue = achievedValue
        self.date = date
        self.passed = false
    }
}
