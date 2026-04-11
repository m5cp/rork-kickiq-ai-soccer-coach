import SwiftUI
import StoreKit

struct FeedbackPromptView: View {
    let storage: StorageService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRating: Int = 0
    @State private var showSupport = false

    var body: some View {
        VStack(spacing: KickIQTheme.Spacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(KickIQTheme.accent.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "heart.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(KickIQTheme.accent)
            }

            VStack(spacing: KickIQTheme.Spacing.sm) {
                Text("How's KickIQ working for you?")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(KickIQTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Your feedback helps us improve")
                    .font(.subheadline)
                    .foregroundStyle(KickIQTheme.textSecondary)
            }

            HStack(spacing: KickIQTheme.Spacing.md) {
                ForEach(1...5, id: \.self) { rating in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedRating = rating
                        }
                    } label: {
                        Image(systemName: rating <= selectedRating ? "star.fill" : "star")
                            .font(.system(size: 36))
                            .foregroundStyle(rating <= selectedRating ? KickIQTheme.accent : KickIQTheme.textSecondary.opacity(0.3))
                    }
                    .sensoryFeedback(.selection, trigger: selectedRating)
                }
            }
            .padding(.vertical, KickIQTheme.Spacing.md)

            if selectedRating > 0 {
                if selectedRating >= 4 {
                    VStack(spacing: KickIQTheme.Spacing.sm) {
                        Text("We're glad you're enjoying KickIQ!")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KickIQTheme.textPrimary)

                        Button {
                            storage.recordFeedbackPrompt()
                            if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                                AppStore.requestReview(in: scene)
                            }
                            dismiss()
                        } label: {
                            HStack(spacing: KickIQTheme.Spacing.sm) {
                                Image(systemName: "star.fill")
                                Text("Rate on App Store")
                            }
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, KickIQTheme.Spacing.md)
                            .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    VStack(spacing: KickIQTheme.Spacing.sm) {
                        Text("We'd love to hear how we can improve")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KickIQTheme.textPrimary)

                        Button {
                            storage.recordFeedbackPrompt()
                            showSupport = true
                        } label: {
                            HStack(spacing: KickIQTheme.Spacing.sm) {
                                Image(systemName: "envelope.fill")
                                Text("Send Feedback")
                            }
                            .font(.headline)
                            .foregroundStyle(KickIQTheme.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, KickIQTheme.Spacing.md)
                            .background(KickIQTheme.accent.opacity(0.15), in: .rect(cornerRadius: KickIQTheme.Radius.lg))
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }

            Spacer()

            Button {
                storage.recordFeedbackPrompt()
                dismiss()
            } label: {
                Text("Not Now")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(KickIQTheme.textSecondary)
            }
            .padding(.bottom, KickIQTheme.Spacing.md)
        }
        .padding(.horizontal, KickIQTheme.Spacing.lg)
        .animation(.spring(response: 0.4), value: selectedRating)
        .sheet(isPresented: $showSupport) {
            SupportView()
        }
    }
}
