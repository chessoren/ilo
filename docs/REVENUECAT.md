# RevenueCat in ilo

ilo uses a **hard paywall** right after onboarding: the learner has just watched ilo build their personal path
("Your Salsa path is ready"), and unlocks it with a 7-day free trial of **ilo Pro**.

All subscription logic lives in [`ilo/Services/PurchaseService.swift`](../ilo/Services/PurchaseService.swift)
(`@Observable`, injected in the environment). The paywall UI is in [`ilo/Features/Paywall/`](../ilo/Features/Paywall).

## How it works

| Situation | Backend used |
| --- | --- |
| `REVENUECAT_API_KEY` set in `ilo/Config.plist` | **RevenueCat SDK** (`purchases-ios-spm`, 5.x) |
| No key | **StoreKit 2** directly, against the local `ilo/Products.storekit` configuration |
| Neither store answers (e.g. launched outside Xcode without a key) | Placeholder prices so the paywall still renders. In **DEBUG** a purchase is simulated so a demo never gets stuck; in Release it shows an error. |

With RevenueCat, `PurchaseService`:

1. calls `Purchases.configure(withAPIKey:)` at launch (debug log level in DEBUG builds);
2. listens to `Purchases.shared.customerInfoStream` and sets `isPro` from the **`pro` entitlement** (`customerInfo.entitlements["pro"]?.isActive`);
3. loads `Purchases.shared.offerings()` → `current` (falls back to `default`), keeps the `$rc_annual`, `$rc_weekly` (and `$rc_monthly` if present) packages;
4. checks free-trial eligibility with `checkTrialOrIntroDiscountEligibility(packages:)` so "7 days free" is only promised to eligible users;
5. computes per-week prices (`StoreProduct.localizedPricePerWeek`) and the annual saving vs. weekly for the plan cards;
6. buys with `Purchases.shared.purchase(package:)` (user cancellation is silent), restores with `restorePurchases()`.

`RootView` routes: onboarding → paywall (while `!store.isPro`) → main app. `isCelebrating` keeps the paywall on screen
for the success confetti after a purchase before the app opens. `AppModel.isPro` is kept in sync.

Nothing sensitive is persisted by ilo; RevenueCat caches its own `CustomerInfo`.

## Live configuration (project "ilo")

This is what's set up in the RevenueCat dashboard today (Test Store app):

| Thing | Value |
| --- | --- |
| Entitlement | `pro` |
| Offering | `default` (current) |
| `$rc_annual` | `ilo_pro_annual`: 1 year, **$79.99**, **1-week free trial** (new customers) |
| `$rc_weekly` | `ilo_pro_weekly`: 1 week, **$7.99** |
| Public SDK key | Test Store `test_…` key, used by DEBUG builds so anyone who clones the repo can buy in the simulator |

## Dashboard setup (from scratch)

1. Create a project in RevenueCat and add an **App Store** app with bundle id `app.ilo.learn`
   (or just use the **Test Store** — see below).
2. **Products**: `ilo.pro.annual` (1 year, 7-day free trial intro offer, $79.99) and `ilo.pro.weekly` (1 week, $7.99),
   subscription group **"ilo Pro"**.
3. **Entitlement**: identifier **`pro`** — attach both products.
   (Override with `REVENUECAT_ENTITLEMENT` in `Config.plist` if you use another name.)
4. **Offering**: identifier **`default`**, mark it *current*, with packages
   - `$rc_annual` → `ilo.pro.annual`
   - `$rc_weekly` → `ilo.pro.weekly`

## Test Store (no App Store Connect needed)

RevenueCat's Test Store lets you run real purchase flows in the simulator without App Store Connect.

1. Every RevenueCat project comes with a **Test Store** app. Create the same products there (Test Store supports free
   trials), attach them to the `pro` entitlement and the `default` offering.
2. Copy the Test Store's **public API key** (it starts with `test_`) from the project's API keys page.
3. `cp ilo/Config.example.plist ilo/Config.plist` (git-ignored) and set:

```xml
<key>REVENUECAT_API_KEY</key>
<string>test_xxxxxxxxxxxxxxxxxxxxxxxxxx</string>
<key>REVENUECAT_ENTITLEMENT</key>
<string>pro</string>
```

4. Run the app. The paywall shows the Test Store prices; tapping **Start my free week** shows RevenueCat's "Test Store Purchase"
   alert where you can simulate success or failure. Never ship a `test_` key in a release build — use the App Store
   public SDK key (`appl_…`) instead.

## Local StoreKit testing (no key at all)

The shared scheme `ilo.xcodeproj/xcshareddata/xcschemes/ilo.xcscheme` references `ilo/Products.storekit`
(`StoreKitConfigurationFileReference`). Running from Xcode (⌘R) therefore serves these products locally, including
the 7-day free trial, and purchases work in the simulator. Use **Debug → StoreKit → Manage Transactions** to refund
or expire a subscription and see the paywall come back.

## Debug helpers (DEBUG builds only)

- Long-press the **ilo PRO** logo on the paywall for 1.5 s → unlocks Pro for testing.
- Launch arguments: `-unlockPro`, `-resetPro`, `-resetOnboarding`, `-skipOnboarding`, `-onboardingStep <n>`
  (jumps to onboarding screen *n*, 0 = splash … 13 = commitment, with sample answers pre-filled).
