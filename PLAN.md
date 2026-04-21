# Home layout changes, modern legal pages, onboarding cleanup, disclaimer update

Here's what I'll change. I won't touch any other working screens or flows.

**Home screen**
- When a full training plan has been generated, show a new **"Your Workout"** section at the top of the home feed (above "Suggested for You").
- Both **"Your Workout"** and **"Suggested for You"** become collapsible dropdowns — tap the header to expand or collapse, with a chevron that rotates and a smooth animation. Default state: Your Workout expanded, Suggested for You collapsed once a plan exists.
- Until a plan is generated, only Suggested for You shows (as today).

**Onboarding**
- Remove the fake testimonials step (Marcus J., Sofia R., Aiden K.) and its "Players Like You" screen entirely from the onboarding flow so users go straight to the next step.

**Legal pages (Privacy Policy, Terms, EULA, Disclaimers, Risks & Safety)**
- Redesign so they no longer look like a wall of text. Each section becomes a modern card with:
  - A small colored icon badge in the corner (SF Symbol matching the section topic)
  - A bold title with subtle accent underline
  - Cleaner spacing, bullet lists rendered with real bullet styling (icon + text rows, not plain "•")
  - Section dividers and soft card shadow
- Header gets a larger hero treatment with the page icon in a tinted circle, page title, and "Last updated" chip.
- Content wording stays the same except for the disclaimer update below.

**Disclaimer — positioning and safety**
- Update the Disclaimers page (and surface the same copy where relevant) to clearly state:
  - KickIQ is a **tracking and organization tool** for workouts, drills, and conditioning programs recommended by the user's own coaches and trainers. The app sorts, schedules, and tracks exercises — it does not prescribe medical or professional training advice.
  - The user should **consult a physician and obtain medical clearance** before beginning any drills, conditioning, or physical activity in the app.
  - Performing drills and conditioning carries inherent risk of injury; the user accepts full responsibility for their own safety, proper warm-up, technique, environment, and stopping if they feel pain.
  - Minors should train under adult supervision.

**Token purchases (RevenueCat)**
- Confirmed already wired through RevenueCat (Small / Medium / Large token packs via the `token_packs` offering, purchased through `Purchases.shared.purchase(package:)`). No change needed — I'll just verify the packs load and purchase path is clean while making the above edits.

**Not touching**
- Benchmark, Drills, Progress, Profile tabs, AI Coach, paywall, subscription plans, existing drills data, analytics, streak logic.

Once you approve I'll implement and run a build to confirm everything compiles.