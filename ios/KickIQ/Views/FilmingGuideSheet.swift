import SwiftUI

struct FilmingGuideSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false

    private let guidelines: [FilmingGuideline] = [
        FilmingGuideline(
            icon: "timer",
            title: "Keep It Short",
            subtitle: "15–30 seconds per clip",
            detail: "Film one action at a time — a single shot, a dribble sequence, a first touch drill, or a passing pattern."
        ),
        FilmingGuideline(
            icon: "figure.stand",
            title: "Full Body in Frame",
            subtitle: "Head to toe visible at all times",
            detail: "The AI tracks your body position, foot placement, and movement patterns. Don't crop at the waist or knees."
        ),
        FilmingGuideline(
            icon: "iphone.gen3.landscape",
            title: "Film in Landscape",
            subtitle: "Turn your phone sideways",
            detail: "Landscape captures more of the field and gives the AI a wider view of your movement."
        ),
        FilmingGuideline(
            icon: "camera.on.rectangle",
            title: "Stable Camera",
            subtitle: "Use a tripod or prop your phone",
            detail: "Lean your phone against a water bottle, use a fence clip, or ask someone to hold it still."
        ),
        FilmingGuideline(
            icon: "ruler",
            title: "Right Distance",
            subtitle: "10–20 feet from the action",
            detail: "Too close and the AI can't see your full body mechanics. Too far and details are lost."
        ),
        FilmingGuideline(
            icon: "sun.max",
            title: "Good Lighting",
            subtitle: "Well-lit, minimal shadows",
            detail: "Natural daylight works best. Avoid filming directly into the sun or harsh overhead lights."
        ),
        FilmingGuideline(
            icon: "arrow.left.and.right",
            title: "Use Two Angles",
            subtitle: "Side + front view for best results",
            detail: "Side shows stride and follow-through. Front shows balance, rotation, and foot placement."
        ),
        FilmingGuideline(
            icon: "arrow.up.doc",
            title: "File Size",
            subtitle: "Under 100 MB per clip",
            detail: "At 1080p and 30fps, a 30-second clip is about 50–80 MB. Keep clips under 60 seconds."
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                        .padding(.bottom, 24)

                    bestClipTypes
                        .padding(.bottom, 16)

                    guidelinesGrid
                        .padding(.bottom, 16)

                    commonMistakes
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(KickIQTheme.accent)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(KickIQTheme.accent.opacity(0.1))
                    .frame(width: 64, height: 64)
                Image(systemName: "video.badge.checkmark")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(KickIQTheme.accent)
            }

            Text("Filming Guide")
                .font(.title2.weight(.bold))
                .foregroundStyle(KickIQTheme.textPrimary)

            Text("Follow these tips so the AI can accurately analyze your technique and give real feedback.")
                .font(.subheadline)
                .foregroundStyle(KickIQTheme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
        .opacity(appeared ? 1 : 0)
    }

    private var bestClipTypes: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label {
                Text("WHAT TO FILM")
                    .font(.caption.weight(.bold))
                    .tracking(0.8)
            } icon: {
                Image(systemName: "film.stack")
                    .font(.caption)
            }
            .foregroundStyle(KickIQTheme.accent)

            let clipTypes: [(icon: String, text: String)] = [
                ("scope", "A single shot on goal (approach + strike + follow-through)"),
                ("figure.run", "A short dribbling sequence through cones"),
                ("hand.point.up", "First touch receiving a pass (show the whole body)"),
                ("arrow.triangle.2.circlepath", "A passing drill (2–3 passes in a pattern)"),
                ("shield.fill", "A defensive 1v1 (jockeying and tackling)")
            ]

            VStack(spacing: 10) {
                ForEach(clipTypes, id: \.text) { clip in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Image(systemName: clip.icon)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(KickIQTheme.accent.opacity(0.7))
                            .frame(width: 18, alignment: .center)
                        Text(clip.text)
                            .font(.subheadline)
                            .foregroundStyle(KickIQTheme.textPrimary.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KickIQTheme.card, in: .rect(cornerRadius: 14))
        .opacity(appeared ? 1 : 0)
    }

    private var guidelinesGrid: some View {
        VStack(spacing: 10) {
            ForEach(Array(guidelines.enumerated()), id: \.element.id) { index, guideline in
                guidelineCard(guideline, index: index)
            }
        }
    }

    private func guidelineCard(_ guideline: FilmingGuideline, index: Int) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(KickIQTheme.accent.opacity(0.1))
                    .frame(width: 38, height: 38)
                Image(systemName: guideline.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(KickIQTheme.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(guideline.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KickIQTheme.textPrimary)

                Text(guideline.subtitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(KickIQTheme.accent.opacity(0.7))

                Text(guideline.detail)
                    .font(.caption)
                    .foregroundStyle(KickIQTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(1.5)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KickIQTheme.card, in: .rect(cornerRadius: 14))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 8)
        .animation(.spring(response: 0.4, dampingFraction: 0.85).delay(Double(index) * 0.03), value: appeared)
    }

    private var commonMistakes: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label {
                Text("AVOID THESE MISTAKES")
                    .font(.caption.weight(.bold))
                    .tracking(0.8)
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
            }
            .foregroundStyle(.red.opacity(0.8))

            let mistakes: [String] = [
                "Filming full matches — the AI needs focused, single-action clips",
                "Shaky handheld footage — stabilize your phone",
                "Filming from too far away — stay within 20 feet",
                "Cutting off your feet or head in the frame",
                "Filming in portrait mode — always use landscape",
                "Dark or backlit environments — face the light source"
            ]

            VStack(spacing: 8) {
                ForEach(mistakes, id: \.self) { mistake in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Circle()
                            .fill(.red.opacity(0.5))
                            .frame(width: 5, height: 5)
                            .padding(.top, 1)
                        Text(mistake)
                            .font(.caption)
                            .foregroundStyle(KickIQTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.05), in: .rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.red.opacity(0.12), lineWidth: 1)
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
