# Unify coach & player into one experience, move planning into Drills

## The big idea

Drop the coach-vs-player split. Everyone gets the same app. The powerful session/campaign/season planning tools that used to live behind "Coach mode" become a dedicated **Coach Planning** hero block inside the Drills tab — available to anyone who wants to plan training for a team, a group, or themselves.

This removes the "which persona am I?" friction, cuts the app's surface area in half, and makes every screen feel polished instead of half-finished.

## What changes

### One experience for everyone
- Remove the coach/player branch from onboarding — onboarding asks about you as an athlete/individual (age, position, experience, goals), with **"I'm primarily a coach"** as just one of the position/role options, not a separate app mode.
- Remove the "COACH" badge on Home and the Plan tab switching.
- The bottom tab bar is the same for everyone: **Home · Benchmark · Drills · Progress · Profile**.

### Drills tab gets a "Coach Planning" hero
- At the top of the Drills tab, a prominent hero block: **"Coach Planning — build sessions, campaigns & full seasons"** with a clear subtitle explaining who it's for (coaches, team captains, self-directed players).
- Tapping it opens the existing planning hub with four clear sections:
  - **Session Builder** — build a single training session
  - **Season Generator** — full season, by date range or length
  - **Phase Generator** — just preseason, in-season, postseason, or any custom window (week / month / phase)
  - **Evaluations** — create and edit evaluation templates with add/remove criteria
  - **Library** — all saved sessions, campaigns, evaluations
- The existing Drills browsing experience stays exactly as it is below the hero.

### Builder gets rescued (fixes the "confusing floating labels" problem)
- Clear stepped flow with a progress indicator at the top: **1. Objective → 2. Sub-objectives → 3. Drills → 4. Review & Save**.
- Each step is a single focused screen with a headline, short helper text ("Pick the main thing this session will train"), tappable cards, and a clear "Continue" button at the bottom.
- No more free-floating labels without context.

### Season & phase generator (new power features)
- **Full season mode**: coach picks a start date and either an end date or a length in weeks. The generator lays out preseason → in-season → postseason automatically with the right session density for each phase.
- **Partial mode**: coach picks just one phase (preseason / in-season / postseason) OR a custom window (this week, next month, custom date range) and generates only that.
- Output is a week-by-week plan of sessions that can be opened, edited, rearranged, and exported.

### Evaluations — editable criteria
- Every evaluation template now has an **"Edit criteria"** button.
- Coaches can add new criteria (with name, description, 1–10 or 1–5 scale) and remove any built-in ones they don't use.
- Custom criteria are saved and reused across evaluations.

### Profile — one settings place, no re-onboarding
- Profile gets an **"Edit profile"** section with inline pickers for: name, age, position (including "Coach / Trainer"), experience level, primary weakness/goal.
- Changing these updates the app content instantly — no onboarding redo.
- A **"Reset all settings"** destructive action at the bottom wipes preferences and returns to onboarding for anyone who wants a fresh start.
- Profile content is the same for everyone — your stats, your streak, your goals, your coach report card.

## Design notes
- The planning hero on Drills uses a bold card with a clipboard icon, gradient accent, and a short one-liner — it should feel like a "pro feature" worth tapping into, not a buried menu item.
- Builder steps use the same clean card + continue pattern Apple uses in Fitness+ setup and Health onboarding.
- Season generator preview is a visual week-strip you can scroll through before saving — makes the output tangible instead of a wall of text.
- Everything stays in the current color/type system; no new theme work.

## Screens affected
- **Onboarding** — remove coach/player branch, treat coach as a position choice.
- **Home** — remove COACH badge and role-based logic; everyone sees the same Home.
- **Drills tab** — add Coach Planning hero block at the top.
- **Coach Planning hub** (was the Plan tab) — now reached from Drills; reorganized with clearer section names.
- **Session Builder** — rebuilt as a 4-step guided flow.
- **Season Generator** — new full-season + partial-phase options.
- **Evaluations** — add/remove criteria editing.
- **Profile** — inline edit for all onboarding answers + reset all settings.

## Not doing
- No changes to the AI chat, benchmarks, progress, widgets, or notifications.
- No migration code needed (app isn't released yet).
- No new tab — the tab bar stays 5 tabs, same for everyone.