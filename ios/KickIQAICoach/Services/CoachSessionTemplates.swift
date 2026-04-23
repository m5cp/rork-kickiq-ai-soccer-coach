import Foundation

enum CoachSessionTemplates {
    static var defaultSessions: [CoachSession] {
        return [
            CoachSession(
                title: "High Press",
                gameMoment: .highPress,
                objective: "Delay and Force",
                duration: 75,
                intensity: 7,
                ageGroup: "U15-U19",
                playerCount: 16,
                activities: [
                    SessionActivity(order: 1, title: "Pressing Pattern Warm-Up", duration: 15, fieldSize: "Hexagon 12 yards apart", playerNumbers: "Groups of 6", setupDescription: "Six cones in a hexagon 12 yards apart. Players at each cone.", instructions: "Press on the pass cue. First player presses the ball carrier.", phases: ["Phase 1: Press on pass in red pattern", "Phase 2: Press and recover in white pattern"], coachingPoints: ["Identify the cue to press early", "Recover shape between press attempts", "Use the cone as a positional guide"]),
                    SessionActivity(order: 2, title: "Possession With Pressing Trigger", duration: 20, fieldSize: "24x24 with 8x8 inner grid", playerNumbers: "3 teams of 4", setupDescription: "Attacking team combines in outer grid. After 3 passes they may switch to far team. Pressing team works in middle zone only.", instructions: "Attacking team combines and switches. Pressing team tries to win in middle zone.", phases: ["Phase 1: Wide switch = 1pt. Middle switch = 3pts", "Phase 2: Winning ball changes pressing team", "Phase 3: One pressing player allowed into wide channel"], coachingPoints: ["Communication drives the press", "Press the ball-side player", "Middle zone player acts as the trigger"]),
                    SessionActivity(order: 3, title: "Press to Win and Score", duration: 15, fieldSize: "24x24", playerNumbers: "10v5 + 2 GK", setupDescription: "Defending team presses to win and score. Attacking team scores with 8 combined passes.", instructions: "Press team wins ball and finishes. Attacking team keeps possession.", phases: ["Phase 1: Press to win and finish in big goal", "Phase 2: Win and score for 2pts or force 10 passes for 1pt"], coachingPoints: ["Organization first", "Make play predictable for the next line", "Score quickly in transition"]),
                    SessionActivity(order: 4, title: "Scrimmage With Press Conditions", duration: 25, fieldSize: "Half field", playerNumbers: "Equal numbers + 2 GK", setupDescription: "Full scrimmage with pressing rules. All restarts are goal kicks.", instructions: "Play normal game with pressing scoring bonus.", phases: ["Phase 1: Shot within 4 seconds of winning = 1pt", "Phase 2: Goal = 3pts"], coachingPoints: ["Press as a unit not as individuals", "Maintain shape when not pressing", "First presser forces — second wins"])
                ],
                notes: "Focus on the trigger for the press. Players must recognize the cue before pressing."
            ),
            CoachSession(
                title: "Low Block",
                gameMoment: .lowBlock,
                objective: "Compact and Cover",
                duration: 75,
                intensity: 6,
                ageGroup: "U15-U19",
                playerCount: 16,
                activities: [
                    SessionActivity(order: 1, title: "Defensive Shape Warm-Up", duration: 15, fieldSize: "30x20", playerNumbers: "8 defenders vs 6 attackers", setupDescription: "Defenders in two compact lines of 4. Attackers pass around outside and look to penetrate.", instructions: "Defenders hold shape and do not press. Stay compact.", phases: ["Phase 1: Defenders hold block — no pressure on ball", "Phase 2: One player presses when ball enters final third"], coachingPoints: ["Hold the block", "Do not get pulled out of shape", "Communication between lines"]),
                    SessionActivity(order: 2, title: "Low Block Possession Game", duration: 20, fieldSize: "30x25", playerNumbers: "6v6 + 2 neutral wide players", setupDescription: "Defending team holds compact low block. Attacking team uses wide neutrals.", instructions: "Attacking team scores by playing through block to target. Defending team counters on win.", phases: ["Phase 1: Score through the block to target = 1pt", "Phase 2: Counter goal in small goals on win = 1pt"], coachingPoints: ["Block must stay connected", "Deny central entry", "Force play wide then close"]),
                    SessionActivity(order: 3, title: "Defend the Final Third", duration: 15, fieldSize: "Penalty area to 30 yards out", playerNumbers: "5 defenders vs 7 attackers", setupDescription: "Attackers combine outside box and look to enter. Defenders deny entry.", instructions: "Attackers score by getting shot off. Defenders score by winning and playing to target.", phases: ["Phase 1: Standard defending", "Phase 2: Add crossing channel"], coachingPoints: ["Compact", "No gaps between defenders", "Win every first and second ball"]),
                    SessionActivity(order: 4, title: "Scrimmage With Block Rules", duration: 25, fieldSize: "Full field", playerNumbers: "Equal numbers + 2 GK", setupDescription: "Full scrimmage. Defending team must establish block before pressing.", instructions: "Play normal game with block scoring bonus.", phases: ["Phase 1: Goal = 3pts", "Phase 2: Ball recovery from compact block = 1pt"], coachingPoints: ["Patience in the block", "Do not press high until the trigger", "Stay connected as a unit"])
                ],
                notes: "Emphasis on shape and compactness. Do not let individuals pull out of position."
            ),
            CoachSession(
                title: "Defensive Transition",
                gameMoment: .immediatePress,
                objective: "Counter-Press",
                duration: 75,
                intensity: 8,
                ageGroup: "U15-U19",
                playerCount: 16,
                activities: [
                    SessionActivity(order: 1, title: "Counter-Press Warm-Up", duration: 10, fieldSize: "20x20", playerNumbers: "4v4", setupDescription: "One team keeps possession. On losing the ball they immediately press to win it back.", instructions: "Win the ball back within 5 seconds of losing it.", phases: ["Phase 1: 5-second counter-press rule", "Phase 2: 3-second counter-press rule"], coachingPoints: ["Immediate reaction on loss", "Nearest player presses", "Others cut passing lanes"]),
                    SessionActivity(order: 2, title: "Transition Rondo", duration: 20, fieldSize: "15x15", playerNumbers: "6v2", setupDescription: "Six players keep ball from two defenders. When defenders win the ball the six immediately become defenders.", instructions: "Win and immediately counter-press. Hunt in pairs.", phases: ["Phase 1: Free play", "Phase 2: Touch restriction on transition"], coachingPoints: ["First reaction on loss", "Hunt the ball in pairs", "Recover positions quickly"]),
                    SessionActivity(order: 3, title: "Win and Score Transition Game", duration: 20, fieldSize: "Half field", playerNumbers: "7v7 + GK", setupDescription: "Team that loses ball must press within 5 yards of where ball was lost.", instructions: "Score normally. Bonus for winning ball and scoring quickly.", phases: ["Phase 1: Goal after winning ball in 6 seconds = 2pts", "Phase 2: Normal goal = 1pt"], coachingPoints: ["Aggression on transition", "Exploit the chaos of the turnover", "Work as a unit"]),
                    SessionActivity(order: 4, title: "Full Game With Transition Focus", duration: 25, fieldSize: "Full field", playerNumbers: "Equal numbers + 2 GK", setupDescription: "Full scrimmage with immediate press rules.", instructions: "Play normal game. Emphasis on immediate press after every loss.", phases: ["Phase 1: Standard game", "Phase 2: Losing team must press within 3 seconds"], coachingPoints: ["Talk before during and after loss", "Drive intensity in first 3 seconds", "First presser forces — second wins"])
                ],
                notes: "Intensity session. Demand maximum effort on every transition moment."
            )
        ]
    }
}
