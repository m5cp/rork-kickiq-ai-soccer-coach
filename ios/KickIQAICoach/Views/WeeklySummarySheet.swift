import SwiftUI

struct WeeklySummarySheet: View {
    let storage: StorageService
    let summaryService: WeeklySummaryService
    @State private var summary: String?
    @State private var isGenerating = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQAICoachTheme.Spacing.lg) {
                    headerSection

                    if isGenerating {
                        loadingState
                    } else if let summary {
                        summaryContent(summary)
                    } else if let existing = storage.weeklySummary {
                        summaryContent(existing)
                    } else {
                        emptyState
                    }

                    if let error = summaryService.errorMessage {
                        Text(error)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.red)
                            .padding(KickIQAICoachTheme.Spacing.sm)
                            .background(Color.red.opacity(0.08), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.sm))
                    }

                    generateButton
                }
                .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                .padding(.bottom, KickIQAICoachTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQAICoachTheme.background.ignoresSafeArea())
            .navigationTitle("Weekly Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .font(.body.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.background)
    }

    private var headerSection: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(KickIQAICoachTheme.accent.opacity(0.15))
                    .frame(width: 64, height: 64)
                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(KickIQAICoachTheme.accent)
            }

            Text("Coach's Report")
                .font(.title3.weight(.black))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)

            Text("AI-powered weekly training analysis")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, KickIQAICoachTheme.Spacing.md)
    }

    private var loadingState: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Analyzing your training week...")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, KickIQAICoachTheme.Spacing.xl)
    }

    private func summaryContent(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.md) {
            if let date = storage.weeklySummaryDate {
                HStack {
                    Text("Generated")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    Text(date, style: .relative)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    Text("ago")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    Spacer()
                }
            }

            Text(text)
                .font(.body)
                .foregroundStyle(KickIQAICoachTheme.textPrimary.opacity(0.9))
                .lineSpacing(6)
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.xl))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(KickIQAICoachTheme.accent)
                .frame(width: 4)
                .padding(.vertical, KickIQAICoachTheme.Spacing.md)
        }
    }

    private var emptyState: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            Image(systemName: "text.document")
                .font(.system(size: 36))
                .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.4))
            Text("No summary yet")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
            Text("Generate a report to see an AI analysis\nof your training this week")
                .font(.caption.weight(.medium))
                .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, KickIQAICoachTheme.Spacing.xl)
    }

    private var generateButton: some View {
        Button {
            Task {
                isGenerating = true
                summary = await summaryService.generateSummary(storage: storage)
                isGenerating = false
            }
        } label: {
            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                if isGenerating {
                    ProgressView()
                        .tint(KickIQAICoachTheme.onAccent)
                } else {
                    Image(systemName: storage.weeklySummary != nil ? "arrow.triangle.2.circlepath" : "sparkles")
                }
                Text(isGenerating ? "Generating..." : storage.weeklySummary != nil ? "Regenerate Summary" : "Generate Summary")
            }
            .font(.headline)
            .foregroundStyle(KickIQAICoachTheme.onAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, KickIQAICoachTheme.Spacing.md)
            .background(KickIQAICoachTheme.accent, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        }
        .disabled(isGenerating)
    }
}
