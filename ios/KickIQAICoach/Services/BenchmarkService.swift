import Foundation

@Observable
@MainActor
class BenchmarkService {
    var benchmarkDrills: [BenchmarkDrill] = []

    func loadDrills(for ageRange: AgeRange, gender: PlayerGender = .male) {
        benchmarkDrills = Self.allBenchmarkDrills(for: ageRange, gender: gender)
    }

    func categoryScore(results: [BenchmarkResult], category: BenchmarkCategory, gender: PlayerGender = .male) -> Double? {
        let catResults = results.filter { $0.category == category && !$0.isSkipped && $0.latestScore != nil }
        guard !catResults.isEmpty else { return nil }
        let drills = benchmarkDrills.filter { $0.category == category }
        var totalPct: Double = 0
        var count = 0
        for result in catResults {
            guard let latest = result.latestScore,
                  let drill = drills.first(where: { $0.id == result.benchmarkDrillID }) else { continue }
            let pct = Self.scorePercentage(score: latest, drill: drill, gender: gender)
            totalPct += pct
            count += 1
        }
        return count > 0 ? totalPct / Double(count) : nil
    }

    func overallScore(results: [BenchmarkResult], gender: PlayerGender = .male) -> Double {
        let measured = results.filter { !$0.isSkipped }
        var totalPct: Double = 0
        var count = 0
        for result in measured {
            guard let latest = result.latestScore,
                  let drill = benchmarkDrills.first(where: { $0.id == result.benchmarkDrillID }) else { continue }
            let pct = Self.scorePercentage(score: latest, drill: drill, gender: gender)
            totalPct += pct
            count += 1
        }
        return count > 0 ? totalPct / Double(count) : 0
    }

    func weakestCategories(results: [BenchmarkResult], gender: PlayerGender = .male) -> [BenchmarkCategory] {
        var scores: [(BenchmarkCategory, Double)] = []
        for cat in BenchmarkCategory.allCases {
            if let score = categoryScore(results: results, category: cat, gender: gender) {
                scores.append((cat, score))
            }
        }
        return scores.sorted { $0.1 < $1.1 }.prefix(3).map(\.0)
    }

    func drillPriorities(results: [BenchmarkResult], gender: PlayerGender = .male) -> [String] {
        let weak = weakestCategories(results: results, gender: gender)
        return weak.map(\.rawValue)
    }

    static func scorePercentage(score: Double, drill: BenchmarkDrill, gender: PlayerGender = .male) -> Double {
        if let gt = drill.genderThresholds {
            let eliteVal = gt.elite(for: gender)
            if drill.higherIsBetter {
                return min(100, (score / eliteVal) * 100)
            } else {
                guard score > 0 else { return 0 }
                return min(100, (eliteVal / score) * 100)
            }
        }
        let eliteVal = drill.eliteThresholds["elite"] ?? 100
        if drill.higherIsBetter {
            return min(100, (score / eliteVal) * 100)
        } else {
            guard score > 0 else { return 0 }
            return min(100, (eliteVal / score) * 100)
        }
    }

    static func averageComparison(score: Double, drill: BenchmarkDrill, gender: PlayerGender) -> String {
        guard let gt = drill.genderThresholds else { return "" }
        let avg = gt.average(for: gender)
        if drill.higherIsBetter {
            if score > avg * 1.1 { return "Above Average" }
            if score < avg * 0.9 { return "Below Average" }
        } else {
            if score < avg * 0.9 { return "Above Average" }
            if score > avg * 1.1 { return "Below Average" }
        }
        return "Average"
    }

    // MARK: - US Soccer DA-Aligned Benchmark Drills

    static func allBenchmarkDrills(for ageRange: AgeRange, gender: PlayerGender = .male) -> [BenchmarkDrill] {
        var drills: [BenchmarkDrill] = []

        switch ageRange {
        case .under8:
            drills = under8Drills()
        case .nine12:
            drills = nine12Drills()
        case .thirteen14:
            drills = thirteen14Drills()
        case .fifteen18:
            drills = fifteen18Drills()
        case .eighteenPlus:
            drills = eighteenPlusDrills()
        }

        return drills
    }

    // MARK: - Under 8

    private static func under8Drills() -> [BenchmarkDrill] {
        [
            BenchmarkDrill(
                id: "u8_juggling",
                category: .ballControl,
                name: "Juggling Test",
                instructions: "Drop the ball from your hands and keep it in the air using feet only. Count consecutive touches. Best of 3 tries.",
                howToRecord: "Record your highest number of consecutive touches.",
                unit: "touches",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 25, maleAverage: 8, femaleElite: 20, femaleAverage: 6)
            ),
            BenchmarkDrill(
                id: "u8_dribble_cone",
                category: .dribbling,
                name: "Cone Weave",
                instructions: "Set 5 cones 2 yards apart in a line. Dribble through all cones and back. Time with a stopwatch.",
                howToRecord: "Record your time in seconds (faster is better).",
                unit: "seconds",
                higherIsBetter: false,
                genderThresholds: GenderThresholds(maleElite: 14.0, maleAverage: 20.0, femaleElite: 15.0, femaleAverage: 21.0)
            ),
            BenchmarkDrill(
                id: "u8_wall_pass",
                category: .firstTouch,
                name: "Wall Pass & Trap",
                instructions: "Stand 3 yards from a wall. Pass and trap the return using inside of foot. Alternate feet. Count controlled returns in 30 seconds.",
                howToRecord: "Record total controlled returns in 30 seconds.",
                unit: "touches",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 15, maleAverage: 8, femaleElite: 14, femaleAverage: 7)
            ),
            BenchmarkDrill(
                id: "u8_target_pass",
                category: .passing,
                name: "Target Passing",
                instructions: "Place a 3x3 foot target on a wall at ground level, 8 yards away. Take 10 passes. Count hits on target.",
                howToRecord: "Record number of on-target passes out of 10.",
                unit: "out of 10",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 7, maleAverage: 4, femaleElite: 7, femaleAverage: 4)
            ),
            BenchmarkDrill(
                id: "u8_shooting",
                category: .shooting,
                name: "Goal Scoring",
                instructions: "From 10 yards, shoot at a full-size goal. Take 10 shots on frame. Count goals or on-target shots.",
                howToRecord: "Record number of on-target shots out of 10.",
                unit: "out of 10",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 7, maleAverage: 4, femaleElite: 7, femaleAverage: 4)
            ),
            BenchmarkDrill(
                id: "u8_shuttle",
                category: .agility,
                name: "10-Yard Shuttle",
                instructions: "Set two cones 10 yards apart. Sprint to the far cone, touch it, sprint back. Time yourself.",
                howToRecord: "Record your time in seconds (faster is better).",
                unit: "seconds",
                higherIsBetter: false,
                genderThresholds: GenderThresholds(maleElite: 5.5, maleAverage: 7.0, femaleElite: 5.8, femaleAverage: 7.3)
            ),
        ]
    }

    // MARK: - 9–12

    private static func nine12Drills() -> [BenchmarkDrill] {
        [
            BenchmarkDrill(
                id: "912_juggling",
                category: .ballControl,
                name: "Juggling Test",
                instructions: "Drop the ball and juggle using feet, thighs, and head. Count consecutive touches without the ball hitting the ground. Best of 3 attempts.",
                howToRecord: "Record your highest number of consecutive touches.",
                unit: "touches",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 50, maleAverage: 20, femaleElite: 40, femaleAverage: 15)
            ),
            BenchmarkDrill(
                id: "912_figure8",
                category: .ballControl,
                name: "Figure-8 Dribble",
                instructions: "Set two cones 3 feet apart. Dribble in a figure-8 pattern using inside and outside of both feet. Count complete figure-8s in 60 seconds.",
                howToRecord: "Record the number of complete figure-8 loops in 60 seconds.",
                unit: "loops",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 14, maleAverage: 8, femaleElite: 12, femaleAverage: 7)
            ),
            BenchmarkDrill(
                id: "912_wall_pass",
                category: .firstTouch,
                name: "Wall Pass & Control",
                instructions: "Stand 5 yards from a wall. Pass and control the return with one touch — alternating left and right foot. Count controlled returns in 60 seconds.",
                howToRecord: "Record total controlled returns in 60 seconds.",
                unit: "touches",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 30, maleAverage: 18, femaleElite: 28, femaleAverage: 16)
            ),
            BenchmarkDrill(
                id: "912_aerial",
                category: .firstTouch,
                name: "Aerial Control",
                instructions: "Toss the ball 8 feet in the air. Control it dead within 2 steps using foot, thigh, or chest. 10 attempts total.",
                howToRecord: "Record the number of successful dead controls out of 10.",
                unit: "out of 10",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 7, maleAverage: 4, femaleElite: 7, femaleAverage: 4)
            ),
            BenchmarkDrill(
                id: "912_target_pass",
                category: .passing,
                name: "Target Passing",
                instructions: "Place a 2x2 foot target on a wall at ground level, 12 yards away. Take 10 passes with each foot (20 total). Count hits on target.",
                howToRecord: "Record number of on-target passes out of 20.",
                unit: "out of 20",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 14, maleAverage: 8, femaleElite: 13, femaleAverage: 7)
            ),
            BenchmarkDrill(
                id: "912_shooting",
                category: .shooting,
                name: "Shooting Accuracy",
                instructions: "From 14 yards out, shoot at each corner of the goal (top left, top right, bottom left, bottom right). 2 shots per corner = 8 total. Count on-target shots.",
                howToRecord: "Record number of shots on target out of 8.",
                unit: "out of 8",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 6, maleAverage: 3, femaleElite: 6, femaleAverage: 3)
            ),
            BenchmarkDrill(
                id: "912_cone_slalom",
                category: .dribbling,
                name: "Cone Slalom Sprint",
                instructions: "Set 8 cones in a line, 2 yards apart. Dribble through all cones and back as fast as possible.",
                howToRecord: "Record your time in seconds (faster is better).",
                unit: "seconds",
                higherIsBetter: false,
                genderThresholds: GenderThresholds(maleElite: 14.0, maleAverage: 18.5, femaleElite: 15.0, femaleAverage: 19.5)
            ),
            BenchmarkDrill(
                id: "912_ttest",
                category: .agility,
                name: "T-Test",
                instructions: "Set up a T with cones: 10 yards forward, then 5 yards left and right. Sprint forward, shuffle left, shuffle right, shuffle to center, backpedal to start.",
                howToRecord: "Record your time in seconds (faster is better).",
                unit: "seconds",
                higherIsBetter: false,
                genderThresholds: GenderThresholds(maleElite: 10.5, maleAverage: 12.5, femaleElite: 11.0, femaleAverage: 13.0)
            ),
        ]
    }

    // MARK: - 13–14

    private static func thirteen14Drills() -> [BenchmarkDrill] {
        [
            BenchmarkDrill(
                id: "1314_juggling",
                category: .ballControl,
                name: "Juggling Test",
                instructions: "Juggle using feet, thighs, and head. Count consecutive touches without the ball hitting the ground. Best of 3 attempts.",
                howToRecord: "Record your highest number of consecutive touches.",
                unit: "touches",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 80, maleAverage: 35, femaleElite: 65, femaleAverage: 25)
            ),
            BenchmarkDrill(
                id: "1314_figure8",
                category: .ballControl,
                name: "Figure-8 Dribble",
                instructions: "Set two cones 3 feet apart. Dribble in a figure-8 pattern using inside and outside of both feet. Count complete loops in 60 seconds.",
                howToRecord: "Record the number of complete figure-8 loops in 60 seconds.",
                unit: "loops",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 17, maleAverage: 11, femaleElite: 15, femaleAverage: 10)
            ),
            BenchmarkDrill(
                id: "1314_wall_pass",
                category: .firstTouch,
                name: "Wall Pass & Control",
                instructions: "Stand 5 yards from a wall. Pass and control the return — alternating inside left, inside right, outside left, outside right. Count controlled returns in 60 seconds.",
                howToRecord: "Record total controlled returns in 60 seconds.",
                unit: "touches",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 35, maleAverage: 22, femaleElite: 32, femaleAverage: 20)
            ),
            BenchmarkDrill(
                id: "1314_aerial",
                category: .firstTouch,
                name: "Aerial Control",
                instructions: "Toss the ball 10 feet in the air. Control it dead within 2 steps using any surface (foot, thigh, chest). 10 attempts total.",
                howToRecord: "Record the number of successful dead controls out of 10.",
                unit: "out of 10",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 8, maleAverage: 5, femaleElite: 8, femaleAverage: 5)
            ),
            BenchmarkDrill(
                id: "1314_target_pass",
                category: .passing,
                name: "Target Passing",
                instructions: "Place a 2x2 foot target on a wall at ground level, 15 yards away. Take 10 passes with each foot (20 total). Count hits on target.",
                howToRecord: "Record number of on-target passes out of 20.",
                unit: "out of 20",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 15, maleAverage: 9, femaleElite: 14, femaleAverage: 8)
            ),
            BenchmarkDrill(
                id: "1314_longball",
                category: .passing,
                name: "Long Ball Accuracy",
                instructions: "Set a 5-yard circle 25 yards away. Take 10 long passes and count how many land inside the circle.",
                howToRecord: "Record number of passes landing in the target out of 10.",
                unit: "out of 10",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 6, maleAverage: 3, femaleElite: 5, femaleAverage: 3)
            ),
            BenchmarkDrill(
                id: "1314_shooting",
                category: .shooting,
                name: "Shooting Accuracy",
                instructions: "From 16 yards out, shoot at each corner of the goal (top left, top right, bottom left, bottom right). 3 shots per corner = 12 total. Count on-target shots.",
                howToRecord: "Record number of shots on target out of 12.",
                unit: "out of 12",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 9, maleAverage: 5, femaleElite: 8, femaleAverage: 5)
            ),
            BenchmarkDrill(
                id: "1314_cone_slalom",
                category: .dribbling,
                name: "Cone Slalom Sprint",
                instructions: "Set 10 cones in a line, 2 yards apart. Dribble through all 10 cones and back as fast as possible.",
                howToRecord: "Record your time in seconds (faster is better).",
                unit: "seconds",
                higherIsBetter: false,
                genderThresholds: GenderThresholds(maleElite: 13.0, maleAverage: 16.0, femaleElite: 14.0, femaleAverage: 17.0)
            ),
            BenchmarkDrill(
                id: "1314_1v1_moves",
                category: .dribbling,
                name: "1v1 Moves Challenge",
                instructions: "Set a cone as a defender. Approach at speed and perform a skill move (stepover, Cruyff turn, scissors) to beat it, then accelerate past. 10 attempts.",
                howToRecord: "Record number of clean, explosive moves out of 10.",
                unit: "out of 10",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 8, maleAverage: 5, femaleElite: 7, femaleAverage: 5)
            ),
            BenchmarkDrill(
                id: "1314_ttest",
                category: .agility,
                name: "T-Test",
                instructions: "Set up a T with cones: 10 yards forward, then 5 yards left and right. Sprint forward, shuffle left, shuffle right, shuffle to center, backpedal to start.",
                howToRecord: "Record your time in seconds (faster is better).",
                unit: "seconds",
                higherIsBetter: false,
                genderThresholds: GenderThresholds(maleElite: 9.8, maleAverage: 11.5, femaleElite: 10.5, femaleAverage: 12.2)
            ),
            BenchmarkDrill(
                id: "1314_illinois",
                category: .agility,
                name: "Illinois Agility Run",
                instructions: "Standard Illinois agility course: 10m long, 5m wide, with 4 center cones to weave through. Sprint start, weave, and finish.",
                howToRecord: "Record your time in seconds (faster is better).",
                unit: "seconds",
                higherIsBetter: false,
                genderThresholds: GenderThresholds(maleElite: 15.5, maleAverage: 18.0, femaleElite: 16.5, femaleAverage: 19.0)
            ),
        ]
    }

    // MARK: - 15–18 (High School)

    private static func fifteen18Drills() -> [BenchmarkDrill] {
        var drills: [BenchmarkDrill] = [
            BenchmarkDrill(
                id: "1518_juggling",
                category: .ballControl,
                name: "Juggling Test",
                instructions: "Juggle using feet, thighs, and head. Count consecutive touches without the ball hitting the ground. Best of 3 attempts.",
                howToRecord: "Record your highest number of consecutive touches.",
                unit: "touches",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 100, maleAverage: 45, femaleElite: 80, femaleAverage: 35)
            ),
            BenchmarkDrill(
                id: "1518_figure8",
                category: .ballControl,
                name: "Figure-8 Dribble",
                instructions: "Set two cones 3 feet apart. Dribble in a figure-8 pattern using inside and outside of both feet. Count complete loops in 60 seconds.",
                howToRecord: "Record the number of complete figure-8 loops in 60 seconds.",
                unit: "loops",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 20, maleAverage: 13, femaleElite: 18, femaleAverage: 12)
            ),
            BenchmarkDrill(
                id: "1518_wall_pass",
                category: .firstTouch,
                name: "Wall Pass & Control",
                instructions: "Stand 5 yards from a wall. Pass and control — alternating inside left, inside right, outside left, outside right. Count controlled returns in 60 seconds.",
                howToRecord: "Record total controlled returns in 60 seconds.",
                unit: "touches",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 40, maleAverage: 25, femaleElite: 36, femaleAverage: 22)
            ),
            BenchmarkDrill(
                id: "1518_aerial",
                category: .firstTouch,
                name: "Aerial Control",
                instructions: "Toss the ball 10+ feet in the air. Control it dead within 2 steps using any surface. 10 attempts total.",
                howToRecord: "Record the number of successful dead controls out of 10.",
                unit: "out of 10",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 9, maleAverage: 6, femaleElite: 8, femaleAverage: 5)
            ),
            BenchmarkDrill(
                id: "1518_target_pass",
                category: .passing,
                name: "Target Passing",
                instructions: "Place a 2x2 foot target on a wall at ground level, 15 yards away. Take 10 passes with each foot (20 total). Count hits on target.",
                howToRecord: "Record number of on-target passes out of 20.",
                unit: "out of 20",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 17, maleAverage: 11, femaleElite: 16, femaleAverage: 10)
            ),
            BenchmarkDrill(
                id: "1518_longball",
                category: .passing,
                name: "Long Ball Accuracy",
                instructions: "Set a 5-yard circle 30 yards away. Take 10 long passes and count how many land inside the circle.",
                howToRecord: "Record number of passes landing in the target out of 10.",
                unit: "out of 10",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 7, maleAverage: 4, femaleElite: 6, femaleAverage: 3)
            ),
            BenchmarkDrill(
                id: "1518_shooting",
                category: .shooting,
                name: "Shooting Accuracy",
                instructions: "From 18 yards out, shoot at each corner of the goal (top left, top right, bottom left, bottom right). 3 shots per corner = 12 total.",
                howToRecord: "Record number of shots on target out of 12.",
                unit: "out of 12",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 10, maleAverage: 6, femaleElite: 9, femaleAverage: 5)
            ),
            BenchmarkDrill(
                id: "1518_power_shot",
                category: .shooting,
                name: "Power Shot Test",
                instructions: "Take 5 full-power shots from 20 yards. Rate each on a 1–5 scale for strike quality, accuracy, and power. Total all scores.",
                howToRecord: "Record total score out of 75 (5 shots × 3 criteria × 5 max).",
                unit: "out of 75",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 60, maleAverage: 38, femaleElite: 55, femaleAverage: 35)
            ),
            BenchmarkDrill(
                id: "1518_cone_slalom",
                category: .dribbling,
                name: "Cone Slalom Sprint",
                instructions: "Set 10 cones in a line, 2 yards apart. Dribble through all 10 cones and back as fast as possible.",
                howToRecord: "Record your time in seconds (faster is better).",
                unit: "seconds",
                higherIsBetter: false,
                genderThresholds: GenderThresholds(maleElite: 12.0, maleAverage: 15.0, femaleElite: 13.0, femaleAverage: 16.0)
            ),
            BenchmarkDrill(
                id: "1518_1v1_moves",
                category: .dribbling,
                name: "1v1 Moves Challenge",
                instructions: "Set a cone as a defender. Approach at speed and perform a skill move to beat it, then accelerate past. 10 attempts — count clean executions.",
                howToRecord: "Record number of clean moves out of 10.",
                unit: "out of 10",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 8, maleAverage: 5, femaleElite: 8, femaleAverage: 5)
            ),
            BenchmarkDrill(
                id: "1518_ttest",
                category: .agility,
                name: "T-Test",
                instructions: "Set up a T with cones: 10 yards forward, then 5 yards left and right. Sprint forward, shuffle left, shuffle right, shuffle to center, backpedal to start.",
                howToRecord: "Record your time in seconds (faster is better).",
                unit: "seconds",
                higherIsBetter: false,
                genderThresholds: GenderThresholds(maleElite: 9.5, maleAverage: 11.0, femaleElite: 10.2, femaleAverage: 11.8)
            ),
            BenchmarkDrill(
                id: "1518_illinois",
                category: .agility,
                name: "Illinois Agility Run",
                instructions: "Standard Illinois agility course: 10m long, 5m wide, with 4 center cones to weave through. Sprint start, weave, and finish.",
                howToRecord: "Record your time in seconds (faster is better).",
                unit: "seconds",
                higherIsBetter: false,
                genderThresholds: GenderThresholds(maleElite: 15.0, maleAverage: 17.5, femaleElite: 16.0, femaleAverage: 18.5)
            ),
            BenchmarkDrill(
                id: "1518_1mile",
                category: .endurance,
                name: "1-Mile Run",
                instructions: "Run 1 mile (4 laps on a standard track) as fast as you can. Use a stopwatch or phone timer.",
                howToRecord: "Record your time in minutes and seconds (e.g. 6:30 = enter 6.5). Convert seconds: 15s = .25, 30s = .5, 45s = .75.",
                unit: "minutes",
                higherIsBetter: false,
                genderThresholds: GenderThresholds(maleElite: 5.5, maleAverage: 7.0, femaleElite: 6.25, femaleAverage: 8.0)
            ),
            BenchmarkDrill(
                id: "1518_2mile",
                category: .endurance,
                name: "2-Mile Run",
                instructions: "Run 2 miles (8 laps on a standard track) as fast as you can. Pace yourself — start steady and build.",
                howToRecord: "Record your time in minutes (e.g. 13:00 = enter 13.0, 13:30 = enter 13.5).",
                unit: "minutes",
                higherIsBetter: false,
                genderThresholds: GenderThresholds(maleElite: 11.5, maleAverage: 14.5, femaleElite: 13.0, femaleAverage: 16.5)
            ),
        ]

        return drills
    }

    // MARK: - 18+

    private static func eighteenPlusDrills() -> [BenchmarkDrill] {
        [
            BenchmarkDrill(
                id: "18p_juggling",
                category: .ballControl,
                name: "Juggling Test",
                instructions: "Juggle using feet, thighs, and head. Count consecutive touches. Best of 3 attempts.",
                howToRecord: "Record your highest number of consecutive touches.",
                unit: "touches",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 100, maleAverage: 50, femaleElite: 85, femaleAverage: 40)
            ),
            BenchmarkDrill(
                id: "18p_figure8",
                category: .ballControl,
                name: "Figure-8 Dribble",
                instructions: "Set two cones 3 feet apart. Dribble in a figure-8 pattern. Count complete loops in 60 seconds.",
                howToRecord: "Record the number of complete figure-8 loops in 60 seconds.",
                unit: "loops",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 22, maleAverage: 14, femaleElite: 19, femaleAverage: 12)
            ),
            BenchmarkDrill(
                id: "18p_wall_pass",
                category: .firstTouch,
                name: "Wall Pass & Control",
                instructions: "Stand 5 yards from a wall. Pass and control — alternating surfaces. Count controlled returns in 60 seconds.",
                howToRecord: "Record total controlled returns in 60 seconds.",
                unit: "touches",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 42, maleAverage: 28, femaleElite: 38, femaleAverage: 24)
            ),
            BenchmarkDrill(
                id: "18p_aerial",
                category: .firstTouch,
                name: "Aerial Control",
                instructions: "Toss the ball 10+ feet high. Control it dead within 2 steps. 10 attempts.",
                howToRecord: "Record successful controls out of 10.",
                unit: "out of 10",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 9, maleAverage: 6, femaleElite: 9, femaleAverage: 6)
            ),
            BenchmarkDrill(
                id: "18p_target_pass",
                category: .passing,
                name: "Target Passing",
                instructions: "2x2 foot target, 15 yards away. 10 passes per foot (20 total). Count hits.",
                howToRecord: "Record number of on-target passes out of 20.",
                unit: "out of 20",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 18, maleAverage: 12, femaleElite: 16, femaleAverage: 10)
            ),
            BenchmarkDrill(
                id: "18p_longball",
                category: .passing,
                name: "Long Ball Accuracy",
                instructions: "5-yard circle, 30 yards away. 10 long passes. Count landings inside.",
                howToRecord: "Record number of passes landing in the target out of 10.",
                unit: "out of 10",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 7, maleAverage: 4, femaleElite: 6, femaleAverage: 3)
            ),
            BenchmarkDrill(
                id: "18p_shooting",
                category: .shooting,
                name: "Shooting Accuracy",
                instructions: "From 18 yards, shoot at corners. 3 per corner = 12 total.",
                howToRecord: "Record on-target shots out of 12.",
                unit: "out of 12",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 10, maleAverage: 6, femaleElite: 9, femaleAverage: 5)
            ),
            BenchmarkDrill(
                id: "18p_power_shot",
                category: .shooting,
                name: "Power Shot Test",
                instructions: "5 full-power shots from 20 yards. Rate 1–5 for strike, accuracy, power.",
                howToRecord: "Record total out of 75.",
                unit: "out of 75",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 62, maleAverage: 40, femaleElite: 57, femaleAverage: 36)
            ),
            BenchmarkDrill(
                id: "18p_cone_slalom",
                category: .dribbling,
                name: "Cone Slalom Sprint",
                instructions: "10 cones, 2 yards apart. Dribble through and back.",
                howToRecord: "Record time in seconds (faster is better).",
                unit: "seconds",
                higherIsBetter: false,
                genderThresholds: GenderThresholds(maleElite: 11.5, maleAverage: 14.5, femaleElite: 12.5, femaleAverage: 15.5)
            ),
            BenchmarkDrill(
                id: "18p_1v1_moves",
                category: .dribbling,
                name: "1v1 Moves Challenge",
                instructions: "Cone defender. Approach + skill move + accelerate. 10 attempts.",
                howToRecord: "Record clean moves out of 10.",
                unit: "out of 10",
                higherIsBetter: true,
                genderThresholds: GenderThresholds(maleElite: 9, maleAverage: 6, femaleElite: 8, femaleAverage: 5)
            ),
            BenchmarkDrill(
                id: "18p_ttest",
                category: .agility,
                name: "T-Test",
                instructions: "Standard T-Test: sprint forward, shuffle left/right, backpedal.",
                howToRecord: "Record time in seconds (faster is better).",
                unit: "seconds",
                higherIsBetter: false,
                genderThresholds: GenderThresholds(maleElite: 9.2, maleAverage: 10.8, femaleElite: 10.0, femaleAverage: 11.5)
            ),
            BenchmarkDrill(
                id: "18p_illinois",
                category: .agility,
                name: "Illinois Agility Run",
                instructions: "Standard Illinois agility course.",
                howToRecord: "Record time in seconds (faster is better).",
                unit: "seconds",
                higherIsBetter: false,
                genderThresholds: GenderThresholds(maleElite: 14.5, maleAverage: 17.0, femaleElite: 15.5, femaleAverage: 18.0)
            ),
            BenchmarkDrill(
                id: "18p_1mile",
                category: .endurance,
                name: "1-Mile Run",
                instructions: "Run 1 mile as fast as you can.",
                howToRecord: "Record time in minutes (e.g. 6:30 = 6.5).",
                unit: "minutes",
                higherIsBetter: false,
                genderThresholds: GenderThresholds(maleElite: 5.25, maleAverage: 6.75, femaleElite: 6.0, femaleAverage: 7.75)
            ),
            BenchmarkDrill(
                id: "18p_2mile",
                category: .endurance,
                name: "2-Mile Run",
                instructions: "Run 2 miles as fast as you can.",
                howToRecord: "Record time in minutes (e.g. 13:30 = 13.5).",
                unit: "minutes",
                higherIsBetter: false,
                genderThresholds: GenderThresholds(maleElite: 11.0, maleAverage: 14.0, femaleElite: 12.5, femaleAverage: 16.0)
            ),
        ]
    }
}
