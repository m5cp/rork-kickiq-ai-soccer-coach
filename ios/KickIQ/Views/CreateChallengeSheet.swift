import SwiftUI

struct CreateChallengeSheet: View {
    let teamId: String
    let storage: StorageService
    @Environment(\.dismiss) private var dismiss
    @State private var challengeService = ChallengeService.shared
    @State private var drillName: String = ""
    @State private var targetValue: String = ""
    @State private var selectedMetric: String = "touches"
    @State private var created = false

    private let metrics = ["touches", "passes", "contacts", "seconds", "reps", "consecutive"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQTheme.Spacing.lg) {
                    if created {
                        successView
                    } else {
                        formView
                    }
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .padding(.top, KickIQTheme.Spacing.md)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle(created ? "Challenge Created" : "New Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(created ? "Done" : "Cancel") { dismiss() }
                        .foregroundStyle(KickIQTheme.accent)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
    }

    private var formView: some View {
        VStack(spacing: KickIQTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(KickIQTheme.accent.opacity(0.15))
                    .frame(width: 72, height: 72)
                Image(systemName: "trophy.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(KickIQTheme.accent)
            }

            VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
                Text("DRILL NAME")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(KickIQTheme.textSecondary)
                TextField("e.g. Wall Pass Returns", text: $drillName)
                    .font(.headline)
                    .padding(KickIQTheme.Spacing.md)
                    .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
            }

            VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
                Text("TARGET SCORE")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(KickIQTheme.textSecondary)
                TextField("e.g. 47", text: $targetValue)
                    .font(.headline)
                    .keyboardType(.numberPad)
                    .padding(KickIQTheme.Spacing.md)
                    .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
            }

            VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
                Text("METRIC")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(KickIQTheme.textSecondary)

                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(metrics, id: \.self) { metric in
                            Button {
                                selectedMetric = metric
                            } label: {
                                Text(metric)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(selectedMetric == metric ? .black : KickIQTheme.textSecondary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedMetric == metric ? KickIQTheme.accent : KickIQTheme.card,
                                        in: Capsule()
                                    )
                            }
                        }
                    }
                }
                .contentMargins(.horizontal, 0)
                .scrollIndicators(.hidden)
            }

            if let error = challengeService.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Button {
                guard let value = Double(targetValue) else { return }
                Task {
                    let success = await challengeService.createChallenge(
                        teamId: teamId,
                        drillId: UUID().uuidString,
                        drillName: drillName.trimmingCharacters(in: .whitespaces),
                        targetValue: value,
                        metricType: selectedMetric
                    )
                    if success {
                        withAnimation(.spring(response: 0.4)) { created = true }
                    }
                }
            } label: {
                HStack(spacing: KickIQTheme.Spacing.sm) {
                    if challengeService.isLoading {
                        ProgressView().tint(.black)
                    }
                    Text("Create Challenge")
                }
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, KickIQTheme.Spacing.md)
                .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
            }
            .disabled(drillName.trimmingCharacters(in: .whitespaces).isEmpty || targetValue.isEmpty)
            .opacity(drillName.isEmpty || targetValue.isEmpty ? 0.5 : 1)
        }
    }

    private var successView: some View {
        VStack(spacing: KickIQTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(.green.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.green)
            }

            Text("Challenge Posted!")
                .font(.title2.weight(.bold))
                .foregroundStyle(KickIQTheme.textPrimary)

            Text("Your teammates can now see and compete in this challenge.")
                .font(.subheadline)
                .foregroundStyle(KickIQTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}
