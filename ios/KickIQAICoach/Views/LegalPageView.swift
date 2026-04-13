import SwiftUI

enum LegalPage: Identifiable {
    var id: String { title }

    case privacyPolicy
    case termsOfUse
    case eula
    case disclaimer
    case risks

    var title: String {
        switch self {
        case .privacyPolicy: "Privacy Policy"
        case .termsOfUse: "Terms of Use"
        case .eula: "End User License Agreement"
        case .disclaimer: "Disclaimers"
        case .risks: "Risks & Safety"
        }
    }

    var icon: String {
        switch self {
        case .privacyPolicy: "lock.shield.fill"
        case .termsOfUse: "doc.text.fill"
        case .eula: "doc.badge.gearshape.fill"
        case .disclaimer: "exclamationmark.triangle.fill"
        case .risks: "shield.lefthalf.filled"
        }
    }

    var lastUpdated: String { "April 12, 2026" }
}

struct LegalPageView: View {
    let page: LegalPage

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.lg) {
                VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
                    HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                        Image(systemName: page.icon)
                            .font(.title3)
                            .foregroundStyle(KickIQAICoachTheme.accent)
                        Text(page.title)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    }

                    Text("Last updated: \(page.lastUpdated)")
                        .font(.caption)
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }

                content
            }
            .padding(KickIQAICoachTheme.Spacing.md)
            .padding(.bottom, KickIQAICoachTheme.Spacing.xl)
        }
        .scrollIndicators(.hidden)
        .background(KickIQAICoachTheme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        
    }

    @ViewBuilder
    private var content: some View {
        switch page {
        case .privacyPolicy:
            privacyPolicyContent
        case .termsOfUse:
            termsOfUseContent
        case .eula:
            eulaContent
        case .disclaimer:
            disclaimerContent
        case .risks:
            risksContent
        }
    }

    private var privacyPolicyContent: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.md) {
            legalSection(title: "Introduction", body: "KickIQAICoach (\"the App\") is operated by M5 Cairo (\"we\", \"us\", \"our\"). We are committed to protecting your privacy and personal information. This Privacy Policy explains how we collect, use, and safeguard your data when you use the App.")

            legalSection(title: "Information We Collect", body: """
• Profile Information: Name, position, skill level, age range, and weakness preferences you provide during onboarding and profile setup.
• Training Data: Video frames and images you upload for AI analysis. These are processed in real-time and are not stored on our servers after analysis is complete.
• Usage Data: App interaction data including session counts, streak data, drill completion, XP points, and token balances stored locally on your device.
• Purchase Data: Records of in-app purchases including subscriptions and token packs, managed through Apple's App Store.
• Profile Photos: If you choose to upload a profile photo, it is stored locally on your device only.
""")

            legalSection(title: "How We Use Your Information", body: """
• To provide AI-powered soccer coaching feedback based on your uploaded training clips.
• To personalize drill recommendations based on your position, skill level, and identified weaknesses.
• To track your training progress, streaks, and milestones.
• To improve the quality and accuracy of our AI analysis over time.
""")

            legalSection(title: "Data Storage & Security", body: "Your profile data, training history, preferences, and token balances are stored locally on your device using iOS secure storage. Video frames sent for AI analysis are transmitted securely via HTTPS and are processed in real-time. We do not retain your video data after analysis is complete.")

            legalSection(title: "Third-Party Services", body: "We use AI services to analyze your training videos. These services process data in real-time and do not store your images. We do not sell, trade, or share your personal information with third parties for marketing purposes.")

            legalSection(title: "Your Rights", body: "You can delete all your data at any time by using the \"Delete Account\" option in the app. This permanently removes all locally stored profile data, training history, preferences, and token balances. Please note that deleting your account will forfeit any remaining bonus tokens.")

            legalSection(title: "Children's Privacy", body: "KickIQAICoach is suitable for users of all ages. For users under 13, we recommend parental supervision. We do not knowingly collect personally identifiable information from children under 13 without parental consent.")

            legalSection(title: "Contact Us", body: "If you have questions about this Privacy Policy, contact us at:\ncontact@m5cairo.com")
        }
    }

    private var termsOfUseContent: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.md) {
            legalSection(title: "Acceptance of Terms", body: "By downloading, installing, or using KickIQAICoach, you agree to be bound by these Terms of Use. If you do not agree to these terms, do not use the App.")

            legalSection(title: "Description of Service", body: "KickIQAICoach is an AI-powered soccer coaching application that analyzes training videos and provides feedback, skill scores, and drill recommendations. The App is designed to supplement — not replace — professional coaching.")

            legalSection(title: "Subscription Terms", body: """
• KickIQAICoach offers auto-renewable subscriptions: Weekly ($6.99/week), Monthly ($19.99/month), and Annual ($99.99/year).
• The Annual plan includes a 3-day free trial.
• Payment is charged to your Apple ID account at confirmation of purchase.
• Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period.
• You can manage and cancel subscriptions in your App Store account settings.
• No refunds are provided for partial subscription periods.
""")

            legalSection(title: "Token Packs (Consumable Purchases)", body: """
• KickIQAICoach offers consumable token packs that provide bonus AI coaching tokens: Small (1,000 tokens / $2.99), Medium (5,000 tokens / $9.99), and Large (20,000 tokens / $29.99).
• Token packs are one-time, non-recurring purchases charged to your Apple ID account.
• Purchased tokens are added to your bonus token balance immediately upon successful purchase.
• Bonus tokens never expire and persist until used.
• Tokens are consumed when you send messages to the AI Coach. Each message uses approximately 15 tokens.
• If a message fails to send or the AI fails to respond, no tokens are deducted for that message.
• Your daily token budget (included with your subscription tier or free plan) is used first; bonus tokens are only consumed after your daily budget is exhausted.
• Token purchases are non-refundable once tokens have been added to your account.
• Token balances are stored locally on your device. Deleting the app or your account will permanently remove your token balance.
""")

            legalSection(title: "User Conduct", body: """
You agree not to:
• Upload inappropriate, offensive, or illegal content.
• Attempt to reverse-engineer, decompile, or disassemble the App.
• Use the App for any purpose other than personal soccer training improvement.
• Share your account credentials with others.
""")

            legalSection(title: "Intellectual Property", body: "All content, features, and functionality of KickIQAICoach — including but not limited to text, graphics, logos, icons, and software — are the exclusive property of M5 Cairo and are protected by copyright and trademark laws.")

            legalSection(title: "Limitation of Liability", body: "KickIQAICoach and M5 Cairo shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of or inability to use the App.")

            legalSection(title: "Termination", body: "We reserve the right to suspend or terminate your access to the App at any time for violation of these Terms.")

            legalSection(title: "Contact", body: "For questions regarding these Terms, contact us at:\ncontact@m5cairo.com")
        }
    }

    private var eulaContent: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.md) {
            legalSection(title: "End User License Agreement", body: "This End User License Agreement (\"EULA\") is a legal agreement between you and M5 Cairo for the use of KickIQAICoach.")

            legalSection(title: "License Grant", body: "M5 Cairo grants you a limited, non-exclusive, non-transferable, revocable license to use KickIQAICoach on any Apple-branded device that you own or control, subject to the Usage Rules set forth in the Apple Media Services Terms and Conditions.")

            legalSection(title: "Restrictions", body: """
You may not:
• License, sell, rent, lease, transfer, assign, distribute, host, or otherwise commercially exploit the App.
• Modify, translate, adapt, merge, make derivative works of, disassemble, decompile, reverse compile, or reverse engineer any part of the App.
• Access the App to build a similar or competitive product or service.
""")

            legalSection(title: "Apple's Standard EULA", body: "This license is also governed by Apple's Standard Licensed Application End User License Agreement (\"Standard EULA\"), which is incorporated herein by reference. In the event of any conflict between this EULA and Apple's Standard EULA, Apple's Standard EULA shall govern. You may access Apple's Standard EULA at:\nhttps://www.apple.com/legal/internet-services/itunes/dev/stdeula/")

            legalSection(title: "Maintenance and Support", body: "M5 Cairo is solely responsible for providing maintenance and support services for KickIQAICoach. Apple has no obligation whatsoever to furnish any maintenance and support services with respect to the App.")

            legalSection(title: "Warranty", body: "The App is provided \"as is\" without warranty of any kind. M5 Cairo disclaims all warranties, express or implied, including but not limited to implied warranties of merchantability and fitness for a particular purpose.")

            legalSection(title: "Contact", body: "For questions about this EULA, contact us at:\ncontact@m5cairo.com")
        }
    }

    private var disclaimerContent: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.md) {
            legalSection(title: "AI Analysis Disclaimer", body: "KickIQAICoach uses artificial intelligence to analyze training videos and provide feedback. AI analysis is not perfect and should be used as a supplementary tool alongside professional coaching. Results may vary based on video quality, angle, lighting, and other factors.")

            legalSection(title: "Not Professional Medical Advice", body: "KickIQAICoach does not provide medical advice. The App's feedback and drill recommendations are for training improvement purposes only. Always consult a qualified healthcare provider before starting any new exercise program, especially if you have pre-existing medical conditions or injuries.")

            legalSection(title: "Not a Substitute for Professional Coaching", body: "KickIQAICoach is designed to supplement your training, not replace qualified coaching. The AI feedback should be considered alongside guidance from certified coaches, trainers, and sports professionals.")

            legalSection(title: "Accuracy of Results", body: "While we strive for accuracy, the skill scores and feedback provided by KickIQAICoach are estimates based on AI analysis of visual data. They should not be considered definitive assessments of athletic ability or potential.")

            legalSection(title: "Testimonials", body: "Testimonials displayed in the App represent individual experiences and are not guaranteed outcomes. Individual results may vary significantly based on dedication, physical condition, existing skill level, and other factors.")

            legalSection(title: "Contact", body: "Questions about these disclaimers? Contact us at:\ncontact@m5cairo.com")
        }
    }

    private var risksContent: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.md) {
            legalSection(title: "Physical Activity Risks", body: "Soccer training involves physical activity that carries inherent risks of injury. By using KickIQAICoach and following its drill recommendations, you acknowledge and accept these risks. Always warm up properly before training and stop immediately if you experience pain or discomfort.")

            legalSection(title: "Training Safety Guidelines", body: """
• Always warm up for at least 10 minutes before performing drills.
• Train on appropriate surfaces — avoid wet, uneven, or hazardous terrain.
• Wear proper footwear and protective equipment as needed.
• Stay hydrated before, during, and after training.
• Do not train through pain or injury.
• Adjust drill intensity to match your current fitness level.
• Supervise minors during training at all times.
""")

            legalSection(title: "Environmental Considerations", body: "Be aware of your training environment. Avoid training in extreme heat or cold, during storms, or in poorly lit areas. Ensure your training space is clear of obstacles and hazards.")

            legalSection(title: "Age Considerations", body: "Young athletes (under 16) should train under adult supervision. Training intensity and volume should be age-appropriate. Consult with a pediatric sports medicine professional if you have concerns about youth training loads.")

            legalSection(title: "Assumption of Risk", body: "By using KickIQAICoach, you assume full responsibility for any risks, injuries, or damages resulting from following the App's training recommendations. You agree to hold M5 Cairo harmless from any claims arising from your use of the App.")

            legalSection(title: "Emergency Contact", body: "In case of injury during training, contact emergency services immediately. For non-emergency questions, contact us at:\ncontact@m5cairo.com")
        }
    }

    private func legalSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            Text(title)
                .font(.headline)
                .foregroundStyle(KickIQAICoachTheme.textPrimary)

            Text(body)
                .font(.subheadline)
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
                .lineSpacing(4)
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
    }
}
