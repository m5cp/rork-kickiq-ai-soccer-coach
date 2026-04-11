import SwiftUI

struct WhatsNewView: View {
    @Environment(\.dismiss) private var dismiss

    private let currentVersion = "1.2"
    private let features: [NewFeature] = [
        NewFeature(icon: "person.3.fill", title: "Coach Role in Onboarding", description: "Coaches can now identify themselves during setup for a tailored experience with team dashboard access.", color: .blue),
        NewFeature(icon: "sportscourt.fill", title: "Post-Game Debrief", description: "Tell the AI about your game and get a personalized drill plan based on what went well and what was tough.", color: .green),
        NewFeature(icon: "play.circle.fill", title: "Live Workout Sessions", description: "Full-screen workout mode with timers, voice coaching cues, rest periods, and session summaries.", color: .orange),
        NewFeature(icon: "square.grid.2x2.fill", title: "Coach Dashboard", description: "Team overview with member stats, drill completion rates, and quick actions for assigning drills.", color: .purple),
        NewFeature(icon: "star.fill", title: "Smart Feedback", description: "Rate your experience and we'll route you to the right place — App Store review or direct support.", color: .yellow),
        NewFeature(icon: "accessibility", title: "Accessibility Improvements", description: "Better VoiceOver support across the app with labels on all key actions and navigation elements.", color: .cyan),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQTheme.Spacing.lg) {
                    headerSection
                    featuresList
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .padding(.bottom, KickIQTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                Button {
                    markAsSeen()
                    dismiss()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, KickIQTheme.Spacing.md)
                        .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .padding(.bottom, KickIQTheme.Spacing.sm)
                .background(KickIQTheme.background)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        markAsSeen()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(KickIQTheme.textSecondary.opacity(0.4))
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
    }

    private var headerSection: some View {
        VStack(spacing: KickIQTheme.Spacing.md) {
            Spacer().frame(height: KickIQTheme.Spacing.sm)

            ZStack {
                Circle()
                    .fill(KickIQTheme.accent.opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: "sparkles")
                    .font(.system(size: 32))
                    .foregroundStyle(KickIQTheme.accent)
            }

            VStack(spacing: KickIQTheme.Spacing.xs) {
                Text("What's New")
                    .font(.system(.title, design: .default, weight: .black))
                    .foregroundStyle(KickIQTheme.textPrimary)

                Text("Version \(currentVersion)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(KickIQTheme.textSecondary)
            }
        }
    }

    private var featuresList: some View {
        VStack(spacing: KickIQTheme.Spacing.sm + 2) {
            ForEach(Array(features.enumerated()), id: \.element.id) { index, feature in
                featureRow(feature)
                    .opacity(1)
                    .offset(y: 0)
            }
        }
    }

    private func featureRow(_ feature: NewFeature) -> some View {
        HStack(alignment: .top, spacing: KickIQTheme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(feature.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: feature.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(feature.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(feature.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(KickIQTheme.textPrimary)
                Text(feature.description)
                    .font(.caption)
                    .foregroundStyle(KickIQTheme.textSecondary)
                    .lineSpacing(2)
            }

            Spacer()
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
    }

    private func markAsSeen() {
        UserDefaults.standard.set(currentVersion, forKey: "kickiq_last_seen_version")
    }

    static var shouldShow: Bool {
        let lastSeen = UserDefaults.standard.string(forKey: "kickiq_last_seen_version") ?? ""
        return lastSeen != "1.2"
    }
}

nonisolated struct NewFeature: Identifiable, Sendable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let color: Color
}
