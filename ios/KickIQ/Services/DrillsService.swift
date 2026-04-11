import Foundation

@Observable
@MainActor
class DrillsService {
    var allDrills: [Drill] = []
    var activeFilter: DrillFilter = .default

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
                Drill(name: "Blindside Run Timing", description: "Start behind a cone as if behind a defender. On a visual cue, make a curved run into the box to meet a through ball.", duration: "12 min", difficulty: .advanced, targetSkill: skill.rawValue, coachingCues: ["Time the run—don't go too early", "Curve the run to stay onside", "Accelerate into the pass"], reps: "4 sets of 5 runs", trainingMode: .partner, equipment: [.ball, .cones], tags: ["minimal-equipment"])
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
                Drill(name: "Sprint-Brake-Sprint", description: "Sprint 10 yards, decelerate sharply, pause 1 second, then re-accelerate for another 10 yards.", duration: "10 min", difficulty: .advanced, targetSkill: skill.rawValue, coachingCues: ["Max effort on both sprints", "Control the deceleration", "Explosive re-start"], reps: "5 sets", equipment: [.cones], tags: ["solo-friendly", "minimal-equipment"])
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
                )
            ]
        case .juggling:
            return [
                Drill(name: "Foot Juggling Basics", description: "Juggle using only your feet. Start with one touch and catch, then build to continuous juggling. Count consecutive touches.", duration: "8 min", difficulty: .beginner, targetSkill: skill.rawValue, coachingCues: ["Lock ankle, toe slightly up", "Small controlled touches", "Keep the ball below head height"], reps: "5 attempts, beat your record", category: .juggling, equipment: [.ball], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(name: "Alternating Foot Juggling", description: "Juggle using alternating feet every touch. Forces balance and coordination on both sides.", duration: "8 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Left-right-left-right rhythm", "Stay light on your standing foot", "Consistent height on each touch"], reps: "4 sets, 30-touch target", category: .juggling, equipment: [.ball], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(name: "Full Body Juggling", description: "Juggle using feet, thighs, chest, and head in a continuous sequence. Each set must include all four surfaces.", duration: "10 min", difficulty: .intermediate, targetSkill: skill.rawValue, coachingCues: ["Smooth transitions between surfaces", "Keep the ball close", "Use spin to redirect"], reps: "3 sets of 20+ touches", category: .juggling, equipment: [.ball], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(name: "Around the World Juggling", description: "Juggle in a pattern: right foot, right thigh, head, left thigh, left foot, repeat. Builds full-body coordination.", duration: "10 min", difficulty: .advanced, targetSkill: skill.rawValue, coachingCues: ["Consistent touch height", "Control the spin", "Stay balanced throughout"], reps: "Best of 5 full cycles", category: .juggling, equipment: [.ball], tags: ["solo-friendly", "minimal-equipment"])
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
                Drill(name: "Ball-at-Feet Endurance", description: "Dribble continuously around a large area for timed intervals. Keep the ball close even when tired.", duration: "15 min", difficulty: diff, targetSkill: "Movement", coachingCues: ["Maintain ball contact even when tired", "Change pace and direction", "Simulate match fatigue"], reps: "3 sets of 4 min", equipment: [.ball], tags: ["solo-friendly", "minimal-equipment"])
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
