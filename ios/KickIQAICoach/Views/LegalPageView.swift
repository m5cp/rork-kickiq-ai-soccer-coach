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

    var subtitle: String {
        switch self {
        case .privacyPolicy: "How we handle your data"
        case .termsOfUse: "The rules for using KickIQ"
        case .eula: "Your software license"
        case .disclaimer: "Important things to know"
        case .risks: "Train safely, train smart"
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

    var accent: Color {
        switch self {
        case .privacyPolicy: .blue
        case .termsOfUse: .indigo
        case .eula: .purple
        case .disclaimer: .orange
        case .risks: .red
        }
    }

    var lastUpdated: String { "April 12, 2026" }
}

nonisolated struct LegalSectionItem: Identifiable, Sendable {
    let id = UUID()
    let icon: String
    let title: String
    let body: String?
    let bullets: [String]

    init(icon: String, title: String, body: String? = nil, bullets: [String] = []) {
        self.icon = icon
        self.title = title
        self.body = body
        self.bullets = bullets
    }
}

struct LegalPageView: View {
    let page: LegalPage

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.lg) {
                hero

                VStack(spacing: KickIQAICoachTheme.Spacing.md) {
                    ForEach(sections) { section in
                        sectionCard(section)
                    }
                }

                footer
            }
            .padding(KickIQAICoachTheme.Spacing.md)
            .padding(.bottom, KickIQAICoachTheme.Spacing.xl)
        }
        .scrollIndicators(.hidden)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.md) {
            HStack(alignment: .top, spacing: KickIQAICoachTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(page.accent.opacity(0.15))
                        .frame(width: 64, height: 64)
                    Image(systemName: page.icon)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(page.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(page.title)
                        .font(.title2.weight(.black))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    Text(page.subtitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 10, weight: .bold))
                Text("Updated \(page.lastUpdated)")
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(page.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(page.accent.opacity(0.12), in: Capsule())
        }
        .padding(KickIQAICoachTheme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [page.accent.opacity(0.12), page.accent.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: .rect(cornerRadius: KickIQAICoachTheme.Radius.xl)
        )
        .overlay(
            RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.xl)
                .stroke(page.accent.opacity(0.18), lineWidth: 1)
        )
    }

    // MARK: - Section Card

    private func sectionCard(_ section: LegalSectionItem) -> some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm + 2) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(page.accent.opacity(0.14))
                        .frame(width: 34, height: 34)
                    Image(systemName: section.icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(page.accent)
                }

                Text(section.title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }

            Rectangle()
                .fill(page.accent.opacity(0.15))
                .frame(height: 1)

            if let body = section.body, !body.isEmpty {
                Text(body)
                    .font(.subheadline)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !section.bullets.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(section.bullets.enumerated()), id: \.offset) { _, bullet in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(page.accent)
                                .padding(.top, 2)
                            Text(bullet)
                                .font(.subheadline)
                                .foregroundStyle(KickIQAICoachTheme.textSecondary)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding(KickIQAICoachTheme.Spacing.md + 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 6) {
            Image(systemName: "envelope.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(page.accent)
            Text("Questions?")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
            Text("contact@m5cairo.com")
                .font(.caption.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(KickIQAICoachTheme.Spacing.md)
    }

    // MARK: - Content

    private var sections: [LegalSectionItem] {
        switch page {
        case .privacyPolicy: return privacyPolicySections
        case .termsOfUse: return termsOfUseSections
        case .eula: return eulaSections
        case .disclaimer: return disclaimerSections
        case .risks: return risksSections
        }
    }

    private var privacyPolicySections: [LegalSectionItem] {
        [
            LegalSectionItem(
                icon: "info.circle.fill",
                title: "Introduction",
                body: "KickIQAICoach (\"the App\") is operated by M5 Cairo (\"we\", \"us\", \"our\"). We are committed to protecting your privacy and personal information. This Privacy Policy explains how we collect, use, and safeguard your data when you use the App."
            ),
            LegalSectionItem(
                icon: "tray.full.fill",
                title: "Information We Collect",
                bullets: [
                    "Profile Information: Name, position, skill level, age range, and weakness preferences you provide during onboarding and profile setup.",
                    "Training Data: Video frames and images you upload for AI analysis. These are processed in real-time and are not stored on our servers after analysis is complete.",
                    "Usage Data: App interaction data including session counts, streak data, drill completion, XP points, and token balances stored locally on your device.",
                    "Purchase Data: Records of in-app purchases including subscriptions and token packs, managed through Apple's App Store.",
                    "Profile Photos: If you choose to upload a profile photo, it is stored locally on your device only."
                ]
            ),
            LegalSectionItem(
                icon: "wand.and.stars",
                title: "How We Use Your Information",
                bullets: [
                    "To provide AI-powered soccer coaching feedback based on your uploaded training clips.",
                    "To personalize drill recommendations based on your position, skill level, and identified weaknesses.",
                    "To track your training progress, streaks, and milestones.",
                    "To improve the quality and accuracy of our AI analysis over time."
                ]
            ),
            LegalSectionItem(
                icon: "lock.fill",
                title: "Data Storage & Security",
                body: "Your profile data, training history, preferences, and token balances are stored locally on your device using iOS secure storage. Video frames sent for AI analysis are transmitted securely via HTTPS and are processed in real-time. We do not retain your video data after analysis is complete."
            ),
            LegalSectionItem(
                icon: "network",
                title: "Third-Party Services",
                body: "We use AI services to analyze your training videos. These services process data in real-time and do not store your images. We do not sell, trade, or share your personal information with third parties for marketing purposes."
            ),
            LegalSectionItem(
                icon: "person.crop.circle.badge.checkmark",
                title: "Your Rights",
                body: "You can delete all your data at any time by using the \"Delete Account\" option in the app. This permanently removes all locally stored profile data, training history, preferences, and token balances. Please note that deleting your account will forfeit any remaining bonus tokens."
            ),
            LegalSectionItem(
                icon: "figure.2.and.child.holdinghands",
                title: "Children's Privacy",
                body: "KickIQAICoach is suitable for users of all ages. For users under 13, we recommend parental supervision. We do not knowingly collect personally identifiable information from children under 13 without parental consent."
            )
        ]
    }

    private var termsOfUseSections: [LegalSectionItem] {
        [
            LegalSectionItem(
                icon: "hand.raised.fill",
                title: "Acceptance of Terms",
                body: "By downloading, installing, or using KickIQAICoach, you agree to be bound by these Terms of Use. If you do not agree to these terms, do not use the App."
            ),
            LegalSectionItem(
                icon: "sparkles",
                title: "Description of Service",
                body: "KickIQAICoach is a training organization and tracking app. It sorts, schedules, and tracks soccer drills and conditioning workouts that have been recommended to you by your own coaches, trainers, or trusted sources. It is designed to supplement — not replace — professional coaching."
            ),
            LegalSectionItem(
                icon: "creditcard.fill",
                title: "Subscription Terms",
                bullets: [
                    "KickIQAICoach offers auto-renewable subscriptions: Weekly ($6.99/week), Monthly ($19.99/month), and Annual ($99.99/year).",
                    "The Annual plan includes a 3-day free trial.",
                    "Payment is charged to your Apple ID account at confirmation of purchase.",
                    "Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period.",
                    "You can manage and cancel subscriptions in your App Store account settings.",
                    "No refunds are provided for partial subscription periods."
                ]
            ),
            LegalSectionItem(
                icon: "bolt.fill",
                title: "Token Packs (Consumable Purchases)",
                bullets: [
                    "KickIQAICoach offers consumable token packs via RevenueCat and Apple's App Store: Small (1,000 tokens / $2.99), Medium (5,000 tokens / $9.99), and Large (20,000 tokens / $29.99).",
                    "Token packs are one-time, non-recurring purchases charged to your Apple ID account.",
                    "Purchased tokens are added to your bonus token balance immediately upon successful purchase.",
                    "Bonus tokens never expire and persist until used.",
                    "Tokens are consumed when you send messages to the AI Coach. Each message uses approximately 15 tokens.",
                    "If a message fails to send or the AI fails to respond, no tokens are deducted for that message.",
                    "Your daily token budget (included with your subscription tier or free plan) is used first; bonus tokens are only consumed after your daily budget is exhausted.",
                    "Token purchases are non-refundable once tokens have been added to your account.",
                    "Token balances are stored locally on your device. Deleting the app or your account will permanently remove your token balance."
                ]
            ),
            LegalSectionItem(
                icon: "person.crop.circle.badge.xmark",
                title: "User Conduct",
                bullets: [
                    "Do not upload inappropriate, offensive, or illegal content.",
                    "Do not attempt to reverse-engineer, decompile, or disassemble the App.",
                    "Use the App only for personal soccer training improvement.",
                    "Do not share your account credentials with others."
                ]
            ),
            LegalSectionItem(
                icon: "c.circle.fill",
                title: "Intellectual Property",
                body: "All content, features, and functionality of KickIQAICoach — including but not limited to text, graphics, logos, icons, and software — are the exclusive property of M5 Cairo and are protected by copyright and trademark laws."
            ),
            LegalSectionItem(
                icon: "exclamationmark.shield.fill",
                title: "Limitation of Liability",
                body: "KickIQAICoach and M5 Cairo shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of or inability to use the App."
            ),
            LegalSectionItem(
                icon: "xmark.octagon.fill",
                title: "Termination",
                body: "We reserve the right to suspend or terminate your access to the App at any time for violation of these Terms."
            )
        ]
    }

    private var eulaSections: [LegalSectionItem] {
        [
            LegalSectionItem(
                icon: "doc.badge.gearshape.fill",
                title: "End User License Agreement",
                body: "This End User License Agreement (\"EULA\") is a legal agreement between you and M5 Cairo for the use of KickIQAICoach."
            ),
            LegalSectionItem(
                icon: "key.fill",
                title: "License Grant",
                body: "M5 Cairo grants you a limited, non-exclusive, non-transferable, revocable license to use KickIQAICoach on any Apple-branded device that you own or control, subject to the Usage Rules set forth in the Apple Media Services Terms and Conditions."
            ),
            LegalSectionItem(
                icon: "nosign",
                title: "Restrictions",
                bullets: [
                    "Do not license, sell, rent, lease, transfer, assign, distribute, host, or otherwise commercially exploit the App.",
                    "Do not modify, translate, adapt, merge, make derivative works of, disassemble, decompile, reverse compile, or reverse engineer any part of the App.",
                    "Do not use the App to build a similar or competitive product or service."
                ]
            ),
            LegalSectionItem(
                icon: "apple.logo",
                title: "Apple's Standard EULA",
                body: "This license is also governed by Apple's Standard Licensed Application End User License Agreement (\"Standard EULA\"), which is incorporated herein by reference. In the event of any conflict between this EULA and Apple's Standard EULA, Apple's Standard EULA shall govern. You may access Apple's Standard EULA at:\nhttps://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
            ),
            LegalSectionItem(
                icon: "wrench.and.screwdriver.fill",
                title: "Maintenance and Support",
                body: "M5 Cairo is solely responsible for providing maintenance and support services for KickIQAICoach. Apple has no obligation whatsoever to furnish any maintenance and support services with respect to the App."
            ),
            LegalSectionItem(
                icon: "checkmark.seal.fill",
                title: "Warranty",
                body: "The App is provided \"as is\" without warranty of any kind. M5 Cairo disclaims all warranties, express or implied, including but not limited to implied warranties of merchantability and fitness for a particular purpose."
            )
        ]
    }

    private var disclaimerSections: [LegalSectionItem] {
        [
            LegalSectionItem(
                icon: "wrench.adjustable.fill",
                title: "What KickIQ Is",
                body: "KickIQ is a tracking and organization tool. It helps you sort, schedule, and keep a record of the soccer drills, skills work, and conditioning exercises that have been recommended to you by your own coaches, trainers, and trusted sources. The app does not design training programs for you, does not replace a qualified coach, trainer, or medical professional, and does not prescribe exercise, medical, or rehabilitation advice."
            ),
            LegalSectionItem(
                icon: "stethoscope",
                title: "Consult a Physician Before You Train",
                body: "Before beginning any drill, skills session, or conditioning activity in this app, you should consult a qualified physician and obtain appropriate medical clearance — including a physical examination if recommended by your doctor. This is especially important if you are new to exercise, returning from injury or illness, are pregnant, or have any pre-existing medical condition. Do not begin any activity in the app until you have been cleared to do so."
            ),
            LegalSectionItem(
                icon: "exclamationmark.triangle.fill",
                title: "Physical Activity Carries Risk",
                body: "Soccer drills, sprints, plyometrics, strength work, and conditioning involve physical exertion and carry an inherent risk of injury. By using KickIQ, you acknowledge and accept these risks. You are fully responsible for your own safety, including proper warm-up, correct technique, appropriate footwear and equipment, a safe training environment, hydration, and stopping immediately if you feel pain, dizziness, or any symptom that concerns you."
            ),
            LegalSectionItem(
                icon: "figure.run",
                title: "You Know Your Body — Use Your Judgment",
                bullets: [
                    "Start at an intensity appropriate for your current fitness level.",
                    "Warm up thoroughly before every session and cool down afterward.",
                    "If an exercise feels unsafe or doesn't match what your coach prescribed, skip it.",
                    "Do not train through pain, injury, or unusual fatigue — stop and seek medical advice.",
                    "Follow the guidance of your own coaches and trainers over anything displayed in the app."
                ]
            ),
            LegalSectionItem(
                icon: "figure.2.and.child.holdinghands",
                title: "Minors & Supervision",
                body: "Users under 18 should train under qualified adult supervision. Parents and guardians are responsible for confirming medical clearance for minors and for making sure drills and conditioning loads are appropriate for the young athlete's age and development."
            ),
            LegalSectionItem(
                icon: "cpu.fill",
                title: "AI Feedback Is Informational Only",
                body: "Any AI analysis, skill scores, or suggested drills are informational only and are based on limited visual data. They are not a professional assessment of athletic ability, medical condition, or fitness to train. Always combine anything the AI shows you with guidance from your own coaches, trainers, and medical professionals."
            ),
            LegalSectionItem(
                icon: "hand.raised.fill",
                title: "Assumption of Risk & Release",
                body: "By using KickIQ, you assume full responsibility for any risk of injury, illness, or loss arising from your training. You agree to release and hold harmless M5 Cairo, its owners, and its staff from any claims related to your use of the app or performance of any activity tracked within it."
            )
        ]
    }

    private var risksSections: [LegalSectionItem] {
        [
            LegalSectionItem(
                icon: "figure.soccer",
                title: "Physical Activity Risks",
                body: "Soccer training involves physical activity that carries inherent risks of injury. By using KickIQAICoach and following any drills you track inside it, you acknowledge and accept these risks. Always warm up properly before training and stop immediately if you experience pain or discomfort."
            ),
            LegalSectionItem(
                icon: "checkmark.shield.fill",
                title: "Training Safety Guidelines",
                bullets: [
                    "Always warm up for at least 10 minutes before performing drills.",
                    "Train on appropriate surfaces — avoid wet, uneven, or hazardous terrain.",
                    "Wear proper footwear and protective equipment as needed.",
                    "Stay hydrated before, during, and after training.",
                    "Do not train through pain or injury.",
                    "Adjust drill intensity to match your current fitness level.",
                    "Supervise minors during training at all times."
                ]
            ),
            LegalSectionItem(
                icon: "cloud.sun.fill",
                title: "Environmental Considerations",
                body: "Be aware of your training environment. Avoid training in extreme heat or cold, during storms, or in poorly lit areas. Ensure your training space is clear of obstacles and hazards."
            ),
            LegalSectionItem(
                icon: "figure.child",
                title: "Age Considerations",
                body: "Young athletes (under 16) should train under adult supervision. Training intensity and volume should be age-appropriate. Consult with a pediatric sports medicine professional if you have concerns about youth training loads."
            ),
            LegalSectionItem(
                icon: "cross.case.fill",
                title: "Emergency",
                body: "In case of injury during training, contact emergency services immediately."
            )
        ]
    }
}
