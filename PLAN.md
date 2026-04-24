# Make the app safe and legal for all ages, including kids under 13

To legally support users of all ages (including under 13) outside of Apple's Kids Category, I'll add an age-aware safety layer across onboarding, chat, and settings.

### New flow for new users
- **Age gate on first launch** — ask for date of birth before account creation. Stored locally, not tied to a public profile.
- **Under-13 path** — shows a friendly "Ask a parent" screen with a parental consent step: parent enters their name + email, confirms they're the legal guardian, and agrees to the Terms & Privacy Policy on the child's behalf. Until consent is confirmed, the child has a limited experience (drills and training only — no AI chat, no social features).
- **13–17 path** — standard onboarding with a short "teen safety" notice and stricter defaults (analytics off, strict content filter on).
- **18+ path** — standard onboarding, unchanged.

### AI Chat safety
- Chat is **locked for under-13 users** until a parent approves it from the parental consent screen or later from Settings.
- When chat is used by anyone under 18, a stricter safety system prompt is applied: no adult topics, no personal info sharing, age-appropriate coaching language.
- Safety filter also scans incoming messages for unsafe topics (self-harm, bullying, inappropriate content) and shows a supportive redirect message instead of a model reply.
- No chat history is stored on servers for minors — minor conversations stay on-device only.

### Privacy & legal
- **In-app Privacy Policy and Terms of Service** accessible from Settings and from the sign-up screen, with a generated kid-friendly summary at the top.
- **Analytics & tracking disabled for all minors** automatically (no tracking prompt shown to under-18s either).
- **Data minimization** — minors' profiles don't show real names publicly, only a first name or chosen nickname.

### User-to-user safety (required if any social/chat)
- **Report & block** buttons on any shared content or user profile, with a clear "We review within 24 hours" message.
- **Zero tolerance policy** surfaced in Terms — abusive accounts are removed.

### Account controls (required by Apple)
- **Delete my account** button in Settings that wipes all user data.
- **Parents can revoke consent** at any time from a "Parental Controls" area in Settings, which removes the child's access to chat and social features immediately.

### Settings additions
- New **Parental Controls** section (visible when account is a minor or was set up by a parent): toggle AI chat, toggle social features, revoke consent, change linked parent email.
- New **Privacy** section: links to Privacy Policy, Terms, "Delete my account", and a "Download my data" request option.

### Design
- Warm, reassuring tone on all consent and safety screens — soft green checkmarks, clear plain-English copy, no legalese dumped on the child.
- Parent consent screen uses a distinct "for parents only" header with a lock symbol so kids don't mistake it for their own screen.
- All safety screens follow the app's existing visual style (same type, spacing, and colors as onboarding).

### Screens added
- **Date of birth** screen (onboarding)
- **Parental consent** screen (under-13 only)
- **Teen safety notice** screen (13–17)
- **Parental Controls** screen (in Settings)
- **Privacy & Legal** screen (in Settings, with Delete Account)
- **Report user / content** sheet (reachable from chat and profiles)

Once you approve, I'll implement this end-to-end and verify the build.