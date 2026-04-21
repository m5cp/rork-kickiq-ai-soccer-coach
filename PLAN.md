# KickIQ Quick Wins: analytics, crash reporting, paywall polish, sharing & Siri

Scope: Quick Wins (A–J) only. Medium items (K, L, N, O) and Major Upgrades are explicitly deferred. Nothing currently working will be touched beyond the specific points below.

## What will change for users

**Paywall & pricing (D, E, F)**
- Paywall already appears after onboarding — I'll audit that trigger and also add one after the first benchmark result so new users see it after their "aha" moment.
- Annual plan will be shown first, pre-selected, with a green "SAVE 60%" badge and a "Just $1.44/week, billed yearly" line beneath the price so the weekly framing is always visible.
- Weekly plan moves to the bottom and shows "$X/week" plainly.
- "Restore Purchases" button already exists in Settings and on the paywall — I'll make it more prominent (full-width row at the top of the paywall footer) and confirm it's reachable without a paywall in the way.

**Milestone share card (H)**
- When a milestone badge is earned, the celebration screen gets a new "Share" button.
- Tapping it opens the native iOS share sheet with a pre-rendered image of the badge + streak/score + pre-filled caption: "I just hit [milestone] on KickIQ 🔥 — free soccer training app: [App Store link]". Users can post to Instagram, WhatsApp, iMessage, etc.

**Siri & Spotlight shortcuts (J)**
- "Start next drill" — users can say "Hey Siri, start my next KickIQ drill" or tap a Shortcut to jump straight into today's drill.
- "Show my streak" — Siri / Spotlight answers with the current streak count and opens the app to the progress screen.
- These also appear as suggested Shortcuts in the Shortcuts app.

**App name on home screen (A)**
- The app icon label will read "KickIQ" instead of the longer target name.

**Behind the scenes**
- Anonymous analytics (TelemetryDeck) and crash reporting (Sentry) are wired up. They only activate once you paste API keys into environment variables — until then they're silent no-ops so nothing breaks. I'll also add a short note in the plan explaining exactly where to sign up (free tiers, takes ~5 min each) and which keys to paste.
- Apple Pay entitlement (unused — no merchant payments in the app) will be removed. This reduces App Review friction.

## Events that will be tracked (once keys are added)

App open, screen views, onboarding step reached, onboarding completed, paywall shown, paywall dismissed, purchase started, purchase succeeded, restore tapped, drill started, drill completed, benchmark completed, milestone earned, share card opened, share completed.

## What I will NOT touch

- Drills data (DrillsService, ConditioningDrillsService) — stays exactly as is.
- Existing onboarding flow, benchmark flow, AI coach, widget, live activity.
- Storage format, data models, RevenueCat product IDs.
- Any working screens outside the specific edits above.

## Deferred (your call, not in this pass)

- K (50%-off retry paywall), L (interactive widget), N (reactivation notifications), O (XP system on home/widget) — will be a separate pass.
- App Store metadata rewrite (skipped per your choice).
- Superwall migration, SwiftData migration, full onboarding redesign — major upgrades, separate project.

## After I implement

I'll give you a short "keys setup" checklist:
1. Sign up at telemetrydeck.com (free) → paste app ID.
2. Sign up at sentry.io (free tier) → paste DSN.
3. Remove Apple Pay merchant from Apple Developer portal if you want to fully clean it up.

Until you add the keys, analytics and crash reporting stay dormant — zero risk to current builds.

Ready for me to proceed?