import ActivityKit
import Foundation

nonisolated struct DrillActivityAttributes: ActivityAttributes, Sendable {
    public struct ContentState: Codable, Hashable, Sendable {
        var timeRemaining: Int
        var totalTime: Int
        var currentSet: Int
        var totalSets: Int
        var isResting: Bool
        var isRunning: Bool
    }

    var drillName: String
    var targetSkill: String
}
