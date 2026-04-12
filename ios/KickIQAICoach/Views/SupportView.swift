import SwiftUI
import MessageUI

struct SupportView: View {
    @State private var showMailUnavailable = false

    var body: some View {
        ScrollView {
            VStack(spacing: KickIQAICoachTheme.Spacing.lg) {
                VStack(spacing: KickIQAICoachTheme.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(KickIQAICoachTheme.accent.opacity(0.15))
                            .frame(width: 80, height: 80)
                        Image(systemName: "headset.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(KickIQAICoachTheme.accent)
                    }

                    Text("How can we help?")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)

                    Text("We're here to help you get the most out of KickIQAICoach. Reach out with any questions, feedback, or issues.")
                        .font(.subheadline)
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, KickIQAICoachTheme.Spacing.md)

                VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                    supportCard(
                        icon: "envelope.fill",
                        title: "Email Support",
                        subtitle: "contact@m5cairo.com",
                        description: "Typically respond within 24 hours"
                    ) {
                        sendEmail()
                    }

                    supportCard(
                        icon: "questionmark.circle.fill",
                        title: "FAQs",
                        subtitle: "Common Questions",
                        description: "Find quick answers below"
                    ) {}
                }

                faqSection

                VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                    Text("QUICK ACTIONS")
                        .font(.caption.weight(.bold))
                        .tracking(1)
                        .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        quickActionRow(icon: "creditcard.fill", title: "Manage Subscription")
                    }

                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        quickActionRow(icon: "gearshape.fill", title: "App Settings")
                    }
                }
            }
            .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
            .padding(.bottom, KickIQAICoachTheme.Spacing.xl)
        }
        .scrollIndicators(.hidden)
        .background(KickIQAICoachTheme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        
        .alert("Email Not Available", isPresented: $showMailUnavailable) {
            Button("Copy Email") {
                UIPasteboard.general.string = "contact@m5cairo.com"
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your device doesn't have a mail app configured. You can copy our email address and contact us at contact@m5cairo.com")
        }
    }

    private func supportCard(icon: String, title: String, subtitle: String, description: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: KickIQAICoachTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(KickIQAICoachTheme.accent.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    Text(subtitle)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(KickIQAICoachTheme.accent)
                    Text(description)
                        .font(.caption2)
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.3))
            }
            .padding(KickIQAICoachTheme.Spacing.md)
            .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        }
    }

    private var faqSection: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            Text("FREQUENTLY ASKED QUESTIONS")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .leading)

            faqItem(q: "How does AI analysis work?", a: "Upload a training video or photo and our AI analyzes your technique, body position, and movement patterns to provide personalized coaching feedback and skill scores.")

            faqItem(q: "Is my video data stored?", a: "No. Your video frames are processed in real-time for analysis and are not stored on our servers. Only your scores and feedback are saved locally on your device.")

            faqItem(q: "Can I cancel my subscription?", a: "Yes. You can cancel anytime through your Apple ID subscription settings. Your access continues until the end of the current billing period.")

            faqItem(q: "How do I restore my purchases?", a: "Go to Profile > Restore Purchases. This will restore any active subscriptions linked to your Apple ID.")

            faqItem(q: "What video formats work best?", a: "We recommend well-lit videos shot from a distance that shows your full body. Landscape orientation works best. Clear, stable footage produces the most accurate analysis.")
        }
    }

    private func faqItem(q: String, a: String) -> some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            HStack(alignment: .top, spacing: KickIQAICoachTheme.Spacing.sm) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(KickIQAICoachTheme.accent)
                    .padding(.top, 2)
                Text(q)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
            }

            Text(a)
                .font(.caption)
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
                .lineSpacing(3)
                .padding(.leading, 24)
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
    }

    private func quickActionRow(icon: String, title: String) -> some View {
        HStack(spacing: KickIQAICoachTheme.Spacing.sm + 2) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(KickIQAICoachTheme.accent)
                .frame(width: 24)
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
            Spacer()
            Image(systemName: "arrow.up.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.3))
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
    }

    private func sendEmail() {
        let email = "contact@m5cairo.com"
        let subject = "KickIQAICoach Support Request"
        let body = "App Version: 1.0\nDevice: \(UIDevice.current.model)\niOS: \(UIDevice.current.systemVersion)\n\nDescribe your issue:\n"

        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let url = URL(string: "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            showMailUnavailable = true
        }
    }
}
