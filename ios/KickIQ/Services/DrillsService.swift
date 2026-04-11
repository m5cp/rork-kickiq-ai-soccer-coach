import Foundation

@Observable
@MainActor
class DrillsService {
    var allDrills: [Drill] = []
    var activeFilter: DrillFilter = .default
    let philosophy: TrainingPhilosophy = .shared

    func loadDrills(for position: PlayerPosition, weakness: WeaknessArea, skillLevel: SkillLevel) {
        allDrills = generateDrills(for: position, weakness: weakness, level: skillLevel)
    }

    func filteredDrills(weakestSkills: [SkillCategory]) -> [Drill] {
        var result = allDrills

        if !activeFilter.isEmpty {
            result = result.filter { activeFilter.matches($0) }
        } else if !weakestSkills.isEmpty {
            let weakNames = Set(weakestSkills.map(\.rawValue))
            let filtered = result.filter { weakNames.contains($0.targetSkill) }
            if !filtered.isEmpty { result = filtered }
        }

        return result
    }

    func restGuidance(for drill: Drill) -> RestGuidance {
        drill.restGuidance ?? philosophy.restGuidance(for: drill.intensity)
    }

    func surfaceNote(for surface: TrainingSurface) -> String {
        philosophy.surfaceNote(for: surface)
    }

    func drillsSortedByWeakness(weakestSkills: [SkillCategory]) -> [Drill] {
        guard !weakestSkills.isEmpty else { return allDrills }
        let weakSet = Set(weakestSkills.map(\.rawValue))
        return allDrills.sorted { a, b in
            let aWeak = weakSet.contains(a.targetSkill)
            let bWeak = weakSet.contains(b.targetSkill)
            if aWeak != bWeak { return aWeak }
            return false
        }
    }

    func filteredDrills(with filter: DrillFilter) -> [Drill] {
        guard !filter.isEmpty else { return allDrills }
        return allDrills.filter { filter.matches($0) }
    }

    func drills(for category: SkillCategory) -> [Drill] {
        allDrills.filter { $0.resolvedCategory == category }
    }

    func focusCategories(for position: PlayerPosition, weaknesses: [SkillCategory] = []) -> [FocusCategory] {
        var counts: [SkillCategory: Int] = [:]
        for drill in allDrills {
            if let cat = drill.resolvedCategory {
                counts[cat, default: 0] += 1
            }
        }
        return FocusCategory.fromSkillCategories(for: position, weaknesses: weaknesses, drillCounts: counts)
    }

    private func generateDrills(for position: PlayerPosition, weakness: WeaknessArea, level: SkillLevel) -> [Drill] {
        var drills: [Drill] = []

        let skills = position.skills
        for skill in skills {
            drills.append(contentsOf: drillsForSkill(skill, level: level))
        }

        let universalCategories: [SkillCategory] = [.turning, .striking, .receiving, .juggling]
        for category in universalCategories where !skills.contains(category) {
            drills.append(contentsOf: drillsForSkill(category, level: level))
        }

        let weaknessDrills = drillsForWeakness(weakness, level: level)
        drills.append(contentsOf: weaknessDrills)

        return drills
    }

    private func drillsForSkill(_ skill: SkillCategory, level: SkillLevel) -> [Drill] {
        let diff = difficultyFor(level)
        switch skill {
        case .firstTouch:
            return [
                Drill(name: "Wall Pass Returns", description: "Pass against a wall and control the return with different surfaces of your foot. Focus on cushioning the ball.", duration: "10 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Soft touch on reception", "Get body behind the ball", "Use inside and outside of foot"], reps: "3 sets of 20", equipment: [.ball, .wall], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(name: "Aerial Control Circuit", description: "Toss the ball in the air, control with thigh, then foot, then pass. Alternate between left and right.", duration: "12 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Watch the ball all the way", "Cushion on contact", "Keep balanced stance"], reps: "3 sets of 15", equipment: [.ball], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(name: "Bounce & Settle", description: "Drop the ball from waist height onto the ground. As it bounces, kill it dead with the sole of your foot. Progress to letting it bounce twice.", duration: "8 min", difficulty: .beginner, targetSkill: skill.rawValue, coachingCues: ["Hover foot just above the ball", "Absorb energy on contact", "Alternate feet every 5 reps"], reps: "4 sets of 12", equipment: [.ball], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(name: "Driven Pass Reception", description: "Have a partner hit hard, driven passes along the ground. Receive and redirect in one motion to a target cone.", duration: "12 min", difficulty: .advanced, targetSkill: skill.rawValue, coachingCues: ["Open body to receive", "Soft ankle on contact", "Direct ball into space, not back to passer"], reps: "3 sets of 10", trainingMode: .partner, equipment: [.ball, .cones], tags: ["minimal-equipment"])
            ]
        case .bodyPosition:
            return [
                Drill(name: "Shadow Play Positioning", description: "Move through cones mimicking game situations. Focus on body orientation, open hips, and scanning.", duration: "15 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Open body to the field", "Check shoulders constantly", "Stay on toes"], reps: "4 sets of 2 min", equipment: [.cones], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(name: "Mirror Drill", description: "Partner mirrors your movements. Stay low, balanced, and ready to react in any direction.", duration: "10 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Low center of gravity", "Quick feet", "Eyes on partner's hips"], reps: "5 rounds of 30 sec", trainingMode: .partner, equipment: [.none], tags: ["minimal-equipment"]),
                Drill(name: "Receive & Turn Pressure", description: "Set up 4 cones in a square. Receive a pass, check your shoulder, then turn toward the open cone. A passive defender applies light pressure.", duration: "12 min", difficulty: .intermediate, targetSkill: skill.rawValue, coachingCues: ["Check shoulder before the ball arrives", "Open hips to escape route", "First touch sets up the turn"], reps: "4 sets of 6", trainingMode: .partner, equipment: [.ball, .cones], tags: ["minimal-equipment"]),
                Drill(name: "Scanning Frequency Drill", description: "Receive passes in a grid. A coach holds up colored cones—you must call the color before receiving. Builds the habit of scanning.", duration: "10 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Scan before, during, and after receiving", "Keep head on a swivel", "Body open to see both ball and field"], reps: "3 sets of 2 min", trainingMode: .partner, equipment: [.ball, .cones], tags: ["minimal-equipment"])
            ]
        case .ballControl:
            return [
                Drill(name: "Cone Dribble Maze", description: "Dribble through a tight cone setup using close touches. Focus on keeping the ball within playing distance.", duration: "12 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Small touches", "Head up between cones", "Use both feet equally"], reps: "4 sets through the course", equipment: [.ball, .cones], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(name: "Tight Space Juggling", description: "Juggle inside a small square. Each time the ball leaves the square, restart the count.", duration: "8 min", difficulty: .intermediate, targetSkill: skill.rawValue, coachingCues: ["Soft controlled touches", "Stay in the zone", "Use all surfaces"], reps: "Best of 5 attempts", equipment: [.ball, .cones], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(name: "Figure 8 Dribbling", description: "Set two cones 3 feet apart. Dribble in a figure-8 pattern using only the inside and outside of one foot, then switch.", duration: "10 min", difficulty: .beginner, targetSkill: skill.rawValue, coachingCues: ["Ball glued to your foot", "Accelerate around the cone", "Low center of gravity"], reps: "3 sets of 1 min per foot", equipment: [.ball, .cones], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(name: "Pressure Box Keepaway", description: "In a 5x5 yard box, keep the ball away from a defender for as long as possible. Use shielding, turns, and quick changes of direction.", duration: "12 min", difficulty: .advanced, targetSkill: skill.rawValue, coachingCues: ["Use your body to shield", "Stay aware of space behind you", "Quick direction changes beat speed"], reps: "5 rounds of 45 sec", trainingMode: .partner, equipment: [.ball, .cones], tags: ["minimal-equipment"])
            ]
        case .shooting:
            return [
                Drill(name: "Finishing Circuit", description: "Set up 5 shooting positions around the box. Take 3 shots from each position, focusing on technique over power.", duration: "20 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Plant foot pointing at target", "Strike through the ball", "Follow through toward goal"], reps: "15 total shots", equipment: [.ball, .goal, .cones], tags: ["solo-friendly"]),
                Drill(name: "One-Touch Finishes", description: "Have a partner feed balls across the box. One touch to finish. Vary the angle and speed of feeds.", duration: "15 min", difficulty: .advanced, targetSkill: skill.rawValue, coachingCues: ["Quick assessment of keeper position", "Redirect with purpose", "Stay composed"], reps: "3 sets of 8", trainingMode: .partner, equipment: [.ball, .goal]),
                Drill(name: "Driven Shot Technique", description: "Place the ball 20 yards out. Focus on striking clean through the center of the ball with your laces. Aim low corners.", duration: "15 min", difficulty: .intermediate, targetSkill: skill.rawValue, coachingCues: ["Lock ankle, toe down", "Lean slightly over the ball", "Hit the center-bottom of the ball"], reps: "4 sets of 5", equipment: [.ball, .goal], tags: ["solo-friendly"]),
                Drill(name: "Turn & Shoot", description: "Receive a pass with your back to goal, take a touch to create space, and shoot within 2 seconds. Simulates real game urgency.", duration: "15 min", difficulty: .advanced, targetSkill: skill.rawValue, coachingCues: ["Quick first touch to shooting position", "Pick your spot before turning", "Shoot early—don't overthink"], reps: "3 sets of 6", trainingMode: .partner, equipment: [.ball, .goal])
            ]
        case .movement:
            return [
                Drill(name: "Agility Ladder Combos", description: "Run through an agility ladder with varied footwork patterns. Finish each set with a sprint.", duration: "10 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Quick feet, light contact", "Arms drive movement", "Explode out of the ladder"], reps: "6 ladder runs", equipment: [.agilityLadder], tags: ["solo-friendly"]),
                Drill(name: "Check-Away Runs", description: "Practice checking to the ball then spinning away into space. Simulate creating separation from a defender.", duration: "12 min", difficulty: .intermediate, targetSkill: skill.rawValue, coachingCues: ["Sharp change of direction", "Accelerate after the turn", "Communicate with passer"], reps: "4 sets of 5 runs", equipment: [.ball, .cones], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(name: "Lateral Shuffle & Sprint", description: "Shuffle laterally between two cones 5 yards apart, then on a signal, explode forward in a 10-yard sprint.", duration: "10 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Stay low during shuffle", "Push off outside foot to change direction", "Explosive first step on sprint"], reps: "4 sets of 6", equipment: [.cones], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(name: "Blindside Run Timing", description: "Start behind a cone as if behind a defender. On a visual cue, make a curved run into the box to meet a through ball.", duration: "12 min", difficulty: .advanced, targetSkill: skill.rawValue, coachingCues: ["Time the run—don't go too early", "Curve the run to stay onside", "Accelerate into the pass"], reps: "4 sets of 5 runs", trainingMode: .partner, equipment: [.ball, .cones], tags: ["minimal-equipment"]),
                Drill(
                    name: "High Knee March to Sprint",
                    description: "March forward lifting knees to hip height for 10 yards, then transition into a full sprint for 20 yards. Develops the knee-drive mechanics essential for acceleration.",
                    duration: "10 min",
                    difficulty: .beginner,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Drive knees to hip height during the march", "Pump arms opposite to legs", "Smooth transition from march to sprint"],
                    reps: "6 reps with walk-back recovery",
                    category: .movement,
                    intensity: .moderate,
                    equipment: [.cones],
                    tags: ["solo-friendly", "minimal-equipment", "speed", "warmup"],
                    purpose: "Groove proper sprint mechanics starting from an exaggerated marching pattern.",
                    setup: "Mark a start line, a 10-yard cone (march zone), and a 30-yard cone (finish).",
                    space: .medium,
                    instructions: [
                        "Start at the line with tall posture.",
                        "March forward with exaggerated high knees for 10 yards.",
                        "At the 10-yard cone, accelerate into a full sprint.",
                        "Sprint through the 30-yard cone.",
                        "Walk back to the start. Rest 20 seconds.",
                        "Repeat 6 times."
                    ],
                    commonMistakes: ["Low knees during the march—exaggerate the height", "Abrupt transition instead of a smooth build-up", "Leaning back during the march—stay tall"]
                ),
                Drill(
                    name: "A-Skip to B-Skip Progression",
                    description: "Perform A-skips (knee drive with a skip) for 15 yards, then B-skips (knee drive with leg extension) for 15 yards. Foundational sprint mechanic drills.",
                    duration: "10 min",
                    difficulty: diff,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Drive the knee up before extending", "Stay on the balls of your feet", "Coordinate arms with opposite legs"],
                    reps: "4 sets of each",
                    category: .movement,
                    intensity: .moderate,
                    equipment: [.cones],
                    tags: ["solo-friendly", "minimal-equipment", "speed", "warmup"],
                    purpose: "Develop proper sprinting mechanics through isolated running drill progressions.",
                    setup: "Mark a 15-yard lane for each drill.",
                    space: .small,
                    instructions: [
                        "A-Skip: Skip forward, driving one knee up to hip height on each skip.",
                        "Alternate legs with a rhythmic bounce.",
                        "Perform for 15 yards, walk back.",
                        "B-Skip: Same as A-skip, but extend the lower leg forward at the top of the knee drive.",
                        "Paw the ground on the way back down.",
                        "4 sets of each with 15 seconds rest."
                    ],
                    commonMistakes: ["Not getting the knee high enough on A-skips", "Reaching forward instead of driving down on B-skips", "Flat-footed landing instead of balls of feet"]
                ),
                Drill(
                    name: "Bounding for Stride Power",
                    description: "Exaggerated running strides covering maximum distance per step. Builds power and coordination for longer sprint strides.",
                    duration: "10 min",
                    difficulty: .intermediate,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Push off powerfully with each step", "Drive the opposite knee high", "Spend time in the air—don't rush the contact"],
                    reps: "5 sets of 30 yards",
                    category: .movement,
                    intensity: .high,
                    equipment: [.cones],
                    tags: ["solo-friendly", "minimal-equipment", "plyometrics", "speed"],
                    purpose: "Develop explosive stride power and single-leg strength for faster top-end speed.",
                    setup: "30-yard open lane.",
                    space: .medium,
                    instructions: [
                        "Start with a 2-3 step run-up.",
                        "Push off one foot and drive the opposite knee high.",
                        "Spend as much time in the air as possible.",
                        "Land on the opposite foot and immediately push off again.",
                        "Cover 30 yards with as few strides as possible.",
                        "Walk back for recovery between sets."
                    ],
                    commonMistakes: ["Short, choppy strides instead of long, powerful ones", "Not driving the knee high enough", "Landing flat-footed—land on the ball of the foot"]
                )
            ]
        case .positioning:
            return [
                Drill(name: "Goalkeeper Angles", description: "Practice narrowing the angle by moving along the arc. Partner shoots from different positions.", duration: "15 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Stay on your line", "Small shuffle steps", "Set before the shot"], reps: "4 sets of 6 saves", trainingMode: .partner, equipment: [.ball, .goal]),
                Drill(name: "Cross Positioning", description: "Crosses come in from wide areas. Move to cut off the cross at the highest point. Focus on starting position and footwork.", duration: "15 min", difficulty: .intermediate, targetSkill: skill.rawValue, coachingCues: ["Start central, adjust based on ball position", "Take a step forward before the cross", "Claim with authority"], reps: "3 sets of 8", trainingMode: .partner, equipment: [.ball, .goal]),
                Drill(name: "1v1 Closing Down", description: "Attacker runs at goal from different angles. Practice when to stay, when to come out, and how to set your feet.", duration: "12 min", difficulty: .advanced, targetSkill: skill.rawValue, coachingCues: ["Make yourself big", "Stay on your feet as long as possible", "Force the attacker wide"], reps: "4 sets of 5", trainingMode: .partner, equipment: [.ball, .goal])
            ]
        case .handling:
            return [
                Drill(name: "Catch and Release", description: "Partner throws balls at varying heights and speeds. Focus on clean catching and immediate distribution.", duration: "12 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["W-shape hands for high balls", "Scoop for low balls", "Secure to chest"], reps: "3 sets of 15", trainingMode: .partner, equipment: [.ball]),
                Drill(name: "Diving Saves", description: "Partner shoots low to each side. Focus on proper diving technique—push off the near foot, hands lead, land on your side.", duration: "12 min", difficulty: .intermediate, targetSkill: skill.rawValue, coachingCues: ["Push off the planted foot", "Lead with hands, not body", "Get back up quickly"], reps: "3 sets of 8", trainingMode: .partner, equipment: [.ball, .goal]),
                Drill(name: "High Ball Collection", description: "Partner or machine delivers high crosses. Practice timing your jump, catching at the highest point, and landing safely.", duration: "15 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Take off on one foot", "Catch at highest point", "Bring knee up for protection"], reps: "3 sets of 10", trainingMode: .partner, equipment: [.ball, .goal])
            ]
        case .distribution:
            return [
                Drill(name: "Target Passing", description: "From the goal area, distribute to targets at different distances. Alternate between throws, goal kicks, and punts.", duration: "15 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Quick scanning", "Weight of pass", "Accurate to feet"], reps: "3 sets of 10", equipment: [.ball, .cones], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(name: "Quick Counter Throw", description: "After making a save, immediately throw to a target in a wide position. Speed of release is key.", duration: "10 min", difficulty: .intermediate, targetSkill: skill.rawValue, coachingCues: ["Scan before the save", "Overarm for distance, underarm for accuracy", "Hit the runner in stride"], reps: "3 sets of 8", trainingMode: .partner, equipment: [.ball, .goal]),
                Drill(name: "Goal Kick Accuracy", description: "Place goal kicks to land in specific zones. Alternate between short and long distribution.", duration: "15 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Consistent run-up", "Strike clean through the ball", "Aim for space, not a player"], reps: "3 sets of 6", equipment: [.ball, .goal, .cones], tags: ["solo-friendly"])
            ]
        case .reflexes:
            return [
                Drill(name: "Reaction Ball Saves", description: "Use a reaction ball thrown at the wall. Dive to save the unpredictable bounce.", duration: "10 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Stay in ready position", "Explosive push off", "Eyes on the ball"], reps: "4 sets of 10", equipment: [.reactionBall, .wall], tags: ["solo-friendly"]),
                Drill(name: "Close-Range Rapid Fire", description: "Three shooters fire in quick succession from 8 yards. Reset position between each shot.", duration: "10 min", difficulty: .advanced, targetSkill: skill.rawValue, coachingCues: ["Get set between saves", "Stay on your toes", "React, don't guess"], reps: "3 sets of 9 shots", trainingMode: .team, equipment: [.ball, .goal]),
                Drill(name: "Tennis Ball Reactions", description: "Partner throws tennis balls at close range. Catch or parry. Smaller ball forces faster hand-eye coordination.", duration: "8 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Soft hands", "Track the ball all the way", "Use both hands"], reps: "4 sets of 12", trainingMode: .partner, equipment: [.tennisBalls])
            ]
        case .communication:
            return [
                Drill(name: "Command the Box", description: "During crossing drills, practice calling for the ball, organizing defenders, and communicating early.", duration: "15 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Loud and clear commands", "Early calls", "Use player names"], reps: "Full session", trainingMode: .team, equipment: [.ball, .goal]),
                Drill(name: "Set Piece Organization", description: "Walk through corners and free kicks. Practice directing defensive wall and marking assignments vocally.", duration: "15 min", difficulty: .intermediate, targetSkill: skill.rawValue, coachingCues: ["Take charge early", "Assign marks clearly", "Adjust wall position based on ball placement"], reps: "8 set pieces", trainingMode: .team, equipment: [.ball, .goal]),
                Drill(name: "Backline Sweeper Calls", description: "In a small-sided game, focus only on organizing the back line. Push up, hold, and squeeze commands.", duration: "15 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Constant communication", "Short, sharp commands", "See the whole picture"], reps: "3 rounds of 4 min", trainingMode: .team, equipment: [.ball])
            ]
        case .passing:
            return [
                Drill(name: "Triangle Passing Patterns", description: "Set up a triangle of cones 10 yards apart. Pass and move to the next cone. Alternate one-touch and two-touch.", duration: "12 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Pass with the inside of your foot", "Weight the pass to arrive at pace", "Move immediately after passing"], reps: "4 sets of 2 min", trainingMode: .partner, equipment: [.ball, .cones], tags: ["minimal-equipment"]),
                Drill(name: "Long-Range Switching", description: "Switch play across a 30-yard grid with driven passes. Alternate between ground and lofted deliveries.", duration: "15 min", difficulty: .advanced, targetSkill: skill.rawValue, coachingCues: ["Open your body to the target", "Strike through the center of the ball", "Follow through toward the target"], reps: "3 sets of 10", trainingMode: .partner, equipment: [.ball, .cones], tags: ["minimal-equipment"]),
                Drill(name: "Passing Under Pressure", description: "Receive in a tight grid with a passive defender. Play a clean pass to a target before the defender closes.", duration: "12 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Scan before receiving", "First touch sets up the pass", "Play quickly but not rushed"], reps: "4 sets of 8", trainingMode: .partner, equipment: [.ball, .cones], tags: ["minimal-equipment"])
            ]
        case .dribbling:
            return [
                Drill(name: "Cone Weave Speed Dribble", description: "Weave through 10 cones spaced 2 yards apart at increasing speed. Use both feet.", duration: "10 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Small touches to keep control", "Use inside and outside of foot", "Accelerate between cones"], reps: "6 runs through", equipment: [.ball, .cones], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(name: "1v1 Beat the Defender", description: "Start 5 yards from a passive defender. Use a move to get past them and accelerate into space.", duration: "15 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Approach at speed", "Drop shoulder or use a feint", "Explode past on the touch"], reps: "4 sets of 5", trainingMode: .partner, equipment: [.ball, .cones], tags: ["minimal-equipment"]),
                Drill(name: "Close Control Box", description: "Dribble inside a 5x5 yard box for 60 seconds without leaving. Use all surfaces of both feet.", duration: "8 min", difficulty: .beginner, targetSkill: skill.rawValue, coachingCues: ["Keep ball within 1 foot", "Use sole rolls and drags", "Change direction constantly"], reps: "4 rounds of 60 sec", equipment: [.ball, .cones], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(
                    name: "Sole Roll Ladder",
                    description: "Place 6 cones in a straight line 1 yard apart. Roll the ball forward with the sole of your right foot through each gate, then return using your left. Progress to alternating feet every gate.",
                    duration: "10 min",
                    difficulty: .beginner,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Keep the ball under your foot, not ahead", "Light contact—guide, don't push", "Stay on the balls of your feet"],
                    reps: "4 sets through and back",
                    category: .dribbling,
                    intensity: .low,
                    equipment: [.ball, .cones],
                    tags: ["solo-friendly", "minimal-equipment", "close-control", "sole-work"],
                    purpose: "Build comfort and confidence rolling the ball with the sole at close range.",
                    setup: "6 cones in a straight line, 1 yard apart.",
                    space: .small,
                    instructions: [
                        "Stand at the first cone with the ball under your right sole.",
                        "Roll the ball forward through each gate using gentle sole contact.",
                        "At the end, stop the ball dead with your sole.",
                        "Return using your left foot only.",
                        "On the third set, alternate feet at every gate.",
                        "On the fourth set, add a slight jog pace."
                    ],
                    commonMistakes: ["Pushing the ball too far ahead between cones", "Flat-footed stance—stay on toes", "Looking down the entire time instead of glancing up"]
                ),
                Drill(
                    name: "Inside-Outside Zig Zag",
                    description: "Set 8 cones in a zig-zag pattern 2 yards apart. Dribble using inside touch toward one cone, then outside touch away toward the next. Maintain a steady rhythm.",
                    duration: "10 min",
                    difficulty: .beginner,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Inside touch angles the ball across your body", "Outside touch pushes it away at 45 degrees", "Keep knees bent and body low"],
                    reps: "5 runs through the pattern",
                    category: .dribbling,
                    intensity: .moderate,
                    equipment: [.ball, .cones],
                    tags: ["solo-friendly", "minimal-equipment", "inside-outside", "cone-pattern"],
                    purpose: "Develop smooth transitions between inside and outside surfaces while changing direction.",
                    setup: "8 cones in a zig-zag, each 2 yards apart at roughly 45-degree angles.",
                    space: .small,
                    instructions: [
                        "Start at the first cone with the ball at your feet.",
                        "Use an inside touch to push the ball diagonally toward the next cone.",
                        "As you reach it, use the outside of the same foot to redirect toward the following cone.",
                        "Continue alternating inside-outside through all cones.",
                        "Walk through the first set, then increase to jog pace.",
                        "Final set: use only your weaker foot."
                    ],
                    commonMistakes: ["Touching the ball too hard and losing the zig-zag line", "Standing upright—stay low for quick changes", "Using only one foot instead of practicing both"]
                ),
                Drill(
                    name: "Sole Drag Pullback Sprint",
                    description: "Dribble forward 5 yards at medium pace, then slam the sole on top of the ball to drag it backward, pivot 180 degrees, and sprint 5 yards in the opposite direction.",
                    duration: "10 min",
                    difficulty: .intermediate,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Sell the forward run before the pullback", "Drag the ball behind your standing foot", "Explosive first step after the turn"],
                    reps: "4 sets of 6 reps",
                    category: .dribbling,
                    intensity: .high,
                    equipment: [.ball, .cones],
                    tags: ["solo-friendly", "minimal-equipment", "sole-work", "start-stop", "change-of-pace"],
                    purpose: "Train the start-stop mechanic and sharp direction reversal used to lose defenders.",
                    setup: "Two cones 5 yards apart. Work between them.",
                    space: .small,
                    instructions: [
                        "Start at cone A and dribble toward cone B at 70% speed.",
                        "Two yards before cone B, plant your standing foot and drag the ball back with your sole.",
                        "Open your hips and pivot 180 degrees toward cone A.",
                        "Accelerate at full speed back to cone A.",
                        "Repeat immediately from cone A toward cone B.",
                        "Rest 30 seconds between sets."
                    ],
                    commonMistakes: ["Slowing down too early—sell the forward run", "Dragging the ball sideways instead of straight back", "No acceleration after the turn—must explode out"]
                ),
                Drill(
                    name: "Diamond Touch Circuit",
                    description: "Set 4 cones in a diamond shape 3 yards apart. Dribble to each cone using a different surface: inside to the first, outside to the second, sole roll to the third, laces push to the fourth.",
                    duration: "12 min",
                    difficulty: .intermediate,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Each surface should feel deliberate, not random", "Accelerate between cones, decelerate at each one", "Head up as you approach each cone"],
                    reps: "4 full circuits per foot",
                    category: .dribbling,
                    intensity: .moderate,
                    equipment: [.ball, .cones],
                    tags: ["solo-friendly", "minimal-equipment", "close-control", "cone-pattern", "inside-outside"],
                    purpose: "Force all four dribbling surfaces in a single pattern to build versatile ball manipulation.",
                    setup: "4 cones in a diamond shape, 3 yards between each.",
                    space: .small,
                    instructions: [
                        "Start at the bottom cone of the diamond.",
                        "Dribble to the right cone using inside-of-foot touches.",
                        "From the right cone, dribble to the top using outside-of-foot touches.",
                        "From the top, sole-roll the ball to the left cone.",
                        "From the left cone, push the ball with your laces back to the start.",
                        "Complete 4 circuits with your dominant foot, then 4 with your weaker foot."
                    ],
                    commonMistakes: ["Reverting to one surface the whole time", "Skipping the sole roll—it is the hardest but most important", "Rushing through without clean touches at each cone"]
                ),
                Drill(
                    name: "Stop-Go Tempo Dribble",
                    description: "Dribble in a straight line for 20 yards. Every 4 yards, dead-stop the ball under your sole for a full second, then burst forward. Builds the rhythm of change of pace dribbling.",
                    duration: "8 min",
                    difficulty: .beginner,
                    targetSkill: skill.rawValue,
                    coachingCues: ["The stop must be instant—no rolling", "Freeze your body, not just the ball", "Explode out of each stop like a sprinter"],
                    reps: "6 runs of 20 yards",
                    category: .dribbling,
                    intensity: .moderate,
                    equipment: [.ball, .cones],
                    tags: ["solo-friendly", "minimal-equipment", "start-stop", "change-of-pace", "sole-work"],
                    purpose: "Develop the start-stop rhythm that freezes defenders in real matches.",
                    setup: "5 cones in a straight line, 4 yards apart (20 yards total).",
                    space: .small,
                    instructions: [
                        "Begin dribbling from the first cone at a comfortable jog.",
                        "At each cone, stop the ball dead under your sole.",
                        "Hold the stop for a full one-second count.",
                        "Burst forward to the next cone at high tempo.",
                        "Repeat the stop-burst pattern through all 5 cones.",
                        "Walk back and repeat. Alternate stopping foot each run."
                    ],
                    commonMistakes: ["Rolling through the stop instead of a clean dead stop", "Not changing speed—the burst must be noticeably faster", "Leaning back during the stop instead of staying balanced over the ball"]
                ),
                Drill(
                    name: "L-Shaped Cutback",
                    description: "Dribble forward 5 yards toward a cone, then use the inside of your foot to cut the ball sharply 90 degrees to the left or right and accelerate along the new line. Mimics cutting inside from the wing.",
                    duration: "10 min",
                    difficulty: .intermediate,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Approach the cone at speed to sell the straight run", "Plant your outside foot and cut with the inside of the other", "First touch after the cut should be an acceleration touch"],
                    reps: "4 sets of 5 per side",
                    category: .dribbling,
                    intensity: .high,
                    equipment: [.ball, .cones],
                    tags: ["solo-friendly", "minimal-equipment", "close-control", "cone-pattern", "change-of-pace"],
                    purpose: "Practice sharp 90-degree cuts to change the angle of attack at speed.",
                    setup: "Set an L-shape with 2 cones: one 5 yards ahead, one 5 yards to the side.",
                    space: .small,
                    instructions: [
                        "Start with the ball, facing the first cone 5 yards away.",
                        "Dribble toward it at 80% speed.",
                        "One yard before the cone, plant your outside foot firmly.",
                        "Cut the ball 90 degrees with the inside of your other foot.",
                        "Accelerate toward the second cone.",
                        "Jog back and repeat. After 5 reps cutting left, do 5 cutting right."
                    ],
                    commonMistakes: ["Slowing down too much before the cut—approach with pace", "Cutting at a shallow angle instead of a sharp 90 degrees", "No burst of speed after the cut"]
                ),
                Drill(
                    name: "Sole Shuffle Square",
                    description: "Stand inside a 2x2 yard cone square. Using only sole touches, move the ball to each corner of the square as fast as possible without leaving the box. Tests close-range sole mastery.",
                    duration: "8 min",
                    difficulty: .intermediate,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Feather-light sole touches—never let the ball escape", "Stay on the balls of your feet the entire time", "Use both feet equally"],
                    reps: "5 rounds of 45 seconds",
                    category: .dribbling,
                    intensity: .moderate,
                    equipment: [.ball, .cones],
                    tags: ["solo-friendly", "minimal-equipment", "close-control", "sole-work"],
                    purpose: "Build rapid sole control in tight spaces where full dribbling strokes are impossible.",
                    setup: "4 cones forming a 2x2 yard square.",
                    space: .minimal,
                    instructions: [
                        "Stand in the center of the square with the ball under your foot.",
                        "Sole-roll the ball to the front-right cone and tap it back.",
                        "Sole-roll to the front-left cone and tap it back.",
                        "Sole-roll to the back-right, then back-left.",
                        "Increase speed each round—try to hit all 4 corners in under 5 seconds.",
                        "Rest 20 seconds between rounds."
                    ],
                    commonMistakes: ["Using the inside of the foot instead of the sole", "Ball escaping the square—keep touches soft", "Favoring one foot—force yourself to alternate"]
                ),
                Drill(
                    name: "Slalom Sprint & Slow",
                    description: "Set 8 cones in a slalom. Dribble slowly through the first 4 cones with tight inside-outside touches, then explode through the last 4 at full speed. Trains gear-shifting while dribbling.",
                    duration: "10 min",
                    difficulty: .intermediate,
                    targetSkill: skill.rawValue,
                    coachingCues: ["The slow section should be silky and controlled", "The speed section should feel like a different gear entirely", "Transition between speeds must be instant, not gradual"],
                    reps: "5 runs through",
                    category: .dribbling,
                    intensity: .high,
                    equipment: [.ball, .cones],
                    tags: ["solo-friendly", "minimal-equipment", "change-of-pace", "cone-pattern", "inside-outside"],
                    purpose: "Develop the ability to shift between controlled close dribbling and explosive speed dribbling.",
                    setup: "8 cones in a slalom line, 2 yards apart. Mark the halfway point with a different colored cone if available.",
                    space: .small,
                    instructions: [
                        "Start at the first cone with the ball.",
                        "Dribble through cones 1-4 at walking pace using tight inside-outside touches.",
                        "At cone 4, take a slightly bigger touch and accelerate.",
                        "Dribble through cones 5-8 at maximum controlled speed.",
                        "Stop the ball dead after the last cone.",
                        "Walk back and repeat. Alternate starting foot each run."
                    ],
                    commonMistakes: ["No real speed difference between the two halves", "Losing control during the fast section—push the limit but keep the ball", "Gradual acceleration instead of an instant gear shift"]
                ),
                Drill(
                    name: "V-Cut Escape Drill",
                    description: "Dribble toward a cone at an angle, then sharply cut the ball in a V-shape back the way you came using the inside of your foot. Simulates beating a defender who commits to one direction.",
                    duration: "10 min",
                    difficulty: .advanced,
                    targetSkill: skill.rawValue,
                    coachingCues: ["The approach angle matters—come in at 45 degrees", "The V-cut is one quick motion, not two separate touches", "Drop your shoulder the opposite way before cutting"],
                    reps: "4 sets of 6 per foot",
                    category: .dribbling,
                    intensity: .high,
                    equipment: [.ball, .cones],
                    tags: ["solo-friendly", "minimal-equipment", "close-control", "change-of-pace", "cone-pattern"],
                    purpose: "Master the V-cut—a sharp directional fake that wrong-foots defenders at close range.",
                    setup: "Place a cone 5 yards ahead. A second cone 5 yards behind and to the side marks your escape direction.",
                    space: .small,
                    instructions: [
                        "Start 5 yards from the target cone at a 45-degree angle.",
                        "Dribble toward the cone as if going past it on the outside.",
                        "One yard before the cone, drop your shoulder to the outside.",
                        "Quickly cut the ball back with the inside of your foot at a sharp angle.",
                        "Accelerate toward the escape cone.",
                        "Alternate between right-foot and left-foot V-cuts each set."
                    ],
                    commonMistakes: ["Cutting too early—get close to the cone before the move", "Shallow V-angle—the cut must be sharp enough to change direction", "No body feint before the cut—the shoulder drop sells the move"]
                ),
                Drill(
                    name: "Figure 8 Sole Weave",
                    description: "Place two cones 3 yards apart. Weave in a figure-8 pattern using only sole touches—roll forward, sideways, and backward to navigate around each cone without using any other foot surface.",
                    duration: "10 min",
                    difficulty: .advanced,
                    targetSkill: skill.rawValue,
                    coachingCues: ["The sole is your only tool—no inside or outside allowed", "Roll sideways around the cone, not just forward", "Keep your body centered over the ball at all times"],
                    reps: "3 sets of 1 min per foot",
                    category: .dribbling,
                    intensity: .moderate,
                    equipment: [.ball, .cones],
                    tags: ["solo-friendly", "minimal-equipment", "sole-work", "close-control"],
                    purpose: "Advanced sole mastery drill that forces multi-directional sole rolls in a continuous pattern.",
                    setup: "2 cones placed 3 yards apart on flat ground.",
                    space: .minimal,
                    instructions: [
                        "Start at the midpoint between the two cones with the ball under your right sole.",
                        "Sole-roll the ball in a curve around the right cone.",
                        "Continue rolling in a figure-8 path toward and around the left cone.",
                        "Complete continuous laps for 1 minute using only your right sole.",
                        "Switch to left foot only for the next minute.",
                        "Final set: alternate feet every half-loop."
                    ],
                    commonMistakes: ["Accidentally using the inside of the foot—stay disciplined with sole only", "Losing the figure-8 shape and going in circles around one cone", "Moving too fast and losing contact with the ball"]
                ),
                Drill(
                    name: "Tick-Tock Pendulum",
                    description: "Stand stationary and tap the ball side to side between your feet using the inside surface only. Build a fast, metronomic rhythm—the ball swings like a pendulum.",
                    duration: "8 min",
                    difficulty: .beginner,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Ball travels only 1 foot side to side", "Stay on the balls of your feet with knees bent", "Increase tempo every 15 seconds"],
                    reps: "4 sets of 45 seconds",
                    category: .dribbling,
                    intensity: .low,
                    equipment: [.ball],
                    tags: ["solo-friendly", "minimal-equipment", "close-control", "inside-outside"],
                    purpose: "Build rapid inside-foot coordination and a natural rhythm for close-quarters dribbling.",
                    setup: "No cones needed. Stand on flat ground with the ball between your feet.",
                    space: .minimal,
                    instructions: [
                        "Stand with feet shoulder-width apart, ball centered between them.",
                        "Tap the ball with the inside of your right foot toward your left foot.",
                        "Immediately tap it back with the inside of your left foot.",
                        "Find a steady rhythm—aim for one tap per second to start.",
                        "Every 15 seconds, increase the tempo slightly.",
                        "On the final set, close your eyes for the last 10 seconds to build feel."
                    ],
                    commonMistakes: ["Tapping too hard and losing the rhythm", "Flat feet—stay light on your toes", "Moving the ball too far from your body"]
                ),
                Drill(
                    name: "Cone Gate Burst",
                    description: "Set 5 pairs of cones as narrow gates (1 yard wide) across a 20-yard line. Dribble slowly between gates but burst through each gate at maximum speed. Reset pace after each gate.",
                    duration: "10 min",
                    difficulty: .intermediate,
                    targetSkill: skill.rawValue,
                    coachingCues: ["The burst must be a genuine gear change—not a gradual speed-up", "Use a single laces push through each gate", "Decelerate with small sole taps after each burst"],
                    reps: "5 runs through all gates",
                    category: .dribbling,
                    intensity: .high,
                    equipment: [.ball, .cones],
                    tags: ["solo-friendly", "minimal-equipment", "change-of-pace", "cone-pattern", "start-stop"],
                    purpose: "Train explosive acceleration through tight spaces followed by controlled deceleration.",
                    setup: "5 pairs of cones forming gates 1 yard wide, spaced 4 yards apart in a straight line.",
                    space: .medium,
                    instructions: [
                        "Start at the first gate with the ball at your feet.",
                        "Dribble slowly toward gate 1 using close inside touches.",
                        "One yard before the gate, push the ball through with your laces and sprint to collect it.",
                        "Immediately slow down with sole taps to regain close control.",
                        "Repeat the slow-approach, burst-through pattern at every gate.",
                        "Walk back and repeat. Use your weaker foot on alternate runs."
                    ],
                    commonMistakes: ["No real speed difference between the slow and burst phases", "Pushing the ball too far through the gate and losing it", "Skipping the deceleration—the slow-down is half the drill"]
                ),
                Drill(
                    name: "Sole Roll Crossover",
                    description: "Roll the ball laterally across your body with the sole of one foot, then step over it and collect with the opposite foot's inside. Repeat continuously, moving down a 15-yard line.",
                    duration: "10 min",
                    difficulty: .intermediate,
                    targetSkill: skill.rawValue,
                    coachingCues: ["The sole roll should be smooth and controlled—don't flick", "Step over cleanly without touching the ball", "Collect softly with the inside of the opposite foot"],
                    reps: "4 sets of 15 yards",
                    category: .dribbling,
                    intensity: .moderate,
                    equipment: [.ball, .cones],
                    tags: ["solo-friendly", "minimal-equipment", "sole-work", "close-control"],
                    purpose: "Combine sole rolls with crossover footwork for deceptive lateral movement on the ball.",
                    setup: "Two cones 15 yards apart. Work in a straight line between them.",
                    space: .small,
                    instructions: [
                        "Start with the ball under your right sole at the first cone.",
                        "Roll the ball to the left across your body using your right sole.",
                        "Step your right foot over the ball without touching it.",
                        "Collect the ball with the inside of your left foot.",
                        "Now roll it back to the right with your left sole and step over.",
                        "Continue this alternating pattern down the 15-yard line. Increase pace each set."
                    ],
                    commonMistakes: ["Sole roll going too far ahead—keep it lateral", "Tripping over the ball on the step-over", "Collecting too hard with the inside and knocking the ball away"]
                ),
                Drill(
                    name: "Lateral Drag Relay",
                    description: "Place 6 cones in a horizontal line 1 yard apart. Drag the ball sideways with the sole from cone to cone, never letting the ball leave contact with your foot. Go right, then return left.",
                    duration: "8 min",
                    difficulty: .beginner,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Maintain constant sole contact—the ball never leaves your foot", "Sidestep with your standing foot to keep balance", "Keep hips facing forward, not turning sideways"],
                    reps: "4 sets right and back",
                    category: .dribbling,
                    intensity: .low,
                    equipment: [.ball, .cones],
                    tags: ["solo-friendly", "minimal-equipment", "sole-work", "close-control"],
                    purpose: "Develop continuous sole-drag technique for tight lateral movement.",
                    setup: "6 cones in a horizontal line, 1 yard apart.",
                    space: .small,
                    instructions: [
                        "Stand at the leftmost cone with the ball under your right sole.",
                        "Drag the ball sideways to the right, passing through each 1-yard gap.",
                        "Your sole must stay in contact with the ball the entire way.",
                        "At the end, switch to your left sole and drag back to the start.",
                        "Each set: one full trip right and one full trip left.",
                        "On the final set, increase speed while keeping constant contact."
                    ],
                    commonMistakes: ["Lifting the foot off the ball between cones—keep contact", "Dragging too fast and losing balance", "Turning hips sideways instead of staying square"]
                ),
                Drill(
                    name: "Quick-Tap Speed Ladder",
                    description: "Place 8 cones in a line 1.5 yards apart. Tap the ball forward with tiny alternating-foot touches through each gap. The goal is maximum foot speed with minimum ball travel per touch.",
                    duration: "10 min",
                    difficulty: .intermediate,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Tiny touches—the ball should barely roll between taps", "Alternate left-right on every single touch", "Arms out for balance, stay low"],
                    reps: "6 runs through the ladder",
                    category: .dribbling,
                    intensity: .moderate,
                    equipment: [.ball, .cones],
                    tags: ["solo-friendly", "minimal-equipment", "close-control", "inside-outside", "cone-pattern"],
                    purpose: "Maximize foot speed and touch frequency in a confined forward dribbling pattern.",
                    setup: "8 cones in a straight line, 1.5 yards apart.",
                    space: .small,
                    instructions: [
                        "Start behind the first cone with the ball at your feet.",
                        "Tap the ball forward with the inside of your right foot.",
                        "Immediately tap it with the inside of your left foot.",
                        "Continue alternating through every gap—aim for 2 touches per gap.",
                        "Count your total touches. Try to beat your count each run.",
                        "Final 2 runs: use only the outside of each foot."
                    ],
                    commonMistakes: ["Taking one big touch instead of many small ones", "Using the same foot twice in a row", "Standing upright—bend your knees and stay athletic"]
                ),
                Drill(
                    name: "Triangle Escape Routes",
                    description: "Set 3 cones in a triangle, 4 yards apart. Dribble to the center, then exit through a different side each time using a different technique: inside cut, outside cut, sole drag.",
                    duration: "12 min",
                    difficulty: .intermediate,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Decide your exit before you reach the center", "Each exit technique must be clean and distinct", "Accelerate out of the triangle on every rep"],
                    reps: "4 sets of 9 reps (3 per exit)",
                    category: .dribbling,
                    intensity: .moderate,
                    equipment: [.ball, .cones],
                    tags: ["solo-friendly", "minimal-equipment", "close-control", "cone-pattern", "change-of-pace"],
                    purpose: "Practice choosing and executing different escape techniques from a central pressure zone.",
                    setup: "3 cones forming an equilateral triangle, 4 yards per side. Mark the center point.",
                    space: .small,
                    instructions: [
                        "Start at cone A and dribble to the center of the triangle.",
                        "At the center, use an inside-foot cut to exit through the side between cones B and C.",
                        "Collect the ball, return to the center from the outside.",
                        "This time, exit through the next side using an outside-foot cut.",
                        "Third rep: exit through the remaining side using a sole drag and pivot.",
                        "Repeat the cycle. Use your weaker foot for the second set."
                    ],
                    commonMistakes: ["Always exiting the same way—force yourself through all three sides", "No acceleration after the exit—treat it like beating a defender", "Dribbling past the center without performing the technique"]
                )
            ]
        case .finishing:
            return [
                Drill(name: "Composure Finishing", description: "Run onto through balls 1v1 with the keeper. Focus on picking your spot and staying calm.", duration: "15 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Look up and pick your corner", "Side-foot for placement", "Don't rush the shot"], reps: "3 sets of 6", trainingMode: .partner, equipment: [.ball, .goal]),
                Drill(name: "First-Time Finishes", description: "Crosses and cutbacks arrive from wide. Finish first-time from different angles around the box.", duration: "15 min", difficulty: .advanced, targetSkill: skill.rawValue, coachingCues: ["Adjust body shape early", "Attack the ball", "Hit the target every time"], reps: "3 sets of 8", trainingMode: .partner, equipment: [.ball, .goal]),
                Drill(name: "Weak Foot Finishing Ladder", description: "Take shots from 6, 12, and 18 yards — all with your weaker foot. Progress distance only when scoring consistently.", duration: "15 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Lock the ankle", "Placement over power", "Follow through toward goal"], reps: "3 sets of 5 per distance", equipment: [.ball, .goal], tags: ["solo-friendly"])
            ]
        case .scanning:
            return [
                Drill(name: "Shoulder Check Rondo", description: "Play a 4v1 rondo. Before every touch, you must check over your shoulder. Coach calls out if you forget.", duration: "12 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Check before the ball arrives", "Quick glance, not a full turn", "Know where pressure is coming from"], reps: "4 rounds of 2 min", trainingMode: .team, equipment: [.ball, .cones], tags: ["minimal-equipment"]),
                Drill(name: "Color Cone Awareness", description: "A coach holds up different colored cones while you receive a pass. Call the color before your first touch.", duration: "10 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Scan continuously", "Process info before the ball arrives", "Head on a swivel"], reps: "3 sets of 2 min", trainingMode: .partner, equipment: [.ball, .cones], tags: ["minimal-equipment"]),
                Drill(name: "Shadow Play Scanning", description: "Move through a pattern of passes and runs. At random moments, a coach shouts — you must point to where space is.", duration: "12 min", difficulty: .intermediate, targetSkill: skill.rawValue, coachingCues: ["Scan between every action", "Know where teammates and opponents are", "Build a mental picture"], reps: "3 sets of 3 min", trainingMode: .partner, equipment: [.ball, .cones], tags: ["minimal-equipment"])
            ]
        case .changeOfDirection:
            return [
                Drill(name: "T-Drill", description: "Sprint forward 10 yards, shuffle left 5 yards, shuffle right 10 yards, shuffle left 5 yards, backpedal to start.", duration: "10 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Low center of gravity on cuts", "Push off outside foot", "Explode out of each turn"], reps: "5 sets", equipment: [.cones], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(name: "5-10-5 Pro Agility", description: "Start in the middle. Sprint 5 yards right, touch the line, sprint 10 yards left, touch, sprint 5 yards back to center.", duration: "8 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Plant and drive", "Stay low through cuts", "Accelerate out of the turn"], reps: "6 sets", equipment: [.cones], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(name: "Reactive Cut Drill", description: "A partner points left or right at random. You must cut in that direction instantly from a jog. Builds game reactions.", duration: "10 min", difficulty: .intermediate, targetSkill: skill.rawValue, coachingCues: ["Stay on the balls of your feet", "Decelerate before cutting", "Sharp angle changes"], reps: "4 sets of 8 cuts", trainingMode: .partner, equipment: [.cones], tags: ["minimal-equipment"])
            ]
        case .acceleration:
            return [
                Drill(name: "Standing Start Sprints", description: "From a dead stop, explode into a 10-yard sprint. Focus on the first 3 steps — power and drive.", duration: "10 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Drive knees forward", "Lean into the sprint", "Pump arms aggressively"], reps: "8 sprints with full recovery", equipment: [.cones], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(name: "Deceleration & Freeze", description: "Sprint 15 yards then decelerate and stop within a 2-yard zone. Teaches controlled braking.", duration: "10 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Lower your hips to brake", "Short choppy steps to decelerate", "Stay balanced at the stop"], reps: "6 sets", equipment: [.cones], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(name: "Sprint-Brake-Sprint", description: "Sprint 10 yards, decelerate sharply, pause 1 second, then re-accelerate for another 10 yards.", duration: "10 min", difficulty: .advanced, targetSkill: skill.rawValue, coachingCues: ["Max effort on both sprints", "Control the deceleration", "Explosive re-start"], reps: "5 sets", equipment: [.cones], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(
                    name: "Flying 20-Yard Sprint",
                    description: "Build speed over 10 yards, then sprint at maximum velocity for 20 yards through a timed zone. Measures and develops top-end speed.",
                    duration: "12 min",
                    difficulty: diff,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Gradual build-up in the first 10 yards", "Hit max speed before entering the timed zone", "Stay relaxed at top speed—don't tense up"],
                    reps: "6 sprints with full recovery",
                    category: .acceleration,
                    intensity: .maximum,
                    equipment: [.cones],
                    tags: ["solo-friendly", "minimal-equipment", "speed"],
                    purpose: "Develop pure top-end speed by sprinting through a zone at max velocity.",
                    setup: "Mark a build-up zone of 10 yards, then a timed zone of 20 yards.",
                    space: .medium,
                    instructions: [
                        "Start at the first cone and accelerate through the 10-yard build-up zone.",
                        "By the second cone, you should be at full speed.",
                        "Sprint through the 20-yard timed zone at max velocity.",
                        "Decelerate gradually after the finish.",
                        "Walk back for full recovery (60-90 seconds).",
                        "Repeat 6 times."
                    ],
                    commonMistakes: ["Accelerating too late and not reaching top speed in the zone", "Tensing up at max speed—stay relaxed", "Not enough recovery between reps"]
                ),
                Drill(
                    name: "Hill Sprint Repeats",
                    description: "Sprint up a moderate incline for 20-30 yards. The incline forces a forward lean and powerful leg drive. Walk back down for recovery.",
                    duration: "15 min",
                    difficulty: .intermediate,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Lean into the hill naturally", "Drive knees high and pump arms", "Walk down slowly for recovery"],
                    reps: "8-10 hill sprints",
                    category: .acceleration,
                    intensity: .high,
                    equipment: [.none],
                    tags: ["solo-friendly", "minimal-equipment", "speed", "conditioning"],
                    purpose: "Build acceleration strength and drive-phase mechanics using natural resistance from an incline.",
                    setup: "Find a hill or incline with a moderate grade. Mark a start and finish 20-30 yards apart.",
                    space: .medium,
                    instructions: [
                        "Start at the bottom of the hill in a sprint-ready position.",
                        "Sprint up the hill at maximum effort for 20-30 yards.",
                        "Focus on driving your knees forward and pumping your arms.",
                        "Walk back down slowly for recovery.",
                        "Start the next rep when you reach the bottom.",
                        "Complete 8-10 total sprints."
                    ],
                    commonMistakes: ["Standing too upright—let the hill encourage forward lean", "Short steps instead of powerful strides", "Jogging down instead of walking for recovery"]
                ),
                Drill(
                    name: "Resisted Sprint Starts",
                    description: "A partner provides light resistance with a band or by holding your waist as you drive forward for 10 yards. Overloads the acceleration muscles.",
                    duration: "10 min",
                    difficulty: .advanced,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Drive hard against the resistance", "Powerful arm pumps", "Forward body lean—don't stand upright"],
                    reps: "4 sets of 4 resisted sprints",
                    category: .acceleration,
                    intensity: .high,
                    trainingMode: .partner,
                    equipment: [.resistanceBand],
                    tags: ["speed", "acceleration", "strength"],
                    purpose: "Overload the drive phase of sprinting to build explosive starting speed.",
                    setup: "Partner holds a resistance band around your waist from behind, or holds your waist directly.",
                    space: .small,
                    instructions: [
                        "Your partner provides moderate resistance from behind.",
                        "Drive forward against the resistance for 10 yards.",
                        "Focus on powerful knee drives and forward lean.",
                        "On the partner's release, accelerate freely for 10 more yards.",
                        "Walk back and switch roles.",
                        "4 resisted sprints per set, 2 sets each."
                    ],
                    commonMistakes: ["Partner providing too much resistance—it should challenge, not stop you", "Standing upright against the band", "Short, choppy steps instead of powerful drives"]
                )
            ]
        case .defensiveFootwork:
            return [
                Drill(name: "Jockey & Shadow", description: "A partner dribbles at you. Stay goal-side, shuffle your feet, and mirror their movements without diving in.", duration: "12 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Stay on your toes", "Don't cross your feet", "Force onto their weak foot"], reps: "5 rounds of 30 sec", trainingMode: .partner, equipment: [.ball], tags: ["minimal-equipment"]),
                Drill(name: "Backpedal & Close", description: "Start 10 yards from a cone. Backpedal slowly, then on a signal, close down the space aggressively and set your stance.", duration: "10 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Controlled backpedal", "Explosive close-down", "Get low and balanced on arrival"], reps: "4 sets of 6", equipment: [.cones], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(name: "Defensive 1v1 Channel", description: "Defend in a narrow 5-yard channel. The attacker tries to dribble past you. Use your body position to funnel them.", duration: "12 min", difficulty: .intermediate, targetSkill: skill.rawValue, coachingCues: ["Angle your body to force one way", "Patience — don't lunge", "Poke tackle when the ball is exposed"], reps: "4 sets of 5", trainingMode: .partner, equipment: [.ball, .cones], tags: ["minimal-equipment"])
            ]
        case .weakFoot:
            return [
                Drill(name: "Weak Foot Wall Passes", description: "Stand 3 yards from a wall. Pass and receive using only your weaker foot. Increase distance over time.", duration: "10 min", difficulty: .beginner, targetSkill: skill.rawValue, coachingCues: ["Lock ankle on your weak foot", "Focus on clean contact", "Aim for the same spot on the wall"], reps: "3 sets of 30", equipment: [.ball, .wall], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(name: "Weak Foot Dribble Course", description: "Set up a cone course and dribble through using only your non-dominant foot. Go slow at first, build speed.", duration: "10 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Use inside and outside", "Keep the ball close", "Don't switch to your strong foot"], reps: "5 runs through", equipment: [.ball, .cones], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(name: "Weak Foot Crossing & Finishing", description: "Cross with your weak foot from wide, then switch and finish with your weak foot from the box.", duration: "15 min", difficulty: .advanced, targetSkill: skill.rawValue, coachingCues: ["Proper technique over power", "Plant foot beside the ball", "Follow through across your body"], reps: "3 sets of 8", equipment: [.ball, .goal], tags: ["solo-friendly"])
            ]
        case .turning:
            return [
                Drill(name: "Inside Hook Turn", description: "Dribble toward a cone, plant your standing foot, and hook the ball back with the inside of your other foot. Accelerate away.", duration: "10 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Sell the forward run first", "Sharp hook with the inside", "Accelerate out of the turn"], reps: "4 sets of 8 per foot", category: .turning, equipment: [.ball, .cones], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(name: "Outside Hook Turn", description: "Dribble forward then drag the ball back behind your standing leg using the outside of your foot. Change direction completely.", duration: "10 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Wrap foot around the ball", "Low center of gravity", "Explode in the new direction"], reps: "4 sets of 8 per foot", category: .turning, equipment: [.ball, .cones], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(name: "Cruyff Turn Drill", description: "Approach a cone as if to pass or shoot, then drag the ball behind your standing leg with the inside of your kicking foot and spin away.", duration: "10 min", difficulty: .intermediate, targetSkill: skill.rawValue, coachingCues: ["Sell the fake pass or shot", "Plant standing foot firmly", "Drag behind and accelerate"], reps: "3 sets of 10 per foot", category: .turning, equipment: [.ball, .cones], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(name: "Receive & Turn Under Pressure", description: "A partner passes to you with a passive defender behind. Use different turns (inside hook, outside hook, drag back) to escape pressure.", duration: "12 min", difficulty: .advanced, targetSkill: skill.rawValue, coachingCues: ["Check shoulder before the ball arrives", "First touch sets up the turn", "Vary the turn type to stay unpredictable"], reps: "4 sets of 6", category: .turning, trainingMode: .partner, equipment: [.ball, .cones], tags: ["minimal-equipment"]),
                Drill(
                    name: "Drag Back & Explode",
                    description: "Dribble toward a cone at 70% pace, stop the ball with your sole, drag it back behind your standing foot, open your hips 180 degrees, and sprint away in the opposite direction.",
                    duration: "10 min",
                    difficulty: .beginner,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Sell the forward run before dragging back", "Open hips quickly—don't shuffle around", "First step after the turn should be explosive"],
                    reps: "4 sets of 8 per foot",
                    category: .turning,
                    intensity: .moderate,
                    equipment: [.ball, .cones],
                    tags: ["solo-friendly", "minimal-equipment", "sole-work", "start-stop"],
                    purpose: "Master the fundamental drag-back turn used to reverse direction under pressure.",
                    setup: "Two cones 8 yards apart. Dribble from one toward the other.",
                    space: .small,
                    instructions: [
                        "Start at cone A and dribble toward cone B at a comfortable jog.",
                        "Two yards before cone B, plant your standing foot and place your sole on top of the ball.",
                        "Drag the ball backward behind your standing foot.",
                        "Pivot your hips 180 degrees to face cone A.",
                        "Push the ball forward with your instep and sprint back to cone A.",
                        "Rest 10 seconds, then repeat. Switch your turning foot after each set."
                    ],
                    commonMistakes: ["Dragging the ball sideways instead of straight back", "Slow hip rotation—snap them open", "Walking away instead of sprinting after the turn"]
                ),
                Drill(
                    name: "Step-Over Spin Exit",
                    description: "Dribble toward a cone, perform a step-over with your dominant foot, then spin 180 degrees on the ball of your standing foot and burst away. Combines flair with functional turning.",
                    duration: "10 min",
                    difficulty: .intermediate,
                    targetSkill: skill.rawValue,
                    coachingCues: ["The step-over should be exaggerated and wide", "Spin tight—your standing foot is the pivot point", "Exit at full speed, not half pace"],
                    reps: "3 sets of 8 per foot",
                    category: .turning,
                    intensity: .high,
                    equipment: [.ball, .cones],
                    tags: ["solo-friendly", "minimal-equipment", "close-control", "change-of-pace"],
                    purpose: "Add a deceptive step-over fake before executing a sharp spin turn to wrong-foot defenders.",
                    setup: "Place a cone 6 yards ahead as a simulated defender.",
                    space: .small,
                    instructions: [
                        "Dribble toward the cone at 80% pace.",
                        "One yard before the cone, swing your right foot around the outside of the ball in a wide step-over.",
                        "As your right foot lands, pivot on the ball of that foot and spin your body 180 degrees.",
                        "Use the outside of your left foot to take the ball with you in the new direction.",
                        "Sprint 5 yards away from the cone.",
                        "Repeat with the opposite foot leading the step-over each set."
                    ],
                    commonMistakes: ["Step-over too small—make it wide and convincing", "Spinning off-balance because the step-over was rushed", "Forgetting to take the ball with you after the spin"]
                ),
                Drill(
                    name: "Cone Circle Continuous Turns",
                    description: "Arrange 6 cones in a circle, 3 yards apart. Dribble to each cone and perform a different turn: inside hook, outside hook, drag back, Cruyff, sole spin, step-over. Continuous loop without stopping.",
                    duration: "12 min",
                    difficulty: .advanced,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Each turn must be clean before moving to the next cone", "No pausing between turns—keep the circuit flowing", "Call out each turn type as you do it to build awareness"],
                    reps: "3 full circuits per direction",
                    category: .turning,
                    intensity: .moderate,
                    equipment: [.ball, .cones],
                    tags: ["solo-friendly", "minimal-equipment", "close-control", "cone-pattern"],
                    purpose: "Cycle through all major turn types in a continuous pattern to build a diverse turning vocabulary.",
                    setup: "6 cones in a circle approximately 6 yards in diameter.",
                    space: .small,
                    instructions: [
                        "Start at any cone. Dribble to the next cone clockwise.",
                        "At cone 1: inside hook turn.",
                        "At cone 2: outside hook turn.",
                        "At cone 3: drag back turn.",
                        "At cone 4: Cruyff turn.",
                        "At cone 5: sole spin (roll ball, spin body around it).",
                        "At cone 6: step-over and exit.",
                        "Complete 3 laps clockwise, then 3 laps counter-clockwise."
                    ],
                    commonMistakes: ["Defaulting to the same comfortable turn at every cone", "Stopping between cones to think—memorize the sequence first", "Sloppy technique when tired—quality over speed"]
                ),
                Drill(
                    name: "Half-Turn Redirect",
                    description: "Dribble forward and at each cone, perform a 90-degree half-turn using the outside of your foot to redirect the ball perpendicular to your original path. Builds the subtle direction change used in tight midfield spaces.",
                    duration: "10 min",
                    difficulty: .intermediate,
                    targetSkill: skill.rawValue,
                    coachingCues: ["The half-turn is quick and subtle—not a full 180", "Use the outside of your foot to nudge the ball 90 degrees", "Accelerate along the new line immediately"],
                    reps: "4 sets of 6 per side",
                    category: .turning,
                    intensity: .moderate,
                    equipment: [.ball, .cones],
                    tags: ["solo-friendly", "minimal-equipment", "close-control", "cone-pattern", "inside-outside"],
                    purpose: "Develop the 90-degree redirect used to slip away from pressure without fully turning around.",
                    setup: "Set a T-shape: one cone 5 yards ahead, with two cones 5 yards to the left and right of it.",
                    space: .small,
                    instructions: [
                        "Dribble from the base toward the top cone of the T.",
                        "One yard before the cone, use the outside of your right foot to redirect the ball 90 degrees to the left.",
                        "Accelerate to the left cone.",
                        "Collect the ball and dribble back to the base.",
                        "Repeat, this time redirecting to the right with the outside of your left foot.",
                        "Complete 6 reps to each side per set."
                    ],
                    commonMistakes: ["Turning a full 180 instead of a sharp 90-degree angle", "Slowing to a stop before the redirect—maintain some pace", "Using the inside of the foot instead of the outside"]
                )
            ]
        case .striking:
            return [
                Drill(name: "Laces Drive Technique", description: "Place the ball on the ground. Strike through the center with your laces, focusing on locked ankle and follow-through. Aim at a wall target.", duration: "12 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Toe pointed down, ankle locked", "Plant foot beside the ball", "Strike through the center"], reps: "4 sets of 10", category: .striking, equipment: [.ball, .wall], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(name: "Inside Foot Pass Striking", description: "Focus on clean inside-foot contact for short and medium range passes against a wall. Alternate feet.", duration: "10 min", difficulty: .beginner, targetSkill: skill.rawValue, coachingCues: ["Open hip to the target", "Firm ankle on contact", "Follow through toward the target"], reps: "3 sets of 20 per foot", category: .striking, equipment: [.ball, .wall], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(name: "Volleys from Self-Toss", description: "Toss the ball to yourself at different heights and strike cleanly on the volley. Focus on timing and clean contact.", duration: "10 min", difficulty: .intermediate, targetSkill: skill.rawValue, coachingCues: ["Watch the ball onto your foot", "Lock the ankle", "Lean slightly over the ball for control"], reps: "3 sets of 10 per foot", category: .striking, equipment: [.ball], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(name: "Chip & Loft Technique", description: "Practice chipping over a cone from 10-15 yards. Get underneath the ball with a scooping motion.", duration: "12 min", difficulty: .advanced, targetSkill: skill.rawValue, coachingCues: ["Lean back slightly", "Stab under the ball", "Minimal follow-through for backspin"], reps: "4 sets of 8", category: .striking, equipment: [.ball, .cones], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(
                    name: "One-Touch Wall Returns",
                    description: "Stand 5 yards from a wall. Pass the ball firmly and redirect the return with a single touch back to the wall. No stopping the ball—every touch is a pass.",
                    duration: "10 min",
                    difficulty: .intermediate,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Open your body before the ball arrives", "Firm ankle on every strike", "Redirect—don't just block the ball back"],
                    reps: "3 sets of 25 passes per foot",
                    category: .striking,
                    intensity: .moderate,
                    equipment: [.ball, .wall],
                    tags: ["solo-friendly", "minimal-equipment", "wall-training", "1-touch"],
                    purpose: "Develop clean one-touch passing technique with a fast rhythm against a wall.",
                    setup: "Stand 5 yards from a flat wall. Mark a target zone on the wall at knee height with chalk or tape.",
                    space: .small,
                    instructions: [
                        "Pass the ball firmly into the wall with your right inside foot.",
                        "As it returns, redirect it back with one touch—no extra touches allowed.",
                        "Aim for the same target zone every rep.",
                        "Complete 25 passes, then switch to your left foot.",
                        "On the third set, alternate feet every pass."
                    ],
                    commonMistakes: ["Taking a cushion touch instead of a clean redirect", "Standing flat-footed—stay on the balls of your feet", "Aiming randomly instead of targeting a specific wall zone"]
                ),
                Drill(
                    name: "Two-Touch Strike Rhythm",
                    description: "Pass to the wall, control the return with your first touch to set the ball to one side, then strike firmly back to the wall with your second touch. Builds the control-then-strike pattern.",
                    duration: "12 min",
                    difficulty: .beginner,
                    targetSkill: skill.rawValue,
                    coachingCues: ["First touch sets the ball out of your feet at a 45-degree angle", "Second touch is a firm, deliberate strike", "Rhythm matters—keep a steady tempo"],
                    reps: "4 sets of 15 per foot",
                    category: .striking,
                    intensity: .low,
                    equipment: [.ball, .wall],
                    tags: ["solo-friendly", "minimal-equipment", "wall-training", "2-touch"],
                    purpose: "Build the habit of a quality set-up touch followed by a purposeful strike.",
                    setup: "Stand 5-7 yards from a flat wall. No cones needed.",
                    space: .small,
                    instructions: [
                        "Pass the ball into the wall at medium pace.",
                        "As it returns, take a controlling touch to push the ball slightly to your right.",
                        "On the second touch, strike it firmly back to the wall.",
                        "Complete 15 reps, then switch so your first touch goes left and you strike with your left foot.",
                        "Increase the pace of the wall pass each set."
                    ],
                    commonMistakes: ["First touch too close to your body—set it at a comfortable striking distance", "Rushing the strike before the ball is properly set", "Letting the ball stop dead—keep it moving"]
                ),
                Drill(
                    name: "Weak Foot Wall Drives",
                    description: "Using only your weaker foot, strike the ball into the wall from increasing distances: 3, 5, 7, and 10 yards. Focus purely on technique and clean laces contact.",
                    duration: "12 min",
                    difficulty: .intermediate,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Lock ankle and point toe down on every strike", "Plant foot beside the ball, not behind it", "Follow through straight—don't let your foot swing across"],
                    reps: "3 sets of 8 per distance",
                    category: .striking,
                    intensity: .moderate,
                    equipment: [.ball, .wall, .cones],
                    tags: ["solo-friendly", "minimal-equipment", "wall-training", "weak-foot"],
                    purpose: "Build striking confidence and power on your weaker foot through progressive distance.",
                    setup: "Place cones at 3, 5, 7, and 10 yards from a flat wall.",
                    space: .small,
                    instructions: [
                        "Start at the 3-yard cone. Strike the ball with your weak-foot laces into the wall.",
                        "Focus on clean contact—accuracy over power at close range.",
                        "After 8 strikes, move to the 5-yard cone and repeat.",
                        "Progress to 7 yards, then 10 yards.",
                        "Only move to the next distance when 6 of 8 strikes hit your target zone.",
                        "Complete 3 full rounds through all distances."
                    ],
                    commonMistakes: ["Trying to smash the ball at every distance—start controlled", "Leaning away from the ball on the weak side", "Giving up and switching to the strong foot"]
                ),
                Drill(
                    name: "Wall Strike & Relocate",
                    description: "Strike the ball into the wall, then immediately shuffle 3 yards laterally before the ball returns. Receive it in your new position and strike again. Builds the habit of moving after every pass.",
                    duration: "12 min",
                    difficulty: .intermediate,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Move the instant you strike—don't admire your pass", "Shuffle with quick feet, don't cross over", "Adjust body shape to face the wall before the ball arrives"],
                    reps: "4 sets of 10 strikes",
                    category: .striking,
                    intensity: .high,
                    equipment: [.ball, .wall, .cones],
                    tags: ["solo-friendly", "minimal-equipment", "wall-training", "movement-after-pass"],
                    purpose: "Train the game-realistic habit of striking and immediately relocating to a new position.",
                    setup: "Stand 7 yards from a flat wall. Place two cones 3 yards apart, parallel to the wall, as your shuffle zone.",
                    space: .small,
                    instructions: [
                        "Start at the left cone. Strike the ball into the wall.",
                        "Immediately shuffle to the right cone.",
                        "Receive the return and strike again from your new position.",
                        "Shuffle back to the left cone and repeat.",
                        "Each set is 10 total strikes (5 from each side).",
                        "Progress by increasing the shuffle distance to 5 yards."
                    ],
                    commonMistakes: ["Standing still after the pass—the movement is the point", "Arriving late and rushing the next strike", "Shuffling without resetting body shape to face the wall"]
                ),
                Drill(
                    name: "Angled Wall Half-Volleys",
                    description: "Stand at a 45-degree angle to the wall, 6 yards away. Strike the ball so it rebounds at an angle, then move to meet it and half-volley it back on the bounce. Trains striking a moving ball under time pressure.",
                    duration: "10 min",
                    difficulty: .advanced,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Time the bounce—strike as the ball rises", "Keep your body over the ball for a clean half-volley", "Angle your plant foot toward the wall target"],
                    reps: "3 sets of 10 per foot",
                    category: .striking,
                    intensity: .high,
                    equipment: [.ball, .wall],
                    tags: ["solo-friendly", "minimal-equipment", "wall-training", "1-touch"],
                    purpose: "Develop the timing and technique to cleanly strike a bouncing ball at pace.",
                    setup: "Stand 6 yards from a flat wall at a 45-degree angle. No cones required.",
                    space: .small,
                    instructions: [
                        "Pass the ball firmly into the wall at an angle so it rebounds to your side.",
                        "Let it bounce once, then half-volley it back into the wall.",
                        "Try to maintain a continuous rhythm without catching the ball.",
                        "Complete 10 reps from the right side, then reposition and do 10 from the left.",
                        "On the final set, alternate sides every 2 reps."
                    ],
                    commonMistakes: ["Letting the ball bounce too high—meet it early on the rise", "Swinging wildly instead of a controlled laces strike", "Standing still instead of adjusting your feet to the ball"]
                ),
                Drill(
                    name: "Alternating Surface Wall Strikes",
                    description: "Pass to the wall using a different striking surface each rep: inside, laces, outside, instep. The wall return forces you to adjust body shape for each surface quickly.",
                    duration: "12 min",
                    difficulty: .intermediate,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Commit to the correct surface before the ball arrives", "Adjust your plant foot angle for each surface", "Keep a consistent wall target despite changing technique"],
                    reps: "4 sets of 12 (3 per surface)",
                    category: .striking,
                    intensity: .moderate,
                    equipment: [.ball, .wall],
                    tags: ["solo-friendly", "minimal-equipment", "wall-training", "2-touch"],
                    purpose: "Build versatility by cycling through all striking surfaces in a single wall session.",
                    setup: "Stand 6 yards from a flat wall. Mark a target zone at knee height.",
                    space: .small,
                    instructions: [
                        "Pass the ball into the wall with the inside of your right foot.",
                        "Receive the return, then strike back with your right laces.",
                        "Next rep: strike with the outside of your right foot.",
                        "Next rep: strike with your right instep.",
                        "Cycle through all four surfaces, then repeat with your left foot.",
                        "Aim for the same target zone every rep regardless of surface."
                    ],
                    commonMistakes: ["Defaulting to inside foot every time—force variety", "Changing your wall distance between surfaces—stay planted", "Rushing through without resetting body shape for each surface"]
                ),
                Drill(
                    name: "Wall Power Ladder",
                    description: "Start 4 yards from the wall and hit 5 passes at controlled pace. Step back to 7 yards and hit 5 at medium power. Step back to 10 yards and hit 5 at full power. Builds progressive striking force.",
                    duration: "12 min",
                    difficulty: .intermediate,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Technique stays the same at every distance—only power changes", "Lean over the ball more as distance increases", "Follow through fully at the longer distances"],
                    reps: "3 rounds of 15 strikes (5 per distance)",
                    category: .striking,
                    intensity: .high,
                    equipment: [.ball, .wall, .cones],
                    tags: ["solo-friendly", "minimal-equipment", "wall-training", "1-touch"],
                    purpose: "Develop the ability to adjust striking power while maintaining clean technique at different ranges.",
                    setup: "Place cones at 4, 7, and 10 yards from a flat wall.",
                    space: .medium,
                    instructions: [
                        "Start at the 4-yard cone. Strike 5 passes into the wall at 50% power with your laces.",
                        "Move to the 7-yard cone. Strike 5 at 75% power.",
                        "Move to the 10-yard cone. Strike 5 at full power.",
                        "Walk back to the 4-yard cone and repeat.",
                        "Use your dominant foot for round 1, weak foot for round 2, alternating for round 3.",
                        "Every strike must hit your wall target—power without accuracy does not count."
                    ],
                    commonMistakes: ["Sacrificing accuracy for power at the longer distances", "Changing technique as you move back—keep the same mechanics", "Not resetting between strikes—take a breath at each distance"]
                ),
                Drill(
                    name: "Quick-Switch Foot Wall Strikes",
                    description: "Pass to the wall with your right foot, receive, then immediately strike back with your left foot. Every return switches the striking foot. Builds ambidextrous striking rhythm.",
                    duration: "10 min",
                    difficulty: .intermediate,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Set the ball to the opposite side on your first touch", "No hesitation—the switch must be instant", "Both feet should produce the same quality of strike"],
                    reps: "3 sets of 20 (10 per foot)",
                    category: .striking,
                    intensity: .moderate,
                    equipment: [.ball, .wall],
                    tags: ["solo-friendly", "minimal-equipment", "wall-training", "weak-foot", "2-touch"],
                    purpose: "Force equal striking reps on both feet within a continuous wall rhythm.",
                    setup: "Stand 5 yards from a flat wall. No cones needed.",
                    space: .small,
                    instructions: [
                        "Strike the ball into the wall with your right inside foot.",
                        "Receive the return and set the ball to your left side with your first touch.",
                        "Strike back to the wall with your left foot.",
                        "Receive and set to your right side, then strike with your right foot.",
                        "Continue alternating without pausing. Count total clean switches.",
                        "If you use the same foot twice in a row, restart the count."
                    ],
                    commonMistakes: ["Cheating by using the strong foot twice—stay disciplined", "Setting the ball directly under you instead of to the striking side", "Losing rhythm because the weak foot strike is slower"]
                ),
                Drill(
                    name: "Wall Target Sniper",
                    description: "Mark 4 target zones on the wall (low-left, low-right, mid-left, mid-right). A mental sequence calls each target in random order. Strike accurately from 8 yards.",
                    duration: "12 min",
                    difficulty: .advanced,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Pick your target before you strike—never aim after contact", "Adjust body angle and plant foot to direct the ball", "Accuracy is everything—a miss counts as zero"],
                    reps: "4 sets of 8 strikes",
                    category: .striking,
                    intensity: .moderate,
                    equipment: [.ball, .wall, .cones],
                    tags: ["solo-friendly", "minimal-equipment", "wall-training", "1-touch"],
                    purpose: "Train precision placement by striking to specific wall targets under self-directed randomization.",
                    setup: "Stand 8 yards from a flat wall. Mark 4 target zones with chalk or tape: low-left, low-right, mid-left, mid-right.",
                    space: .small,
                    instructions: [
                        "Before each strike, call out your target zone out loud.",
                        "Strike the ball with purpose toward that zone.",
                        "Receive the return and immediately call the next target—choose a different one each time.",
                        "Score yourself: 1 point for hitting the zone, 0 for a miss.",
                        "Aim for 6 out of 8 per set.",
                        "Use your weak foot for the final set."
                    ],
                    commonMistakes: ["Always aiming for the easiest target—force yourself to vary", "Striking before picking a target—decide first, then hit", "Ignoring your weak foot on the final set"]
                ),
                Drill(
                    name: "Drop-Volley Wall Strikes",
                    description: "Hold the ball at chest height, drop it, and strike a clean volley into the wall from 6 yards. Focus on timing the drop and making clean laces contact before the second bounce.",
                    duration: "10 min",
                    difficulty: .advanced,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Drop the ball—do not toss it", "Strike as it falls, not after it bounces", "Lock your ankle and keep your toe pointed down"],
                    reps: "3 sets of 10 per foot",
                    category: .striking,
                    intensity: .moderate,
                    equipment: [.ball, .wall],
                    tags: ["solo-friendly", "minimal-equipment", "wall-training", "1-touch", "weak-foot"],
                    purpose: "Develop clean volley technique with a controlled self-serve against the wall.",
                    setup: "Stand 6 yards from a flat wall. No cones required.",
                    space: .small,
                    instructions: [
                        "Hold the ball at chest height with both hands.",
                        "Drop it straight down—no spin or toss.",
                        "As the ball falls, strike it on the full with your laces into the wall.",
                        "Let the return bounce and collect it.",
                        "Complete 10 volleys with your right foot, then 10 with your left.",
                        "Final set: let the wall return bounce once and half-volley it back."
                    ],
                    commonMistakes: ["Tossing the ball upward instead of a clean drop", "Striking after the bounce instead of on the full", "Leaning back and skying the volley—stay over the ball"]
                )
            ]
        case .receiving:
            return [
                Drill(name: "Wall Return & Cushion", description: "Pass firmly against a wall and cushion the return with different foot surfaces (inside, outside, sole). Kill the ball dead.", duration: "10 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Withdraw foot on contact to absorb", "Get body behind the ball", "Alternate surfaces each rep"], reps: "3 sets of 20", category: .receiving, equipment: [.ball, .wall], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(name: "Thigh & Chest Receive", description: "Toss the ball in the air and bring it down using your thigh, then your chest, then settle with your foot. Progress to one continuous sequence.", duration: "10 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Cushion on contact", "Get body shape right before the ball arrives", "Settle to the ground quickly"], reps: "4 sets of 10", category: .receiving, equipment: [.ball], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(name: "Receive & Play Forward", description: "A partner passes to you. Receive, take a directional touch, and play forward to a target cone in one motion.", duration: "12 min", difficulty: .intermediate, targetSkill: skill.rawValue, coachingCues: ["Open body to the direction of play", "First touch moves the ball forward", "Scan before the ball arrives"], reps: "3 sets of 10", category: .receiving, trainingMode: .partner, equipment: [.ball, .cones], tags: ["minimal-equipment"]),
                Drill(name: "Driven Ball Reception", description: "A partner hits hard, driven passes. Receive and redirect cleanly under tempo. Progress to receiving with a defender behind.", duration: "12 min", difficulty: .advanced, targetSkill: skill.rawValue, coachingCues: ["Soft ankle to absorb pace", "Take touch away from pressure", "Body shape open"], reps: "3 sets of 10", category: .receiving, trainingMode: .partner, equipment: [.ball], tags: ["minimal-equipment"]),
                Drill(
                    name: "Wall Receive & Set Left-Right",
                    description: "Pass into the wall and receive the return by cushioning it to one side with the inside of your foot. Alternate setting the ball left and right on consecutive reps.",
                    duration: "10 min",
                    difficulty: .beginner,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Withdraw your foot on contact to kill the pace", "Push the ball 1 yard to the side—not under your feet", "Open your hips toward the direction you want to set"],
                    reps: "3 sets of 20 (10 each side)",
                    category: .receiving,
                    intensity: .low,
                    equipment: [.ball, .wall],
                    tags: ["solo-friendly", "minimal-equipment", "wall-training", "2-touch"],
                    purpose: "Build directional first-touch control by receiving and setting the ball to a chosen side.",
                    setup: "Stand 5 yards from a flat wall. Place a cone 1 yard to your left and 1 yard to your right as target zones.",
                    space: .small,
                    instructions: [
                        "Pass the ball into the wall at medium pace.",
                        "As it returns, cushion it with the inside of your right foot, directing it toward the left cone.",
                        "Collect the ball and pass again.",
                        "This time, cushion with the inside of your left foot toward the right cone.",
                        "Alternate every rep for 20 total receives.",
                        "Progress by increasing the wall pass speed each set."
                    ],
                    commonMistakes: ["Stopping the ball directly under you instead of setting it to the side", "Stiff ankle—relax and withdraw on contact", "Not opening hips before the ball arrives"]
                ),
                Drill(
                    name: "Wall Receive & Turn Away",
                    description: "Pass into the wall, then receive the return with a turning touch that spins you 180 degrees away from the wall. Simulate receiving under pressure and turning into space.",
                    duration: "12 min",
                    difficulty: .intermediate,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Check over your shoulder before the ball arrives", "Use the outside of your foot to turn in one motion", "Accelerate 3 yards after turning before resetting"],
                    reps: "4 sets of 8 per foot",
                    category: .receiving,
                    intensity: .moderate,
                    equipment: [.ball, .wall, .cones],
                    tags: ["solo-friendly", "minimal-equipment", "wall-training", "turning-after-receive"],
                    purpose: "Train the receive-and-turn mechanic used to play forward after a back-to-play reception.",
                    setup: "Stand 5 yards from a flat wall. Place a cone 3 yards behind you as your turn target.",
                    space: .small,
                    instructions: [
                        "Pass the ball into the wall at medium-firm pace.",
                        "As the ball returns, let it arrive on the outside of your right foot.",
                        "In one motion, use the outside touch to spin 180 degrees away from the wall.",
                        "Accelerate to the cone behind you, stop the ball, and jog back.",
                        "Complete 8 reps turning to the right, then 8 turning to the left.",
                        "Progress by increasing wall-pass speed to simulate a harder incoming pass."
                    ],
                    commonMistakes: ["Taking a heavy touch that sends the ball too far after turning", "Turning before the ball arrives—let it reach your foot first", "Forgetting to check the shoulder—build the scanning habit"]
                ),
                Drill(
                    name: "Weak Foot Wall Cushion",
                    description: "Pass with your strong foot and receive every return using only your weaker foot. Focus on soft, controlled receptions with the inside, outside, and sole of your weak foot.",
                    duration: "10 min",
                    difficulty: .intermediate,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Relax the weak ankle—tension kills the cushion", "Receive with a different surface every 5 reps", "If the ball bounces away, you struck it—withdraw gently"],
                    reps: "3 sets of 15 receives",
                    category: .receiving,
                    intensity: .low,
                    equipment: [.ball, .wall],
                    tags: ["solo-friendly", "minimal-equipment", "wall-training", "weak-foot", "2-touch"],
                    purpose: "Develop receiving confidence and soft touch on your weaker foot.",
                    setup: "Stand 4-6 yards from a flat wall. No cones required.",
                    space: .small,
                    instructions: [
                        "Pass the ball into the wall with your strong foot at moderate pace.",
                        "Receive the return using only your weaker foot.",
                        "Reps 1-5: receive with the inside of your weak foot.",
                        "Reps 6-10: receive with the outside of your weak foot.",
                        "Reps 11-15: receive with the sole, killing the ball dead.",
                        "Increase wall-pass speed in sets 2 and 3."
                    ],
                    commonMistakes: ["Chickening out and using the strong foot when it gets hard", "Jabbing at the ball instead of withdrawing to cushion", "Only using one receiving surface the whole time"]
                ),
                Drill(
                    name: "Rapid Wall One-Two Receive",
                    description: "Stand close to the wall (3 yards) and play rapid one-touch passes. Every 5th pass, cushion-receive and hold the ball for 2 seconds before restarting. Trains switching between one-touch rhythm and controlled reception.",
                    duration: "10 min",
                    difficulty: .intermediate,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Count in your head—1, 2, 3, 4, HOLD", "The hold receive must be dead still—no bounce", "Stay light on your feet during the rapid phase"],
                    reps: "4 sets of 30 passes (6 hold receives per set)",
                    category: .receiving,
                    intensity: .moderate,
                    equipment: [.ball, .wall],
                    tags: ["solo-friendly", "minimal-equipment", "wall-training", "1-touch", "2-touch"],
                    purpose: "Train the mental switch between fast one-touch play and controlled dead-stop receiving.",
                    setup: "Stand 3 yards from a flat wall.",
                    space: .minimal,
                    instructions: [
                        "Start passing one-touch against the wall at a quick tempo.",
                        "Count each pass: 1, 2, 3, 4.",
                        "On the 5th pass, cushion-receive and stop the ball dead under your sole.",
                        "Hold for a full 2-second count.",
                        "Restart the rapid one-touch sequence.",
                        "Alternate between right and left foot for the hold receive."
                    ],
                    commonMistakes: ["Losing count and never doing the hold receive", "The hold receive bouncing away—must be completely dead", "Slowing the one-touch rhythm down—keep it fast"]
                ),
                Drill(
                    name: "Long Wall Receive & Reset",
                    description: "Stand 10 yards from the wall. Strike the ball hard, then receive the fast return with a cushioned first touch that sets it back to your feet. Jog 3 yards laterally and repeat. Simulates receiving a long driven pass.",
                    duration: "12 min",
                    difficulty: .advanced,
                    targetSkill: skill.rawValue,
                    coachingCues: ["The harder you strike, the faster the return—prepare your body shape early", "Absorb the pace completely on your first touch", "Move after every receive—never stand still"],
                    reps: "3 sets of 10 per foot",
                    category: .receiving,
                    intensity: .high,
                    equipment: [.ball, .wall, .cones],
                    tags: ["solo-friendly", "minimal-equipment", "wall-training", "movement-after-pass", "2-touch"],
                    purpose: "Build the ability to receive hard-driven balls cleanly and immediately reposition.",
                    setup: "Stand 10 yards from a flat wall. Place two cones 3 yards apart as your lateral movement zone.",
                    space: .medium,
                    instructions: [
                        "From the left cone, strike the ball hard with your laces into the wall.",
                        "Receive the fast return with a cushioned inside-foot touch that sets the ball at your feet.",
                        "Immediately jog laterally to the right cone with the ball.",
                        "Strike hard again from the new position.",
                        "Continue alternating positions for 10 total strikes.",
                        "Switch to your weaker foot for the second set."
                    ],
                    commonMistakes: ["The ball bouncing off your foot on reception—withdraw and cushion", "Standing still after receiving instead of relocating", "Striking weakly because you are afraid of the fast return"]
                ),
                Drill(
                    name: "Outside Foot Wall Catch",
                    description: "Pass firmly into the wall and receive the return exclusively with the outside of your foot, killing the ball dead. The outside surface is the hardest to cushion with—this drill isolates it.",
                    duration: "10 min",
                    difficulty: .intermediate,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Rotate your ankle inward so the outside faces the ball", "Withdraw on contact—don't stab at it", "Keep your standing foot planted and balanced"],
                    reps: "3 sets of 15 per foot",
                    category: .receiving,
                    intensity: .moderate,
                    equipment: [.ball, .wall],
                    tags: ["solo-friendly", "minimal-equipment", "wall-training", "2-touch"],
                    purpose: "Isolate and improve the outside-of-foot receiving surface, often neglected in training.",
                    setup: "Stand 5 yards from a flat wall. No cones required.",
                    space: .small,
                    instructions: [
                        "Pass the ball into the wall at moderate pace with your inside foot.",
                        "As the ball returns, receive it with the outside of your right foot only.",
                        "Cushion the ball so it stops within 1 foot of you.",
                        "Reset and pass again. Complete 15 reps on your right foot.",
                        "Switch to receiving with the outside of your left foot.",
                        "Final set: alternate feet every rep."
                    ],
                    commonMistakes: ["Cheating by using the inside foot—commit to the outside surface", "Jabbing at the ball instead of withdrawing to cushion", "Ball bouncing away because ankle is too stiff"]
                ),
                Drill(
                    name: "Wall Chest-to-Foot Settle",
                    description: "Strike the ball hard and low into the wall so it pops up on the return. Chest the rising ball down and settle it with your foot in one fluid sequence. Trains aerial-to-ground reception.",
                    duration: "12 min",
                    difficulty: .advanced,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Strike low on the wall so the return bounces up", "Chest out and withdraw to absorb—don't let it bounce off you", "Settle with a soft foot touch immediately after the chest"],
                    reps: "3 sets of 10",
                    category: .receiving,
                    intensity: .moderate,
                    equipment: [.ball, .wall],
                    tags: ["solo-friendly", "minimal-equipment", "wall-training", "2-touch"],
                    purpose: "Develop the chest-to-foot settling combination used to control bouncing passes and clearances.",
                    setup: "Stand 6 yards from a flat wall. Strike low so the ball returns with a bounce.",
                    space: .small,
                    instructions: [
                        "Strike the ball firmly into the base of the wall so it bounces up on the return.",
                        "As the ball rises toward chest height, chest it downward.",
                        "Immediately settle the ball with the inside of your foot as it drops.",
                        "The ball should be under control within 2 touches after the chest.",
                        "Reset and repeat. Vary the power of your wall strike to change the return height.",
                        "On the final set, settle with your weaker foot only."
                    ],
                    commonMistakes: ["Chest too rigid—puff out then withdraw to cushion", "Letting the ball hit the ground before your foot touch", "Striking the wall too high so the return stays flat"]
                ),
                Drill(
                    name: "Blind-Side Receive Drill",
                    description: "Stand sideways to the wall so the ball returns from your blind side. Pass, then quickly open your hips to receive the return you cannot fully see until the last moment. Trains peripheral awareness.",
                    duration: "10 min",
                    difficulty: .advanced,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Start with your shoulder facing the wall, not your chest", "Open your hips at the last second to receive", "Use your ears and peripheral vision to time the turn"],
                    reps: "4 sets of 8 per side",
                    category: .receiving,
                    intensity: .moderate,
                    equipment: [.ball, .wall, .cones],
                    tags: ["solo-friendly", "minimal-equipment", "wall-training", "turning-after-receive"],
                    purpose: "Simulate receiving a pass from behind or from the blind side, building awareness and body adjustment speed.",
                    setup: "Stand 5 yards from a flat wall. Place a cone 3 yards behind you as a turn target.",
                    space: .small,
                    instructions: [
                        "Stand sideways to the wall with your left shoulder closest to it.",
                        "Pass the ball into the wall with a quick body rotation.",
                        "Immediately return to your sideways stance so the return arrives from your blind side.",
                        "At the last moment, open your hips and receive the ball with your right foot.",
                        "Turn toward the cone behind you and dribble to it.",
                        "Complete 8 reps, then switch so your right shoulder faces the wall."
                    ],
                    commonMistakes: ["Peeking at the wall the whole time—trust your timing", "Opening hips too early and losing the blind-side simulation", "Heavy first touch because you panicked at the late adjustment"]
                ),
                Drill(
                    name: "Sole Kill & Go",
                    description: "Pass firmly into the wall and kill the return dead with the sole of your foot. The instant the ball stops, explode forward 3 yards with a push, then jog back and repeat. Combines dead reception with instant acceleration.",
                    duration: "10 min",
                    difficulty: .intermediate,
                    targetSkill: skill.rawValue,
                    coachingCues: ["The sole kill must be instant—one touch, dead stop", "Transition from stop to sprint with zero delay", "Push the ball ahead with your laces on the explosion, not with the sole"],
                    reps: "4 sets of 8",
                    category: .receiving,
                    intensity: .high,
                    equipment: [.ball, .wall, .cones],
                    tags: ["solo-friendly", "minimal-equipment", "wall-training", "2-touch", "movement-after-pass"],
                    purpose: "Train the receive-and-explode pattern: dead-stop a pass then burst into space instantly.",
                    setup: "Stand 5 yards from a flat wall. Place a cone 3 yards behind you as your sprint target.",
                    space: .small,
                    instructions: [
                        "Pass the ball into the wall at firm pace.",
                        "As the ball returns, kill it dead under your sole—no bounce, no roll.",
                        "The instant the ball stops, push it forward with your laces and sprint to the cone behind you.",
                        "Stop at the cone, turn, jog back to the wall, and repeat.",
                        "Complete 8 reps per set. Use your weak foot sole on set 3.",
                        "Increase wall-pass power each set to make the sole kill harder."
                    ],
                    commonMistakes: ["The ball rolling after the sole touch—it must be dead still", "Pausing between the kill and the explosion—the transition is the drill", "Sprinting without the ball—push it ahead with you"]
                ),
                Drill(
                    name: "Bounce Receive & Redirect",
                    description: "Strike the ball into the lower wall so it bounces back along the ground with pace. Let it bounce once, then redirect it left or right with a single cushioned touch. Simulates receiving a skipping pass on an uneven pitch.",
                    duration: "10 min",
                    difficulty: .intermediate,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Read the bounce height early and adjust your foot height", "Redirect to the side, not straight back—simulate playing around a defender", "Stay on the balls of your feet to react to unpredictable bounces"],
                    reps: "3 sets of 12 (6 each direction)",
                    category: .receiving,
                    intensity: .moderate,
                    equipment: [.ball, .wall],
                    tags: ["solo-friendly", "minimal-equipment", "wall-training", "2-touch"],
                    purpose: "Build the ability to control bouncing passes and redirect them with purpose.",
                    setup: "Stand 6 yards from a flat wall. No cones needed.",
                    space: .small,
                    instructions: [
                        "Strike the ball low and firm into the base of the wall.",
                        "The return will bounce and skip back toward you.",
                        "Let it bounce once, then cushion-redirect it to your left with the inside of your right foot.",
                        "Collect the ball and repeat, this time redirecting right.",
                        "Alternate directions for 12 total reps.",
                        "On the final set, use only your weaker foot to redirect."
                    ],
                    commonMistakes: ["Trying to receive before the bounce—let it skip once", "Redirecting straight back instead of to the side", "Flat-footed stance making it hard to adjust to the bounce"]
                )
            ]
        case .juggling:
            return [
                Drill(
                    name: "Touch and Catch",
                    description: "Kick the ball up with one foot and catch it. Repeat, adding one extra touch each round before catching. Builds rhythm and confidence.",
                    duration: "6 min",
                    difficulty: .beginner,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Lock your ankle on contact", "Toe pointed slightly up", "Keep touches waist height"],
                    reps: "5 rounds, add 1 touch per round",
                    category: .juggling,
                    intensity: .low,
                    equipment: [.ball],
                    tags: ["solo-friendly", "minimal-equipment"],
                    purpose: "Build a consistent striking surface and develop comfort keeping the ball airborne.",
                    setup: "Stand in an open area with the ball in your hands.",
                    space: .small,
                    instructions: [
                        "Drop the ball and kick it up with your laces, then catch it.",
                        "Next round, do 2 touches before catching.",
                        "Add 1 touch each round up to 5.",
                        "If you drop the ball, restart that round.",
                        "Focus on a soft, controlled contact each time."
                    ],
                    commonMistakes: ["Kicking too hard and losing control", "Toe pointing down instead of slightly up", "Not watching the ball onto the foot"]
                ),
                Drill(
                    name: "Strict Alternating Feet",
                    description: "Juggle using strictly alternating feet — left, right, left, right. No same-foot doubles allowed. Trains balance and bilateral coordination.",
                    duration: "8 min",
                    difficulty: diff,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Left-right-left-right rhythm", "Stay light on your standing foot", "Keep each touch at the same height"],
                    reps: "4 sets of 60 seconds",
                    category: .juggling,
                    intensity: .low,
                    equipment: [.ball],
                    tags: ["solo-friendly", "minimal-equipment"],
                    purpose: "Force even development on both feet and build a natural alternating rhythm.",
                    setup: "Stand with the ball in your hands in a small open area.",
                    space: .small,
                    instructions: [
                        "Drop the ball and begin juggling, alternating feet every touch.",
                        "Count consecutive alternating touches.",
                        "If you use the same foot twice, restart the count.",
                        "Rest 30 seconds between sets.",
                        "Try to beat your record each set."
                    ],
                    commonMistakes: ["Defaulting to dominant foot under pressure", "Rushing touches instead of staying relaxed", "Leaning too far to one side"]
                ),
                Drill(
                    name: "Weak Foot Only Challenge",
                    description: "Juggle using only your non-dominant foot. Start with low targets and gradually increase. Builds weak-foot confidence fast.",
                    duration: "8 min",
                    difficulty: .intermediate,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Commit fully to the weak foot", "Soft touches, no power", "Stay patient — consistency over quantity"],
                    reps: "5 sets of 45 seconds",
                    category: .juggling,
                    intensity: .low,
                    equipment: [.ball],
                    tags: ["solo-friendly", "minimal-equipment"],
                    purpose: "Accelerate weak-foot development through focused repetition.",
                    setup: "Ball in hands, open space. Decide which foot is your weaker one.",
                    space: .small,
                    instructions: [
                        "Drop the ball and juggle using only your weak foot.",
                        "Count your consecutive touches.",
                        "If the ball drops, pick it up and go again.",
                        "Target: 5 touches in set 1, 8 in set 2, 10+ in sets 3–5.",
                        "Rest 30 seconds between sets."
                    ],
                    commonMistakes: ["Switching to the strong foot out of habit", "Tense ankle — keep it relaxed but firm", "Giving up too early when the count is low"]
                ),
                Drill(
                    name: "Bounce Juggling",
                    description: "Let the ball bounce once between every touch. Kick it up, let it bounce, kick it up again. Teaches timing and soft contact.",
                    duration: "7 min",
                    difficulty: .beginner,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Let the ball rise off the bounce before touching", "Meet the ball gently — don't stab at it", "Stay over the ball"],
                    reps: "4 sets of 60 seconds",
                    category: .juggling,
                    intensity: .low,
                    equipment: [.ball],
                    tags: ["solo-friendly", "minimal-equipment"],
                    purpose: "Develop timing and a soft touch by using the bounce as a built-in rhythm keeper.",
                    setup: "Find a flat, hard surface. Grass works but hard ground gives a better bounce.",
                    space: .small,
                    instructions: [
                        "Drop the ball and let it bounce.",
                        "As it rises, tap it up gently with your laces.",
                        "Let it bounce once, then tap again.",
                        "Keep the bounce-touch pattern going for 60 seconds.",
                        "Alternate feet if comfortable, or stick to one foot per set."
                    ],
                    commonMistakes: ["Hitting the ball too hard so the bounce goes high", "Not waiting for the ball to rise — striking on the way down", "Standing flat-footed instead of on the balls of your feet"]
                ),
                Drill(
                    name: "Freeze and Hold",
                    description: "Juggle continuously, then on a self-count of 5, dead-stop the ball on your foot and hold it still for 2 seconds. Tests control under momentum.",
                    duration: "8 min",
                    difficulty: .intermediate,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Cushion the ball to a stop — absorb its energy", "Balance on one leg with a strong core", "Hold the freeze, don't rush"],
                    reps: "6 freeze attempts per set, 3 sets",
                    category: .juggling,
                    intensity: .moderate,
                    equipment: [.ball],
                    tags: ["solo-friendly", "minimal-equipment"],
                    purpose: "Train the ability to kill a moving ball instantly — transfers directly to first-touch control in games.",
                    setup: "Open space, ball in hands.",
                    space: .small,
                    instructions: [
                        "Start juggling with both feet.",
                        "After every 5 touches, trap the ball dead on top of your foot.",
                        "Hold the ball still on your foot for a full 2-second count.",
                        "Resume juggling and repeat.",
                        "If the ball rolls off during the freeze, restart the count."
                    ],
                    commonMistakes: ["Slapping the foot down instead of cushioning", "Losing balance during the hold", "Rushing the freeze — count a full 2 seconds"]
                ),
                Drill(
                    name: "Walking Juggle",
                    description: "Juggle while walking forward in a straight line. Combine ball control with movement — a key match skill.",
                    duration: "10 min",
                    difficulty: .intermediate,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Small forward steps between touches", "Angle touches slightly ahead of you", "Keep your head up periodically"],
                    reps: "5 lengths of 15–20 yards",
                    category: .juggling,
                    intensity: .moderate,
                    equipment: [.ball],
                    tags: ["solo-friendly", "minimal-equipment"],
                    purpose: "Train juggling with forward movement, building coordination that transfers to dribbling under pressure.",
                    setup: "Mark a start and end point about 15–20 yards apart.",
                    space: .medium,
                    instructions: [
                        "Start at the line with the ball in your hands.",
                        "Begin juggling and walk forward at the same time.",
                        "Keep touches low and slightly ahead of your body.",
                        "If the ball drops, pick it up and continue from where it fell.",
                        "Try to cover the full distance without dropping."
                    ],
                    commonMistakes: ["Juggling in place and forgetting to move", "Taking big steps that throw off balance", "Touching the ball too high — keep it below the waist"]
                ),
                Drill(
                    name: "Spin Move Juggle",
                    description: "Juggle 5 touches, pop the ball up higher, do a 360-degree spin, then continue juggling. Builds aerial awareness and body control.",
                    duration: "10 min",
                    difficulty: .advanced,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Pop the ball high enough to give yourself time", "Spin quickly and find the ball with your eyes", "Cushion the first touch after the spin"],
                    reps: "Best of 8 attempts",
                    category: .juggling,
                    intensity: .moderate,
                    equipment: [.ball],
                    tags: ["solo-friendly", "minimal-equipment"],
                    purpose: "Develop spatial awareness and the ability to recover control after losing sight of the ball briefly.",
                    setup: "Open flat area, ball in hands.",
                    space: .small,
                    instructions: [
                        "Start juggling normally.",
                        "After 5 touches, pop the ball about head height.",
                        "Quickly spin 360 degrees.",
                        "Find the ball and continue juggling without dropping.",
                        "Count it as a success if you get 3+ touches after the spin."
                    ],
                    commonMistakes: ["Not popping the ball high enough before spinning", "Spinning slowly and losing the ball", "Panicking after the spin — stay calm and cushion"]
                ),
                Drill(
                    name: "Thigh-Foot Combo Ladder",
                    description: "Alternate between thigh and foot touches in a set pattern: foot-foot-thigh, foot-foot-thigh. Builds multi-surface fluency.",
                    duration: "8 min",
                    difficulty: .intermediate,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Thigh touch should be flat and controlled", "Transition smoothly — don't pause between surfaces", "Keep the ball in a tight vertical column"],
                    reps: "4 sets of 60 seconds",
                    category: .juggling,
                    intensity: .moderate,
                    equipment: [.ball],
                    tags: ["solo-friendly", "minimal-equipment"],
                    purpose: "Train seamless transitions between body surfaces, improving overall ball manipulation.",
                    setup: "Open space, ball in hands.",
                    space: .small,
                    instructions: [
                        "Start juggling with your right foot.",
                        "Pattern: right foot, left foot, right thigh, left foot, right foot, left thigh.",
                        "Repeat the pattern continuously for 60 seconds.",
                        "If you lose the pattern, restart from foot-foot-thigh.",
                        "Rest 30 seconds between sets."
                    ],
                    commonMistakes: ["Thigh angled wrong — keep it flat and horizontal", "Breaking the pattern under pressure", "Touching too hard with the thigh — just redirect, don't kick"]
                ),
                Drill(
                    name: "Countdown Juggle",
                    description: "Start at 50 touches. Every time you drop, subtract 5. Race against the clock to finish before time runs out. Adds pressure to your practice.",
                    duration: "10 min",
                    difficulty: diff,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Stay calm even when the count drops", "Find your rhythm after every restart", "Focus on consistency, not speed"],
                    reps: "3 rounds of 3 minutes",
                    category: .juggling,
                    intensity: .moderate,
                    equipment: [.ball],
                    tags: ["solo-friendly", "minimal-equipment"],
                    purpose: "Simulate pressure situations — forces focus and composure when the count is slipping.",
                    setup: "Ball in hands. Set a timer for 3 minutes per round.",
                    space: .small,
                    instructions: [
                        "Set your target at 50 cumulative touches.",
                        "Start juggling and count each touch.",
                        "If you drop the ball, subtract 5 from your total.",
                        "Try to reach 50 within 3 minutes.",
                        "Rest 1 minute, then start a new round."
                    ],
                    commonMistakes: ["Panicking after a drop and rushing", "Counting wrong — stay honest", "Going for flashy touches instead of safe ones"]
                ),
                Drill(
                    name: "Lateral Shuffle Juggle",
                    description: "Juggle while shuffling side to side between two markers. Combines footwork agility with aerial control.",
                    duration: "10 min",
                    difficulty: .advanced,
                    targetSkill: skill.rawValue,
                    coachingCues: ["Small quick shuffles, stay low", "Angle touches in the direction you're moving", "Eyes on the ball, feel the cones"],
                    reps: "4 sets of 60 seconds",
                    category: .juggling,
                    intensity: .high,
                    equipment: [.ball, .cones],
                    tags: ["solo-friendly", "minimal-equipment"],
                    purpose: "Train juggling under movement stress — builds coordination that transfers to receiving while on the move.",
                    setup: "Place two cones 5 yards apart. Stand between them with the ball.",
                    space: .medium,
                    instructions: [
                        "Start juggling at the center.",
                        "Shuffle to the right cone while keeping the ball up.",
                        "Touch the cone area, then shuffle back to the left cone.",
                        "Keep juggling the entire time — no catching.",
                        "If the ball drops, pick up and continue shuffling."
                    ],
                    commonMistakes: ["Standing still and just juggling — commit to the movement", "Crossing feet while shuffling", "Losing the ball because touches aren't angled with movement"]
                )
            ]
        }
    }

    private func drillsForWeakness(_ weakness: WeaknessArea, level: SkillLevel) -> [Drill] {
        let diff = difficultyFor(level)
        switch weakness {
        case .firstTouch:
            return [
                Drill(name: "First Touch Pressure Drill", description: "Receive passes under simulated pressure. A defender closes you down, forcing quick control and turn.", duration: "15 min", difficulty: diff, targetSkill: "First Touch", coachingCues: ["Look before receiving", "Take touch away from pressure", "Protect the ball"], reps: "4 sets of 8", trainingMode: .partner, equipment: [.ball, .cones], tags: ["minimal-equipment"]),
                Drill(name: "Two-Touch Passing Triangles", description: "In a triangle of 3 players, first touch sets up a clean pass. Increase tempo every minute.", duration: "10 min", difficulty: diff, targetSkill: "First Touch", coachingCues: ["First touch out of feet", "Weight of pass matters", "Communicate early"], reps: "4 rounds of 2 min", trainingMode: .team, equipment: [.ball, .cones], tags: ["minimal-equipment"])
            ]
        case .shooting:
            return [
                Drill(name: "Shooting Under Fatigue", description: "Sprint 20 yards, receive a pass, and shoot. The fatigue simulates real game conditions.", duration: "15 min", difficulty: diff, targetSkill: "Shooting Form", coachingCues: ["Composure despite fatigue", "Pick your spot", "Follow through clean"], reps: "3 sets of 6", equipment: [.ball, .goal], tags: ["solo-friendly"]),
                Drill(name: "Weak Foot Finishing", description: "All shots must be taken with your weaker foot. Start close and gradually move farther from goal.", duration: "15 min", difficulty: diff, targetSkill: "Shooting Form", coachingCues: ["Lock the ankle", "Technique over power", "Aim for placement"], reps: "3 sets of 8", equipment: [.ball, .goal], tags: ["solo-friendly"])
            ]
        case .dribbling:
            return [
                Drill(name: "1v1 Dribble Gauntlet", description: "Dribble through 4 simulated defenders. Use feints, step-overs, and changes of pace.", duration: "15 min", difficulty: diff, targetSkill: "Ball Control", coachingCues: ["Close control near defenders", "Accelerate past them", "Use body feints"], reps: "5 runs through", equipment: [.ball, .cones, .mannequin], tags: ["solo-friendly"]),
                Drill(name: "Speed Dribble Sprints", description: "Dribble at full speed over 30 yards, keeping the ball under control. Focus on pushing the ball ahead and sprinting to it.", duration: "10 min", difficulty: diff, targetSkill: "Ball Control", coachingCues: ["Push ball 2-3 yards ahead", "Sprint to catch it", "Use laces for speed dribbling"], reps: "6 sprints", equipment: [.ball, .cones], tags: ["solo-friendly", "minimal-equipment"])
            ]
        case .defending:
            return [
                Drill(name: "Defensive Stance Drill", description: "Practice jockeying, pressing triggers, and recovery runs against a partner with the ball.", duration: "15 min", difficulty: diff, targetSkill: "Body Position", coachingCues: ["Stay low and balanced", "Force onto weak foot", "Don't dive in"], reps: "4 sets of 2 min", trainingMode: .partner, equipment: [.ball], tags: ["minimal-equipment"]),
                Drill(name: "Recovery Run & Tackle", description: "Start 5 yards behind an attacker. Sprint to recover, get goal-side, and make a clean challenge.", duration: "12 min", difficulty: diff, targetSkill: "Body Position", coachingCues: ["Sprint to get goal-side first", "Patience once recovered", "Time the tackle"], reps: "4 sets of 5", trainingMode: .partner, equipment: [.ball, .cones], tags: ["minimal-equipment"])
            ]
        case .fitness:
            return [
                Drill(name: "High Intensity Interval Circuit", description: "Alternate between sprints, lateral shuffles, and recovery jogs. Finish with ball work.", duration: "20 min", difficulty: diff, targetSkill: "Movement", coachingCues: ["Max effort on sprints", "Active recovery", "Push through fatigue"], reps: "6 intervals", equipment: [.ball, .cones], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(name: "Ball-at-Feet Endurance", description: "Dribble continuously around a large area for timed intervals. Keep the ball close even when tired.", duration: "15 min", difficulty: diff, targetSkill: "Movement", coachingCues: ["Maintain ball contact even when tired", "Change pace and direction", "Simulate match fatigue"], reps: "3 sets of 4 min", equipment: [.ball], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(
                    name: "Interval Sprint Ladder",
                    description: "Sprint progressively longer distances with timed rest. Start at 20 yards, increase to 40, 60, 80, then back down. Full recovery between reps.",
                    duration: "25 min",
                    difficulty: diff,
                    targetSkill: "Movement",
                    coachingCues: ["100% effort on every sprint", "Drive knees and pump arms", "Complete the full rest—don't cheat recovery"],
                    reps: "5x20yd, 4x40yd, 3x60yd, 2x80yd, then reverse",
                    category: .movement,
                    intensity: .maximum,
                    equipment: [.cones],
                    tags: ["solo-friendly", "minimal-equipment", "conditioning", "speed"],
                    purpose: "Build anaerobic capacity and speed endurance through progressive sprint distances.",
                    setup: "Mark lines at 20, 40, 60, and 80 yards.",
                    space: .large,
                    instructions: [
                        "Begin with 5 sprints of 20 yards, resting 20 seconds between each.",
                        "Move to 4 sprints of 40 yards with 30 seconds rest.",
                        "Then 3 sprints of 60 yards with 45 seconds rest.",
                        "Then 2 sprints of 80 yards with 60 seconds rest.",
                        "Work back down the ladder: 3x60, 4x40, 5x20.",
                        "Walk back to the start line during rest periods."
                    ],
                    commonMistakes: ["Pacing sprints instead of going 100%", "Cutting rest short—full recovery is essential", "Poor form when fatigued—maintain mechanics"]
                ),
                Drill(
                    name: "120-Yard Shuttle Conditioning",
                    description: "Sprint 20 yards and back, 40 yards and back, then 60 yards and back without stopping. That is one rep. Rest and repeat.",
                    duration: "20 min",
                    difficulty: .advanced,
                    targetSkill: "Movement",
                    coachingCues: ["Touch the line on every turn", "Decelerate under control before turning", "Maintain sprint form even when tired"],
                    reps: "4-6 reps with 90 sec rest",
                    category: .movement,
                    intensity: .maximum,
                    equipment: [.cones],
                    tags: ["solo-friendly", "minimal-equipment", "conditioning", "endurance"],
                    purpose: "Simulate the repeated high-intensity efforts of a full match with direction changes.",
                    setup: "Mark lines at 20, 40, and 60 yards from a start line.",
                    space: .large,
                    instructions: [
                        "Start at the baseline. Sprint to the 20-yard line and back.",
                        "Immediately sprint to the 40-yard line and back.",
                        "Immediately sprint to the 60-yard line and back.",
                        "That completes one rep. Rest 90 seconds.",
                        "Repeat for 4-6 total reps.",
                        "Aim to complete each rep in under 30 seconds."
                    ],
                    commonMistakes: ["Not touching the line on turns", "Jogging instead of sprinting", "Leaning too far forward on direction changes"]
                ),
                Drill(
                    name: "Dynamic Warm-Up Routine",
                    description: "A full-body dynamic stretching circuit to prepare muscles and joints for training. Covers hip flexors, hamstrings, quads, groin, and ankles.",
                    duration: "10 min",
                    difficulty: .beginner,
                    targetSkill: "Movement",
                    coachingCues: ["Controlled movements—no bouncing", "Increase range of motion gradually", "Breathe through each stretch"],
                    reps: "2 circuits of all exercises",
                    category: .movement,
                    intensity: .low,
                    equipment: [.none],
                    tags: ["solo-friendly", "minimal-equipment", "warmup", "flexibility"],
                    purpose: "Prepare the body for intense training and reduce injury risk.",
                    setup: "Clear area of at least 20 yards in length.",
                    space: .medium,
                    instructions: [
                        "High knees for 20 yards—drive knees to hip height.",
                        "Butt kicks for 20 yards—heels touch glutes.",
                        "Lateral leg swings: 10 per leg, holding a wall or fence for balance.",
                        "Forward leg swings: 10 per leg, swinging front to back.",
                        "Walking lunges with a twist: 10 per leg, rotate torso over the front knee.",
                        "Inchworms: 5 reps—walk hands out to plank, walk feet to hands.",
                        "Lateral shuffles: 20 yards each direction.",
                        "Carioca (grapevine): 20 yards each direction."
                    ],
                    commonMistakes: ["Rushing through the movements", "Skipping the lateral movements", "Static stretching instead of dynamic—keep moving"]
                ),
                Drill(
                    name: "Bodyweight Strength Circuit",
                    description: "A full-body strength circuit using only bodyweight. Targets legs, core, and upper body for athletic performance.",
                    duration: "25 min",
                    difficulty: diff,
                    targetSkill: "Movement",
                    coachingCues: ["Quality over speed—control every rep", "Full range of motion", "Core braced throughout"],
                    reps: "3 rounds of all exercises",
                    category: .movement,
                    intensity: .high,
                    equipment: [.none],
                    tags: ["solo-friendly", "minimal-equipment", "strength", "conditioning"],
                    purpose: "Build functional strength for explosive movements, shielding, and injury prevention.",
                    setup: "Flat surface with enough room to lie down.",
                    space: .minimal,
                    instructions: [
                        "Bodyweight squats: 15 reps. Sit back, chest up, knees tracking over toes.",
                        "Push-ups: 12 reps. Full range, chest to ground.",
                        "Reverse lunges: 10 per leg. Step back, drop rear knee to just above ground.",
                        "Plank hold: 45 seconds. Straight line from head to heels.",
                        "Single-leg glute bridges: 10 per leg. Drive hips up, squeeze at top.",
                        "Mountain climbers: 20 total (10 per side). Quick knees to chest.",
                        "Rest 60 seconds between rounds."
                    ],
                    commonMistakes: ["Half reps—go full range", "Sagging hips during planks", "Rushing through reps instead of controlled movement"]
                ),
                Drill(
                    name: "Lower Body Power Circuit",
                    description: "Plyometric and strength exercises targeting quads, hamstrings, glutes, and calves for explosive power.",
                    duration: "20 min",
                    difficulty: .intermediate,
                    targetSkill: "Movement",
                    coachingCues: ["Land softly on plyometrics—absorb through the legs", "Drive through the heels on squats and lunges", "Maintain core stability throughout"],
                    reps: "3 rounds",
                    category: .movement,
                    intensity: .high,
                    equipment: [.none],
                    tags: ["solo-friendly", "minimal-equipment", "strength", "plyometrics"],
                    purpose: "Develop explosive lower body power for sprinting, jumping, and quick direction changes.",
                    setup: "Flat surface. Optional: a sturdy box or bench for step-ups.",
                    space: .small,
                    instructions: [
                        "Jump squats: 10 reps. Squat down, explode upward, land soft.",
                        "Walking lunges: 12 per leg. Long stride, drive through front heel.",
                        "Single-leg calf raises: 15 per leg. Full range up and down.",
                        "Box jumps or tuck jumps: 8 reps. Explode up, land with bent knees.",
                        "Lateral lunges: 10 per side. Push hips back, keep chest up.",
                        "Wall sit: 45 seconds. Thighs parallel to ground, back flat on wall.",
                        "Rest 60 seconds between rounds."
                    ],
                    commonMistakes: ["Landing stiff-legged on jumps", "Knees caving inward on squats and lunges", "Not going deep enough on squats"]
                ),
                Drill(
                    name: "Core Stability Circuit",
                    description: "Targeted core exercises to build stability, rotational power, and injury resilience for athletic performance.",
                    duration: "15 min",
                    difficulty: diff,
                    targetSkill: "Movement",
                    coachingCues: ["Brace your core as if bracing for a hit", "Breathe steadily—don't hold your breath", "Quality holds over rushing through reps"],
                    reps: "3 rounds",
                    category: .movement,
                    intensity: .moderate,
                    equipment: [.none],
                    tags: ["solo-friendly", "minimal-equipment", "core", "strength"],
                    purpose: "Build a strong, stable core that transfers to every movement on the field.",
                    setup: "Flat surface with room to lie down and extend fully.",
                    space: .minimal,
                    instructions: [
                        "Front plank: 45 seconds. Elbows under shoulders, body straight.",
                        "Side plank: 30 seconds each side. Stack feet, lift hips.",
                        "Dead bugs: 10 per side. Opposite arm and leg extend slowly.",
                        "Russian twists: 20 total. Sit at 45 degrees, rotate side to side.",
                        "Bird dogs: 10 per side. Extend opposite arm and leg, hold 2 seconds.",
                        "Hollow body hold: 30 seconds. Lower back pressed to ground, legs and shoulders lifted.",
                        "Rest 45 seconds between rounds."
                    ],
                    commonMistakes: ["Arching the lower back during planks", "Using momentum on Russian twists instead of controlled rotation", "Holding breath instead of breathing steadily"]
                ),
                Drill(
                    name: "Tabata Sprint Protocol",
                    description: "20 seconds of all-out sprinting followed by 10 seconds of rest, repeated for 8 rounds. Maximum cardiovascular demand in minimal time.",
                    duration: "12 min",
                    difficulty: .advanced,
                    targetSkill: "Movement",
                    coachingCues: ["True 100% effort on every 20-second interval", "Complete rest during the 10 seconds—don't jog", "Maintain sprint form even in later rounds"],
                    reps: "8 rounds of 20 sec on / 10 sec off",
                    category: .movement,
                    intensity: .maximum,
                    equipment: [.cones],
                    tags: ["solo-friendly", "minimal-equipment", "conditioning", "hiit"],
                    purpose: "Maximize aerobic and anaerobic capacity in a short, intense session.",
                    setup: "Mark a 30-yard sprint lane. Timer or stopwatch required.",
                    space: .medium,
                    instructions: [
                        "Warm up for 3-5 minutes with light jogging and dynamic stretches.",
                        "Sprint at maximum effort for 20 seconds.",
                        "Rest completely for 10 seconds.",
                        "Repeat for 8 total rounds (4 minutes of work).",
                        "Cool down with 3-5 minutes of walking and light stretching.",
                        "Track your distance each round to monitor performance."
                    ],
                    commonMistakes: ["Pacing yourself—each round must be max effort", "Starting without a proper warm-up", "Jogging during rest instead of full recovery"]
                ),
                Drill(
                    name: "Tempo Run Endurance Builder",
                    description: "Run at 70-80% of max speed for sustained intervals. Builds the aerobic base needed for 90 minutes of match play.",
                    duration: "25 min",
                    difficulty: diff,
                    targetSkill: "Movement",
                    coachingCues: ["Maintain a steady, sustainable pace", "Controlled breathing—in through nose, out through mouth", "Upright posture, relaxed shoulders"],
                    reps: "4 sets of 4 min with 2 min jog recovery",
                    category: .movement,
                    intensity: .moderate,
                    equipment: [.cones],
                    tags: ["solo-friendly", "minimal-equipment", "endurance", "conditioning"],
                    purpose: "Develop the aerobic engine needed to maintain intensity throughout a full match.",
                    setup: "A field or open area for continuous running. Mark a loop if possible.",
                    space: .large,
                    instructions: [
                        "Warm up with 3 minutes of easy jogging.",
                        "Run at 70-80% effort for 4 minutes. This should feel comfortably hard.",
                        "Slow to an easy jog for 2 minutes of active recovery.",
                        "Repeat the 4-minute tempo run.",
                        "Complete 4 total tempo intervals.",
                        "Cool down with 3 minutes of walking."
                    ],
                    commonMistakes: ["Starting too fast and fading in later intervals", "Recovery jog too fast—keep it truly easy", "Hunching over when fatigued—stay tall"]
                ),
                Drill(
                    name: "Cone Agility Box Drill",
                    description: "Set 4 cones in a 10-yard square. Sprint forward, shuffle right, backpedal, shuffle left back to start. Repeat in both directions.",
                    duration: "12 min",
                    difficulty: diff,
                    targetSkill: "Movement",
                    coachingCues: ["Stay low through all movements", "Push off the outside foot on direction changes", "Face forward the entire time"],
                    reps: "6 reps each direction",
                    category: .movement,
                    intensity: .high,
                    equipment: [.cones],
                    tags: ["solo-friendly", "minimal-equipment", "agility", "conditioning"],
                    purpose: "Develop multi-directional agility that mirrors in-game defensive and offensive movement.",
                    setup: "4 cones in a 10x10 yard square.",
                    space: .medium,
                    instructions: [
                        "Start at the bottom-left cone.",
                        "Sprint forward to the top-left cone.",
                        "Lateral shuffle right to the top-right cone.",
                        "Backpedal to the bottom-right cone.",
                        "Lateral shuffle left back to the start.",
                        "Rest 30 seconds, then repeat going counter-clockwise."
                    ],
                    commonMistakes: ["Crossing feet during lateral shuffles", "Standing too upright—stay in an athletic stance", "Rounding corners instead of sharp direction changes"]
                ),
                Drill(
                    name: "Resistance Band Lateral Walks",
                    description: "Place a resistance band above your knees and walk laterally in an athletic stance. Strengthens hip abductors critical for cutting and stability.",
                    duration: "10 min",
                    difficulty: .beginner,
                    targetSkill: "Movement",
                    coachingCues: ["Keep tension on the band at all times", "Stay low in an athletic stance", "Push knees out against the band"],
                    reps: "3 sets of 15 steps each direction",
                    category: .movement,
                    intensity: .low,
                    equipment: [.resistanceBand],
                    tags: ["solo-friendly", "strength", "injury-prevention"],
                    purpose: "Strengthen the hip stabilizers to improve lateral quickness and reduce knee injury risk.",
                    setup: "Place a light-to-medium resistance band just above both knees.",
                    space: .small,
                    instructions: [
                        "Stand with feet hip-width apart, band above knees.",
                        "Bend knees slightly into an athletic stance.",
                        "Step sideways with your lead foot, maintaining band tension.",
                        "Follow with your trail foot—don't let feet come together.",
                        "Take 15 steps to the right, then 15 steps to the left.",
                        "Rest 30 seconds between sets."
                    ],
                    commonMistakes: ["Letting knees cave inward", "Standing too tall—stay in a quarter squat", "Dragging the trail foot instead of controlled steps"]
                ),
                Drill(
                    name: "Plyometric Box Jumps",
                    description: "Explosive two-footed jumps onto a raised surface. Builds vertical power and fast-twitch muscle recruitment.",
                    duration: "12 min",
                    difficulty: .intermediate,
                    targetSkill: "Movement",
                    coachingCues: ["Swing arms to generate momentum", "Land softly with bent knees on top", "Step down—don't jump down"],
                    reps: "4 sets of 8 jumps",
                    category: .movement,
                    intensity: .high,
                    equipment: [.none],
                    tags: ["solo-friendly", "plyometrics", "strength"],
                    purpose: "Develop explosive vertical power for winning aerial duels and generating sprint power.",
                    setup: "A sturdy bench, step, or raised surface 12-24 inches high.",
                    space: .minimal,
                    instructions: [
                        "Stand facing the box with feet shoulder-width apart.",
                        "Swing arms back, load through your hips and knees.",
                        "Explode upward, driving arms forward and up.",
                        "Land softly on the box with both feet, knees bent.",
                        "Stand fully upright on the box.",
                        "Step down carefully and reset. Rest 45 seconds between sets."
                    ],
                    commonMistakes: ["Landing stiff-legged", "Jumping down instead of stepping down", "Not fully extending hips at the top"]
                ),
                Drill(
                    name: "Broad Jump & Sprint Combo",
                    description: "Perform a standing broad jump for max distance, then immediately sprint 20 yards. Combines horizontal power with acceleration.",
                    duration: "12 min",
                    difficulty: .intermediate,
                    targetSkill: "Movement",
                    coachingCues: ["Drive forward and up on the jump", "Stick the landing, then explode into the sprint", "Pump arms hard on the sprint"],
                    reps: "5 sets of 3 jump-sprint combos",
                    category: .movement,
                    intensity: .high,
                    equipment: [.cones],
                    tags: ["solo-friendly", "minimal-equipment", "plyometrics", "speed"],
                    purpose: "Train the transition from explosive power generation to top-speed acceleration.",
                    setup: "Open space with a marked start line and a cone 20 yards ahead.",
                    space: .medium,
                    instructions: [
                        "Stand at the start line with feet shoulder-width apart.",
                        "Swing arms and perform a max-effort standing broad jump.",
                        "Land with bent knees, absorb the impact.",
                        "Immediately transition into a 20-yard sprint.",
                        "Walk back to the start. Rest 30 seconds.",
                        "Repeat 3 times per set, rest 60 seconds between sets."
                    ],
                    commonMistakes: ["Pausing too long between the jump and sprint", "Landing on heels instead of balls of feet", "Poor arm mechanics on the sprint"]
                ),
                Drill(
                    name: "Single-Leg Balance & Reach",
                    description: "Stand on one leg and reach in multiple directions without losing balance. Builds proprioception, ankle stability, and single-leg strength.",
                    duration: "10 min",
                    difficulty: .beginner,
                    targetSkill: "Movement",
                    coachingCues: ["Keep your standing knee slightly bent", "Hinge at the hip, don't round your back", "Control the movement—no rushing"],
                    reps: "3 sets of 8 reaches per leg",
                    category: .movement,
                    intensity: .low,
                    equipment: [.none],
                    tags: ["solo-friendly", "minimal-equipment", "balance", "injury-prevention"],
                    purpose: "Develop balance and ankle stability to reduce injury risk and improve single-leg performance.",
                    setup: "Stand on flat ground. Optional: place cones at reach targets.",
                    space: .minimal,
                    instructions: [
                        "Stand on your right leg with a slight knee bend.",
                        "Reach forward with your left foot as far as possible, tap the ground, return.",
                        "Reach to the left side, tap, return.",
                        "Reach behind you, tap, return.",
                        "That is one rep. Complete 8 reps.",
                        "Switch to your left leg and repeat."
                    ],
                    commonMistakes: ["Locking the standing knee", "Losing balance and putting the reaching foot down", "Not reaching far enough—push your range"]
                ),
                Drill(
                    name: "Fartlek Run with Ball",
                    description: "Continuous run with random speed changes while dribbling. Alternate between jogging, tempo running, and sprinting based on feel.",
                    duration: "20 min",
                    difficulty: diff,
                    targetSkill: "Movement",
                    coachingCues: ["Speed changes should be unpredictable", "Keep ball close during speed transitions", "Recover at jog pace, then burst again"],
                    reps: "Continuous for 15-20 min",
                    category: .movement,
                    intensity: .moderate,
                    equipment: [.ball, .cones],
                    tags: ["solo-friendly", "minimal-equipment", "endurance", "conditioning"],
                    purpose: "Build match-like fitness by combining continuous running with unpredictable speed changes and ball control.",
                    setup: "A large area or field for continuous running with a ball.",
                    space: .large,
                    instructions: [
                        "Start jogging with the ball at an easy pace for 2 minutes.",
                        "Sprint with the ball for 15-20 seconds.",
                        "Return to a jog for 1 minute.",
                        "Run at 75% pace for 30 seconds.",
                        "Jog again for 1 minute.",
                        "Continue varying speeds randomly for 15-20 minutes total."
                    ],
                    commonMistakes: ["Keeping a constant pace—the whole point is variability", "Losing the ball during speed changes", "Not pushing hard enough on the sprint sections"]
                ),
                Drill(
                    name: "Hamstring Nordic Curl",
                    description: "Kneel on the ground with ankles anchored. Slowly lower your body forward using hamstring control, then push back up. Elite injury prevention exercise.",
                    duration: "8 min",
                    difficulty: .advanced,
                    targetSkill: "Movement",
                    coachingCues: ["Lower as slowly as possible", "Keep your body straight from knees to head", "Use hands to catch yourself and push back up"],
                    reps: "3 sets of 6-8",
                    category: .movement,
                    intensity: .high,
                    equipment: [.none],
                    tags: ["solo-friendly", "minimal-equipment", "strength", "injury-prevention"],
                    purpose: "Strengthen hamstrings eccentrically to dramatically reduce hamstring strain risk.",
                    setup: "Kneel on a soft surface. Have a partner hold your ankles, or anchor them under a heavy object.",
                    space: .minimal,
                    instructions: [
                        "Kneel with your body upright and ankles secured.",
                        "Cross arms over your chest or hold them ready to catch yourself.",
                        "Slowly lean forward, controlling the descent with your hamstrings.",
                        "Lower as far as you can under control.",
                        "Catch yourself with your hands and push back to the start.",
                        "Rest 60 seconds between sets."
                    ],
                    commonMistakes: ["Falling forward uncontrolled—go as slow as possible", "Bending at the hips instead of keeping a straight body line", "Skipping this exercise—it is the most effective hamstring injury preventer"]
                ),
                Drill(
                    name: "Acceleration Sled Sprint Simulation",
                    description: "Lean forward at 45 degrees against a wall and drive your knees high in a marching pattern. Then transition to a 15-yard acceleration sprint. Builds drive-phase mechanics.",
                    duration: "12 min",
                    difficulty: diff,
                    targetSkill: "Acceleration & Deceleration",
                    coachingCues: ["45-degree body angle during wall drives", "Piston-like knee drive—up and down", "Explode into the sprint with the same body lean"],
                    reps: "4 sets of 6 wall drives + sprint",
                    category: .acceleration,
                    intensity: .high,
                    equipment: [.wall, .cones],
                    tags: ["solo-friendly", "speed", "acceleration"],
                    purpose: "Train the forward lean and knee drive mechanics of the acceleration phase.",
                    setup: "Stand arm's length from a wall. Place a cone 15 yards behind you.",
                    space: .small,
                    instructions: [
                        "Lean into the wall at 45 degrees, hands on the wall.",
                        "Drive your right knee up to hip height, then snap it down.",
                        "Immediately drive your left knee up.",
                        "Perform 6 alternating knee drives.",
                        "On the last drive, push off the wall and sprint 15 yards.",
                        "Walk back and rest 30 seconds."
                    ],
                    commonMistakes: ["Body too upright during wall drives—maintain the lean", "Slow knee drives—they should be fast and powerful", "Standing up too quickly during the sprint transition"]
                ),
                Drill(
                    name: "Cooldown Stretching Routine",
                    description: "A full-body static stretching routine for post-training recovery. Hold each stretch for 30 seconds to improve flexibility and reduce soreness.",
                    duration: "10 min",
                    difficulty: .beginner,
                    targetSkill: "Movement",
                    coachingCues: ["Hold each stretch—no bouncing", "Breathe deeply and relax into the stretch", "Never stretch to the point of pain"],
                    reps: "30 seconds per stretch",
                    category: .movement,
                    intensity: .low,
                    equipment: [.none],
                    tags: ["solo-friendly", "minimal-equipment", "flexibility", "recovery"],
                    purpose: "Promote recovery, reduce muscle soreness, and maintain flexibility after training.",
                    setup: "Flat surface with room to sit and lie down.",
                    space: .minimal,
                    instructions: [
                        "Standing quad stretch: grab your ankle behind you, pull heel to glute. 30 sec each leg.",
                        "Standing hamstring stretch: place heel on a low surface, lean forward with straight back. 30 sec each.",
                        "Hip flexor stretch: kneel on one knee, push hips forward. 30 sec each side.",
                        "Seated groin stretch: sit with soles of feet together, gently press knees toward ground. 30 sec.",
                        "Lying glute stretch: cross ankle over opposite knee, pull toward chest. 30 sec each side.",
                        "Calf stretch: lean against a wall with one leg extended back, heel on ground. 30 sec each.",
                        "Child's pose: kneel and reach arms forward, rest forehead on ground. 30 sec."
                    ],
                    commonMistakes: ["Bouncing in the stretch", "Holding your breath—breathe deeply", "Rushing through instead of holding the full 30 seconds"]
                ),
                Drill(
                    name: "Yo-Yo Intermittent Recovery Test",
                    description: "Run 20-yard shuttles at progressively increasing speeds with 10-second active recovery between each. Continue until you can no longer keep pace.",
                    duration: "15 min",
                    difficulty: .advanced,
                    targetSkill: "Movement",
                    coachingCues: ["Pace the early levels—don't burn out", "Use the 10 seconds to walk and recover", "Push through the discomfort in later levels"],
                    reps: "Continue until failure",
                    category: .movement,
                    intensity: .maximum,
                    equipment: [.cones],
                    tags: ["solo-friendly", "minimal-equipment", "endurance", "conditioning"],
                    purpose: "Measure and improve your repeated sprint ability and match-specific endurance.",
                    setup: "Mark two lines 20 yards apart.",
                    space: .medium,
                    instructions: [
                        "Start at one line. Run to the other line and back (40 yards total).",
                        "Walk for 10 seconds to actively recover.",
                        "Repeat the shuttle at a slightly faster pace each level.",
                        "Continue increasing speed every 2 shuttles.",
                        "The test ends when you can no longer complete the shuttle in time.",
                        "Record your level and total distance for tracking progress."
                    ],
                    commonMistakes: ["Going too fast in the early levels", "Not using the recovery period to walk", "Stopping before you truly can't continue—push your limit"]
                ),
                Drill(
                    name: "Upper Body Push-Pull Circuit",
                    description: "Alternating push and pull exercises for balanced upper body strength. Improves shielding, throw-ins, and physical duels.",
                    duration: "15 min",
                    difficulty: diff,
                    targetSkill: "Movement",
                    coachingCues: ["Full range of motion on every rep", "Squeeze at the top of each movement", "Controlled tempo—2 seconds up, 2 seconds down"],
                    reps: "3 rounds",
                    category: .movement,
                    intensity: .moderate,
                    equipment: [.none],
                    tags: ["solo-friendly", "minimal-equipment", "strength"],
                    purpose: "Build balanced upper body strength for physical play, shielding the ball, and throw-ins.",
                    setup: "Flat surface. Optional: a pull-up bar or sturdy overhead support.",
                    space: .minimal,
                    instructions: [
                        "Push-ups: 12 reps. Chest to ground, full extension.",
                        "Inverted rows or bent-over bodyweight rows: 10 reps.",
                        "Diamond push-ups: 8 reps. Hands close together under chest.",
                        "Superman holds: 10 reps, hold for 3 seconds at top.",
                        "Pike push-ups: 8 reps. Feet elevated, shoulders targeted.",
                        "Rest 45 seconds between rounds."
                    ],
                    commonMistakes: ["Flaring elbows on push-ups—keep them at 45 degrees", "Partial reps—go full range", "Holding breath—exhale on exertion"]
                ),
                Drill(
                    name: "Sprint Interval Training",
                    description: "Alternate between maximum-effort sprints and walking recovery. Builds top-end speed and the ability to repeat high-intensity efforts.",
                    duration: "18 min",
                    difficulty: diff,
                    targetSkill: "Acceleration & Deceleration",
                    coachingCues: ["Each sprint is 100% effort", "Walk during recovery—don't jog", "Maintain sprint form even when fatigued"],
                    reps: "8-10 sprints of 30 yards",
                    category: .acceleration,
                    intensity: .maximum,
                    equipment: [.cones],
                    tags: ["solo-friendly", "minimal-equipment", "speed", "conditioning"],
                    purpose: "Develop repeated sprint ability to maintain speed throughout a full match.",
                    setup: "Mark a 30-yard sprint lane with cones.",
                    space: .medium,
                    instructions: [
                        "Warm up thoroughly with 5 minutes of dynamic stretching.",
                        "Sprint 30 yards at maximum effort.",
                        "Walk back to the start line for recovery (approximately 45-60 seconds).",
                        "Sprint again as soon as you reach the start.",
                        "Complete 8-10 total sprints.",
                        "Cool down with easy jogging and stretching."
                    ],
                    commonMistakes: ["Jogging instead of sprinting", "Not enough recovery between sprints", "Poor sprint mechanics when tired"]
                ),
                Drill(
                    name: "Repeat 100s",
                    description: "Two sets of 8x100m sprints at high intensity with 30-second rest between reps and 3-minute rest between sets. Goal is to reduce your time each cycle while maintaining the prescribed rest interval.",
                    duration: "25 min",
                    difficulty: .intermediate,
                    targetSkill: "Movement",
                    coachingCues: ["Maintain proper running mechanics throughout", "Drive knees and pump arms on each rep", "Use the rest interval fully—don't cut it short"],
                    reps: "2 sets of 8x100m",
                    category: .movement,
                    intensity: .high,
                    equipment: [.cones],
                    tags: ["solo-friendly", "minimal-equipment", "conditioning", "speed"],
                    purpose: "Build speed endurance and the ability to repeat high-intensity 100m efforts with short recovery.",
                    setup: "Mark a 100m distance on a field or track.",
                    space: .large,
                    instructions: [
                        "Warm up with 3-5 min of jogging and active stretching.",
                        "Sprint 100m at 85-90% effort.",
                        "Rest 30 seconds, then sprint again.",
                        "Complete 8 reps, then rest 3 minutes between sets.",
                        "Repeat for a second set of 8.",
                        "Finish with a 10-minute steady cooldown run."
                    ],
                    commonMistakes: ["Starting too fast and fading on later reps", "Cutting the rest interval short", "Poor posture and arm mechanics when fatigued"]
                ),
                Drill(
                    name: "30/30 Interval Runs",
                    description: "10 repetitions of 30-second sprints followed by 30-second jog recovery. A classic interval format that builds both aerobic and anaerobic capacity.",
                    duration: "15 min",
                    difficulty: diff,
                    targetSkill: "Movement",
                    coachingCues: ["Sprint hard for the full 30 seconds", "Jog actively during recovery—don't walk", "Maintain good running form throughout"],
                    reps: "10x30 sec sprint / 30 sec jog",
                    category: .movement,
                    intensity: .high,
                    equipment: [.cones],
                    tags: ["solo-friendly", "minimal-equipment", "conditioning", "hiit"],
                    purpose: "Develop the aerobic-anaerobic crossover capacity needed for repeated match efforts.",
                    setup: "Open field or track. Timer or stopwatch required.",
                    space: .medium,
                    instructions: [
                        "Warm up with 3-5 minutes of jogging.",
                        "Sprint at 85-90% effort for 30 seconds.",
                        "Jog at recovery pace for 30 seconds.",
                        "Repeat for 10 total sprint intervals.",
                        "Finish with a 10-minute steady cooldown run.",
                        "Progress by increasing to 12 reps with 45-second jog recovery."
                    ],
                    commonMistakes: ["Pacing the sprints instead of going hard", "Walking instead of jogging during recovery", "Not using a timer—guessing intervals leads to inconsistency"]
                ),
                Drill(
                    name: "90-Second Runs",
                    description: "6 repetitions of 90-second runs at high effort with 3-minute recovery between each. Builds sustained speed and lactate tolerance.",
                    duration: "25 min",
                    difficulty: .advanced,
                    targetSkill: "Movement",
                    coachingCues: ["Maintain a hard but sustainable pace for the full 90 seconds", "Use the 3-minute rest to walk and recover fully", "Emphasize good running mechanics"],
                    reps: "6x90 sec with 3 min recovery",
                    category: .movement,
                    intensity: .high,
                    equipment: [.cones],
                    tags: ["solo-friendly", "minimal-equipment", "conditioning", "endurance"],
                    purpose: "Build lactate tolerance and sustained high-intensity running capacity.",
                    setup: "Open field or track for continuous running.",
                    space: .large,
                    instructions: [
                        "Warm up with 3-5 minutes of jogging and dynamic stretches.",
                        "Run at 80-85% effort for 90 seconds.",
                        "Walk for 3 minutes of full recovery.",
                        "Repeat for 6 total runs.",
                        "Finish with a 10-minute steady cooldown run.",
                        "Progress by increasing to 8 reps over several weeks."
                    ],
                    commonMistakes: ["Starting too fast and dying out at 60 seconds", "Not recovering fully during the 3-minute rest", "Dropping form when fatigued"]
                ),
                Drill(
                    name: "One-Minute Runs",
                    description: "6 repetitions of 1-minute runs at near-maximum effort with 2-minute recovery between each. Targets anaerobic power and speed endurance.",
                    duration: "20 min",
                    difficulty: .intermediate,
                    targetSkill: "Movement",
                    coachingCues: ["Push hard for the full minute", "Controlled breathing during recovery", "Maintain upright posture even when tired"],
                    reps: "6x1 min with 2 min recovery",
                    category: .movement,
                    intensity: .high,
                    equipment: [.cones],
                    tags: ["solo-friendly", "minimal-equipment", "conditioning", "speed"],
                    purpose: "Develop the ability to sustain near-max effort for one-minute bursts, simulating match surges.",
                    setup: "Open field or track.",
                    space: .medium,
                    instructions: [
                        "Warm up with 3-5 minutes of jogging.",
                        "Run at 85-90% effort for 1 minute.",
                        "Walk or light jog for 2 minutes recovery.",
                        "Repeat for 6 total runs.",
                        "Finish with a 10-minute steady cooldown run.",
                        "Progress by reducing recovery to 90 seconds."
                    ],
                    commonMistakes: ["Not pushing hard enough—this should feel uncomfortable", "Cutting the recovery short", "Slowing down in the final 15 seconds"]
                ),
                Drill(
                    name: "Two-Minute Runs",
                    description: "3 repetitions of 2-minute runs at high effort with 2-minute recovery between each. Builds aerobic power and sustained running capacity.",
                    duration: "15 min",
                    difficulty: .intermediate,
                    targetSkill: "Movement",
                    coachingCues: ["Find a pace you can hold for the full 2 minutes", "Stay relaxed in your upper body", "Breathe rhythmically"],
                    reps: "3x2 min with 2 min recovery",
                    category: .movement,
                    intensity: .high,
                    equipment: [.cones],
                    tags: ["solo-friendly", "minimal-equipment", "conditioning", "endurance"],
                    purpose: "Build aerobic power and the mental toughness to sustain hard running for extended periods.",
                    setup: "Open field or track.",
                    space: .medium,
                    instructions: [
                        "Warm up with 3-5 minutes of jogging.",
                        "Run at 80% effort for 2 minutes.",
                        "Walk or light jog for 2 minutes recovery.",
                        "Repeat for 3 total runs.",
                        "Finish with a 10-minute steady cooldown run.",
                        "Progress by increasing to 5 reps over several weeks."
                    ],
                    commonMistakes: ["Going out too fast in the first 30 seconds", "Hunching over when tired—stay tall", "Not pushing through mental discomfort"]
                ),
                Drill(
                    name: "10-Second Burst Intervals",
                    description: "Burst at maximum effort for 10 seconds, then slow down and coast for 30 seconds. Continue this pattern for the total time. Builds explosive speed and recovery between bursts.",
                    duration: "15 min",
                    difficulty: diff,
                    targetSkill: "Movement",
                    coachingCues: ["Maximum effort for the full 10 seconds", "Coast at an easy jog—don't stop", "Maintain sprint form on every burst"],
                    reps: "2 sets of 5 min with 3 min walk between sets",
                    category: .movement,
                    intensity: .maximum,
                    equipment: [.cones],
                    tags: ["solo-friendly", "minimal-equipment", "conditioning", "speed", "hiit"],
                    purpose: "Simulate the short explosive bursts and recovery pattern of match play.",
                    setup: "Open field or track.",
                    space: .medium,
                    instructions: [
                        "Warm up with 3-5 minutes of jogging and active stretching.",
                        "Burst hard at maximum effort for 10 seconds.",
                        "Slow down and coast at easy jog pace for 30 seconds.",
                        "Repeat the burst-coast pattern for 5 minutes.",
                        "Walk for 3 minutes between sets.",
                        "Finish with a 10-minute steady cooldown run."
                    ],
                    commonMistakes: ["Not going truly max effort on bursts", "Stopping completely during coast phase—keep moving", "Losing form on later bursts"]
                ),
                Drill(
                    name: "Speed Play Conditioning",
                    description: "Continuous running with quick starts and stops to simulate match demands. Work bouts vary from 15 seconds to 90 seconds. Run hard, jog for recovery, alternate until the total time is completed.",
                    duration: "20 min",
                    difficulty: diff,
                    targetSkill: "Movement",
                    coachingCues: ["Vary your effort—mix sprints, tempo runs, and jogs", "Hard efforts should be genuinely hard", "Recovery jogs keep you moving, not standing"],
                    reps: "20 min total with 15 hard efforts dispersed",
                    category: .movement,
                    intensity: .high,
                    equipment: [.cones],
                    tags: ["solo-friendly", "minimal-equipment", "conditioning", "endurance"],
                    purpose: "Build match-like fitness with unpredictable speed changes and continuous movement.",
                    setup: "Open field or track for continuous running.",
                    space: .large,
                    instructions: [
                        "Warm up with 3-5 minutes of easy jogging.",
                        "Begin running at a comfortable pace.",
                        "At random intervals, burst into a hard run for 15-90 seconds.",
                        "Jog for recovery after each hard effort.",
                        "Aim for 15 hard efforts spread across the total time.",
                        "Finish with a 10-minute steady cooldown run."
                    ],
                    commonMistakes: ["Making all efforts the same intensity—vary them", "Not enough hard efforts—push yourself", "Walking instead of jogging during recovery"]
                ),
                Drill(
                    name: "Anaerobic Power Runs",
                    description: "3 repetitions of 45-second all-out sprints with 10-12 minutes of recovery between each. Develops peak anaerobic power output.",
                    duration: "35 min",
                    difficulty: .advanced,
                    targetSkill: "Movement",
                    coachingCues: ["Truly all-out effort for 45 seconds", "Full recovery between reps is essential", "Maintain sprint mechanics throughout"],
                    reps: "3x45 sec all-out with 10-12 min recovery",
                    category: .movement,
                    intensity: .maximum,
                    equipment: [.cones],
                    tags: ["solo-friendly", "minimal-equipment", "conditioning", "speed"],
                    purpose: "Develop peak anaerobic power for match-winning explosive efforts.",
                    setup: "Open field or track. Timer required.",
                    space: .medium,
                    instructions: [
                        "Warm up thoroughly with 5-10 minutes of jogging and dynamic stretches.",
                        "Sprint at absolute maximum effort for 45 seconds.",
                        "Walk and recover for 10-12 minutes until fully recovered.",
                        "Repeat for 3 total sprints.",
                        "Finish with a 10-minute steady cooldown run.",
                        "Progress by adding a 4th rep over several weeks."
                    ],
                    commonMistakes: ["Not going truly all-out—this must be maximum effort", "Cutting recovery short—you need full recovery", "Attempting this without a thorough warm-up"]
                ),
                Drill(
                    name: "Progressive Sprint Program — Phase 1",
                    description: "A structured sprinting session with progressive distances: 8x20yd, 6x40yd, 4x60yd, 2x80yd, and 1x100yd. Rest periods are scaled by distance. Builds sprint endurance and acceleration.",
                    duration: "25 min",
                    difficulty: .beginner,
                    targetSkill: "Acceleration & Deceleration",
                    coachingCues: ["Sprint at 90-95% effort on each rep", "Walk back to the start for recovery", "Focus on acceleration mechanics at shorter distances"],
                    reps: "8x20, 6x40, 4x60, 2x80, 1x100 yards",
                    category: .acceleration,
                    intensity: .high,
                    equipment: [.cones],
                    tags: ["solo-friendly", "minimal-equipment", "speed", "conditioning"],
                    purpose: "Build a foundation of sprint fitness with progressive distances and structured volume.",
                    setup: "Mark distances at 20, 40, 60, 80, and 100 yards.",
                    space: .large,
                    instructions: [
                        "Warm up with 5 minutes of jogging and dynamic stretches.",
                        "Sprint 8x20 yards with 30-second rest between reps.",
                        "Sprint 6x40 yards with 45-second rest.",
                        "Sprint 4x60 yards with 60-second rest.",
                        "Sprint 2x80 yards with 75-second rest.",
                        "Sprint 1x100 yards. Cool down with easy jogging."
                    ],
                    commonMistakes: ["Pacing sprints instead of running at high effort", "Skipping rest periods", "Poor deceleration after each sprint"]
                ),
                Drill(
                    name: "Progressive Sprint Program — Phase 2",
                    description: "Increased volume sprint session: 14x20yd, 10x40yd, 8x60yd, 6x80yd, 4x100yd. Shorter rest periods than Phase 1. For athletes with an established sprint base.",
                    duration: "35 min",
                    difficulty: .intermediate,
                    targetSkill: "Acceleration & Deceleration",
                    coachingCues: ["Maintain form even as volume increases", "Quality over quantity—if form breaks, rest longer", "Drive arms and knees on every rep"],
                    reps: "14x20, 10x40, 8x60, 6x80, 4x100 yards",
                    category: .acceleration,
                    intensity: .high,
                    equipment: [.cones],
                    tags: ["solo-friendly", "minimal-equipment", "speed", "conditioning"],
                    purpose: "Advance sprint endurance with higher volume and shorter rest for competitive athletes.",
                    setup: "Mark distances at 20, 40, 60, 80, and 100 yards.",
                    space: .large,
                    instructions: [
                        "Warm up with 5 minutes of jogging and dynamic stretches.",
                        "Sprint 14x20 yards with 25-second rest.",
                        "Sprint 10x40 yards with 35-second rest.",
                        "Sprint 8x60 yards with 50-second rest.",
                        "Sprint 6x80 yards with 60-second rest.",
                        "Sprint 4x100 yards with 75-second rest. Cool down."
                    ],
                    commonMistakes: ["Trying Phase 2 without completing Phase 1 first", "Sacrificing form for speed when fatigued", "Not stretching before and after"]
                ),
                Drill(
                    name: "Progressive Sprint Program — Phase 3",
                    description: "Peak volume sprint session: 18-20x20yd, 10x40yd, 8x60yd, 6x80yd, 4x100yd with reduced rest periods. For athletes approaching peak conditioning.",
                    duration: "40 min",
                    difficulty: .advanced,
                    targetSkill: "Acceleration & Deceleration",
                    coachingCues: ["This is peak volume—monitor your body for signs of overtraining", "Maintain explosive starts on every rep", "Rest periods are shorter—manage fatigue wisely"],
                    reps: "18x20, 10x40, 8x60, 6x80, 4x100 yards",
                    category: .acceleration,
                    intensity: .maximum,
                    equipment: [.cones],
                    tags: ["solo-friendly", "minimal-equipment", "speed", "conditioning"],
                    purpose: "Achieve peak sprint conditioning with maximum volume and reduced recovery.",
                    setup: "Mark distances at 20, 40, 60, 80, and 100 yards.",
                    space: .large,
                    instructions: [
                        "Warm up thoroughly with 5-10 minutes of jogging and dynamic stretches.",
                        "Sprint 18x20 yards with 20-second rest.",
                        "Sprint 10x40 yards with 30-second rest.",
                        "Sprint 8x60 yards with 45-second rest.",
                        "Sprint 6x80 yards with 60-second rest.",
                        "Sprint 4x100 yards with 75-second rest. Thorough cooldown."
                    ],
                    commonMistakes: ["Attempting without completing Phase 1 and 2", "Ignoring pain signals—this is peak volume", "Rushing through without proper warm-up"]
                ),
                Drill(
                    name: "Track Workout A — Distance Ladder",
                    description: "A progressive track workout: 4 laps (1 mile), 2 laps (half mile), 2 laps (half mile), 1 lap (quarter mile), 1 lap (quarter mile), 2 laps (half mile). Timed with structured rest between each.",
                    duration: "30 min",
                    difficulty: .advanced,
                    targetSkill: "Movement",
                    coachingCues: ["Hit target times for each distance", "Use rest periods to recover fully", "Maintain form even on longer intervals"],
                    reps: "1 mile, 2x half mile, 2x quarter mile, 1x half mile",
                    category: .movement,
                    intensity: .high,
                    equipment: [.cones],
                    tags: ["solo-friendly", "minimal-equipment", "endurance", "conditioning"],
                    purpose: "Build aerobic capacity and pacing discipline through structured track intervals.",
                    setup: "Standard track or measured loop. Stopwatch required.",
                    space: .large,
                    instructions: [
                        "Warm up with 5-10 minutes of easy jogging and dynamic stretches.",
                        "Run 4 laps (1 mile) at target pace. Rest 3 minutes.",
                        "Run 2 laps (half mile) at target pace. Rest 90 seconds.",
                        "Run 2 laps (half mile) at target pace. Rest 90 seconds.",
                        "Run 1 lap (quarter mile) at target pace. Rest 90 seconds.",
                        "Run 1 lap (quarter mile). Rest 90 seconds. Run 2 laps (half mile) to finish."
                    ],
                    commonMistakes: ["Starting the mile too fast", "Not timing rest periods accurately", "Slowing too much on later intervals"]
                ),
                Drill(
                    name: "Track Workout B — Descending Intervals",
                    description: "Descending distance track workout: 4 laps (1 mile), 3 laps (3/4 mile), 2 laps (half mile), 2 laps (half mile), 1 lap (quarter mile), 1 lap (quarter mile). Each interval faster than the last.",
                    duration: "30 min",
                    difficulty: .advanced,
                    targetSkill: "Movement",
                    coachingCues: ["Get faster as distances get shorter", "Pace the longer intervals—save energy for the short ones", "Precise rest between intervals"],
                    reps: "1 mile, 3/4 mile, 2x half mile, 2x quarter mile",
                    category: .movement,
                    intensity: .high,
                    equipment: [.cones],
                    tags: ["solo-friendly", "minimal-equipment", "endurance", "conditioning"],
                    purpose: "Develop the ability to increase speed as fatigue builds—simulating late-match intensity.",
                    setup: "Standard track or measured loop. Stopwatch required.",
                    space: .large,
                    instructions: [
                        "Warm up with 5-10 minutes of easy jogging.",
                        "Run 4 laps (1 mile) at a strong pace. Rest 2 minutes.",
                        "Run 3 laps (3/4 mile) faster. Rest 90 seconds.",
                        "Run 2 laps (half mile) faster. Rest 90 seconds.",
                        "Run 2 laps (half mile) at same pace. Rest 90 seconds.",
                        "Run 1 lap (quarter mile) fast. Rest 90 seconds. Run 1 lap all-out to finish."
                    ],
                    commonMistakes: ["Going too hard on the mile and having nothing left", "Not progressively increasing speed", "Skipping rest periods"]
                ),
                Drill(
                    name: "Pyramid Track Workout",
                    description: "A pyramid interval session: 1 lap, 2 laps, 3 laps, 4 laps, then back down 3, 2, 1 laps. Build up distance then taper back down with increasing speed on the descent.",
                    duration: "35 min",
                    difficulty: .advanced,
                    targetSkill: "Movement",
                    coachingCues: ["Pace yourself on the way up the pyramid", "Push harder on the way back down", "Rest between each interval"],
                    reps: "1-2-3-4-3-2-1 laps",
                    category: .movement,
                    intensity: .high,
                    equipment: [.cones],
                    tags: ["solo-friendly", "minimal-equipment", "endurance", "conditioning"],
                    purpose: "Build comprehensive running fitness through ascending and descending interval distances.",
                    setup: "Standard track or measured loop. Stopwatch required.",
                    space: .large,
                    instructions: [
                        "Warm up with 5-10 minutes of easy jogging and dynamic stretches.",
                        "Run 1 lap (quarter mile). Rest 30 seconds.",
                        "Run 2 laps (half mile). Rest 70 seconds.",
                        "Run 3 laps (3/4 mile). Rest 90 seconds.",
                        "Run 4 laps (1 mile). Rest 2 minutes.",
                        "Descend: 3 laps (rest 90 sec), 2 laps (rest 70 sec), 1 lap all-out to finish."
                    ],
                    commonMistakes: ["Burning out on the ascent and having nothing for the descent", "Not timing rest periods", "Running the descent slower than the ascent"]
                ),
                Drill(
                    name: "Water Workout Conditioning",
                    description: "Perform the equivalent of your land conditioning workout in waist-deep water, adding 25% more volume. The water provides natural resistance while reducing impact on joints.",
                    duration: "25 min",
                    difficulty: diff,
                    targetSkill: "Movement",
                    coachingCues: ["Maintain ground contact in waist-deep water", "Push through the water resistance on every stride", "Increase volume by 25% compared to your land workout"],
                    reps: "Land workout equivalent + 25% volume",
                    category: .movement,
                    intensity: .moderate,
                    equipment: [.none],
                    tags: ["solo-friendly", "conditioning", "recovery", "low-impact"],
                    purpose: "Build conditioning while reducing joint impact. Ideal for recovery days or injury prevention.",
                    setup: "Pool or body of water with waist-deep access.",
                    space: .medium,
                    instructions: [
                        "Enter waist-deep water and warm up with easy water jogging for 3 minutes.",
                        "Perform your standard conditioning intervals in the water.",
                        "Add 25% more reps than your land equivalent.",
                        "Keep some work in waist-deep water to maintain ground feel.",
                        "Focus on driving knees high against water resistance.",
                        "Cool down with easy water walking for 3 minutes."
                    ],
                    commonMistakes: ["Going to deep water where you lose ground contact", "Not increasing volume—water makes it easier, so add 25%", "Neglecting arm drive in the water"]
                ),
                Drill(
                    name: "Stationary Bike Conditioning",
                    description: "Bike equivalent of your land conditioning workout with one-third more volume. For example, instead of 10x30-second sprints, ride hard for 30 seconds then pedal easy for 30 seconds, 15 repetitions.",
                    duration: "25 min",
                    difficulty: diff,
                    targetSkill: "Movement",
                    coachingCues: ["Match the intensity of your land workout on the bike", "Add one-third more time to compensate for lower impact", "Maintain high cadence during hard efforts"],
                    reps: "Land workout equivalent + 33% volume",
                    category: .movement,
                    intensity: .moderate,
                    equipment: [.none],
                    tags: ["solo-friendly", "conditioning", "recovery", "low-impact"],
                    purpose: "Maintain conditioning on a bike when field training is not possible or for active recovery.",
                    setup: "Stationary bike.",
                    space: .minimal,
                    instructions: [
                        "Warm up with 3 minutes of easy pedaling.",
                        "Ride hard at high resistance for 30 seconds.",
                        "Pedal easy at low resistance for 30 seconds.",
                        "Repeat for 15 total hard efforts.",
                        "Cool down with 3 minutes of easy pedaling.",
                        "Increase resistance or reps as fitness improves."
                    ],
                    commonMistakes: ["Resistance too low during hard efforts", "Not adding the extra volume—bikes are lower impact so you need more", "Stopping pedaling during rest instead of easy spinning"]
                ),
                Drill(
                    name: "Stairmaster Conditioning",
                    description: "Use a stair climber at level 8 or above for 30-45 minutes without holding the hand rails. Builds leg endurance, balance, and cardiovascular fitness.",
                    duration: "35 min",
                    difficulty: .intermediate,
                    targetSkill: "Movement",
                    coachingCues: ["Stay at level 8 or above the entire session", "Do not hold the hand rails—this builds balance", "Maintain upright posture throughout"],
                    reps: "30-45 min continuous",
                    category: .movement,
                    intensity: .moderate,
                    equipment: [.none],
                    tags: ["solo-friendly", "conditioning", "balance", "endurance"],
                    purpose: "Build sustained leg endurance and balance while training cardiovascular fitness.",
                    setup: "Stair climber machine.",
                    space: .minimal,
                    instructions: [
                        "Set the stair climber to level 8 or higher.",
                        "Begin stepping without holding the hand rails.",
                        "Maintain an upright posture—don't lean on the machine.",
                        "Continue for 30-45 minutes at a steady pace.",
                        "If you need a break, reduce the level briefly then return to 8+.",
                        "Cool down with 3 minutes at a lower level."
                    ],
                    commonMistakes: ["Holding the rails—this defeats the balance benefit", "Setting the level too low", "Leaning forward on the machine instead of standing upright"]
                )
            ]
        }
    }

    private func difficultyFor(_ level: SkillLevel) -> DrillDifficulty {
        switch level {
        case .beginner: .beginner
        case .intermediate: .intermediate
        case .competitive, .semiPro: .advanced
        }
    }
}
