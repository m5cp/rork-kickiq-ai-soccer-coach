import SwiftUI

struct ChallengeDetailView: View {
    let challenge: ChallengeDTO
    let teamId: String
    @State private var challengeService = ChallengeService.shared
    @State private var myScore: String = ""
    @State private var submitted = false
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: KickIQTheme.Spacing.lg) {
                challengeHeader
                submitSection
                resultsSection
            }
            .padding(.horizontal, KickIQTheme.Spacing.md)
            .padding(.bottom, KickIQTheme.Spacing.xl)
        }
        .scrollIndicators(.hidden)
        .background(KickIQTheme.background.ignoresSafeArea())
        .navigationTitle("Challenge")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await challengeService.loadResults(challengeId: challenge.id)
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
    }

    private var challengeHeader: some View {
        VStack(spacing: KickIQTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(KickIQTheme.accent.opacity(0.15))
                    .frame(width: 72, height: 72)
                Image(systemName: "trophy.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(KickIQTheme.accent)
            }

            Text(challenge.drill_name)
                .font(.title2.weight(.bold))
                .foregroundStyle(KickIQTheme.textPrimary)
                .multilineTextAlignment(.center)

            HStack(spacing: KickIQTheme.Spacing.md) {
                VStack(spacing: 2) {
                    Text("\(Int(challenge.target_value))")
                        .font(.title.weight(.black))
                        .foregroundStyle(KickIQTheme.accent)
                    Text(challenge.metric_type)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(KickIQTheme.textSecondary)
                }

                Rectangle()
                    .fill(KickIQTheme.divider)
                    .frame(width: 1, height: 40)

                VStack(spacing: 2) {
                    Text(challenge.creator_name ?? "Coach")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KickIQTheme.textPrimary)
                    Text("Created by")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(KickIQTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: KickIQTheme.Radius.xl)
                .fill(KickIQTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: KickIQTheme.Radius.xl)
                        .stroke(KickIQTheme.accent.opacity(0.25), lineWidth: 1)
                )
        )
        .opacity(appeared ? 1 : 0)
    }

    private var submitSection: some View {
        VStack(spacing: KickIQTheme.Spacing.md) {
            Text("SUBMIT YOUR SCORE")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQTheme.accent)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: KickIQTheme.Spacing.md) {
                TextField("Your score", text: $myScore)
                    .font(.headline)
                    .keyboardType(.decimalPad)
                    .padding(KickIQTheme.Spacing.md)
                    .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))

                Button {
                    guard let value = Double(myScore) else { return }
                    Task {
                        let success = await challengeService.submitResult(
                            challengeId: challenge.id,
                            teamId: teamId,
                            value: value
                        )
                        if success {
                            withAnimation(.spring(response: 0.4)) { submitted = true }
                            await challengeService.loadResults(challengeId: challenge.id)
                        }
                    }
                } label: {
                    Text("Submit")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, KickIQTheme.Spacing.lg)
                        .padding(.vertical, KickIQTheme.Spacing.md)
                        .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.md))
                }
                .disabled(myScore.isEmpty || submitted)
            }

            if submitted {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Score submitted!")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.5).delay(0.1), value: appeared)
    }

    private var resultsSection: some View {
        let results = challengeService.challengeResults[challenge.id] ?? []

        return VStack(spacing: KickIQTheme.Spacing.md) {
            Text("RESULTS")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQTheme.accent)
                .frame(maxWidth: .infinity, alignment: .leading)

            if results.isEmpty {
                VStack(spacing: KickIQTheme.Spacing.sm) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(KickIQTheme.textSecondary.opacity(0.3))
                    Text("No results yet — be the first!")
                        .font(.subheadline)
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, KickIQTheme.Spacing.xl)
            } else {
                ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                    HStack(spacing: KickIQTheme.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(index == 0 ? KickIQTheme.accent.opacity(0.2) : KickIQTheme.surface)
                                .frame(width: 36, height: 36)
                            if index == 0 {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(KickIQTheme.accent)
                            } else {
                                Text("#\(index + 1)")
                                    .font(.caption.weight(.black))
                                    .foregroundStyle(KickIQTheme.textSecondary)
                            }
                        }

                        Text(result.display_name ?? "Player")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KickIQTheme.textPrimary)

                        Spacer()

                        Text("\(Int(result.value))")
                            .font(.title3.weight(.black))
                            .foregroundStyle(index == 0 ? KickIQTheme.accent : KickIQTheme.textPrimary)
                    }
                    .padding(KickIQTheme.Spacing.md)
                    .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.5).delay(0.15), value: appeared)
    }
}
