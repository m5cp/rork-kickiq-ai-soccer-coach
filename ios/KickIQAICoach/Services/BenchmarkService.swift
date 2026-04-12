import Foundation

@Observable
@MainActor
class BenchmarkService {
    var benchmarkDrills: [BenchmarkDrill] = []

    func loadDrills(for ageRange: AgeRange) {
        benchmarkDrills = Self.allBenchmarkDrills(for: ageRange)
    }

    func categoryScore(results: [BenchmarkResult], category: BenchmarkCategory) -> Double? {
        let catResults = results.filter { $0.category == category && $0.latestScore != nil }
        guard !catResults.isEmpty else { return nil }
        let drills = benchmarkDrills.filter { $0.category == category }
        var totalPct: Double = 0
        var count = 0
        for result in catResults {
            guard let latest = result.latestScore,
                  let drill = drills.first(where: { $0.id == result.benchmarkDrillID }) else { continue }
            let pct = Self.scorePercentage(score: latest, drill: drill)
            totalPct += pct
            count += 1
        }
        return count > 0 ? totalPct / Double(count) : nil
    }

    func overallScore(results: [BenchmarkResult]) -> Double {
        var totalPct: Double = 0
        var count = 0
        for result in results {
            guard let latest = result.latestScore,
                  let drill = benchmarkDrills.first(where: { $0.id == result.benchmarkDrillID }) else { continue }
            let pct = Self.scorePercentage(score: latest, drill: drill)
            totalPct += pct
            count += 1
        }
        return count > 0 ? totalPct / Double(count) : 0
    }

    func weakestCategories(results: [BenchmarkResult]) -> [BenchmarkCategory] {
        var scores: [(BenchmarkCategory, Double)] = []
        for cat in BenchmarkCategory.allCases {
            if let score = categoryScore(results: results, category: cat) {
                scores.append((cat, score))
            }
        }
        return scores.sorted { $0.1 < $1.1 }.prefix(3).map(\.0)
    }

    func drillPriorities(results: [BenchmarkResult]) -> [String] {
        let weak = weakestCategories(results: results)
        return weak.map(\.rawValue)
    }

    static func scorePercentage(score: Double, drill: BenchmarkDrill) -> Double {
        let eliteVal = drill.eliteThresholds["elite"] ?? 100
        if drill.higherIsBetter {
            return min(100, (score / eliteVal) * 100)
        } else {
            guard score > 0 else { return 0 }
            return min(100, (eliteVal / score) * 100)
        }
    }

    static func allBenchmarkDrills(for ageRange: AgeRange) -> [BenchmarkDrill] {
        let ageMultiplier: Double = switch ageRange {
        case .under12: 0.7
        case .twelve15: 0.85
        case .sixteen18: 0.95
        case .eighteenPlus: 1.0
        }

        return [
            BenchmarkDrill(
                id: "bc_juggling",
                category: .ballControl,
                name: "Juggling Test",
                instructions: "Start with the ball in your hands. Drop it and juggle using feet, thighs, and head. Count consecutive touches without the ball hitting the ground. Use your best of 3 attempts.",
                howToRecord: "Record your highest number of consecutive touches from 3 attempts.",
                unit: "touches",
                higherIsBetter: true,
                eliteThresholds: ["elite": 100 * ageMultiplier]
            ),
            BenchmarkDrill(
                id: "bc_figure8",
                category: .ballControl,
                name: "Figure-8 Dribble",
                instructions: "Set two cones 3 feet apart. Dribble in a figure-8 pattern using inside and outside of both feet. Count how many complete figure-8s you can do in 60 seconds.",
                howToRecord: "Record the number of complete figure-8 loops in 60 seconds.",
                unit: "loops",
                higherIsBetter: true,
                eliteThresholds: ["elite": 20 * ageMultiplier]
            ),
            BenchmarkDrill(
                id: "ft_wall_pass",
                category: .firstTouch,
                name: "Wall Pass & Control",
                instructions: "Stand 5 yards from a wall. Pass against it and control the return with one touch — alternating inside left, inside right, outside left, outside right. Count successful controlled touches in 60 seconds.",
                howToRecord: "Record total controlled returns in 60 seconds.",
                unit: "touches",
                higherIsBetter: true,
                eliteThresholds: ["elite": 40 * ageMultiplier]
            ),
            BenchmarkDrill(
                id: "ft_aerial",
                category: .firstTouch,
                name: "Aerial Control",
                instructions: "Toss the ball 10 feet in the air. Control it dead within 2 steps using any surface (foot, thigh, chest). 10 attempts total.",
                howToRecord: "Record the number of successful dead controls out of 10.",
                unit: "out of 10",
                higherIsBetter: true,
                eliteThresholds: ["elite": 9]
            ),
            BenchmarkDrill(
                id: "pa_target",
                category: .passing,
                name: "Target Passing",
                instructions: "Place a 2x2 foot target on a wall at ground level, 15 yards away. Take 10 passes with each foot (20 total). Count hits on target.",
                howToRecord: "Record number of on-target passes out of 20.",
                unit: "out of 20",
                higherIsBetter: true,
                eliteThresholds: ["elite": 17 * ageMultiplier]
            ),
            BenchmarkDrill(
                id: "pa_longball",
                category: .passing,
                name: "Long Ball Accuracy",
                instructions: "Set a 5-yard circle 30 yards away. Take 10 long passes and count how many land inside the circle.",
                howToRecord: "Record number of passes landing in the target circle out of 10.",
                unit: "out of 10",
                higherIsBetter: true,
                eliteThresholds: ["elite": 7 * ageMultiplier]
            ),
            BenchmarkDrill(
                id: "sh_accuracy",
                category: .shooting,
                name: "Shooting Accuracy",
                instructions: "From 18 yards out, shoot at each corner of the goal (top left, top right, bottom left, bottom right). 3 shots per corner = 12 total. Count on-target shots.",
                howToRecord: "Record number of shots on target out of 12.",
                unit: "out of 12",
                higherIsBetter: true,
                eliteThresholds: ["elite": 10 * ageMultiplier]
            ),
            BenchmarkDrill(
                id: "sh_power",
                category: .shooting,
                name: "Power Shot Test",
                instructions: "Take 5 full-power shots from 20 yards. Rate each shot on a 1-5 scale for clean strike, accuracy, and power. Add up the scores.",
                howToRecord: "Record total score out of 75 (5 shots x 3 criteria x 5 max).",
                unit: "out of 75",
                higherIsBetter: true,
                eliteThresholds: ["elite": 60 * ageMultiplier]
            ),
            BenchmarkDrill(
                id: "dr_cone",
                category: .dribbling,
                name: "Cone Slalom Sprint",
                instructions: "Set 10 cones in a line, 2 yards apart. Dribble through all 10 cones and back as fast as possible. Time yourself with a stopwatch.",
                howToRecord: "Record your time in seconds (faster is better).",
                unit: "seconds",
                higherIsBetter: false,
                eliteThresholds: ["elite": 12.0 / ageMultiplier]
            ),
            BenchmarkDrill(
                id: "dr_1v1",
                category: .dribbling,
                name: "1v1 Moves Challenge",
                instructions: "Set a cone as a defender. Approach at speed and perform a skill move (stepover, Cruyff turn, scissors) to beat it, then accelerate past. 10 attempts — count clean, explosive executions.",
                howToRecord: "Record number of clean moves out of 10.",
                unit: "out of 10",
                higherIsBetter: true,
                eliteThresholds: ["elite": 8 * ageMultiplier]
            ),
            BenchmarkDrill(
                id: "ag_ttest",
                category: .agility,
                name: "T-Test",
                instructions: "Set up a T with cones: 10 yards forward, then 5 yards left and right. Sprint forward, shuffle left, shuffle right, shuffle back to center, backpedal to start. Time yourself.",
                howToRecord: "Record your time in seconds (faster is better).",
                unit: "seconds",
                higherIsBetter: false,
                eliteThresholds: ["elite": 9.5 / ageMultiplier]
            ),
            BenchmarkDrill(
                id: "ag_illinois",
                category: .agility,
                name: "Illinois Agility Run",
                instructions: "Standard Illinois agility course: 10m long, 5m wide, with 4 center cones to weave through. Sprint start, weave, and finish. Time yourself.",
                howToRecord: "Record your time in seconds (faster is better).",
                unit: "seconds",
                higherIsBetter: false,
                eliteThresholds: ["elite": 15.0 / ageMultiplier]
            ),
        ]
    }
}
