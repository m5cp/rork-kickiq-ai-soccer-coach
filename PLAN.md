# Add timers to every drill and an all-day step tracker with Apple Watch app

## Universal Activity Timer

Every drill and coach session activity (technical, tactical, conditioning, fitness) will have a Start button that opens a full-screen countdown timer.

**Timer screen shows:**
- Large circular countdown ring in orange that drains as time passes
- Big monospaced time remaining with WORK / REST label
- Set indicator dots (for multi-set drills)
- Play / Pause, Reset, and Skip-to-next controls
- Audio beeps on 3-2-1 countdown and a final completion tone, with a mute toggle
- Live Activity on the Lock Screen and Dynamic Island so the timer keeps ticking when the phone is locked
- Scrollable panel below the ring listing the activity's phases and coaching points so the coach or player can read them while the drill runs
- A live step counter chip showing steps taken during this drill

**Coach session runner:**
- From any saved coach session, a "Run Session" button walks through all activities back-to-back, auto-advancing to the next drill with a short rest screen in between
- Progress bar at the top shows which activity of the session is active

## All-Day Step Tracking

A lightweight pedometer runs in the background using motion-only permission (no Apple Health required) so the app tracks steps throughout the day, similar to Apple Fitness.

**In the main app:**
- New "Activity" card on the Home/Progress tab showing today's steps, distance, and a 7-day bar chart
- Weekly and monthly step history
- Goal ring (default 10,000 steps) that fills as the user walks

## Apple Watch Companion App

A standalone watchOS app paired with the iPhone app:
- **Today view** — step ring, distance, and active minutes for the day, glanceable at a wrist raise
- **Timer view** — mirror of the phone's drill timer so a player or coach can start and control any drill from the watch
- **History** — scrollable list of the last 7 days of steps
- Complications on the watch face showing current step count

## Permissions

The app will ask for Motion & Fitness permission the first time the user opens the Activity card or starts a drill timer. A friendly explainer screen describes why steps are tracked (training load, daily activity) before the system prompt appears.

## App Icon

No icon change needed — existing icon is reused for both the iPhone and Apple Watch apps.
