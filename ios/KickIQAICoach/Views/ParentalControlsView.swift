import SwiftUI

struct ParentalControlsView: View {
    @State private var safety = AgeSafetyService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var chatEnabled: Bool = AgeSafetyService.shared.chatEnabledByParent
    @State private var socialEnabled: Bool = AgeSafetyService.shared.socialEnabledByParent
    @State private var parentEmail: String = AgeSafetyService.shared.parentEmail
    @State private var showRevokeAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQAICoachTheme.Spacing.md) {
                    header

                    VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                        toggleRow(icon: "brain.head.profile.fill",
                                  title: "AI Coach Chat",
                                  subtitle: "Age-appropriate coaching with strict safety filters",
                                  isOn: $chatEnabled)
                            .onChange(of: chatEnabled) { _, newValue in
                                safety.setChatEnabled(newValue)
                            }

                        toggleRow(icon: "person.2.fill",
                                  title: "Social Features",
                                  subtitle: "Sharing, reports, community interactions",
                                  isOn: $socialEnabled)
                            .onChange(of: socialEnabled) { _, newValue in
                                safety.setSocialEnabled(newValue)
                            }
                    }

                    parentEmailCard

                    revokeCard

                    Text("As the parent or guardian, you can change these settings at any time. Revoking consent will immediately remove your child's access to AI Coach and social features.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                        .padding(.horizontal, 8)
                }
                .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                .padding(.bottom, KickIQAICoachTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQAICoachTheme.background.ignoresSafeArea())
            .navigationTitle("Parental Controls")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }.fontWeight(.bold)
                }
            }
            .alert("Revoke Consent?", isPresented: $showRevokeAlert) {
                Button("Revoke", role: .destructive) {
                    safety.revokeParentalConsent()
                    chatEnabled = false
                    socialEnabled = false
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your child will lose access to AI Coach and social features. You can grant consent again later.")
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(KickIQAICoachTheme.accent.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(KickIQAICoachTheme.accent)
            }
            Text("Parental Consent Active")
                .font(.headline.weight(.black))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
            if !safety.parentName.isEmpty {
                Text("Linked to \(safety.parentName)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
    }

    private func toggleRow(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(KickIQAICoachTheme.accent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(KickIQAICoachTheme.accent)
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
    }

    private var parentEmailCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "envelope.fill")
                    .font(.caption.weight(.bold))
                Text("PARENT EMAIL")
                    .font(.caption.weight(.black))
                    .tracking(1)
            }
            .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.6))

            TextField("Parent email", text: $parentEmail)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(12)
                .background(KickIQAICoachTheme.surface, in: .rect(cornerRadius: 10))
                .onChange(of: parentEmail) { _, newValue in
                    safety.grantParentalConsent(parentName: safety.parentName, parentEmail: newValue, enableChat: safety.chatEnabledByParent)
                }
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
    }

    private var revokeCard: some View {
        Button {
            showRevokeAlert = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "xmark.shield.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.red)
                    .frame(width: 24)
                Text("Revoke Consent")
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(.red)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.red.opacity(0.3))
            }
            .padding(KickIQAICoachTheme.Spacing.md)
            .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
        }
    }
}

// MARK: - Report Content Sheet

struct ReportContentSheet: View {
    let contextLabel: String
    let onSubmit: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: String?
    @State private var details: String = ""
    @State private var didSubmit = false

    private let reasons = [
        "Inappropriate content",
        "Harmful or unsafe advice",
        "Bullying or harassment",
        "Sexual or adult content",
        "Violence or threats",
        "Spam or misleading info",
        "Something else"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                if didSubmit {
                    thankYouView
                } else {
                    VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.md) {
                        Text("What's wrong with this \(contextLabel)?")
                            .font(.title3.weight(.black))
                            .foregroundStyle(KickIQAICoachTheme.textPrimary)

                        VStack(spacing: 8) {
                            ForEach(reasons, id: \.self) { reason in
                                Button {
                                    selectedReason = reason
                                } label: {
                                    HStack {
                                        Text(reason)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(KickIQAICoachTheme.textPrimary)
                                        Spacer()
                                        if selectedReason == reason {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(KickIQAICoachTheme.accent)
                                        }
                                    }
                                    .padding(KickIQAICoachTheme.Spacing.md)
                                    .background(
                                        selectedReason == reason
                                            ? KickIQAICoachTheme.accent.opacity(0.1)
                                            : KickIQAICoachTheme.card,
                                        in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.md)
                                            .stroke(selectedReason == reason ? KickIQAICoachTheme.accent.opacity(0.5) : .clear, lineWidth: 1.5)
                                    )
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("DETAILS (OPTIONAL)")
                                .font(.caption.weight(.black))
                                .tracking(1)
                                .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.6))
                            TextField("Tell us what happened…", text: $details, axis: .vertical)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(3...6)
                                .padding(12)
                                .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: 10))
                        }

                        Text("We review reports within 24 hours. Abusive accounts are removed — zero tolerance.")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)

                        Button {
                            guard let reason = selectedReason else { return }
                            onSubmit("\(reason)\n\n\(details)")
                            withAnimation(.spring(response: 0.4)) { didSubmit = true }
                        } label: {
                            Text("Submit Report")
                                .font(.headline.weight(.black))
                                .foregroundStyle(KickIQAICoachTheme.onAccent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    (selectedReason == nil ? Color.gray : KickIQAICoachTheme.accent),
                                    in: .rect(cornerRadius: 14)
                                )
                        }
                        .disabled(selectedReason == nil)
                    }
                    .padding(KickIQAICoachTheme.Spacing.md)
                }
            }
            .background(KickIQAICoachTheme.background.ignoresSafeArea())
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var thankYouView: some View {
        VStack(spacing: 18) {
            Spacer().frame(height: 40)
            ZStack {
                Circle().fill(KickIQAICoachTheme.accent.opacity(0.12)).frame(width: 100, height: 100)
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(KickIQAICoachTheme.accent)
            }
            Text("Report Submitted")
                .font(.title2.weight(.black))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
            Text("Thank you for keeping KickIQ safe. We'll review this within 24 hours.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            Button { dismiss() } label: {
                Text("Done")
                    .font(.headline.weight(.black))
                    .foregroundStyle(KickIQAICoachTheme.onAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(KickIQAICoachTheme.accent, in: .rect(cornerRadius: 14))
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
    }
}
