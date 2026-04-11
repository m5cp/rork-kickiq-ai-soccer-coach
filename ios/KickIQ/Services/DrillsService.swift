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
                Drill(name: "Close Control Box", description: "Dribble inside a 5x5 yard box for 60 seconds without leaving. Use all surfaces of both feet.", duration: "8 min", difficulty: .beginner, targetSkill: skill.rawValue, coachingCues: ["Keep ball within 1 foot", "Use sole rolls and drags", "Change direction constantly"], reps: "4 rounds of 60 sec", equipment: [.ball, .cones], tags: ["solo-friendly", "minimal-equipment"])
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
                Drill(name: "Receive & Turn Under Pressure", description: "A partner passes to you with a passive defender behind. Use different turns (inside hook, outside hook, drag back) to escape pressure.", duration: "12 min", difficulty: .advanced, targetSkill: skill.rawValue, coachingCues: ["Check shoulder before the ball arrives", "First touch sets up the turn", "Vary the turn type to stay unpredictable"], reps: "4 sets of 6", category: .turning, trainingMode: .partner, equipment: [.ball, .cones], tags: ["minimal-equipment"])
            ]
        case .striking:
            return [
                Drill(name: "Laces Drive Technique", description: "Place the ball on the ground. Strike through the center with your laces, focusing on locked ankle and follow-through. Aim at a wall target.", duration: "12 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Toe pointed down, ankle locked", "Plant foot beside the ball", "Strike through the center"], reps: "4 sets of 10", category: .striking, equipment: [.ball, .wall], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(name: "Inside Foot Pass Striking", description: "Focus on clean inside-foot contact for short and medium range passes against a wall. Alternate feet.", duration: "10 min", difficulty: .beginner, targetSkill: skill.rawValue, coachingCues: ["Open hip to the target", "Firm ankle on contact", "Follow through toward the target"], reps: "3 sets of 20 per foot", category: .striking, equipment: [.ball, .wall], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(name: "Volleys from Self-Toss", description: "Toss the ball to yourself at different heights and strike cleanly on the volley. Focus on timing and clean contact.", duration: "10 min", difficulty: .intermediate, targetSkill: skill.rawValue, coachingCues: ["Watch the ball onto your foot", "Lock the ankle", "Lean slightly over the ball for control"], reps: "3 sets of 10 per foot", category: .striking, equipment: [.ball], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(name: "Chip & Loft Technique", description: "Practice chipping over a cone from 10-15 yards. Get underneath the ball with a scooping motion.", duration: "12 min", difficulty: .advanced, targetSkill: skill.rawValue, coachingCues: ["Lean back slightly", "Stab under the ball", "Minimal follow-through for backspin"], reps: "4 sets of 8", category: .striking, equipment: [.ball, .cones], tags: ["solo-friendly", "minimal-equipment"])
            ]
        case .receiving:
            return [
                Drill(name: "Wall Return & Cushion", description: "Pass firmly against a wall and cushion the return with different foot surfaces (inside, outside, sole). Kill the ball dead.", duration: "10 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Withdraw foot on contact to absorb", "Get body behind the ball", "Alternate surfaces each rep"], reps: "3 sets of 20", category: .receiving, equipment: [.ball, .wall], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(name: "Thigh & Chest Receive", description: "Toss the ball in the air and bring it down using your thigh, then your chest, then settle with your foot. Progress to one continuous sequence.", duration: "10 min", difficulty: diff, targetSkill: skill.rawValue, coachingCues: ["Cushion on contact", "Get body shape right before the ball arrives", "Settle to the ground quickly"], reps: "4 sets of 10", category: .receiving, equipment: [.ball], tags: ["solo-friendly", "minimal-equipment"]),
                Drill(name: "Receive & Play Forward", description: "A partner passes to you. Receive, take a directional touch, and play forward to a target cone in one motion.", duration: "12 min", difficulty: .intermediate, targetSkill: skill.rawValue, coachingCues: ["Open body to the direction of play", "First touch moves the ball forward", "Scan before the ball arrives"], reps: "3 sets of 10", category: .receiving, trainingMode: .partner, equipment: [.ball, .cones], tags: ["minimal-equipment"]),
                Drill(name: "Driven Ball Reception", description: "A partner hits hard, driven passes. Receive and redirect cleanly under tempo. Progress to receiving with a defender behind.", duration: "12 min", difficulty: .advanced, targetSkill: skill.rawValue, coachingCues: ["Soft ankle to absorb pace", "Take touch away from pressure", "Body shape open"], reps: "3 sets of 10", category: .receiving, trainingMode: .partner, equipment: [.ball], tags: ["minimal-equipment"])
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
