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
            ),
            CoachSession(
                title: "Build Up Play",
                gameMoment: .buildUpPlay,
                objective: "Support Movement",
                duration: 75,
                intensity: 6,
                ageGroup: "U15-U19",
                playerCount: 16,
                activities: [
                    SessionActivity(order: 1, title: "Passing and Movement Pattern", duration: 15, fieldSize: "25x15", playerNumbers: "Groups of 6-8", setupDescription: "Diamond shape with overlapping runners. Pass sequences with movement.", instructions: "Pass and move. Support ahead and behind the ball.", phases: ["Phase 1: Pass move support", "Phase 2: Add overlap and receive", "Phase 3: Add switch and combine"], coachingPoints: ["Foot placement on receive", "Weight of pass to match the run", "Move off ball immediately after passing"]),
                    SessionActivity(order: 2, title: "Build Out of Back", duration: 20, fieldSize: "30x25", playerNumbers: "4v4 + 2 GK", setupDescription: "Team builds from GK through defenders into midfield. Pressing team applies soft pressure.", instructions: "Build from back. GK is a player. Score by reaching far endline.", phases: ["Phase 1: Free build", "Phase 2: 3-touch max for defenders", "Phase 3: GK must play to feet — no long balls"], coachingPoints: ["Create passing angles", "Support ahead and behind the ball", "GK as a player not a spectator"]),
                    SessionActivity(order: 3, title: "Line Breaking Passing Game", duration: 20, fieldSize: "35x25", playerNumbers: "5v5 + 5 neutral midfielders", setupDescription: "Two teams with neutral players in central zone. Score by playing through central zone.", instructions: "Find and play through the neutrals in middle zone to score.", phases: ["Phase 1: Neutrals are 1 touch", "Phase 2: Neutrals restricted to zone"], coachingPoints: ["Identify when to play through the lines", "Weight and timing of pass into neutrals", "Movement ahead of the ball"]),
                    SessionActivity(order: 4, title: "Scrimmage With Build Up Rules", duration: 25, fieldSize: "Full field", playerNumbers: "Equal numbers + 2 GK", setupDescription: "Full scrimmage. Must build from back — no long balls.", instructions: "No long balls from GK or defenders. Build through the thirds.", phases: ["Phase 1: Goal after 8 or more passes = 2pts", "Phase 2: Normal goal = 1pt"], coachingPoints: ["Patience in build up", "Recognize when to go forward vs recycle", "Width and depth in every moment"])
                ],
                notes: "Technical and positional session. Low intensity but high concentration required."
            ),
            CoachSession(
                title: "Combination Play",
                gameMoment: .combinationPlay,
                objective: "Wall Pass",
                duration: 75,
                intensity: 7,
                ageGroup: "U15-U19",
                playerCount: 16,
                activities: [
                    SessionActivity(order: 1, title: "Combination Pattern Warm-Up", duration: 15, fieldSize: "20x15", playerNumbers: "Groups of 6", setupDescription: "Pairs and triangles. Wall pass third man run and overlap sequences.", instructions: "Walk through each combination then add pace. Finish each with a shot.", phases: ["Phase 1: Walk through each combination", "Phase 2: Add movement and pace", "Phase 3: Finish each with a shot"], coachingPoints: ["Timing of the run", "Weight of pass", "Communication before the combination"]),
                    SessionActivity(order: 2, title: "Combination in Tight Space", duration: 20, fieldSize: "15x15", playerNumbers: "4v4", setupDescription: "Small sided game with combination scoring rules.", instructions: "Score by combining. Bonus points for specific combinations.", phases: ["Phase 1: Any goal = 1pt", "Phase 2: Goal after wall pass = 2pts", "Phase 3: Goal after third man run = 3pts"], coachingPoints: ["Create combinations under pressure", "Quick decision making", "Body shape on receive"]),
                    SessionActivity(order: 3, title: "Final Third Combination", duration: 20, fieldSize: "30x25 attacking third", playerNumbers: "6v4 + GK", setupDescription: "Attackers combine to create and finish chances. Defenders reset after each attempt.", instructions: "Build combination from top of zone and finish.", phases: ["Phase 1: Build combination from top of zone", "Phase 2: Add wide players for crossing opportunities"], coachingPoints: ["Quick combinations in tight spaces", "Shoot early when chance appears", "Movement into box before the shot"]),
                    SessionActivity(order: 4, title: "Scrimmage With Combination Rules", duration: 25, fieldSize: "Full field", playerNumbers: "Equal numbers + 2 GK", setupDescription: "Full game. Goals from combinations worth double.", instructions: "Play normal game. Combination goals worth double points.", phases: ["Phase 1: Combination goal = 2pts", "Phase 2: Standard goal = 1pt"], coachingPoints: ["Be brave in tight spaces", "Play simple then combine", "Third man runs unlock every combination"])
                ],
                notes: "Timing and communication are the keys. Slow the warm-up down to get the timing right."
            ),
            CoachSession(
                title: "Counter Attack",
                gameMoment: .counterAttack,
                objective: "Quick Transition",
                duration: 75,
                intensity: 8,
                ageGroup: "U15-U19",
                playerCount: 16,
                activities: [
                    SessionActivity(order: 1, title: "Transition Finishing Warm-Up", duration: 15, fieldSize: "Half field", playerNumbers: "Groups of 4", setupDescription: "Players start in defensive position. On signal they receive a pass and attack goal.", instructions: "React to signal receive and attack goal within 4 seconds.", phases: ["Phase 1: 1v0 technique and composure", "Phase 2: 2v1 decision making", "Phase 3: 3v2 read the defender"], coachingPoints: ["First touch forward", "Decision speed", "Pick shot or pass early"]),
                    SessionActivity(order: 2, title: "Win and Counter Game", duration: 20, fieldSize: "35x25", playerNumbers: "6v6", setupDescription: "Team that wins ball must get a shot off within 6 seconds.", instructions: "Score normally. Bonus for quick shot after winning.", phases: ["Phase 1: Shot within 6 seconds of winning = 2pts", "Phase 2: Reduce to 4 seconds"], coachingPoints: ["Immediate forward pass on win", "Runners go before ball is won", "Keep numbers forward"]),
                    SessionActivity(order: 3, title: "Counter Against Recovering Defenders", duration: 20, fieldSize: "Full field", playerNumbers: "4v4 + midfielders", setupDescription: "Midfielders play possession. When ball is won they launch a 4v4 counter against recovering defense.", instructions: "Counter quickly. Defenders start from goal and sprint to recover.", phases: ["Phase 1: Defenders start from goal and sprint to recover", "Phase 2: Defenders get 3-second head start"], coachingPoints: ["Exploit space before defenders recover", "Decision to run or pass — make it early", "Finish first time when possible"]),
                    SessionActivity(order: 4, title: "Scrimmage With Counter Rules", duration: 25, fieldSize: "Full field", playerNumbers: "Equal numbers + 2 GK", setupDescription: "Full game with counter scoring bonus.", instructions: "Play normal game. Fast counter goals worth more.", phases: ["Phase 1: Goal within 5 seconds of winning = 3pts", "Phase 2: Normal goal = 1pt"], coachingPoints: ["Transition mentality at all times", "Protect the ball then strike fast", "Numbers forward — do not let attack become isolated"])
                ],
                notes: "High intensity. Demand urgency on every transition. Rest periods between activities."
            ),
            CoachSession(
                title: "Overload Play",
                gameMoment: .overloadPlay,
                objective: "Exploit Overload",
                duration: 75,
                intensity: 7,
                ageGroup: "U15-U19",
                playerCount: 16,
                activities: [
                    SessionActivity(order: 1, title: "Rondo Overload Progression", duration: 15, fieldSize: "10x10 to 20x20", playerNumbers: "4v1 then 5v2 then 6v2", setupDescription: "Progress through overload rondos. Each stage adds one defender.", instructions: "Maintain possession and exploit the numerical advantage.", phases: ["Phase 1: 4v1 maintain possession", "Phase 2: 5v2 exploit the numbers", "Phase 3: 6v2 combine and switch"], coachingPoints: ["Find and play to the free player immediately", "Move the ball quickly", "Make the defenders chase"]),
                    SessionActivity(order: 2, title: "Overload to Finish", duration: 20, fieldSize: "30x25", playerNumbers: "6v4 attackers + GK", setupDescription: "Attacking team has numerical advantage and must create and finish chances.", instructions: "Find the overload and exploit it to score.", phases: ["Phase 1: Find the overload and attack", "Phase 2: Must play through wide channel before shooting"], coachingPoints: ["Identify the overload immediately", "Use width to stretch defenders", "Finish early before defenders recover"]),
                    SessionActivity(order: 3, title: "Switch to Find Overload", duration: 20, fieldSize: "40x30", playerNumbers: "7v6", setupDescription: "Attacking team must switch ball to create overload on weak side.", instructions: "Patient build then explosive switch to create and exploit.", phases: ["Phase 1: Switch pass creates overload — attack it", "Phase 2: Must switch before entering final third"], coachingPoints: ["Patient build to create the switch", "Explosive movement after the switch", "Exploit before defenders recover"]),
                    SessionActivity(order: 4, title: "Scrimmage With Width Rules", duration: 25, fieldSize: "Full field", playerNumbers: "Equal numbers + 2 GK", setupDescription: "Full game. Goal from wide overload worth double.", instructions: "Play normal game. Create and exploit wide overloads.", phases: ["Phase 1: Goal from wide overload = 2pts", "Phase 2: Standard goal = 1pt"], coachingPoints: ["Use the full width of the field", "Recognize and attack overloads", "Switch quickly when overload appears"])
                ],
                notes: "Teach players to recognize numerical advantages and exploit them immediately."
            ),
            CoachSession(
                title: "Defend the Box",
                gameMoment: .defendTheBox,
                objective: "Win Aerial Duels",
                duration: 75,
                intensity: 7,
                ageGroup: "U15-U19",
                playerCount: 16,
                activities: [
                    SessionActivity(order: 1, title: "Crossing and Defending Warm-Up", duration: 15, fieldSize: "Wide channel and box", playerNumbers: "3 attackers vs 2 defenders", setupDescription: "Ball delivered from wide positions. Defenders organize to defend the cross.", instructions: "Defenders organize shape to deal with every cross type.", phases: ["Phase 1: Zonal defending — cover zones", "Phase 2: Man marking — track runners"], coachingPoints: ["GK communication leads the defense", "Defenders step to meet the ball", "Clearance quality — distance and direction"]),
                    SessionActivity(order: 2, title: "Box Defense Game", duration: 20, fieldSize: "Penalty area", playerNumbers: "5 defenders vs 6 attackers + GK", setupDescription: "Attackers cross and combine around box. Defenders clear and organize.", instructions: "Defend every ball into the box. Clear and counter.", phases: ["Phase 1: Attackers score from crosses only", "Phase 2: Attackers can also shoot from outside"], coachingPoints: ["Compact box", "Win first ball and clear second ball", "GK command is non-negotiable"]),
                    SessionActivity(order: 3, title: "Defend the Box Live", duration: 20, fieldSize: "Full width final third", playerNumbers: "8v8 + GK", setupDescription: "Full width attacking play. Defending team organizes to deny goal.", instructions: "Defend crosses combinations and shots from all positions.", phases: ["Phase 1: Standard defending", "Phase 2: Add set piece — corner and wide free kick"], coachingPoints: ["Organize quickly on every delivery", "Communication between GK and defenders", "Win every aerial duel"]),
                    SessionActivity(order: 4, title: "Scrimmage With Box Defending Rules", duration: 25, fieldSize: "Full field", playerNumbers: "Equal numbers + 2 GK", setupDescription: "Full game. Defending team scores for winning clearances from inside box.", instructions: "Play normal game. Reward defending team for winning box duels.", phases: ["Phase 1: Clearance from inside box = 1pt", "Phase 2: Goal = 3pts"], coachingPoints: ["Defend box as a unit", "GK leads the organization", "Win first ball — hunt second ball"])
                ],
                notes: "Aerial duels and communication are the focus. GK must be vocal throughout."
            ),
            CoachSession(
                title: "High Percentage Finishing",
                gameMoment: .highPercentageFinishing,
                objective: "First Time Finish",
                duration: 75,
                intensity: 7,
                ageGroup: "U15-U19",
                playerCount: 16,
                activities: [
                    SessionActivity(order: 1, title: "Finishing Technique Warm-Up", duration: 15, fieldSize: "Penalty area", playerNumbers: "Groups of 4 + GK", setupDescription: "Players shoot from 6 12 and 18 yards from various angles.", instructions: "Focus on technique. Pick your spot before the ball arrives.", phases: ["Phase 1: Placement shots — accuracy", "Phase 2: Power shots — driven low", "Phase 3: First time finish — feed and finish"], coachingPoints: ["Pick your spot before ball arrives", "Strike clean through center of ball", "Follow up every shot for rebounds"]),
                    SessionActivity(order: 2, title: "Combination to Finish", duration: 20, fieldSize: "Attacking third", playerNumbers: "5v3 + GK", setupDescription: "Attacking team combines to create and finish in high percentage zones.", instructions: "Combine and finish in the box.", phases: ["Phase 1: Must touch ball into box before shooting", "Phase 2: One touch finish only"], coachingPoints: ["Arrive into box at pace", "Attack the ball — do not wait for it", "Composure on the shot"]),
                    SessionActivity(order: 3, title: "Crossing and Finishing", duration: 20, fieldSize: "Full width attacking half", playerNumbers: "6v5 + GK", setupDescription: "Wide players deliver crosses. Strikers and midfielders attack the box.", instructions: "Create and attack crossing situations. Score from deliveries.", phases: ["Phase 1: Driven low cross only", "Phase 2: Mixed low and high delivery", "Phase 3: Add pressing defender chasing the striker"], coachingPoints: ["Movement before the cross — create separation", "Meet ball at pace", "Attack near post first"]),
                    SessionActivity(order: 4, title: "Scrimmage With Finishing Rules", duration: 25, fieldSize: "Full field", playerNumbers: "Equal numbers + 2 GK", setupDescription: "Full game with finishing bonus scoring.", instructions: "Play normal game. Bonus for box finishes.", phases: ["Phase 1: Shot inside penalty area = 2pts", "Phase 2: Goal = 3pts"], coachingPoints: ["Get in the box", "Shoot early when chance appears", "Rebound mentality — follow every shot"])
                ],
                notes: "Finishing sessions require high repetition. Keep rest periods short to build composure under fatigue."
            )
        ]
    }
}
