import Foundation
import CoreMotion
import Observation

@Observable
@MainActor
final class PedometerService {
    static let shared = PedometerService()

    private let pedometer = CMPedometer()
    private var isLiveQueryActive = false

    var todaySteps: Int = 0
    var todayDistanceMeters: Double = 0
    var liveSessionSteps: Int = 0
    var liveSessionDistance: Double = 0
    var isAuthorized: Bool = false
    var isAvailable: Bool = CMPedometer.isStepCountingAvailable()
    var weeklySteps: [DaySteps] = []
    var dailyGoal: Int = UserDefaults.standard.integer(forKey: "kickiq_step_goal") == 0 ? 10000 : UserDefaults.standard.integer(forKey: "kickiq_step_goal")

    private var liveBaselineSteps: Int = 0
    private var liveBaselineDistance: Double = 0
    private var sessionStart: Date?

    struct DaySteps: Identifiable, Hashable {
        let id = UUID()
        let date: Date
        let steps: Int
    }

    private init() {}

    func refreshAuthorization() {
        let status = CMPedometer.authorizationStatus()
        isAuthorized = status == .authorized
    }

    func requestAndLoadToday() {
        guard isAvailable else { return }
        let start = Calendar.current.startOfDay(for: Date())
        pedometer.queryPedometerData(from: start, to: Date()) { [weak self] data, _ in
            Task { @MainActor in
                guard let self else { return }
                self.refreshAuthorization()
                if let d = data {
                    self.todaySteps = d.numberOfSteps.intValue
                    self.todayDistanceMeters = d.distance?.doubleValue ?? 0
                    self.isAuthorized = true
                }
                self.startTodayLiveUpdates()
                self.loadWeekly()
            }
        }
    }

    private func startTodayLiveUpdates() {
        guard isAvailable else { return }
        let start = Calendar.current.startOfDay(for: Date())
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
        var days: [DaySteps] = []
        let group = DispatchGroup()
        for offset in (0..<7).reversed() {
            guard let start = cal.date(byAdding: .day, value: -offset, to: today),
                  let end = cal.date(byAdding: .day, value: 1, to: start) else { continue }
            group.enter()
            pedometer.queryPedometerData(from: start, to: end) { data, _ in
                let count = data?.numberOfSteps.intValue ?? 0
                Task { @MainActor in
                    days.append(DaySteps(date: start, steps: count))
                }
                group.leave()
            }
        }
        group.notify(queue: .main) { [weak self] in
            Task { @MainActor in
                self?.weeklySteps = days.sorted { $0.date < $1.date }
            }
        }
    }

    func beginLiveSession() {
        guard isAvailable else { return }
        liveSessionSteps = 0
        liveSessionDistance = 0
        sessionStart = Date()
        if isLiveQueryActive { return }
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
        sessionStart = nil
        startTodayLiveUpdates()
    }

    func setDailyGoal(_ goal: Int) {
        dailyGoal = max(1000, goal)
        UserDefaults.standard.set(dailyGoal, forKey: "kickiq_step_goal")
    }

    var todayDistanceMiles: Double {
        todayDistanceMeters / 1609.34
    }

    var goalProgress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(1.0, Double(todaySteps) / Double(dailyGoal))
    }
}
