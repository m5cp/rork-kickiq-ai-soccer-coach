# Redesign Coach Plan with Periodization, Block Builder & Sharing

## What you'll be able to do

- **Generate a full multi-week training campaign** in a few taps by picking how many weeks, the age group, level, and the style of periodization (Tactical Morphocycle or Classic Preseason/In-season/Peaking/Taper). The app auto-fills every week and session from the built-in library.
- **Build sessions in clear phase blocks** instead of a flat list — Warm-up, Technical, Tactical, Game, Cool-down — with the drills grouped under each block and timings shown.
- **Step through the Builder as tidy cards** — Moment, Focus, Parameters, Activities, Review — each a collapsible card so it's obvious what to do next.
- **Share any plan or session four ways**: a printable PDF, an iMessage-ready text summary, a QR code that contains the full plan (works offline), and a deep link that opens the plan inside KickIQ on another coach's phone.
- **See drill instructions clearly** — every drill shows setup, phases, coaching points, and field info so a player or assistant coach can run it.

## How it will look and feel

- Same dark theme (near-black background, dark cards, orange accent) used throughout the app — fully consistent with the current Coach Plan.
- The Builder becomes a vertical stack of numbered **step cards** with soft dividers. Only the active step is expanded; completed steps collapse to a one-line summary you can tap to re-open.
- Activities are shown as **phase blocks** — each block has a small colored bar on the left, the phase name, total minutes, and the drills stacked inside it. Looks like a pro club's session sheet.
- A new **Campaign** tab (added to the existing segmented control) shows the multi-week plan as a vertical timeline. Each week is a card labeled with its phase (e.g. "Week 2 — Strength") and shows the 2–3 sessions inside.
- **Share sheet** is a clean bottom sheet with four big icons: PDF, Text, QR, Link.
- The **PDF** is clean black-and-white typography — like a pro club training document. Club header, week/date/phase, session objective, phase blocks with timings, drill details, and coaching points. Print-friendly, no busy colors.
- **QR code** screen shows a large QR on a white card with the plan title underneath — ready to scan from a tablet or clipboard on the training field.

## Screens

- **Coach Plan home** — segmented control expands to 5 tabs: Builder · Campaign · Blocks · Library · Evals.
- **Campaign tab** — list of saved campaigns plus a big "Generate Campaign" button. Tap a campaign to see its weekly timeline.
- **Campaign Generator** — pick number of weeks (1–16), age group, level, start date, and periodization style (Tactical Morphocycle or Classic). Tap Generate → full plan appears, editable.
- **Campaign Detail** — week-by-week timeline, each week showing its phase label and sessions. Tap any session to open and edit. Share button in the nav bar.
- **Session Builder (redesigned)** — collapsible numbered step cards (Moment → Focus → Parameters → Activities → Review). The Activities step shows drills grouped into phase blocks (Warm-up, Technical, Tactical, Game, Cool-down) with add/remove per block.
- **Session Detail (redesigned)** — same phase-block layout for reading. Share button added.
- **Share sheet** — four options: Export PDF, Send as Text, Show QR Code, Copy Link.
- **QR viewer** — full-screen QR with plan title; tap to save to photos.
- **PDF preview** — native preview with Share/Save/Print.

## Notes

- All existing sessions, evaluations, and blocks remain intact — this is additive plus a visual redesign of the Builder and Session Detail.
- The QR code embeds the plan data directly so it works with no internet and no backend.
- Deep links use a `kickiq://plan/...` scheme so tapping a shared link opens the plan in the recipient's KickIQ app.
- Only the Coach Plan area and its views are touched — no changes to Home, Drills, Progress, or Profile.

