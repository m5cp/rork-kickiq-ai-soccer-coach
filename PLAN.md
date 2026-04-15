# KickIQ Overhaul — Phase 1: Home Redesign, Drills Page Fixes, Calendar & AI Summaries


This is a comprehensive update split into two phases, both delivered back-to-back without pause.

---

## Phase 1 — UI Fixes, Home Redesign & Drills Page

### Naming Fixes
- Home page "DRILLS" card → renamed to **"SKILLS"**
- Home page "FITNESS" card → renamed to **"CONDITIONING"**
- Drills tab title stays "Drills" but the Skills/Conditioning toggle labels are consistent

### Home Screen Redesign
- **Remove** the two generator cards (Skills Generator / Conditioning Generator) from the Home screen — they're redundant
- **Replace with "Today's Training"** section:
  - If the user has an active plan, show today's scheduled drills and conditioning with a quick-glance card (drill names, focus area, estimated time)
  - If no plan exists, auto-suggest drills based on the player's weakest areas (3–4 drills + 1–2 conditioning exercises), with a nudge to generate a full plan from the Drills tab
  - Each drill in the Today's Training section is tappable to see details
- Keep all other Home sections (Progress, Training, Benchmark, Focus Areas) as-is

### Drills Tab Enhancements
- **Add plan generator access** directly on the Drills page — "Generate Skills Plan" and "Generate Conditioning Plan" buttons are now accessible from the Drills tab itself (within each Skills/Conditioning segment)
- **Add "Reset Plan" option** — a button on the Drills page to clear/reset the active Skills or Conditioning plan, with a confirmation prompt

---

## Phase 2 — Training Calendar & AI Weekly Summaries

### Training Calendar (Progress Tab)
- **Calendar button** in the Progress tab toolbar that opens a full calendar view
- Calendar shows color-coded dots on days: past training days (completed), today, future planned days
- **Tap any day** to see a detail sheet showing:
  - Drills and conditioning completed that day
  - Duration, reps, or other stats recorded
  - A notes field where the user can annotate what they did, how long, speed, perceived effort, or any freeform text
  - Annotations are saved and visible when revisiting that day

### AI Weekly Training Summary
- **Auto-generated every week** (Sunday evening) — appears as a card on the Home screen
- **Also available on demand** — "Weekly Summary" button in the Progress tab
- Uses **Groq (cloud AI)** for consistent, high-quality output — same engine as the coach chat
- The summary reads like a **coach's weekly report**: natural language covering training volume, skills practiced, benchmark improvements, streak status, and encouragement
- Apple Intelligence is used where appropriate (e.g., on-device text refinement if available on iOS 26+ devices)
- The AI has access to **coach chat history** (via the existing coach memory system) so it can reference topics the player discussed and weave them into the summary

### Design
- Calendar view uses a clean month-grid layout with the app's accent color for training days
- Weekly summary card on Home has a distinct coach-style design — quote-like layout with a subtle accent border
- All new UI follows the existing KickIQ theme (accent colors, card styles, typography)
