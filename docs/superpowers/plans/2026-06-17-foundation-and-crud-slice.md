# Foundation + CRUD Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A runnable iPhone app (macOS destination added at the end) where you can add, list, and delete subscriptions in the Trade Republic design language, backed by SwiftData and a test-driven domain core.

**Architecture:** Two layers. (1) `SubscriptionKit` — a dependency-free Swift package holding pure value types and logic (`Money`, `CurrencyFormatter`, `BillingCycle`, `BillingScheduler`), fully unit-tested via `swift test`. (2) `Subs` — an XcodeGen-generated SwiftUI app depending on `SubscriptionKit`, holding the SwiftData models, the DesignSystem, and feature views. The data store is **local** in this plan; CloudKit sync is deferred to a later milestone (the model is already CloudKit-safe). Detail/edit screens and M2–M6 are separate plans.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, Swift Testing, XcodeGen 2.x, Xcode 26.5. Deployment target iOS 18 (macOS 15 added in Task 13).

**Spec coverage (this plan):** §3 stack/module structure, §4 data model (Subscription/Category/PaymentMethod), §5 BillingScheduler, §7 design system (tokens, formatting, row/tag/monogram/floating-nav), §10 M0 + start of M1. Deferred to later plans: §6 detail/edit screens, §5 CurrencyConverter/SpendCalculator (M2), §8 FX + auto-detect (M3/M4), reminders (M5), CloudKit + full macOS + accessibility polish (M6).

---

## File Structure

```
SubscriptionKit/
  Package.swift
  Sources/SubscriptionKit/
    Money.swift              # Decimal + currency value type
    CurrencyFormatter.swift  # value-first, symbol-after formatting
    BillingCycle.swift       # cycle enum + display
    BillingScheduler.swift   # next-charge date math (month-end clamping)
  Tests/SubscriptionKitTests/
    MoneyTests.swift
    CurrencyFormatterTests.swift
    BillingCycleTests.swift
    BillingSchedulerTests.swift
project.yml                  # XcodeGen project definition
App/
  SubsApp.swift              # @main entry
  Persistence/
    AppModelContainer.swift  # local SwiftData container
    CategorySeed.swift       # seed built-in categories
  Models/
    Subscription.swift
    Category.swift
    PaymentMethod.swift
  DesignSystem/
    Color+Hex.swift
    Theme.swift
    Typography.swift
    Spacing.swift
    Components/
      MonogramView.swift
      CategoryTag.swift
      SubscriptionRow.swift
      PrimaryButtonStyle.swift
      FloatingTabBar.swift
  Features/
    Shell/RootView.swift
    Home/HomePlaceholderView.swift
    Settings/SettingsPlaceholderView.swift
    Subscriptions/SubscriptionsView.swift
    AddEdit/AddSubscriptionView.swift
LICENSE
README.md
```

---

## Task 1: SubscriptionKit package skeleton

**Files:**
- Create: `SubscriptionKit/Package.swift`
- Create: `SubscriptionKit/Sources/SubscriptionKit/Placeholder.swift`
- Test: `SubscriptionKit/Tests/SubscriptionKitTests/SmokeTests.swift`

- [ ] **Step 1: Create `Package.swift`**

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SubscriptionKit",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "SubscriptionKit", targets: ["SubscriptionKit"])
    ],
    targets: [
        .target(name: "SubscriptionKit"),
        .testTarget(name: "SubscriptionKitTests", dependencies: ["SubscriptionKit"])
    ]
)
```

- [ ] **Step 2: Create a placeholder source so the target compiles**

`SubscriptionKit/Sources/SubscriptionKit/Placeholder.swift`:
```swift
// Intentionally empty; real types arrive in later tasks.
```

- [ ] **Step 3: Write a smoke test**

`SubscriptionKit/Tests/SubscriptionKitTests/SmokeTests.swift`:
```swift
import Testing
@testable import SubscriptionKit

@Test func toolchainWorks() {
    #expect(1 + 1 == 2)
}
```

- [ ] **Step 4: Run the tests to verify the toolchain**

Run: `cd SubscriptionKit && swift test`
Expected: builds and PASSES (`1 test` passed).

- [ ] **Step 5: Commit**

```bash
git add SubscriptionKit
git commit -m "chore: scaffold SubscriptionKit package with passing smoke test"
```

---

## Task 2: `Money` value type

**Files:**
- Create: `SubscriptionKit/Sources/SubscriptionKit/Money.swift`
- Test: `SubscriptionKit/Tests/SubscriptionKitTests/MoneyTests.swift`

- [ ] **Step 1: Write the failing test**

`MoneyTests.swift`:
```swift
import Testing
import Foundation
@testable import SubscriptionKit

@Test func moneyStoresAmountAndCurrency() {
    let m = Money(amount: Decimal(9.99), currencyCode: "EUR")
    #expect(m.amount == Decimal(9.99))
    #expect(m.currencyCode == "EUR")
}

@Test func moneyEquatable() {
    #expect(Money(amount: 5, currencyCode: "USD") == Money(amount: 5, currencyCode: "USD"))
    #expect(Money(amount: 5, currencyCode: "USD") != Money(amount: 5, currencyCode: "EUR"))
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `cd SubscriptionKit && swift test`
Expected: FAIL — "cannot find 'Money' in scope".

- [ ] **Step 3: Implement `Money`**

`Money.swift`:
```swift
import Foundation

public struct Money: Equatable, Hashable, Sendable {
    public var amount: Decimal
    public var currencyCode: String

    public init(amount: Decimal, currencyCode: String) {
        self.amount = amount
        self.currencyCode = currencyCode
    }
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `cd SubscriptionKit && swift test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add SubscriptionKit
git commit -m "feat: add Money value type"
```

---

## Task 3: `CurrencyFormatter` (value-first, symbol-after)

The Trade Republic rule: value first, currency symbol after, separated by a non-breaking space (e.g. `1,043.64 €`).

**Files:**
- Create: `SubscriptionKit/Sources/SubscriptionKit/CurrencyFormatter.swift`
- Test: `SubscriptionKit/Tests/SubscriptionKitTests/CurrencyFormatterTests.swift`

- [ ] **Step 1: Write the failing test**

`CurrencyFormatterTests.swift`:
```swift
import Testing
import Foundation
@testable import SubscriptionKit

private let enUS = Locale(identifier: "en_US")

@Test func formatsEuroValueFirstSymbolAfter() {
    let s = CurrencyFormatter.string(for: Money(amount: Decimal(1043.64), currencyCode: "EUR"), locale: enUS)
    #expect(s == "1,043.64\u{00A0}€")
}

@Test func formatsUSD() {
    let s = CurrencyFormatter.string(for: Money(amount: Decimal(9.99), currencyCode: "USD"), locale: enUS)
    #expect(s == "9.99\u{00A0}$")
}

@Test func alwaysTwoFractionDigits() {
    let s = CurrencyFormatter.string(for: Money(amount: Decimal(5), currencyCode: "EUR"), locale: enUS)
    #expect(s == "5.00\u{00A0}€")
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `cd SubscriptionKit && swift test`
Expected: FAIL — "cannot find 'CurrencyFormatter' in scope".

- [ ] **Step 3: Implement `CurrencyFormatter`**

`CurrencyFormatter.swift`:
```swift
import Foundation

public enum CurrencyFormatter {
    /// Value first, symbol after, non-breaking space between — Trade Republic style.
    public static func string(for money: Money, locale: Locale = .current) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.locale = locale
        nf.minimumFractionDigits = 2
        nf.maximumFractionDigits = 2
        let number = NSDecimalNumber(decimal: money.amount)
        let value = nf.string(from: number) ?? "\(money.amount)"
        return "\(value)\u{00A0}\(symbol(for: money.currencyCode, locale: locale))"
    }

    public static func symbol(for currencyCode: String, locale: Locale = .current) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.locale = locale
        nf.currencyCode = currencyCode
        return nf.currencySymbol ?? currencyCode
    }
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `cd SubscriptionKit && swift test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add SubscriptionKit
git commit -m "feat: add value-first CurrencyFormatter"
```

---

## Task 4: `BillingCycle` enum

**Files:**
- Create: `SubscriptionKit/Sources/SubscriptionKit/BillingCycle.swift`
- Test: `SubscriptionKit/Tests/SubscriptionKitTests/BillingCycleTests.swift`

- [ ] **Step 1: Write the failing test**

`BillingCycleTests.swift`:
```swift
import Testing
@testable import SubscriptionKit

@Test func displayNames() {
    #expect(BillingCycle.weekly.displayName == "Weekly")
    #expect(BillingCycle.monthly.displayName == "Monthly")
    #expect(BillingCycle.quarterly.displayName == "Quarterly")
    #expect(BillingCycle.semiAnnual.displayName == "Every 6 months")
    #expect(BillingCycle.yearly.displayName == "Yearly")
    #expect(BillingCycle.custom(days: 10).displayName == "Every 10 days")
}

@Test func cycleEquatable() {
    #expect(BillingCycle.custom(days: 30) == BillingCycle.custom(days: 30))
    #expect(BillingCycle.custom(days: 30) != BillingCycle.custom(days: 31))
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `cd SubscriptionKit && swift test`
Expected: FAIL — "cannot find 'BillingCycle' in scope".

- [ ] **Step 3: Implement `BillingCycle`**

`BillingCycle.swift`:
```swift
import Foundation

public enum BillingCycle: Equatable, Hashable, Sendable {
    case weekly
    case monthly
    case quarterly
    case semiAnnual
    case yearly
    case custom(days: Int)

    public var displayName: String {
        switch self {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .semiAnnual: return "Every 6 months"
        case .yearly: return "Yearly"
        case .custom(let days): return "Every \(days) days"
        }
    }

    /// All non-custom cases, for pickers.
    public static var presets: [BillingCycle] {
        [.weekly, .monthly, .quarterly, .semiAnnual, .yearly]
    }
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `cd SubscriptionKit && swift test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add SubscriptionKit
git commit -m "feat: add BillingCycle enum"
```

---

## Task 5: `BillingScheduler` next-charge math

The hard part is month-end clamping. We compute the *nth* occurrence by adding `cycle × n` to the anchor with `Calendar.date(byAdding:)`, which clamps overflowing days (Jan 31 + 1 month → Feb 28).

**Files:**
- Create: `SubscriptionKit/Sources/SubscriptionKit/BillingScheduler.swift`
- Test: `SubscriptionKit/Tests/SubscriptionKitTests/BillingSchedulerTests.swift`

- [ ] **Step 1: Write the failing tests**

`BillingSchedulerTests.swift`:
```swift
import Testing
import Foundation
@testable import SubscriptionKit

private func utcCalendar() -> Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "UTC")!
    return cal
}

private func d(_ y: Int, _ m: Int, _ day: Int) -> Date {
    var c = DateComponents()
    c.year = y; c.month = m; c.day = day
    return utcCalendar().date(from: c)!
}

@Test func futureFirstDateReturnsItself() {
    let s = BillingScheduler(calendar: utcCalendar())
    let result = s.nextChargeDate(firstBillingDate: d(2026, 7, 1), cycle: .monthly, after: d(2026, 6, 17))
    #expect(result == d(2026, 7, 1))
}

@Test func monthlyAdvancesPastReference() {
    let s = BillingScheduler(calendar: utcCalendar())
    let result = s.nextChargeDate(firstBillingDate: d(2026, 1, 15), cycle: .monthly, after: d(2026, 1, 20))
    #expect(result == d(2026, 2, 15))
}

@Test func monthlyClampsToShortMonth() {
    let s = BillingScheduler(calendar: utcCalendar())
    let result = s.nextChargeDate(firstBillingDate: d(2026, 1, 31), cycle: .monthly, after: d(2026, 2, 5))
    #expect(result == d(2026, 2, 28)) // 2026 is not a leap year
}

@Test func weeklyAdvances() {
    let s = BillingScheduler(calendar: utcCalendar())
    let result = s.nextChargeDate(firstBillingDate: d(2026, 6, 1), cycle: .weekly, after: d(2026, 6, 10))
    #expect(result == d(2026, 6, 15))
}

@Test func customDaysAdvances() {
    let s = BillingScheduler(calendar: utcCalendar())
    let result = s.nextChargeDate(firstBillingDate: d(2026, 6, 1), cycle: .custom(days: 10), after: d(2026, 6, 15))
    #expect(result == d(2026, 6, 21))
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `cd SubscriptionKit && swift test`
Expected: FAIL — "cannot find 'BillingScheduler' in scope".

- [ ] **Step 3: Implement `BillingScheduler`**

`BillingScheduler.swift`:
```swift
import Foundation

public struct BillingScheduler {
    public let calendar: Calendar

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    /// The first charge date strictly after `reference`, for a cycle anchored at `firstBillingDate`.
    public func nextChargeDate(firstBillingDate: Date, cycle: BillingCycle, after reference: Date) -> Date {
        if firstBillingDate > reference { return firstBillingDate }
        var n = 1
        while n < 100_000 {
            let candidate = occurrence(of: cycle, multiplier: n, from: firstBillingDate)
            if candidate > reference { return candidate }
            n += 1
        }
        return occurrence(of: cycle, multiplier: n, from: firstBillingDate)
    }

    private func occurrence(of cycle: BillingCycle, multiplier n: Int, from base: Date) -> Date {
        var components = DateComponents()
        switch cycle {
        case .weekly:           components.day = 7 * n
        case .monthly:          components.month = n
        case .quarterly:        components.month = 3 * n
        case .semiAnnual:       components.month = 6 * n
        case .yearly:           components.year = n
        case .custom(let days): components.day = days * n
        }
        return calendar.date(byAdding: components, to: base) ?? base
    }
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `cd SubscriptionKit && swift test`
Expected: PASS (all 6 BillingScheduler tests + earlier tests).

- [ ] **Step 5: Commit**

```bash
git add SubscriptionKit
git commit -m "feat: add BillingScheduler with month-end clamping"
```

---

## Task 6: XcodeGen project + empty app that builds

**Files:**
- Create: `project.yml`
- Create: `App/SubsApp.swift`
- Create: `App/Features/Shell/RootView.swift` (temporary minimal body)

- [ ] **Step 1: Install XcodeGen (one-time)**

Run: `brew install xcodegen && xcodegen --version`
Expected: prints a version (e.g. `Version: 2.x`).

- [ ] **Step 2: Create `project.yml`**

```yaml
name: Subs
options:
  bundleIdPrefix: com.ahmedabouelleil
  createIntermediateGroups: true
  deploymentTarget:
    iOS: "18.0"
packages:
  SubscriptionKit:
    path: SubscriptionKit
targets:
  Subs:
    type: application
    platform: iOS
    sources:
      - path: App
    dependencies:
      - package: SubscriptionKit
    settings:
      base:
        PRODUCT_NAME: Subs
        PRODUCT_BUNDLE_IDENTIFIER: com.ahmedabouelleil.subs
        MARKETING_VERSION: "0.1.0"
        CURRENT_PROJECT_VERSION: "1"
        GENERATE_INFOPLIST_FILE: YES
        SWIFT_VERSION: "6.0"
        TARGETED_DEVICE_FAMILY: "1,2"
        INFOPLIST_KEY_CFBundleDisplayName: Subs
        INFOPLIST_KEY_UILaunchScreen_Generation: YES
```

- [ ] **Step 3: Create the app entry (temporary minimal RootView)**

`App/SubsApp.swift`:
```swift
import SwiftUI

@main
struct SubsApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
```

`App/Features/Shell/RootView.swift`:
```swift
import SwiftUI

struct RootView: View {
    var body: some View {
        Text("Subs")
    }
}
```

- [ ] **Step 4: Generate and build**

Run:
```bash
xcodegen generate
xcodebuild -project Subs.xcodeproj -scheme Subs \
  -destination 'platform=iOS Simulator,name=iPhone 15' build
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Ignore generated project and commit**

Append to `.gitignore`:
```
# XcodeGen output
*.xcodeproj
```
Then:
```bash
git add project.yml App/SubsApp.swift App/Features/Shell/RootView.swift .gitignore
git commit -m "chore: add XcodeGen project; empty app builds for iOS simulator"
```

> Note: the `.xcodeproj` is regenerated with `xcodegen generate` and is intentionally not committed.

---

## Task 7: DesignSystem tokens

**Files:**
- Create: `App/DesignSystem/Color+Hex.swift`
- Create: `App/DesignSystem/Theme.swift`
- Create: `App/DesignSystem/Typography.swift`
- Create: `App/DesignSystem/Spacing.swift`

- [ ] **Step 1: Create the hex `Color` initializer**

`App/DesignSystem/Color+Hex.swift`:
```swift
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension Color {
    init(hex: String) {
        let s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255
        let g = Double((rgb & 0x00FF00) >> 8) / 255
        let b = Double(rgb & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }

    /// A color that resolves differently in light vs dark, cross-platform.
    static func dynamic(light: Color, dark: Color) -> Color {
        #if canImport(UIKit)
        return Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #elseif canImport(AppKit)
        return Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return isDark ? NSColor(dark) : NSColor(light)
        })
        #else
        return light
        #endif
    }
}
```

- [ ] **Step 2: Create the `Theme` color tokens**

`App/DesignSystem/Theme.swift`:
```swift
import SwiftUI

enum Theme {
    static let bg        = Color.dynamic(light: Color(hex: "#FFFFFF"), dark: Color(hex: "#000000"))
    static let surface   = Color.dynamic(light: Color(hex: "#F4F4F6"), dark: Color(hex: "#161618"))
    static let track     = Color.dynamic(light: Color(hex: "#ECECEF"), dark: Color(hex: "#26262A"))
    static let text      = Color.dynamic(light: Color(hex: "#0D0D0F"), dark: Color(hex: "#FFFFFF"))
    static let text2     = Color.dynamic(light: Color(hex: "#A0A0A7"), dark: Color(hex: "#86868B"))
    static let hairline  = Color.dynamic(light: Color.black.opacity(0.06), dark: Color.white.opacity(0.08))
    static let positive  = Color(hex: "#00C46A")
    static let negative  = Color(hex: "#F5475B")
}
```

- [ ] **Step 3: Create typography**

`App/DesignSystem/Typography.swift`:
```swift
import SwiftUI

extension Font {
    static let trHero        = Font.system(size: 36, weight: .bold).monospacedDigit()
    static let trSectionTitle = Font.system(size: 15, weight: .semibold)
    static let trRowName     = Font.system(size: 14, weight: .medium)
    static let trAmount      = Font.system(size: 14, weight: .semibold).monospacedDigit()
    static let trSecondary   = Font.system(size: 12, weight: .regular)
    static let trLabel       = Font.system(size: 12, weight: .regular)
    static let trAppTitle    = Font.system(size: 16, weight: .semibold)
}
```

- [ ] **Step 4: Create spacing constants**

`App/DesignSystem/Spacing.swift`:
```swift
import CoreGraphics

enum Spacing {
    static let screenH: CGFloat = 20
    static let rowV: CGFloat = 9
    static let section: CGFloat = 20
}
```

- [ ] **Step 5: Regenerate, build, commit**

Run:
```bash
xcodegen generate
xcodebuild -project Subs.xcodeproj -scheme Subs -destination 'platform=iOS Simulator,name=iPhone 15' build
```
Expected: `** BUILD SUCCEEDED **`.
```bash
git add App/DesignSystem
git commit -m "feat: add DesignSystem tokens (color, type, spacing)"
```

---

## Task 8: SwiftData models + local container + category seed

**Files:**
- Create: `App/Models/Category.swift`
- Create: `App/Models/PaymentMethod.swift`
- Create: `App/Models/Subscription.swift`
- Create: `App/Persistence/AppModelContainer.swift`
- Create: `App/Persistence/CategorySeed.swift`

> CloudKit-safe rules applied: every stored property has a default value; all relationships are optional; no unique constraints.

- [ ] **Step 1: Create `Category`**

`App/Models/Category.swift`:
```swift
import Foundation
import SwiftData

@Model
final class Category {
    var name: String = ""
    var colorHex: String = "#0D0D0F"
    var sfSymbol: String = "square.grid.2x2"
    var isBuiltIn: Bool = false
    var sortOrder: Int = 0

    init() {}
}
```

- [ ] **Step 2: Create `PaymentMethod`**

`App/Models/PaymentMethod.swift`:
```swift
import Foundation
import SwiftData

@Model
final class PaymentMethod {
    var label: String = ""
    var typeRaw: String = "card"   // card | paypal | bank | applePay | other
    var last4: String?

    init() {}
}
```

- [ ] **Step 3: Create `Subscription`**

`App/Models/Subscription.swift`:
```swift
import Foundation
import SwiftData
import SubscriptionKit

@Model
final class Subscription {
    var name: String = ""
    var amountValue: Decimal = 0
    var currencyCode: String = "EUR"
    var cycleRaw: String = "monthly"     // weekly | monthly | quarterly | semiAnnual | yearly | custom
    var customIntervalDays: Int = 30
    var firstBillingDate: Date = Date()
    var nextChargeDate: Date = Date()
    var colorHex: String = "#0D0D0F"
    var catalogServiceId: String?
    var notes: String?
    var reminderLeadDays: Int?
    var isActive: Bool = true
    var startedDate: Date?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    @Relationship var category: Category?
    @Relationship var paymentMethod: PaymentMethod?

    init() {}

    var money: Money { Money(amount: amountValue, currencyCode: currencyCode) }

    var cycle: BillingCycle {
        get {
            switch cycleRaw {
            case "weekly": return .weekly
            case "monthly": return .monthly
            case "quarterly": return .quarterly
            case "semiAnnual": return .semiAnnual
            case "yearly": return .yearly
            case "custom": return .custom(days: customIntervalDays)
            default: return .monthly
            }
        }
        set {
            switch newValue {
            case .weekly: cycleRaw = "weekly"
            case .monthly: cycleRaw = "monthly"
            case .quarterly: cycleRaw = "quarterly"
            case .semiAnnual: cycleRaw = "semiAnnual"
            case .yearly: cycleRaw = "yearly"
            case .custom(let days): cycleRaw = "custom"; customIntervalDays = days
            }
        }
    }

    /// Recompute and store the next charge date from the anchor + cycle.
    func refreshNextChargeDate(now: Date = .now, calendar: Calendar = .current) {
        nextChargeDate = BillingScheduler(calendar: calendar)
            .nextChargeDate(firstBillingDate: firstBillingDate, cycle: cycle, after: now)
    }
}
```

- [ ] **Step 4: Create the local model container**

`App/Persistence/AppModelContainer.swift`:
```swift
import SwiftData

enum AppModelContainer {
    static let shared: ModelContainer = {
        do {
            return try ModelContainer(for: Subscription.self, Category.self, PaymentMethod.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
}
```

- [ ] **Step 5: Create the category seed**

`App/Persistence/CategorySeed.swift`:
```swift
import SwiftData

enum CategorySeed {
    // (name, hex, SF Symbol)
    static let builtIns: [(String, String, String)] = [
        ("Entertainment", "#F5475B", "play.tv"),
        ("Music",         "#00C46A", "music.note"),
        ("Productivity",  "#3A8DDE", "checkmark.circle"),
        ("Cloud & Storage", "#7C8DDE", "icloud"),
        ("Utilities",     "#9A9AA1", "bolt"),
        ("Health & Fitness", "#FF7A45", "heart"),
        ("News",          "#0D0D0F", "newspaper"),
        ("Gaming",        "#A35BFF", "gamecontroller"),
        ("Shopping",      "#FFB018", "bag"),
        ("Education",     "#16A4C7", "book"),
        ("Finance",       "#00A86B", "creditcard"),
        ("Other",         "#9A9AA1", "square.grid.2x2"),
    ]

    @MainActor
    static func seedIfNeeded(_ context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<Category>())) ?? 0
        guard count == 0 else { return }
        for (index, item) in builtIns.enumerated() {
            let c = Category()
            c.name = item.0
            c.colorHex = item.1
            c.sfSymbol = item.2
            c.isBuiltIn = true
            c.sortOrder = index
            context.insert(c)
        }
        try? context.save()
    }
}
```

- [ ] **Step 6: Wire the container into the app entry**

Replace the body of `App/SubsApp.swift`:
```swift
import SwiftUI
import SwiftData

@main
struct SubsApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(AppModelContainer.shared)
    }
}
```

- [ ] **Step 7: Regenerate, build, commit**

Run:
```bash
xcodegen generate
xcodebuild -project Subs.xcodeproj -scheme Subs -destination 'platform=iOS Simulator,name=iPhone 15' build
```
Expected: `** BUILD SUCCEEDED **`.
```bash
git add App/Models App/Persistence App/SubsApp.swift
git commit -m "feat: add SwiftData models, local container, category seed"
```

---

## Task 9: Core components — Monogram, CategoryTag, PrimaryButtonStyle

**Files:**
- Create: `App/DesignSystem/Components/MonogramView.swift`
- Create: `App/DesignSystem/Components/CategoryTag.swift`
- Create: `App/DesignSystem/Components/PrimaryButtonStyle.swift`

- [ ] **Step 1: Create `MonogramView`** (muted circular logo placeholder)

`App/DesignSystem/Components/MonogramView.swift`:
```swift
import SwiftUI

struct MonogramView: View {
    let name: String
    var size: CGFloat = 32

    private var letter: String {
        String(name.trimmingCharacters(in: .whitespaces).prefix(1)).uppercased()
    }

    var body: some View {
        Circle()
            .fill(Theme.surface)
            .frame(width: size, height: size)
            .overlay(
                Text(letter.isEmpty ? "•" : letter)
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundStyle(Theme.text2)
            )
    }
}
```

- [ ] **Step 2: Create `CategoryTag`** (grey pill)

`App/DesignSystem/Components/CategoryTag.swift`:
```swift
import SwiftUI

struct CategoryTag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(Theme.text2)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Theme.surface, in: Capsule())
    }
}
```

- [ ] **Step 3: Create `PrimaryButtonStyle`** (full-width black pill)

`App/DesignSystem/Components/PrimaryButtonStyle.swift`:
```swift
import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Theme.bg)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Theme.text, in: Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}
```

- [ ] **Step 4: Regenerate, build, commit**

Run:
```bash
xcodegen generate
xcodebuild -project Subs.xcodeproj -scheme Subs -destination 'platform=iOS Simulator,name=iPhone 15' build
```
Expected: `** BUILD SUCCEEDED **`.
```bash
git add App/DesignSystem/Components
git commit -m "feat: add Monogram, CategoryTag, PrimaryButtonStyle components"
```

---

## Task 10: `SubscriptionRow` component

**Files:**
- Create: `App/DesignSystem/Components/SubscriptionRow.swift`

- [ ] **Step 1: Create `SubscriptionRow`**

`App/DesignSystem/Components/SubscriptionRow.swift`:
```swift
import SwiftUI
import SubscriptionKit

struct SubscriptionRow: View {
    let name: String
    let money: Money
    let subtitle: String

    var body: some View {
        HStack(spacing: 11) {
            MonogramView(name: name)
            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.trRowName)
                    .foregroundStyle(Theme.text)
                Text(subtitle)
                    .font(.trSecondary)
                    .foregroundStyle(Theme.text2)
            }
            Spacer(minLength: 8)
            Text(CurrencyFormatter.string(for: money))
                .font(.trAmount)
                .foregroundStyle(Theme.text)
        }
        .padding(.vertical, Spacing.rowV)
    }
}
```

- [ ] **Step 2: Regenerate, build, commit**

Run:
```bash
xcodegen generate
xcodebuild -project Subs.xcodeproj -scheme Subs -destination 'platform=iOS Simulator,name=iPhone 15' build
```
Expected: `** BUILD SUCCEEDED **`.
```bash
git add App/DesignSystem/Components/SubscriptionRow.swift
git commit -m "feat: add SubscriptionRow component"
```

---

## Task 11: Subscriptions list with empty state + delete

**Files:**
- Create: `App/Features/Subscriptions/SubscriptionsView.swift`

- [ ] **Step 1: Create `SubscriptionsView`**

`App/Features/Subscriptions/SubscriptionsView.swift`:
```swift
import SwiftUI
import SwiftData
import SubscriptionKit

struct SubscriptionsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Subscription.nextChargeDate, order: .forward)
    private var subscriptions: [Subscription]

    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            Group {
                if subscriptions.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .background(Theme.bg)
            .navigationTitle("Subscriptions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Theme.text)
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddSubscriptionView()
            }
        }
    }

    private var list: some View {
        List {
            ForEach(subscriptions) { sub in
                SubscriptionRow(
                    name: sub.name,
                    money: sub.money,
                    subtitle: "\(relativeDate(sub.nextChargeDate)) · \(sub.category?.name ?? "Other")"
                )
                .listRowInsets(EdgeInsets(top: 0, leading: Spacing.screenH, bottom: 0, trailing: Spacing.screenH))
                .listRowBackground(Theme.bg)
                .listRowSeparatorTint(Theme.hairline)
            }
            .onDelete(perform: delete)
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("No subscriptions yet")
                .font(.trSectionTitle)
                .foregroundStyle(Theme.text)
            Text("Tap + to add your first one.")
                .font(.trSecondary)
                .foregroundStyle(Theme.text2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func delete(_ offsets: IndexSet) {
        for index in offsets { context.delete(subscriptions[index]) }
        try? context.save()
    }

    private func relativeDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        if Calendar.current.isDateInTomorrow(date) { return "Tomorrow" }
        if Calendar.current.isDateInToday(date) { return "Today" }
        return f.string(from: date)
    }
}
```

- [ ] **Step 2: Regenerate, build, commit** (the app still renders `Text("Subs")`; `AddSubscriptionView` arrives next — to keep this task self-contained, temporarily stub it)

Create a temporary stub `App/Features/AddEdit/AddSubscriptionView.swift`:
```swift
import SwiftUI

struct AddSubscriptionView: View {
    var body: some View { Text("Add") }
}
```
Run:
```bash
xcodegen generate
xcodebuild -project Subs.xcodeproj -scheme Subs -destination 'platform=iOS Simulator,name=iPhone 15' build
```
Expected: `** BUILD SUCCEEDED **`.
```bash
git add App/Features/Subscriptions App/Features/AddEdit
git commit -m "feat: add Subscriptions list with empty state and swipe-delete"
```

---

## Task 12: Add Subscription form

**Files:**
- Modify: `App/Features/AddEdit/AddSubscriptionView.swift` (replace the stub)

- [ ] **Step 1: Replace the stub with the full form**

`App/Features/AddEdit/AddSubscriptionView.swift`:
```swift
import SwiftUI
import SwiftData
import SubscriptionKit

struct AddSubscriptionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var name = ""
    @State private var amountText = ""
    @State private var currencyCode = "EUR"
    @State private var cycle: BillingCycle = .monthly
    @State private var firstBillingDate = Date()
    @State private var selectedCategory: Category?
    @State private var notes = ""

    private let currencyOptions = ["EUR", "USD", "GBP", "CHF", "JPY", "CAD", "AUD"]

    private var amountDecimal: Decimal? {
        Decimal(string: amountText.replacingOccurrences(of: ",", with: "."))
    }
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && (amountDecimal ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Service") {
                    TextField("Name", text: $name)
                }
                Section("Price") {
                    TextField("Amount", text: $amountText)
                    #if os(iOS)
                        .keyboardType(.decimalPad)
                    #endif
                    Picker("Currency", selection: $currencyCode) {
                        ForEach(currencyOptions, id: \.self) { Text($0).tag($0) }
                    }
                }
                Section("Billing") {
                    Picker("Cycle", selection: $cycle) {
                        ForEach(BillingCycle.presets, id: \.self) { c in
                            Text(c.displayName).tag(c)
                        }
                    }
                    DatePicker("First charge", selection: $firstBillingDate, displayedComponents: .date)
                }
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("Other").tag(Category?.none)
                        ForEach(categories) { cat in
                            Text(cat.name).tag(Category?.some(cat))
                        }
                    }
                }
                Section("Notes") {
                    TextField("Optional", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle("New subscription")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        guard let amount = amountDecimal else { return }
        let sub = Subscription()
        sub.name = name.trimmingCharacters(in: .whitespaces)
        sub.amountValue = amount
        sub.currencyCode = currencyCode
        sub.cycle = cycle
        sub.firstBillingDate = firstBillingDate
        sub.startedDate = firstBillingDate
        sub.category = selectedCategory
        sub.notes = notes.isEmpty ? nil : notes
        sub.refreshNextChargeDate()
        context.insert(sub)
        try? context.save()
        dismiss()
    }
}
```

- [ ] **Step 2: Regenerate, build, commit**

Run:
```bash
xcodegen generate
xcodebuild -project Subs.xcodeproj -scheme Subs -destination 'platform=iOS Simulator,name=iPhone 15' build
```
Expected: `** BUILD SUCCEEDED **`.
```bash
git add App/Features/AddEdit/AddSubscriptionView.swift
git commit -m "feat: add New Subscription form that persists to SwiftData"
```

---

## Task 13: App shell with floating tab bar + seeding, then run

**Files:**
- Create: `App/DesignSystem/Components/FloatingTabBar.swift`
- Create: `App/Features/Home/HomePlaceholderView.swift`
- Create: `App/Features/Settings/SettingsPlaceholderView.swift`
- Modify: `App/Features/Shell/RootView.swift`

- [ ] **Step 1: Create the floating tab bar**

`App/DesignSystem/Components/FloatingTabBar.swift`:
```swift
import SwiftUI

enum AppTab: CaseIterable {
    case home, subscriptions, settings
    var symbol: String {
        switch self {
        case .home: return "house.fill"
        case .subscriptions: return "list.bullet"
        case .settings: return "gearshape"
        }
    }
}

struct FloatingTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 6) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    selection = tab
                } label: {
                    Image(systemName: tab.symbol)
                        .font(.system(size: 19, weight: .medium))
                        .foregroundStyle(selection == tab ? Theme.bg : Theme.text2)
                        .frame(width: 40, height: 40)
                        .background(selection == tab ? Theme.text : Color.clear, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Theme.hairline, lineWidth: 1))
        .shadow(color: .black.opacity(0.16), radius: 15, y: 10)
    }
}
```

- [ ] **Step 2: Create the two placeholder screens**

`App/Features/Home/HomePlaceholderView.swift`:
```swift
import SwiftUI

struct HomePlaceholderView: View {
    var body: some View {
        VStack(spacing: 6) {
            Text("Overview").font(.trSectionTitle).foregroundStyle(Theme.text)
            Text("Totals and upcoming arrive in M2.")
                .font(.trSecondary).foregroundStyle(Theme.text2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg)
    }
}
```

`App/Features/Settings/SettingsPlaceholderView.swift`:
```swift
import SwiftUI

struct SettingsPlaceholderView: View {
    var body: some View {
        VStack(spacing: 6) {
            Text("Settings").font(.trSectionTitle).foregroundStyle(Theme.text)
            Text("Currency, appearance, reminders arrive later.")
                .font(.trSecondary).foregroundStyle(Theme.text2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg)
    }
}
```

- [ ] **Step 3: Replace `RootView` with the shell**

`App/Features/Shell/RootView.swift`:
```swift
import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @State private var selection: AppTab = .subscriptions

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selection {
                case .home: HomePlaceholderView()
                case .subscriptions: SubscriptionsView()
                case .settings: SettingsPlaceholderView()
                }
            }
            FloatingTabBar(selection: $selection)
                .padding(.bottom, 8)
        }
        .background(Theme.bg)
        .task { CategorySeed.seedIfNeeded(context) }
    }
}
```

- [ ] **Step 4: Regenerate and build**

Run:
```bash
xcodegen generate
xcodebuild -project Subs.xcodeproj -scheme Subs -destination 'platform=iOS Simulator,name=iPhone 15' build
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Run in the simulator and verify by hand**

Run:
```bash
xcrun simctl boot "iPhone 15" 2>/dev/null; open -a Simulator
xcodebuild -project Subs.xcodeproj -scheme Subs \
  -destination 'platform=iOS Simulator,name=iPhone 15' -derivedDataPath build build
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/Subs.app
xcrun simctl launch booted com.ahmedabouelleil.subs
```
Manual checks:
1. App launches to the Subscriptions tab with the empty state and a floating tab bar.
2. Tap `+`, fill name + amount, pick a cycle/category, Save → the row appears, formatted `9.99 €` (value-first).
3. Swipe a row to delete → it disappears.
4. Switch tabs via the floating bar.

- [ ] **Step 6: Commit**

```bash
git add App/DesignSystem/Components/FloatingTabBar.swift App/Features
git commit -m "feat: app shell with floating tab bar and category seeding"
```

---

## Task 14: Add macOS destination

**Files:**
- Modify: `project.yml`

- [ ] **Step 1: Switch the target to multiplatform**

In `project.yml`, replace `platform: iOS` on the `Subs` target with:
```yaml
    supportedDestinations: [iOS, macOS]
```
and add to `options.deploymentTarget`:
```yaml
    macOS: "15.0"
```

- [ ] **Step 2: Regenerate and verify destinations**

Run:
```bash
xcodegen generate
xcodebuild -project Subs.xcodeproj -scheme Subs -showdestinations
```
Expected: lists both an iOS Simulator destination and a `platform:macOS` destination.

> If `supportedDestinations` is not recognized by the installed XcodeGen version, fall back to declaring two targets (`Subs_iOS` with `platform: iOS`, `Subs_macOS` with `platform: macOS`, identical `sources`/`dependencies`) and a shared scheme. Note the change in the commit message.

- [ ] **Step 3: Build for macOS**

Run:
```bash
xcodebuild -project Subs.xcodeproj -scheme Subs -destination 'platform=macOS' build
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add project.yml
git commit -m "feat: add macOS destination to the app target"
```

---

## Task 15: README + LICENSE

**Files:**
- Create: `LICENSE`
- Create: `README.md`

- [ ] **Step 1: Add the MIT license**

`LICENSE` — standard MIT text, copyright `2026 Ahmed Abouelleil`.

- [ ] **Step 2: Add the README**

`README.md`:
```markdown
# Subs — open-source subscription tracker

Native iPhone + Mac subscription tracker (SwiftUI + SwiftData), Trade Republic
design language, local-first with iCloud sync planned. MIT licensed.

## Develop

```bash
brew install xcodegen        # one-time
cd SubscriptionKit && swift test   # run the domain unit tests
cd .. && xcodegen generate          # regenerate Subs.xcodeproj
open Subs.xcodeproj                 # build & run in Xcode
```

The `.xcodeproj` is generated from `project.yml` and is not committed.

## Structure
- `SubscriptionKit/` — pure, tested domain logic (no UI)
- `App/` — SwiftUI app: Models, DesignSystem, Features

See `docs/superpowers/specs/` for the design spec.
```

- [ ] **Step 3: Commit**

```bash
git add LICENSE README.md
git commit -m "docs: add MIT license and README"
```

---

## Done criteria

- `cd SubscriptionKit && swift test` → all tests pass.
- `xcodegen generate && xcodebuild ... build` → BUILD SUCCEEDED for iOS and macOS.
- The app runs: add → row appears with value-first formatting → swipe-delete works → tabs switch.
- Next plan: subscription detail + edit (rest of M1), then M2 (Home overview & totals).
