import SwiftUI

// MARK: - Date of Birth step (used inside onboarding)

struct OnboardingDOBStep: View {
    @Binding var dateOfBirth: Date

    private let maxDate: Date = .now
    private let minDate: Date = Calendar.current.date(byAdding: .year, value: -100, to: .now) ?? .now

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("YOUR BIRTHDAY")
                        .font(.system(size: 24, weight: .black).width(.compressed))
                        .tracking(3)
                        .foregroundStyle(.white)

                    Text("So we can give you an age-appropriate experience")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)

                ZStack {
                    Circle()
                        .fill(KickIQAICoachTheme.accent.opacity(0.08))
                        .frame(width: 100, height: 100)
                    Image(systemName: "birthday.cake.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }

                DatePicker(
                    "Date of Birth",
                    selection: $dateOfBirth,
                    in: minDate...maxDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .colorScheme(.dark)
                .padding(.horizontal, 20)

                HStack(spacing: 10) {
                    Image(systemName: "lock.fill")
                        .font(.caption.weight(.bold))
                    Text("Stored privately on your device. Never shared.")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.white.opacity(0.5))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.06), in: Capsule())
            }
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - Parental Consent Screen

struct ParentalConsentView: View {
    let onConsent: (_ parentName: String, _ parentEmail: String, _ enableChat: Bool) -> Void
    let onCancel: () -> Void

    @State private var parentName: String = ""
    @State private var parentEmail: String = ""
    @State private var agreedToTerms: Bool = false
    @State private var agreedToGuardian: Bool = false
    @State private var enableChat: Bool = true
    @State private var showLegalPage: LegalPage?

    private var canSubmit: Bool {
        !parentName.trimmingCharacters(in: .whitespaces).isEmpty
            && parentEmail.contains("@") && parentEmail.contains(".")
            && agreedToTerms && agreedToGuardian
    }

    var body: some View {
        ZStack {
            OnboardingBackground()

            ScrollView {
                VStack(spacing: 20) {
                    header

                    inputFields

                    checkboxes

                    chatToggleCard

                    continueButton

                    Button {
                        onCancel()
                    } label: {
                        Text("Not a parent? Go back")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
            }
            .scrollIndicators(.hidden)
        }
        .preferredColorScheme(.dark)
        .sheet(item: $showLegalPage) { page in
            NavigationStack {
                LegalPageView(page: page)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showLegalPage = nil }.fontWeight(.bold)
                        }
                    }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.caption.weight(.bold))
                Text("FOR PARENTS ONLY")
                    .font(.system(size: 11, weight: .black))
                    .tracking(1.5)
            }
            .foregroundStyle(KickIQAICoachTheme.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(KickIQAICoachTheme.accent.opacity(0.15), in: Capsule())
            .overlay(Capsule().stroke(KickIQAICoachTheme.accent.opacity(0.4), lineWidth: 1))

            Text("Parental Consent")
                .font(.system(size: 30, weight: .black))
                .foregroundStyle(.white)

            Text("Your child is under 13. Before they can use KickIQ, we need a parent or legal guardian to confirm and agree to our terms.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var inputFields: some View {
        VStack(spacing: 12) {
            labeledField(icon: "person.fill", label: "Parent / Guardian Name", text: $parentName, placeholder: "Your full name", keyboard: .default)
            labeledField(icon: "envelope.fill", label: "Parent Email", text: $parentEmail, placeholder: "you@email.com", keyboard: .emailAddress)
        }
    }

    private func labeledField(icon: String, label: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
                Text(label)
                    .font(.caption.weight(.black))
                    .tracking(1)
            }
            .foregroundStyle(.white.opacity(0.5))

            TextField("", text: text, prompt: Text(placeholder).foregroundStyle(.white.opacity(0.25)))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .keyboardType(keyboard)
                .textContentType(keyboard == .emailAddress ? .emailAddress : .name)
                .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                .autocorrectionDisabled(keyboard == .emailAddress)
                .padding(14)
                .background(Color.white.opacity(0.05), in: .rect(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
    }

    private var checkboxes: some View {
        VStack(spacing: 10) {
            checkboxRow(isOn: $agreedToGuardian, text: "I confirm I am the parent or legal guardian of this child.")
            VStack(alignment: .leading, spacing: 8) {
                checkboxRow(isOn: $agreedToTerms, text: "I agree to the Terms of Use and Privacy Policy on behalf of my child.")
                HStack(spacing: 10) {
                    Button("Privacy Policy") { showLegalPage = .privacyPolicy }
                    Text("·").foregroundStyle(.white.opacity(0.2))
                    Button("Terms of Use") { showLegalPage = .termsOfUse }
                }
                .font(.caption2.weight(.bold))
                .foregroundStyle(KickIQAICoachTheme.accent)
                .padding(.leading, 34)
            }
        }
    }

    private func checkboxRow(isOn: Binding<Bool>, text: String) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isOn.wrappedValue ? KickIQAICoachTheme.accent : .white.opacity(0.25), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isOn.wrappedValue {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(KickIQAICoachTheme.accent)
                            .frame(width: 22, height: 22)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(.white)
                    }
                }

                Text(text)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
        }
        .sensoryFeedback(.selection, trigger: isOn.wrappedValue)
    }

    private var chatToggleCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "brain.head.profile.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Allow AI Coach Chat")
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(.white)
                    Text("Age-appropriate coaching with strict safety filters. You can change this later in Settings.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.5))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Toggle("", isOn: $enableChat)
                    .labelsHidden()
                    .tint(KickIQAICoachTheme.accent)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.04), in: .rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }

    private var continueButton: some View {
        Button {
            onConsent(parentName.trimmingCharacters(in: .whitespaces), parentEmail.trimmingCharacters(in: .whitespaces), enableChat)
        } label: {
            Text("Grant Consent & Continue")
                .font(.headline.weight(.black))
                .foregroundStyle(canSubmit ? KickIQAICoachTheme.onAccent : .white.opacity(0.3))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: canSubmit
                            ? [KickIQAICoachTheme.accent, KickIQAICoachTheme.accent.opacity(0.8)]
                            : [Color.white.opacity(0.1), Color.white.opacity(0.06)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: .rect(cornerRadius: 16)
                )
        }
        .disabled(!canSubmit)
        .padding(.top, 8)
    }
}

// MARK: - Teen Safety Notice

struct TeenSafetyNoticeView: View {
    let onContinue: () -> Void
    @State private var showLegalPage: LegalPage?

    var body: some View {
        ZStack {
            OnboardingBackground()

            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(KickIQAICoachTheme.accent.opacity(0.1))
                        .frame(width: 120, height: 120)
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }

                VStack(spacing: 12) {
                    Text("Safety First")
                        .font(.system(size: 30, weight: .black))
                        .foregroundStyle(.white)

                    Text("Because you're under 18, we've turned on extra protections automatically:")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 12) {
                    safetyRow(icon: "brain.head.profile.fill", text: "AI Coach uses age-appropriate language and stricter content filters")
                    safetyRow(icon: "chart.bar.xaxis", text: "No analytics or tracking — we don't collect usage data")
                    safetyRow(icon: "person.fill.questionmark", text: "Your profile only shows a first name or nickname — never your full identity")
                    safetyRow(icon: "exclamationmark.bubble.fill", text: "You can report anything that feels wrong, and we review within 24 hours")
                }
                .padding(18)
                .background(Color.white.opacity(0.04), in: .rect(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06), lineWidth: 1))

                Spacer()

                Button {
                    onContinue()
                } label: {
                    Text("I Understand")
                        .font(.headline.weight(.black))
                        .foregroundStyle(KickIQAICoachTheme.onAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [KickIQAICoachTheme.accent, KickIQAICoachTheme.accent.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: .rect(cornerRadius: 16)
                        )
                }

                HStack(spacing: 12) {
                    Button("Privacy Policy") { showLegalPage = .privacyPolicy }
                    Text("·").foregroundStyle(.white.opacity(0.2))
                    Button("Terms of Use") { showLegalPage = .termsOfUse }
                }
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.4))
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
        .preferredColorScheme(.dark)
        .sheet(item: $showLegalPage) { page in
            NavigationStack {
                LegalPageView(page: page)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showLegalPage = nil }.fontWeight(.bold)
                        }
                    }
            }
        }
    }

    private func safetyRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(KickIQAICoachTheme.accent.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(KickIQAICoachTheme.accent)
            }
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}
