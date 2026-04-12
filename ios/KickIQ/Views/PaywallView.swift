import SwiftUI
import RevenueCat

struct PaywallView: View {
    var store: StoreViewModel
    var userRole: UserRole = .player
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPackage: Package?
    @State private var appeared = false

    private var isCoach: Bool { userRole == .coach }

    var body: some View {
        NavigationStack {
            Group {
                if store.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(KickIQTheme.background)
                } else if let current = store.offerings?.current {
                    paywallContent(offering: current)
                } else {
                    ContentUnavailableView(
                        "Unable to Load",
                        systemImage: "exclamationmark.triangle",
                        description: Text("Check your connection and try again.")
                    )
                    .background(KickIQTheme.background)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(KickIQTheme.textSecondary)
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
    }

    private func paywallContent(offering: Offering) -> some View {
        ScrollView {
            VStack(spacing: KickIQTheme.Spacing.lg) {
                headerSection

                featuresGrid

                packagesSection(offering: offering)

                subscribeButton

                restoreAndLegal
            }
            .padding(.bottom, KickIQTheme.Spacing.xl)
        }
        .scrollIndicators(.hidden)
        .background(KickIQTheme.background.ignoresSafeArea())
        .onAppear {
            if selectedPackage == nil {
                let annualPkg = offering.availablePackages.first { $0.identifier == "$rc_annual" }
                selectedPackage = annualPkg ?? offering.availablePackages.first
            }
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
    }

    private var headerSection: some View {
        VStack(spacing: KickIQTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [KickIQTheme.accent.opacity(0.3), KickIQTheme.accent.opacity(0.05)],
                            center: .center,
                            startRadius: 10,
                            endRadius: 60
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: isCoach ? "whistle.fill" : "bolt.shield.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(KickIQTheme.accent)
                    .symbolEffect(.bounce, value: appeared)
            }

            Text(isCoach ? "UNLOCK COACH PRO" : "UNLOCK KICKIQ PRO")
                .font(.system(.title2, design: .default, weight: .black).width(.compressed))
                .tracking(2)
                .foregroundStyle(KickIQTheme.textPrimary)

            Text(isCoach ? "AI-powered tools for your entire team" : "Train smarter with premium AI coaching")
                .font(.subheadline)
                .foregroundStyle(KickIQTheme.textSecondary)
        }
        .padding(.top, KickIQTheme.Spacing.lg)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
    }

    private var featuresGrid: some View {
        VStack(spacing: 10) {
            if isCoach {
                HStack(spacing: 10) {
                    featureItem(icon: "person.3.fill", title: "Players", free: "Unlimited", pro: "Unlimited")
                    featureItem(icon: "brain.head.profile.fill", title: "AI Chat", free: "10/day", pro: "Up to 500/day")
                }
                HStack(spacing: 10) {
                    featureItem(icon: "video.fill", title: "AI Analysis", free: "2/day", pro: "Up to 100/day")
                    featureItem(icon: "chart.bar.doc.horizontal.fill", title: "Reports", free: "Basic", pro: "Full + Export")
                }
            } else {
                HStack(spacing: 10) {
                    featureItem(icon: "brain.head.profile.fill", title: "AI Chat", free: "10/day", pro: "Up to 500/day")
                    featureItem(icon: "video.fill", title: "Video Analysis", free: "2/day", pro: "Up to 100/day")
                }
                HStack(spacing: 10) {
                    featureItem(icon: "figure.soccer", title: "Custom Drills", free: "Basic", pro: "Advanced")
                    featureItem(icon: "chart.line.uptrend.xyaxis", title: "Progress", free: "Limited", pro: "Full Access")
                }
            }
        }
        .padding(.horizontal, KickIQTheme.Spacing.md)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.1), value: appeared)
    }

    private func featureItem(icon: String, title: String, free: String, pro: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(KickIQTheme.accent)
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(KickIQTheme.textPrimary)
            }

            HStack(spacing: 4) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.red.opacity(0.6))
                Text(free)
                    .font(.system(size: 10))
                    .foregroundStyle(KickIQTheme.textSecondary)
            }

            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.green)
                Text(pro)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(KickIQTheme.textPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(KickIQTheme.Spacing.sm + 4)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
    }

    private func packagesSection(offering: Offering) -> some View {
        VStack(spacing: 10) {
            ForEach(sortedPackages(offering.availablePackages), id: \.identifier) { package in
                packageCard(package: package)
            }
        }
        .padding(.horizontal, KickIQTheme.Spacing.md)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.5).delay(0.15), value: appeared)
    }

    private func sortedPackages(_ packages: [Package]) -> [Package] {
        let order = ["$rc_annual", "$rc_monthly", "$rc_weekly"]
        return packages.sorted { a, b in
            let ai = order.firstIndex(of: a.identifier) ?? 99
            let bi = order.firstIndex(of: b.identifier) ?? 99
            return ai < bi
        }
    }

    private func packageCard(package: Package) -> some View {
        let isSelected = selectedPackage?.identifier == package.identifier
        let isAnnual = package.identifier == "$rc_annual"
        let product = package.storeProduct

        return Button {
            withAnimation(.spring(response: 0.3)) {
                selectedPackage = package
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: KickIQTheme.Spacing.sm) {
                        Text(product.localizedTitle)
                            .font(.headline)
                            .foregroundStyle(KickIQTheme.textPrimary)

                        if isAnnual {
                            Text("BEST VALUE")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(KickIQTheme.accent, in: Capsule())
                        }
                    }

                    Text(periodDescription(for: package))
                        .font(.caption)
                        .foregroundStyle(KickIQTheme.textSecondary)

                    if let intro = product.introductoryDiscount {
                        Text(introText(intro))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(KickIQTheme.accent)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.localizedPriceString)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(KickIQTheme.textPrimary)
                    Text(periodLabel(for: package))
                        .font(.caption2)
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
            }
            .padding(KickIQTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                    .fill(isSelected ? KickIQTheme.accent.opacity(0.12) : KickIQTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                            .stroke(isSelected ? KickIQTheme.accent : KickIQTheme.divider, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    private func periodDescription(for package: Package) -> String {
        if isCoach {
            switch package.identifier {
            case "$rc_annual": return "500 AI chats/day · 100 analyses · Full reports"
            case "$rc_monthly": return "150 AI chats/day · 30 analyses · Full reports"
            case "$rc_weekly": return "50 AI chats/day · 10 analyses · Basic reports"
            default: return ""
            }
        } else {
            switch package.identifier {
            case "$rc_annual": return "500 AI chats/day · 100 analyses · All features"
            case "$rc_monthly": return "150 AI chats/day · 30 analyses · All features"
            case "$rc_weekly": return "50 AI chats/day · 10 analyses · All features"
            default: return ""
            }
        }
    }

    private func periodLabel(for package: Package) -> String {
        switch package.identifier {
        case "$rc_annual": return "per year"
        case "$rc_monthly": return "per month"
        case "$rc_weekly": return "per week"
        default: return ""
        }
    }

    private func introText(_ discount: StoreProductDiscount) -> String {
        let value = discount.subscriptionPeriod.value
        let unit: String
        switch discount.subscriptionPeriod.unit {
        case .day: unit = value == 1 ? "day" : "days"
        case .week: unit = value == 1 ? "week" : "weeks"
        case .month: unit = value == 1 ? "month" : "months"
        case .year: unit = value == 1 ? "year" : "years"
        @unknown default: unit = "period"
        }
        return "\(value)-\(unit) free trial"
    }

    private var subscribeButton: some View {
        VStack(spacing: KickIQTheme.Spacing.sm) {
            Button {
                guard let pkg = selectedPackage else { return }
                Task { await store.purchase(package: pkg) }
            } label: {
                Group {
                    if store.isPurchasing {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Text(subscribeButtonText)
                            .font(.headline)
                            .foregroundStyle(.black)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, KickIQTheme.Spacing.md)
                .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
            }
            .disabled(store.isPurchasing || selectedPackage == nil)
            .padding(.horizontal, KickIQTheme.Spacing.md)
            .sensoryFeedback(.impact(weight: .medium), trigger: store.isPurchasing)

            if let pkg = selectedPackage {
                billingDisclosure(for: pkg)
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.5).delay(0.2), value: appeared)
    }

    private var subscribeButtonText: String {
        guard let pkg = selectedPackage else { return "Subscribe" }
        if pkg.storeProduct.introductoryDiscount != nil {
            return "Start Free Trial"
        }
        return "Subscribe Now"
    }

    private func billingDisclosure(for package: Package) -> some View {
        Group {
            if let intro = package.storeProduct.introductoryDiscount {
                let trialText = introText(intro)
                Text("After the \(trialText), auto-renews at \(package.storeProduct.localizedPriceString)\(periodLabel(for: package).isEmpty ? "" : "/\(periodSuffix(for: package))").")
                    .font(.caption2)
                    .foregroundStyle(KickIQTheme.textSecondary.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, KickIQTheme.Spacing.lg)
            } else {
                Text("Auto-renews at \(package.storeProduct.localizedPriceString)/\(periodSuffix(for: package)). Cancel anytime in Settings > Subscriptions.")
                    .font(.caption2)
                    .foregroundStyle(KickIQTheme.textSecondary.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, KickIQTheme.Spacing.lg)
            }
        }
    }

    private func periodSuffix(for package: Package) -> String {
        switch package.identifier {
        case "$rc_annual": return "year"
        case "$rc_monthly": return "month"
        case "$rc_weekly": return "week"
        default: return "period"
        }
    }

    private var restoreAndLegal: some View {
        VStack(spacing: KickIQTheme.Spacing.sm) {
            Button {
                Task { await store.restore() }
            } label: {
                Text("Restore Purchases")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(KickIQTheme.textSecondary)
            }

            HStack(spacing: KickIQTheme.Spacing.md) {
                NavigationLink("Privacy Policy") {
                    LegalPageView(page: .privacyPolicy)
                }
                Text("·").foregroundStyle(KickIQTheme.textSecondary.opacity(0.4))
                NavigationLink("Terms of Service") {
                    LegalPageView(page: .termsOfUse)
                }
            }
            .font(.caption2)
            .foregroundStyle(KickIQTheme.textSecondary.opacity(0.5))
        }
        .padding(.bottom, KickIQTheme.Spacing.lg)
    }
}
