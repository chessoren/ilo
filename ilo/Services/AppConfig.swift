import Foundation

/// Runtime configuration read from `Config.plist` (git-ignored). See `Config.example.plist`.
/// Every key is optional: without keys ilo runs fully offline with its local brain and a local store.
enum AppConfig {
    nonisolated(unsafe) private static let values: [String: Any] = {
        guard let url = Bundle.main.url(forResource: "Config", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else { return [:] }
        return dict
    }()

    private static func string(_ key: String) -> String? {
        guard let value = values[key] as? String, !value.isEmpty, !value.hasPrefix("YOUR_") else { return nil }
        return value
    }

    /// https://<project>.supabase.co
    static var supabaseURL: URL? { string("SUPABASE_URL").flatMap(URL.init(string:)) }
    static var supabaseAnonKey: String? { string("SUPABASE_ANON_KEY") }
    /// RevenueCat public SDK key (Test Store key `test_…` works without App Store Connect).
    static var revenueCatAPIKey: String? {
        if let key = string("REVENUECAT_API_KEY") { return key }
        #if DEBUG
        // RevenueCat Test Store public SDK key (sandbox only, safe to ship): anyone who clones the repo can buy in the
        // simulator without an Apple account. UI tests pass `-noStore` to use the simulated purchase instead.
        if !ProcessInfo.processInfo.arguments.contains("-noStore") { return "test_GRtVIWecARMLDWKvQbqLwKQWYec" }
        #endif
        return nil
    }
    /// Entitlement identifier configured in RevenueCat.
    static var entitlementID: String { string("REVENUECAT_ENTITLEMENT") ?? "pro" }

    /// True once the `ilo-ai` edge function is deployed (OpenRouter proxy). Leaderboards only need `hasBackend`.
    static var aiFunctionEnabled: Bool { (values["SUPABASE_AI_FUNCTION"] as? Bool) ?? false }

    static var hasBackend: Bool { supabaseURL != nil && supabaseAnonKey != nil }
    static var hasRevenueCat: Bool { revenueCatAPIKey != nil }
}
