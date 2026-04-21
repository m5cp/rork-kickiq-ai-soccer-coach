# Quick wins: paywall polish, Restore in Settings, onboarding trigger, Siri tips, share link fix

Based on your answers, here's the focused scope — skipping analytics SDKs, Superwall, retry paywall, SwiftData, and HealthKit. No metadata or screenshot work.

## What you'll get

**Paywall improvements**
- Confirm weekly, monthly, and annual plans all show up and are purchasable (weekly was already in the offering — I'll verify it renders correctly alongside the others).
- Annual selected by default with a clear "SAVE" badge and a "just $X/week, billed yearly" helper line.
- Monthly shows its weekly-equivalent price.
- Weekly plan appears last and shows its true weekly price.
- Clean auto-renew disclaimer and a prominent Restore Purchases button stay in place.

**Restore Purchases in Settings**
- New "Subscription" section in Settings with a Restore Purchases row and a Manage Subscription link (opens Apple's subscription page).
- Shows your current plan status (Premium / Free).

**Paywall trigger after the first benchmark**
- After a new user finishes their first benchmark assessment during or right after onboarding, the paywall appears once — right at the peak "value moment."
- Only fires once, never interrupts returning users.

**Milestone share card fix**
- The share caption currently points to a placeholder App Store link. I'll make the App Store URL configurable so that once you have your live app ID, it takes one line to update — and in the meantime it falls back to a clean TestFlight/coming-soon message instead of a broken link.

**Siri Tips on key screens**
- Add small "Try saying 'Hey Siri, start next drill'" tip cards on the Home and Drills screens so users discover the Siri Shortcuts that are already wired up.

**Entitlements cleanup**
- Review the entitlements file and remove Apple Pay / any unused capability so App Review doesn't flag it.

**Compliance sweep**
- Verify Privacy Policy and Terms screens are reachable from Settings and Onboarding.
- Scan for any dead buttons or placeholder features.
- Make sure every tappable element hits the 44pt minimum.

## What I'm NOT doing (per your instructions)
- No Superwall (sticking with RevenueCat).
- No new weekly product creation (keeping what's already in your offering).
- No TelemetryDeck or Sentry.
- No 50%-off retry paywall.
- No SwiftData migration.
- No HealthKit.
- No new App Store metadata or screenshots.

## After approval
I'll implement, build, and verify everything compiles cleanly before handing back. Existing working flows (onboarding copy, drills library, AI coach, widgets, streak system) will not be touched.