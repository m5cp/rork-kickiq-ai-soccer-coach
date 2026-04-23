import Foundation
import CoreMotion
import Observation

@Observable
@MainActor
final class WatchPedometerService {
    static let shared = WatchPedometerService()

    private let pedometer = CMPedometer()

    var todaySteps: Int = 0
    var todayDistanceMeters: Double = 0
    var dailyGoal: Int = 10000
    var isAvailable: Bool = CMPedometer.isStepCountingAvailable()
    var weekly: [Day] = []

    var liveSessionSteps: Int = 0
    var liveSessionDistance: Double = 0
    private var isLiveQueryActive = false

    struct Day: Identifiable, Hashable {
        let id = UUID()
        let date: Date
        let steps: Int
    }

    private init() {}

    var goalProgress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(1.0, Double(todaySteps) / Double(dailyGoal))
    }

    var todayDistanceMiles: Double {
        todayDistanceMeters / 1609.34
    }

    func loadToday() {
        guard isAvailable else { return }
        let start = Calendar.current.startOfDay(for: Date())
        pedometer.queryPedometerData(from: start, to: Date()) { [weak self] data, _ in
            Task { @MainActor in
                guard let self, let d = data else { return }
                self.todaySteps = d.numberOfSteps.intValue
                self.todayDistanceMeters = d.distance?.doubleValue ?? 0
            }
        }
        pedometer.startUpdates(from: start) { [weak self] data, _ in
            Task { @MainActor in
                guard let self, let d = data else { return }
                self.todaySteps = d.numberOfSteps.intValue
                self.todayDistanceMeters = d.distance?.doubleValue ?? 0
            }
        }
    }

    func loadWeekly() {
        guard isAvailable else { return }
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var days: [Day] = []
        let group = DispatchGroup()
        for offset in (0..<7).reversed() {
            guard let start = cal.date(byAdding: .day, value: -offset, to: today),
                  let end = cal.date(byAdding: .day, value: 1, to: start) else { continue }
            group.enter()
            pedometer.queryPedometerData(from: start, to: end) { data, _ in
                let steps = data?.numberOfSteps.intValue ?? 0
                Task { @MainActor in
                    days.append(Day(date: start, steps: steps))
                }
                group.leave()
            }
        }
        group.notify(queue: .main) { [weak self] in
            Task { @MainActor in
                self?.weekly = days.sorted { $0.date < $1.date }
            }
        }
    }

    func beginLiveSession() {
        guard isAvailable, !isLiveQueryActive else { return }
        liveSessionSteps = 0
        liveSessionDistance = 0
        isLiveQueryActive = true
        pedometer.startUpdates(from: Date()) { [weak self] data, _ in
            Task { @MainActor in
                guard let self, let d = data else { return }
                self.liveSessionSteps = d.numberOfSteps.intValue
                self.liveSessionDistance = d.distance?.doubleValue ?? 0
            }
        }
    }

    func endLiveSession() {
        pedometer.stopUpdates()
        isLiveQueryActive = false
        loadToday()
    }
}
