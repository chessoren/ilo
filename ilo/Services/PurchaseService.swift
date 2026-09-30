import Foundation
import Observation
import RevenueCat
import StoreKit

/// One purchasable plan as the paywall shows it — backed by a RevenueCat `Package` or a raw StoreKit 2 `Product`.
struct PaywallPackage: Identifiable, Hashable, Sendable {
    enum Kind: Int, Sendable, Comparable {
        case annual, monthly, weekly
        static func < (a: Kind, b: Kind) -> Bool { a.rawValue < b.rawValue }
    }

    /// RevenueCat package identifier (`$rc_annual`) or StoreKit product id.
    var id: String
    var productID: String
    var kind: Kind
    /// "$79.99"
    var price: String
    var priceValue: Decimal
    /// "$1.54"
    var pricePerWeek: String
    var pricePerWeekValue: Decimal
    /// Free-trial length in days when the learner is eligible (nil = no trial).
    var trialDays: Int?
    /// True when this plan is a local stand-in (store not reachable) — purchase is simulated in DEBUG only.
    var isPlaceholder = false

    var title: String {
        switch kind {
        case .annual: "Yearly"
        case .monthly: "Monthly"
        case .weekly: "Weekly"
        }
    }

    var periodWord: String {
        switch kind {
        case .annual: "year"
        case .monthly: "month"
        case .weekly: "week"
        }
    }

    var hasTrial: Bool { (trialDays ?? 0) > 0 }
}

/// Subscription state for ilo Pro.
///
/// - With `REVENUECAT_API_KEY` in `Config.plist` → RevenueCat (offering `default`, entitlement `pro`).
///   A Test Store key (`test_…`) works in the simulator without App Store Connect.
/// - Without a key → StoreKit 2 directly against `ilo/Products.storekit` (selected in the shared `ilo` scheme).
/// - If neither store answers (e.g. app launched outside Xcode) → placeholder prices so the paywall still renders;
///   in DEBUG a purchase is then simulated so a demo can never get stuck.
@Observable
@MainActor
final class PurchaseService {
    enum Backend: String, Sendable { case revenueCat = "RevenueCat", storeKit = "StoreKit", offline = "Offline" }

    static let annualID = "ilo.pro.annual"
    static let weeklyID = "ilo.pro.weekly"
    static let monthlyID = "ilo.pro.monthly"

    // MARK: Public state

    /// The learner has the `pro` entitlement.
    var isPro = false
    /// First entitlement check finished (avoids flashing the paywall for subscribers on launch).
    var hasCheckedEntitlements = false
    /// Plans sorted annual → weekly.
    var packages: [PaywallPackage] = []
    var isLoadingPackages = false
    var isPurchasing = false
    var isRestoring = false
    var errorMessage: String?
    /// While true the paywall stays on screen even after `isPro` flips (success celebration).
    var isCelebrating = false
    private(set) var backend: Backend = .offline

    var annual: PaywallPackage? { packages.first { $0.kind == .annual } }
    var weekly: PaywallPackage? { packages.first { $0.kind == .weekly } }

    /// "Save 80%" of annual vs paying weekly for a year.
    var annualSavingsPercent: Int? {
        guard let annual, let weekly, weekly.priceValue > 0 else { return nil }
        let yearlyAtWeekly = weekly.priceValue * 52
        let saving = (1 - NSDecimalNumber(decimal: annual.priceValue / yearlyAtWeekly).doubleValue) * 100
        return saving > 1 ? Int(saving.rounded()) : nil
    }

    // MARK: Private

    private var rcPackages: [String: RevenueCat.Package] = [:]
    private var skProducts: [String: StoreKit.Product] = [:]
    private var listeners: [Task<Void, Never>] = []
    private var started = false
    private var debugUnlocked: Bool {
        get { UserDefaults.standard.bool(forKey: "ilo.debug.proUnlocked") }
        set { UserDefaults.standard.set(newValue, forKey: "ilo.debug.proUnlocked") }
    }

    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-resetPro") { debugUnlocked = false }
        if ProcessInfo.processInfo.arguments.contains("-unlockPro") { debugUnlocked = true }
        if debugUnlocked { isPro = true; hasCheckedEntitlements = true }
        #endif
        start()
    }

    /// Configures the store and starts listening. Safe to call more than once.
    func start() {
        guard !started else { return }
        started = true
        if let key = AppConfig.revenueCatAPIKey {
            backend = .revenueCat
            #if DEBUG
            Purchases.logLevel = .debug
            #else
            Purchases.logLevel = .warn
            #endif
            Purchases.configure(withAPIKey: key)
            listeners.append(Task { [weak self] in
                for await info in Purchases.shared.customerInfoStream {
                    self?.apply(info)
                }
            })
        } else {
            backend = .storeKit
            listeners.append(Task { [weak self] in
                for await update in StoreKit.Transaction.updates {
                    if case .verified(let transaction) = update { await transaction.finish() }
                    await self?.refreshStoreKitEntitlements()
                }
            })
            Task { await refreshStoreKitEntitlements() }
        }
        Task { await loadPackages() }
    }

    // MARK: Loading

    func loadPackages() async {
        guard !isLoadingPackages else { return }
        isLoadingPackages = true
        defer { isLoadingPackages = false }
        switch backend {
        case .revenueCat: await loadRevenueCat()
        case .storeKit, .offline: await loadStoreKit()
        }
        if packages.isEmpty {
            packages = Self.placeholders
        }
    }

    private func loadRevenueCat() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            guard let offering = offerings.current ?? offerings.all["default"] ?? offerings.all.values.first else {
                errorMessage = nil
                return
            }
            let available = offering.availablePackages.filter { [.annual, .weekly, .monthly].contains($0.packageType) }
            let eligibility = await Purchases.shared.checkTrialOrIntroDiscountEligibility(packages: available)
            var result: [PaywallPackage] = []
            rcPackages = [:]
            for package in available {
                let product = package.storeProduct
                let kind: PaywallPackage.Kind = switch package.packageType {
                case .annual: .annual
                case .monthly: .monthly
                default: .weekly
                }
                var trialDays: Int?
                if let intro = product.introductoryDiscount, intro.paymentMode == .freeTrial,
                   eligibility[package]?.status != .ineligible {
                    trialDays = Self.days(value: intro.subscriptionPeriod.value, unit: intro.subscriptionPeriod.unit)
                }
                let perWeek = product.pricePerWeek?.decimalValue ?? Self.perWeek(product.price, kind)
                result.append(PaywallPackage(
                    id: package.identifier,
                    productID: product.productIdentifier,
                    kind: kind,
                    price: product.localizedPriceString,
                    priceValue: product.price,
                    pricePerWeek: product.localizedPricePerWeek ?? Self.format(perWeek, like: product.priceFormatter),
                    pricePerWeekValue: perWeek,
                    trialDays: trialDays))
                rcPackages[package.identifier] = package
            }
            packages = result.sorted { $0.kind < $1.kind }
        } catch {
            // Falls back to placeholder plans; a purchase attempt will surface a real error.
            #if DEBUG
            print("[PurchaseService] offerings failed: \(error.localizedDescription)")
            #endif
        }
    }

    private func loadStoreKit() async {
        do {
            let products = try await StoreKit.Product.products(for: [Self.annualID, Self.monthlyID, Self.weeklyID])
            guard !products.isEmpty else { backend = .offline; return }
            backend = .storeKit
            var result: [PaywallPackage] = []
            skProducts = [:]
            for product in products {
                let kind: PaywallPackage.Kind = switch product.id {
                case Self.annualID: .annual
                case Self.monthlyID: .monthly
                default: .weekly
                }
                var trialDays: Int?
                if let sub = product.subscription, let intro = sub.introductoryOffer, intro.paymentMode == .freeTrial,
                   await sub.isEligibleForIntroOffer {
                    trialDays = Self.days(value: intro.period.value, unit: intro.period.unit)
                }
                let perWeek = Self.perWeek(product.price, kind)
                result.append(PaywallPackage(
                    id: product.id, productID: product.id, kind: kind,
                    price: product.displayPrice, priceValue: product.price,
                    pricePerWeek: perWeek.formatted(product.priceFormatStyle),
                    pricePerWeekValue: perWeek, trialDays: trialDays))
                skProducts[product.id] = product
            }
            packages = result.sorted { $0.kind < $1.kind }
        } catch {
            backend = .offline
        }
    }

    // MARK: Purchasing

    /// Buys a plan. Returns true when the learner is now Pro. Cancellation returns false without an error.
    @discardableResult
    func purchase(_ package: PaywallPackage) async -> Bool {
        guard !isPurchasing else { return false }
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }

        if package.isPlaceholder {
            #if DEBUG
            try? await Task.sleep(for: .seconds(1.2))
            debugUnlocked = true
            isPro = true
            return true
            #else
            errorMessage = "The App Store isn't reachable right now. Please try again in a moment."
            return false
            #endif
        }

        do {
            switch backend {
            case .revenueCat:
                guard let rc = rcPackages[package.id] else { throw StoreError.missingProduct }
                let result = try await Purchases.shared.purchase(package: rc)
                if result.userCancelled { return false }
                apply(result.customerInfo)
            case .storeKit, .offline:
                guard let product = skProducts[package.productID] else { throw StoreError.missingProduct }
                switch try await product.purchase() {
                case .success(let verification):
                    guard case .verified(let transaction) = verification else { throw StoreError.unverified }
                    await transaction.finish()
                    await refreshStoreKitEntitlements()
                case .userCancelled:
                    return false
                case .pending:
                    errorMessage = "Your purchase is pending approval. You'll get Pro as soon as it's approved."
                    return false
                @unknown default:
                    return false
                }
            }
            return isPro
        } catch ErrorCode.purchaseCancelledError {
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Restores previous purchases. Returns true when Pro is active afterwards.
    @discardableResult
    func restore() async -> Bool {
        guard !isRestoring else { return false }
        isRestoring = true
        errorMessage = nil
        defer { isRestoring = false }
        do {
            switch backend {
            case .revenueCat:
                apply(try await Purchases.shared.restorePurchases())
            case .storeKit, .offline:
                try await AppStore.sync()
                await refreshStoreKitEntitlements()
            }
            if !isPro { errorMessage = "No active ilo Pro subscription was found for this Apple Account." }
            return isPro
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    #if DEBUG
    /// Hidden testing unlock (long-press the paywall logo). Never compiled into release builds.
    func debugUnlock() {
        debugUnlocked = true
        isPro = true
    }

    func debugLock() {
        debugUnlocked = false
        isPro = false
    }
    #endif

    // MARK: Entitlements

    private func apply(_ info: CustomerInfo) {
        let active = info.entitlements[AppConfig.entitlementID]?.isActive == true
        isPro = active || debugOverride
        hasCheckedEntitlements = true
    }

    private func refreshStoreKitEntitlements() async {
        var active = false
        let ids: Set<String> = [Self.annualID, Self.monthlyID, Self.weeklyID]
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let t) = result, ids.contains(t.productID), t.revocationDate == nil {
                if let exp = t.expirationDate, exp < .now { continue }
                active = true
            }
        }
        isPro = active || debugOverride
        hasCheckedEntitlements = true
    }

    private var debugOverride: Bool {
        #if DEBUG
        debugUnlocked
        #else
        false
        #endif
    }

    // MARK: Helpers

    enum StoreError: LocalizedError {
        case missingProduct, unverified
        var errorDescription: String? {
            switch self {
            case .missingProduct: "That plan isn't available right now. Please try again."
            case .unverified: "The App Store couldn't verify this purchase."
            }
        }
    }

    private static let placeholders: [PaywallPackage] = [
        PaywallPackage(id: "$rc_annual", productID: annualID, kind: .annual, price: "$79.99", priceValue: 79.99,
                       pricePerWeek: "$1.54", pricePerWeekValue: 1.54, trialDays: 7, isPlaceholder: true),
        PaywallPackage(id: "$rc_weekly", productID: weeklyID, kind: .weekly, price: "$7.99", priceValue: 7.99,
                       pricePerWeek: "$7.99", pricePerWeekValue: 7.99, trialDays: nil, isPlaceholder: true),
    ]

    private static func perWeek(_ price: Decimal, _ kind: PaywallPackage.Kind) -> Decimal {
        let weeks: Decimal = switch kind {
        case .annual: 52
        case .monthly: Decimal(52) / 12
        case .weekly: 1
        }
        var value = price / weeks
        var rounded = Decimal()
        NSDecimalRound(&rounded, &value, 2, .down)
        return rounded
    }

    private static func format(_ value: Decimal, like formatter: NumberFormatter?) -> String {
        (formatter ?? {
            let f = NumberFormatter(); f.numberStyle = .currency; f.locale = .current; return f
        }()).string(from: NSDecimalNumber(decimal: value)) ?? "\(value)"
    }

    private static func days(value: Int, unit: RevenueCat.SubscriptionPeriod.Unit) -> Int {
        switch unit {
        case .day: value
        case .week: value * 7
        case .month: value * 30
        case .year: value * 365
        @unknown default: value
        }
    }

    private static func days(value: Int, unit: StoreKit.Product.SubscriptionPeriod.Unit) -> Int {
        switch unit {
        case .day: value
        case .week: value * 7
        case .month: value * 30
        case .year: value * 365
        @unknown default: value
        }
    }
}
