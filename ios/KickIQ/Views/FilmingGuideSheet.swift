import SwiftUI

struct FilmingGuideSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false

    private let guidelines: [FilmingGuideline] = [
        FilmingGuideline(
            icon: "timer",
            title: "Keep It Short",
            subtitle: "15–30 seconds per clip",
            detail: "Film one action at a time — a single shot, a dribble sequence, a first touch drill, or a passing pattern. Short, focused clips give the AI the clearest signal to analyze your technique."
        ),
        FilmingGuideline(
            icon: "figure.stand",
            title: "Full Body in Frame",
            subtitle: "Head to toe visible at all times",
            detail: "The AI tracks your body position, foot placement, and movement patterns. Make sure your entire body stays in frame for the full clip — don't crop at the waist or knees."
        ),
        FilmingGuideline(
            icon: "iphone.gen3.landscape",
            title: "Film in Landscape",
            subtitle: "Turn your phone sideways",
            detail: "Landscape orientation captures more of the field and gives the AI a wider view of your movement. This is how pro analysis tools work."
        ),
        FilmingGuideline(
            icon: "camera.on.rectangle",
            title: "Stable Camera",
            subtitle: "Use a tripod or prop your phone",
            detail: "A steady camera is critical. Lean your phone against a water bottle, use a fence clip, or ask someone to hold it still. Shaky footage reduces analysis accuracy."
        ),
        FilmingGuideline(
            icon: "ruler",
            title: "Right Distance",
            subtitle: "10–20 feet away from the action",
            detail: "Too close and the AI can't see your full body mechanics. Too far and details are lost. 10–20 feet is the sweet spot for individual drills and shots."
        ),
        FilmingGuideline(
            icon: "sun.max",
            title: "Good Lighting",
            subtitle: "Well-lit, minimal shadows",
            detail: "Natural daylight works best. Avoid filming directly into the sun. If indoors, make sure overhead lights illuminate you evenly without harsh shadows."
        ),
        FilmingGuideline(
            icon: "arrow.left.and.right",
            title: "Use Two Angles",
            subtitle: "Side view + front view for best results",
            detail: "A side angle shows stride length, body lean, and follow-through. A front angle shows balance, hip rotation, and foot placement. Film both for the most complete feedback."
        ),
        FilmingGuideline(
            icon: "arrow.up.doc",
            title: "File Size",
            subtitle: "Under 100 MB per clip",
            detail: "At 1080p and 30fps, a 30-second clip is about 50–80 MB. Keep clips under 60 seconds and 100 MB for smooth uploading and processing."
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQTheme.Spacing.lg) {
                    headerSection

                    bestClipTypes

                    VStack(spacing: KickIQTheme.Spacing.sm + 2) {
                        ForEach(Array(guidelines.enumerated()), id: \.element.id) { index, guideline in
                            guidelineRow(guideline, index: index)
                        }
                    }

                    commonMistakes
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .padding(.bottom, KickIQTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(KickIQTheme.accent)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.background)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
        }
    }

    private var headerSection: some View {
        VStack(spacing: KickIQTheme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(KickIQTheme.accent.opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: "video.badge.checkmark")
                    .font(.system(size: 30))
                    .foregroundStyle(KickIQTheme.accent)
            }

            Text("Filming Guide")
                .font(.title2.weight(.bold))
                .foregroundStyle(KickIQTheme.textPrimary)

            Text("Follow these tips so the AI can accurately\nanalyze your technique and give real feedback.")
                .font(.subheadline)
                .foregroundStyle(KickIQTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .padding(.top, KickIQTheme.Spacing.sm)
        .opacity(appeared ? 1 : 0)
    }

    private var bestClipTypes: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            Text("WHAT TO FILM")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQTheme.accent)

            let clipTypes: [(icon: String, text: String)] = [
                ("scope", "A single shot on goal (approach + strike + follow-through)"),
                ("figure.run", "A short dribbling sequence through cones"),
                ("hand.point.up", "First touch receiving a pass (show the whole body)"),
                ("arrow.triangle.2.circlepath", "A passing drill (2–3 passes in a pattern)"),
                ("shield.fill", "A defensive 1v1 (jockeying and tackling)")
            ]

            VStack(spacing: KickIQTheme.Spacing.sm) {
                ForEach(clipTypes, id: \.text) { clip in
                    HStack(alignment: .top, spacing: KickIQTheme.Spacing.sm + 2) {
                        Image(systemName: clip.icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(KickIQTheme.accent)
                            .frame(width: 20)
                            .padding(.top, 2)
                        Text(clip.text)
                            .font(.subheadline)
                            .foregroundStyle(KickIQTheme.textPrimary.opacity(0.85))
                    }
                }
            }
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
    }

    private func guidelineRow(_ guideline: FilmingGuideline, index: Int) -> some View {
        HStack(alignment: .top, spacing: KickIQTheme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: KickIQTheme.Radius.sm)
                    .fill(KickIQTheme.accent.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: guideline.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(KickIQTheme.accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(guideline.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(KickIQTheme.textPrimary)

                Text(guideline.subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KickIQTheme.accent.opacity(0.8))

                Text(guideline.detail)
                    .font(.caption)
                    .foregroundStyle(KickIQTheme.textSecondary)
                    .lineSpacing(2)
            }
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.35).delay(Double(index) * 0.04), value: appeared)
    }

    private var commonMistakes: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            Text("AVOID THESE MISTAKES")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(.red.opacity(0.8))

            let mistakes: [String] = [
                "Filming full matches — the AI needs focused, single-action clips",
                "Shaky handheld footage — stabilize your phone",
                "Filming from too far away — stay within 20 feet",
                "Cutting off your feet or head in the frame",
                "Filming in portrait mode — always use landscape",
                "Dark or backlit environments — face the light source"
            ]

            VStack(spacing: KickIQTheme.Spacing.sm) {
                ForEach(mistakes, id: \.self) { mistake in
                    HStack(alignment: .top, spacing: KickIQTheme.Spacing.sm) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.red.opacity(0.6))
                            .padding(.top, 2)
                        Text(mistake)
                            .font(.caption)
                            .foregroundStyle(KickIQTheme.textSecondary)
                    }
                }
            }
        }
        .padding(KickIQTheme.Spacing.md)
        .background(Color.red.opacity(0.06), in: .rect(cornerRadius: KickIQTheme.Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                .stroke(Color.red.opacity(0.15), lineWidth: 1)
        )
        .opacity(appeared ? 1 : 0)
    }
}

nonisolated struct FilmingGuideline: Identifiable, Sendable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let detail: String
}
