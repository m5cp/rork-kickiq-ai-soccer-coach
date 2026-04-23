# Redesign Coach Plan: pro library, blocks intro, custom evaluations, full season generator

## Library — Pro Design

- Replace the plain list with large, tappable session tiles grouped by category (Defending, Attacking, Transitions).
- Each tile: bold colored icon header strip, session title, game moment tag, duration, intensity flame, activity count.
- Sections feel like polished product cards, not list rows.
- Context menu on long press: Duplicate, Delete, Share.

## Blocks Tab — Clear Intro

- When empty, show a friendly explainer card: "Training Blocks" with icon, short description ("Group 4–8 weeks of sessions into a focused training block"), and a prominent "Create Block" button.
- When populated, show a subtle info banner at top reminding coaches what blocks are for.

## Evaluations — Customizable Criteria

- Default criteria: Technical, Tactical, Physical, Character (unchanged).
- New "Edit Criteria" button in the Evaluations tab header — opens a sheet where the coach can:
  - Rename any criterion
  - Delete criteria
  - Add new criteria (e.g. Leadership, Speed, Decision Making)
  - Reorder criteria
- Changes apply globally going forward; existing evaluations keep their scores.
- Add/Edit Evaluation sheet dynamically shows sliders for whatever criteria are currently defined.
- Evaluation cards show progress bars for all active criteria.

## Campaign (Season) Generator — New Tab

A dedicated "Campaign" segment (replacing nothing — already in the tab bar). Fully reworked:

### Season Setup

- Choose season length by either:
  - **Total weeks** (stepper, e.g. 8–52 weeks), OR
  - **Start and end dates** (two date pickers)
- Pick team age group and player count.

### Scope Selection

Coach picks what to generate:

- **Full Season** — all phases across the whole season
- **Single Phase** — pick one: Preseason, Early Season, Mid Season, Late Season, Playoffs, Off-Season
- **Single Month** — pick month within the season
- **Single Week** — pick a specific week
- **Single Session** — one session for a specific date
- **Custom Date Range** — start and end date for a partial plan

### Phase Model

- Six phases: Preseason, Early Season, Mid Season, Late Season, Playoffs, Off-Season.
- Each phase has a default training focus (e.g. Preseason = fitness + build-up, Playoffs = finishing + set pieces).
- Coach can tap any phase to customize its focus before generating.

### Output

- Generator creates a structured plan: phase → weeks → sessions, each with activities and coaching points.
- Plan appears in a scrollable overview with week rows and session cards.
- Every generated session can be tapped to edit, and saved to the Library.
- Share the whole plan as PDF, text summary, or QR code (using the existing share system).

## Design Consistency

- All screens keep the dark-mode, card-based style with orange accents already in the app.
- 8pt grid, SF Pro, consistent corner radius and spacing across new components.
- Empty states always explain the screen's purpose and show a clear primary action.

