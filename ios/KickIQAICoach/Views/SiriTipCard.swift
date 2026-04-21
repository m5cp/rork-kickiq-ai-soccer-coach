import SwiftUI
import AppIntents

struct SiriTipCard: View {
    let phrase: String
    let systemImage: String

    var body: some View {
        HStack(spacing: KickIQAICoachTheme.Spacing.sm + 2) {
            ZStack {
                Circle()
                    .fill(KickIQAICoachTheme.accent.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "mic.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(KickIQAICoachTheme.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Try with Siri")
                    .font(.caption.weight(.black))
                    .tracking(1)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                Text("\u{201C}\(phrase)\u{201D}")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: systemImage)
                .font(.subheadline)
                .foregroundStyle(KickIQAICoachTheme.accent.opacity(0.6))
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.md)
                .stroke(KickIQAICoachTheme.accent.opacity(0.15), lineWidth: 1)
        )
    }
}
