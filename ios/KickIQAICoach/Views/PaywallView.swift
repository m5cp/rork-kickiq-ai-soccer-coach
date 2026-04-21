import SwiftUI
import RevenueCat

struct PaywallView: View {
    var store: StoreViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPackageIndex: Int = 0
    @State private var appeared = false

    private var sortedPackages: [Package] {
        guard let current = store.offerings?.current else { return [] }
        let order = ["$rc_annual", "$rc_monthly", "$rc_weekly"]
        return current.availablePackages.sorted { a, b in
            let aIdx = order.firstIndex(of: a.identifier) ?? 99
            let bIdx = order.firstIndex(of: b.identifier) ?? 99
            return aIdx < bIdx
        }
    }

    private func weeklyPriceString(for package: Package) -> String? {
        let product = package.storeProduct
        let price = product.price as NSDecimalNumber
        let divisor: NSDecimalNumber
        switch package.identifier {
        case "$rc_annual": divisor = NSDecimalNumber(value: 52)
        case "$rc_monthly": divisor = NSDecimalNumber(value: 4.345)
        case "$rc_weekly": divisor = NSDecimalNumber(value: 1)
        default: return nil
        }
        let weekly = price.dividing(by: divisor)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceFormatter?.locale ?? .current
        formatter.currencyCode = product.currencyCode
        return formatter.string(from: weekly)
    }

    private func savingsBadge(for package: Package) -> String? {
        switch package.identifier {
        case "$rc_annual": return "SAVE 60%"
        case "$rc_monthly": return "SAVE 30%"
        default: return nil
        }
    }

    private func subtitle(for package: Package) -> String? {
        switch package.identifier {
        case "$rc_annual":
            if let weekly = weeklyPriceString(for: package) {
                return "Just \(weekly)/week, billed yearly"
            }
            return nil
        case "$rc_monthly":
            if let weekly = weeklyPriceString(for: package) {
                return "Just \(weekly)/week, billed monthly"
            }
            return nil
        case "$rc_weekly":
            return "Billed weekly"
        default: return nil
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                KickIQAICoachTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: KickIQAICoachTheme.Spacing.lg) {
                        headerSection
                        featuresSection
                        packagesSection
                        subscribeButton
                        footerSection
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
                get: { store.error != nil },
                set: { if !$0 { store.error = nil } }
            )) {
                Button("OK") { store.error = nil }
            } message: {
                Text(store.error ?? "")
            }
            .onChange(of: store.isPremium) { _, isPremium in
                if isPremium { dismiss() }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appeared = true }
            AnalyticsService.shared.track(.paywallShown)
        }
        .onDisappear {
            if !store.isPremium {
                AnalyticsService.shared.track(.paywallDismissed)
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.md) {
            Spacer().frame(height: 10)

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [KickIQAICoachTheme.accent.opacity(0.3), KickIQAICoachTheme.accent.opacity(0.02)],
                            center: .center,
                            startRadius: 15,
                            endRadius: 60
                        )
                    )
                    .frame(width: 110, height: 110)

                Image(systemName: "crown.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(KickIQAICoachTheme.accent)
                    .symbolEffect(.bounce, value: appeared)
            }

            VStack(spacing: 6) {
                Text("KICKIQ PREMIUM")
                    .font(.system(.title2, design: .default, weight: .black))
                    .tracking(2)
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)

                Text("7.5x more coaching · 22.5K tokens/month")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
    }

    private var featuresSection: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.sm + 2) {
            featureRow(icon: "brain.head.profile.fill", title: "7.5x More AI Coaching", subtitle: "750 tokens/day vs 100 free")
            featureRow(icon: "bolt.fill", title: "Daily Token Reset", subtitle: "Fresh tokens every midnight")
            featureRow(icon: "chart.line.uptrend.xyaxis", title: "Advanced Progress Insights", subtitle: "Deep analytics and trends")
            featureRow(icon: "doc.text.fill", title: "Custom Training Plans", subtitle: "AI-generated multi-week plans")
            featureRow(icon: "crown.fill", title: "Priority Support", subtitle: "Get help when you need it")
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.1), value: appeared)
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: KickIQAICoachTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(KickIQAICoachTheme.accent.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(KickIQAICoachTheme.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.subheadline)
                .foregroundStyle(KickIQAICoachTheme.accent)
        }
        .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
        .padding(.vertical, KickIQAICoachTheme.Spacing.sm + 2)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
    }

    private var packagesSection: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            if store.isLoading {
                ProgressView()
                    .frame(height: 100)
            } else {
                ForEach(Array(sortedPackages.enumerated()), id: \.element.identifier) { index, package in
                    packageCard(package, index: index)
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.15), value: appeared)
    }

    private func packageCard(_ package: Package, index: Int) -> some View {
        let isSelected = selectedPackageIndex == index
        let isAnnual = package.identifier == "$rc_annual"

        return Button {
            withAnimation(.spring(response: 0.3)) {
                selectedPackageIndex = index
            }
        } label: {
            HStack(spacing: KickIQAICoachTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? KickIQAICoachTheme.accent : KickIQAICoachTheme.divider, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Circle()
                            .fill(KickIQAICoachTheme.accent)
                            .frame(width: 14, height: 14)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(package.storeProduct.localizedTitle)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(KickIQAICoachTheme.textPrimary)

                        if let savings = savingsBadge(for: package) {
                            Text(savings)
                                .font(.system(size: 9, weight: .black))
                                .tracking(0.5)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green, in: Capsule())
                        }
                        if isAnnual {
                            Text("BEST VALUE")
                                .font(.system(size: 9, weight: .black))
                                .tracking(0.5)
                                .foregroundStyle(KickIQAICoachTheme.onAccent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(KickIQAICoachTheme.accent, in: Capsule())
                        }
                    }

                    if let sub = subtitle(for: package) {
                        Text(sub)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    }

                    if let intro = package.storeProduct.introductoryDiscount {
                        Text("Free for \(intro.subscriptionPeriod.value) \(intro.subscriptionPeriod.unit)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                    }
                }

                Spacer()

                Text(package.storeProduct.localizedPriceString)
                    .font(.headline.weight(.black))
                    .foregroundStyle(isSelected ? KickIQAICoachTheme.accent : KickIQAICoachTheme.textPrimary)
            }
            .padding(KickIQAICoachTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                    .fill(isSelected ? KickIQAICoachTheme.accent.opacity(0.1) : KickIQAICoachTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                            .stroke(isSelected ? KickIQAICoachTheme.accent : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .sensoryFeedback(.selection, trigger: selectedPackageIndex)
    }

    private var subscribeButton: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            Button {
                guard !sortedPackages.isEmpty, selectedPackageIndex < sortedPackages.count else { return }
                let package = sortedPackages[selectedPackageIndex]
                Task { await store.purchase(package: package) }
            } label: {
                HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                    if store.isPurchasing {
                        ProgressView()
                            .tint(KickIQAICoachTheme.onAccent)
                    } else {
                        Text("Subscribe Now")
                            .font(.headline.weight(.black))
                    }
                }
                .foregroundStyle(KickIQAICoachTheme.onAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, KickIQAICoachTheme.Spacing.md)
                .background(KickIQAICoachTheme.accent, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
                .shadow(color: KickIQAICoachTheme.accent.opacity(0.3), radius: 12, y: 4)
            }
            .disabled(store.isPurchasing || sortedPackages.isEmpty)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.5).delay(0.2), value: appeared)
    }

    private var footerSection: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            Button {
                Task { await store.restore() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Restore Purchases")
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(KickIQAICoachTheme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, KickIQAICoachTheme.Spacing.md)
                .background(KickIQAICoachTheme.accent.opacity(0.1), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                        .stroke(KickIQAICoachTheme.accent.opacity(0.3), lineWidth: 1)
                )
            }

            Button {
                dismiss()
            } label: {
                Text("Continue with Free Version")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, KickIQAICoachTheme.Spacing.md)
            }

            Text("Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period. Manage in Settings > Apple ID > Subscriptions.")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.5).delay(0.25), value: appeared)
    }
}
