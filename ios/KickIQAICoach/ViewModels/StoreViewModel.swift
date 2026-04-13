import Foundation
import RevenueCat

@Observable
@MainActor
class StoreViewModel {
    var offerings: Offerings?
    var tokenPackOffering: Offering?
    var isPremium = false
    var isLoading = false
    var isPurchasing = false
    var error: String?
    var lastPurchasedTokenPack: TokenPackSize?

    init() {
        Task { await listenForUpdates() }
        Task { await fetchOfferings() }
    }

    private func listenForUpdates() async {
        for await info in Purchases.shared.customerInfoStream {
            self.isPremium = info.entitlements["premium"]?.isActive == true
        }
    }

    func fetchOfferings() async {
        isLoading = true
        do {
            offerings = try await Purchases.shared.offerings()
            tokenPackOffering = offerings?.offering(identifier: "token_packs")
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func purchase(package: Package) async {
        isPurchasing = true
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if !result.userCancelled {
                isPremium = result.customerInfo.entitlements["premium"]?.isActive == true
            }
        } catch ErrorCode.purchaseCancelledError {
        } catch ErrorCode.paymentPendingError {
        } catch {
            self.error = error.localizedDescription
        }
        isPurchasing = false
    }

    func purchaseTokenPack(package: Package, storage: StorageService) async -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await Purchases.shared.purchase(package: package)
            if !result.userCancelled {
                let identifier = package.storeProduct.productIdentifier
                let tokens = tokenAmountForIdentifier(identifier)
                if tokens > 0 {
                    storage.addTokens(tokens)
                    lastPurchasedTokenPack = tokenPackSizeForIdentifier(identifier)
                    return true
                }
            }
        } catch ErrorCode.purchaseCancelledError {
        } catch ErrorCode.paymentPendingError {
        } catch {
            self.error = error.localizedDescription
        }
        return false
    }

    func restore() async {
        do {
            let info = try await Purchases.shared.restorePurchases()
            isPremium = info.entitlements["premium"]?.isActive == true
        } catch {
            self.error = error.localizedDescription
        }
    }

    func checkStatus() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            isPremium = info.entitlements["premium"]?.isActive == true
        } catch {
            self.error = error.localizedDescription
        }
    }

    var tokenPackPackages: [Package] {
        guard let offering = tokenPackOffering else { return [] }
        let order = ["token_small", "token_medium", "token_large"]
        return offering.availablePackages.sorted { a, b in
            let aIdx = order.firstIndex(of: a.identifier) ?? 99
            let bIdx = order.firstIndex(of: b.identifier) ?? 99
            return aIdx < bIdx
        }
    }

    private func tokenAmountForIdentifier(_ identifier: String) -> Int {
        switch identifier {
        case "kickiq_tokens_small": return TokenPackSize.small.tokenAmount
        case "kickiq_tokens_medium": return TokenPackSize.medium.tokenAmount
        case "kickiq_tokens_large": return TokenPackSize.large.tokenAmount
        default: return 0
        }
    }

    private func tokenPackSizeForIdentifier(_ identifier: String) -> TokenPackSize? {
        switch identifier {
        case "kickiq_tokens_small": return .small
        case "kickiq_tokens_medium": return .medium
        case "kickiq_tokens_large": return .large
        default: return nil
        }
    }
}
