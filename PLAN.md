# KickIQ: AI Soccer Coach — Premium Dark Training App

## Features

- **Onboarding flow** — Enter your name, select your position (Goalkeeper, Defender, Midfielder, Forward), choose skill level (Beginner, Intermediate, Advanced), and set a training goal
- **AI video analysis** — Pick a training video from your photo library, the app extracts key frames and sends them to AI for real coaching feedback with per-skill scoring (e.g. Ball Control 7/10, Positioning 8/10)
- **Position-specific feedback** — AI tailors its analysis and drill recommendations based on your selected position
- **Skill score tracking** — Every analysis session saves scores, viewable over time as progress charts
- **Daily training streak** — Tracks consecutive days you've analyzed a session, with a flame icon and streak counter on the home dashboard
- **Shareable progress cards** — Generate a bold, branded image card showing your latest scores to share with friends or coaches
- **Drill recommendations** — After each analysis, receive 3–5 position-specific drills to improve weak areas
- **Home dashboard** — See your streak, latest session scores, overall skill rating, and quick-start button to analyze a new video

## Design

- **Dark theme throughout** — Deep black/charcoal backgrounds inspired by Whoop and Nike Training Club
- **Bold orange accent color** — Used for primary buttons, progress indicators, highlights, and the streak flame
- **Typography** — SF Pro with heavy/bold weights for headings, creating an athletic, premium feel. Compressed width for large titles
- **Cards** — Dark charcoal cards (`Color(white: 0.12)`) with subtle rounded corners and orange accent borders or highlights
- **Progress charts** — Custom-drawn skill radar/bar charts in orange gradients against dark backgrounds
- **Animations** — Spring animations on score reveals, bounce effects on streak milestones, symbol effects on navigation icons
- **Haptics** — Impact feedback on video upload, success feedback on analysis complete, selection feedback on position picker

## Screens

1. **Onboarding (3 steps)** — Welcome screen with app name and tagline → Position & skill level picker → Name and training goal input. Bold orange accents on dark background, large athletic typography
2. **Home (Dashboard)** — Training streak with flame icon, overall skill rating circle, latest session summary card, "Analyze New Session" prominent button, quick stats row
3. **Analyze** — Video picker from photo library, position confirmation, loading state with athletic animation while AI processes, results screen with per-skill scores and drill recommendations
4. **Progress** — Skill score history as bar charts over time, filterable by skill category, overall rating trend line
5. **Profile** — Player name, position badge, skill level, total sessions analyzed, settings (reset onboarding, about)

## App Icon

- Dark background with a bold orange soccer ball silhouette combined with a subtle AI/brain circuit pattern, creating a tech-meets-sport feel. Clean and recognizable at small sizes.

