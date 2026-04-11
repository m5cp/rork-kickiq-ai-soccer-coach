import SwiftUI

struct QRCodeShareSheet: View {
    let payload: QRSharePayload
    let title: String
    let subtitle: String
    @Environment(\.dismiss) private var dismiss
    @State private var qrImage: UIImage?
    @State private var showCopied = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQTheme.Spacing.lg) {
                    headerBadge

                    qrCodeCard

                    infoCard

                    instructionsBanner
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .padding(.bottom, KickIQTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle("Share via QR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(KickIQTheme.accent)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if let image = qrImage {
                        ShareLink(item: Image(uiImage: image), preview: SharePreview("KickIQ \(title)", image: Image(uiImage: image))) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(KickIQTheme.accent)
                        }
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
        .task {
            qrImage = QRCodeService.generateQRImage(from: payload)
        }
    }

    private var headerBadge: some View {
        VStack(spacing: KickIQTheme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(KickIQTheme.accent.opacity(0.12))
                    .frame(width: 56, height: 56)
                Image(systemName: "qrcode")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(KickIQTheme.accent)
            }

            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(KickIQTheme.textPrimary)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(KickIQTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, KickIQTheme.Spacing.md)
    }

    private var qrCodeCard: some View {
        VStack(spacing: KickIQTheme.Spacing.md) {
            if let image = qrImage {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 240, height: 240)
                    .padding(KickIQTheme.Spacing.lg)
                    .background(.white, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
            } else {
                ProgressView()
                    .frame(width: 240, height: 240)
            }

            HStack(spacing: KickIQTheme.Spacing.xs) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 9))
                Text("KICKIQ")
                    .font(.system(size: 10, weight: .black))
                    .tracking(1.5)
            }
            .foregroundStyle(KickIQTheme.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, KickIQTheme.Spacing.lg)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.xl))
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: typeIcon)
                    .font(.caption)
                    .foregroundStyle(KickIQTheme.accent)
                Text(typeLabel.uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(KickIQTheme.accent)
            }

            switch payload.type {
            case .drill:
                if let drill = payload.drill {
                    drillInfo(drill)
                }
            case .analysis, .session:
                if let session = payload.session {
                    sessionInfo(session)
                }
            case .dailyPlan:
                if let plan = payload.dailyPlan {
                    planInfo(plan)
                }
            }
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
    }

    private func drillInfo(_ drill: QRDrillPayload) -> some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.xs) {
            Text(drill.name)
                .font(.headline)
                .foregroundStyle(KickIQTheme.textPrimary)
            HStack(spacing: KickIQTheme.Spacing.sm) {
                Label(drill.duration, systemImage: "clock")
                Text("·")
                Text(drill.difficulty.rawValue)
                Text("·")
                Text(drill.targetSkill)
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(KickIQTheme.textSecondary)
        }
    }

    private func sessionInfo(_ session: QRSessionPayload) -> some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.xs) {
            HStack {
                Text("Score: \(session.overallScore)/100")
                    .font(.headline)
                    .foregroundStyle(KickIQTheme.textPrimary)
                Spacer()
                Text(session.position.rawValue)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(KickIQTheme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(KickIQTheme.accent.opacity(0.15), in: Capsule())
            }
            Text("\(session.skillScores.count) skills · \(session.drills.count) drills")
                .font(.caption.weight(.medium))
                .foregroundStyle(KickIQTheme.textSecondary)
        }
    }

    private func planInfo(_ plan: QRDailyPlanPayload) -> some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.xs) {
            Text(plan.focus)
                .font(.headline)
                .foregroundStyle(KickIQTheme.textPrimary)
            HStack(spacing: KickIQTheme.Spacing.sm) {
                Label(plan.intensity.rawValue, systemImage: plan.intensity.icon)
                Text("·")
                Text(plan.duration.label)
                Text("·")
                Label(plan.mode.rawValue, systemImage: plan.mode.icon)
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(KickIQTheme.textSecondary)
            Text("\(plan.drills.count) drills included")
                .font(.caption)
                .foregroundStyle(KickIQTheme.textSecondary.opacity(0.7))
        }
    }

    private var instructionsBanner: some View {
        HStack(spacing: KickIQTheme.Spacing.sm) {
            Image(systemName: "viewfinder")
                .font(.title3)
                .foregroundStyle(KickIQTheme.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text("How to import")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(KickIQTheme.textPrimary)
                Text("The other player opens KickIQ, taps Scan QR, and points their camera at this code.")
                    .font(.caption)
                    .foregroundStyle(KickIQTheme.textSecondary)
                    .lineSpacing(2)
            }
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.accent.opacity(0.06), in: .rect(cornerRadius: KickIQTheme.Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                .stroke(KickIQTheme.accent.opacity(0.15), lineWidth: 1)
        )
    }

    private var typeIcon: String {
        switch payload.type {
        case .drill: "figure.run"
        case .analysis, .session: "chart.bar.fill"
        case .dailyPlan: "calendar"
        }
    }

    private var typeLabel: String {
        switch payload.type {
        case .drill: "Drill"
        case .analysis, .session: "Analysis Results"
        case .dailyPlan: "Training Session"
        }
    }
}
