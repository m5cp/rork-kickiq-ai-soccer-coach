import SwiftUI
import RevenueCat

struct TokenPacksView: View {
    let storage: StorageService
    var storeVM: StoreViewModel
    let showSubscriptionUpsell: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false
    @State private var purchaseSuccess = false

    var body: some View {
        NavigationStack {
            ZStack {
                KickIQAICoachTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: KickIQAICoachTheme.Spacing.lg) {
                        headerSection
                        currentBalanceCard
                        packagesSection

                        if showSubscriptionUpsell {
                            subscriptionUpsell
                        }

                        infoSection
                    }
                    .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                    .padding(.bottom, KickIQAICoachTheme.Spacing.xl)
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    }
                }
            }
            .alert("Error", isPresented: .init(
                get: { storeVM.error != nil },
                set: { if !$0 { storeVM.error = nil } }
            )) {
                Button("OK") { storeVM.error = nil }
            } message: {
                Text(storeVM.error ?? "")
            }
            .overlay {
                if purchaseSuccess {
                    successOverlay
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appeared = true }
        }
    }

    private var headerSection: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.md) {
            Spacer().frame(height: 10)

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.orange.opacity(0.3), .orange.opacity(0.02)],
                            center: .center,
                            startRadius: 15,
                            endRadius: 60
                        )
                    )
                    .frame(width: 110, height: 110)

                Image(systemName: "bolt.badge.plus.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.orange)
                    .symbolEffect(.bounce, value: appeared)
            }

            VStack(spacing: 6) {
                Text("TOKEN PACKS")
                    .font(.system(.title2, design: .default, weight: .black))
                    .tracking(2)
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)

                Text("Extra coaching when you need it")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
    }

    private var currentBalanceCard: some View {
        HStack(spacing: KickIQAICoachTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text("CURRENT BALANCE")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(formattedBalance)
                        .font(.system(.title, design: .default, weight: .black))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    Text("bonus tokens")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(.orange.opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.orange)
            }
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                .fill(KickIQAICoachTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                        .stroke(.orange.opacity(0.2), lineWidth: 1)
                )
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.1), value: appeared)
    }

    private var packagesSection: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            if storeVM.isLoading {
                ProgressView()
                    .frame(height: 200)
            } else if storeVM.tokenPackPackages.isEmpty {
                VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                    tokenPackCard(
                        title: "100K Tokens",
                        subtitle: "~60 coaching messages",
                        price: "$2.99",
                        icon: "bolt.fill",
                        color: .blue,
                        packSize: .small,
                        package: nil
                    )
                    tokenPackCard(
                        title: "500K Tokens",
                        subtitle: "~300 coaching messages",
                        price: "$9.99",
                        icon: "bolt.badge.plus.fill",
                        color: .purple,
                        packSize: .medium,
                        package: nil
                    )
                    tokenPackCard(
                        title: "2M Tokens",
                        subtitle: "~1,200 coaching messages",
                        price: "$29.99",
                        icon: "bolt.shield.fill",
                        color: .orange,
                        packSize: .large,
                        package: nil
                    )
                }
            } else {
                ForEach(storeVM.tokenPackPackages, id: \.identifier) { package in
                    let info = packInfo(for: package)
                    tokenPackCard(
                        title: info.title,
                        subtitle: info.subtitle,
                        price: package.storeProduct.localizedPriceString,
                        icon: info.icon,
                        color: info.color,
                        packSize: info.packSize,
                        package: package
                    )
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.15), value: appeared)
    }

    private func tokenPackCard(title: String, subtitle: String, price: String, icon: String, color: Color, packSize: TokenPackSize, package: Package?) -> some View {
        Button {
            guard let package else { return }
            Task {
                let success = await storeVM.purchaseTokenPack(package: package, storage: storage)
                if success {
                    withAnimation(.spring(response: 0.4)) {
                        purchaseSuccess = true
                    }
                    try? await Task.sleep(for: .seconds(2))
                    withAnimation { purchaseSuccess = false }
                }
            }
        } label: {
            HStack(spacing: KickIQAICoachTheme.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline.weight(.black))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    Text(subtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }

                Spacer()

                if storeVM.isPurchasing {
                    ProgressView()
                } else {
                    Text(price)
                        .font(.headline.weight(.black))
                        .foregroundStyle(color)
                }
            }
            .padding(KickIQAICoachTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                    .fill(KickIQAICoachTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                            .stroke(color.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .disabled(storeVM.isPurchasing || package == nil)
        .sensoryFeedback(.impact(weight: .medium), trigger: purchaseSuccess)
    }

    private var subscriptionUpsell: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.md) {
            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                Image(systemName: "crown.fill")
                    .font(.headline)
                    .foregroundStyle(KickIQAICoachTheme.accent)
                Text("BETTER VALUE WITH PREMIUM")
                    .font(.caption.weight(.black))
                    .tracking(1)
                    .foregroundStyle(KickIQAICoachTheme.accent)
                Spacer()
            }

            VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
                comparisonRow(icon: "bolt.fill", text: "75K tokens daily (free: 10K)")
                comparisonRow(icon: "infinity", text: "Resets every day automatically")
                comparisonRow(icon: "dollarsign.circle.fill", text: "Way cheaper than token packs")
            }

            Text("Premium gives you 2.25M tokens/month — that's 4x the large token pack, every month.")
                .font(.caption.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                .fill(KickIQAICoachTheme.accent.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                        .stroke(KickIQAICoachTheme.accent.opacity(0.2), lineWidth: 1)
                )
        )
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.5).delay(0.2), value: appeared)
    }

    private func comparisonRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(KickIQAICoachTheme.accent)
                .frame(width: 20)
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
        }
    }

    private var infoSection: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.caption)
                Text("HOW TOKENS WORK")
                    .font(.caption.weight(.bold))
                    .tracking(1)
            }
            .foregroundStyle(KickIQAICoachTheme.textSecondary)

            VStack(alignment: .leading, spacing: 6) {
                infoRow("Each AI coaching message uses ~1,500 tokens")
                infoRow("Bonus tokens are used after your daily budget runs out")
                infoRow("Bonus tokens never expire — use them anytime")
                infoRow("Your daily budget resets every midnight")
            }
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.5).delay(0.25), value: appeared)
    }

    private func infoRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(KickIQAICoachTheme.textSecondary.opacity(0.3))
                .frame(width: 5, height: 5)
                .padding(.top, 6)
            Text(text)
                .font(.caption.weight(.medium))
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
        }
    }

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: KickIQAICoachTheme.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(.green.opacity(0.2))
                        .frame(width: 100, height: 100)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.green)
                        .symbolEffect(.bounce, value: purchaseSuccess)
                }

                VStack(spacing: 6) {
                    Text("TOKENS ADDED!")
                        .font(.system(.title3, design: .default, weight: .black))
                        .tracking(2)
                        .foregroundStyle(.white)

                    if let pack = storeVM.lastPurchasedTokenPack {
                        Text("+\(formattedTokenAmount(pack.tokenAmount)) tokens")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.green)
                    }
                }
            }
        }
        .transition(.opacity)
    }

    private var formattedBalance: String {
        formattedTokenAmount(storage.tokenBalance)
    }

    private func formattedTokenAmount(_ amount: Int) -> String {
        if amount >= 1_000_000 {
            return String(format: "%.1fM", Double(amount) / 1_000_000.0)
        } else if amount >= 1_000 {
            return String(format: "%.0fK", Double(amount) / 1_000.0)
        }
        return "\(amount)"
    }

    private func packInfo(for package: Package) -> (title: String, subtitle: String, icon: String, color: Color, packSize: TokenPackSize) {
        let id = package.storeProduct.productIdentifier
        switch id {
        case "kickiq_tokens_small":
            return ("100K Tokens", "~60 coaching messages", "bolt.fill", .blue, .small)
        case "kickiq_tokens_medium":
            return ("500K Tokens", "~300 coaching messages", "bolt.badge.plus.fill", .purple, .medium)
        case "kickiq_tokens_large":
            return ("2M Tokens", "~1,200 coaching messages", "bolt.shield.fill", .orange, .large)
        default:
            return (package.storeProduct.localizedTitle, "", "bolt.fill", .blue, .small)
        }
    }
}
