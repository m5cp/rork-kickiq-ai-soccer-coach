import Foundation
import Observation
import RevenueCat

nonisolated enum SubscriptionTier: String, Sendable {
    case free
    case weekly
    case monthly
    case annual
}

@Observable
@MainActor
class StoreViewModel {
    static let shared = StoreViewModel()

    var offerings: Offerings?
    var isPremium = false
    var currentTier: SubscriptionTier = .free
    var isLoading = false
    var isPurchasing = false
    var error: String?

    var userRole: UserRole = .player

    var dailyMessageLimit: Int {
        switch currentTier {
        case .free: return 10
        case .weekly: return 50
        case .monthly: return 150
        case .annual: return 500
        }
    }

    var sessionMessageLimit: Int {
        switch currentTier {
        case .free: return 5
        case .weekly: return 25
        case .monthly: return 50
        case .annual: return 100
        }
    }

    var analysisLimit: Int {
        switch currentTier {
        case .free: return 2
        case .weekly: return 10
        case .monthly: return 30
        case .annual: return 100
        }
    }

    var unlimitedPlayers: Bool {
        userRole == .coach
    }

    var coachFreeFeatures: [String] {
        ["Unlimited Players", "Custom Drill Plans", "Team Reports (Basic)", "Data Export (CSV)", "QR Code Invites"]
    }

    var coachProFeatures: [String] {
        ["AI Video Analysis", "AI Coach Chat", "Full Reports + PDF Export", "Advanced Analytics"]
    }

    var tierDisplayName: String {
        switch currentTier {
        case .free: return "Free"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .annual: return "Annual"
        }
    }

    init() {
        Task { await listenForUpdates() }
        Task { await fetchOfferings() }
    }

    func syncUserRole(from profile: PlayerProfile?) {
        guard let role = profile?.userRole else { return }
        if userRole != role {
            userRole = role
        }
    }

    var dailyAnalysisRemaining: Int {
        let used = UserDefaults.standard.integer(forKey: "kickiq_daily_analysis_count")
        let dateKey = UserDefaults.standard.string(forKey: "kickiq_daily_analysis_date") ?? ""
        let today = formattedToday()
        if dateKey != today { return analysisLimit }
        return max(0, analysisLimit - used)
    }

    var canAnalyze: Bool {
        dailyAnalysisRemaining > 0
    }

    func consumeAnalysis() {
        let today = formattedToday()
        let dateKey = UserDefaults.standard.string(forKey: "kickiq_daily_analysis_date") ?? ""
        var count = UserDefaults.standard.integer(forKey: "kickiq_daily_analysis_count")
        if dateKey != today {
            count = 0
            UserDefaults.standard.set(today, forKey: "kickiq_daily_analysis_date")
        }
        count += 1
        UserDefaults.standard.set(count, forKey: "kickiq_daily_analysis_count")
    }

    private func formattedToday() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: .now)
    }

    private func listenForUpdates() async {
        for await info in Purchases.shared.customerInfoStream {
            updateTier(from: info)
        }
    }

    func fetchOfferings() async {
        isLoading = true
        do {
            offerings = try await Purchases.shared.offerings()
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
                updateTier(from: result.customerInfo)
            }
        } catch ErrorCode.purchaseCancelledError {
        } catch ErrorCode.paymentPendingError {
        } catch {
            self.error = error.localizedDescription
        }
        isPurchasing = false
    }

    func restore() async {
        do {
            let info = try await Purchases.shared.restorePurchases()
            updateTier(from: info)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func checkStatus() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            updateTier(from: info)
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func updateTier(from info: CustomerInfo) {
        let hasPremium = info.entitlements["premium"]?.isActive == true
        isPremium = hasPremium

        if !hasPremium {
            currentTier = .free
            return
        }

        let productID = info.entitlements["premium"]?.productIdentifier ?? ""
        if productID.contains("annual") {
            currentTier = .annual
        } else if productID.contains("monthly") {
            currentTier = .monthly
        } else if productID.contains("weekly") {
            currentTier = .weekly
        } else {
            currentTier = .weekly
        }
    }
}
