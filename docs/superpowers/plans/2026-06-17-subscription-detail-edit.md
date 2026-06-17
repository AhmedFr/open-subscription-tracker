# Subscription Detail + Edit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Trade Republic–style subscription **detail** screen and an **edit** flow, sharing one persistence path with the existing Add form, on top of a testable cycle⇄raw coding extracted into `SubscriptionKit`.

**Architecture:** Extract the `BillingCycle` ⇄ (rawCode, customDays) mapping into `SubscriptionKit` as pure, unit-tested code; refactor `Subscription.cycle` to use it. Introduce a `SubscriptionDraft` value type that captures the editable fields and `apply(to:)`s them to a `Subscription` (setting `nextChargeDate` and `updatedAt`). Extract a shared `SubscriptionFormView` used by both `AddSubscriptionView` and a new `EditSubscriptionView`. Add a `SubscriptionDetailView` (reusable `DetailRow` description-list) reachable by tapping a list row.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, Swift Testing, XcodeGen. Builds verified with `xcodebuild ... -destination 'generic/platform=iOS Simulator'`; domain tests with `swift test --package-path SubscriptionKit`.

**Spec coverage (this plan):** Completes §6 "Detail" + "Add/Edit" screens of the design spec; implements the final-review recommendations (testable cycle bridge, shared Add/Edit persistence, `updatedAt` on mutation). Deferred as before: Home totals (M2), FX (M3), auto-detect (M4), reminders (M5), CloudKit + macOS sidebar + a11y (M6). "Total paid" is intentionally omitted (no payment history yet).

---

## File Structure

```
SubscriptionKit/Sources/SubscriptionKit/
  BillingCycle+Coding.swift     NEW — rawCode / init(rawCode:customIntervalDays:) / customDays
SubscriptionKit/Tests/SubscriptionKitTests/
  BillingCycleCodingTests.swift NEW — round-trip tests
App/Models/
  Subscription.swift            MODIFY — cycle uses the new coding; add touch()
App/Features/AddEdit/
  SubscriptionDraft.swift        NEW — editable fields + apply(to:)
  SubscriptionFormView.swift     NEW — shared form UI (Add + Edit)
  AddSubscriptionView.swift      MODIFY — thin wrapper using draft + form
  EditSubscriptionView.swift     NEW — edit an existing subscription
App/DesignSystem/Components/
  DetailRow.swift                NEW — hairline label/value row
App/Features/Detail/
  SubscriptionDetailView.swift   NEW — detail screen + actions
App/Features/Subscriptions/
  SubscriptionsView.swift        MODIFY — rows navigate to detail
```

---

## Task 1: Testable `BillingCycle` raw coding (SubscriptionKit, TDD)

**Files:**
- Create: `SubscriptionKit/Sources/SubscriptionKit/BillingCycle+Coding.swift`
- Test: `SubscriptionKit/Tests/SubscriptionKitTests/BillingCycleCodingTests.swift`

- [ ] **Step 1: Write the failing tests**

`BillingCycleCodingTests.swift`:
```swift
import Testing
@testable import SubscriptionKit

@Test func presetsRoundTripThroughRawCode() {
    for cycle in BillingCycle.presets {
        let decoded = BillingCycle(rawCode: cycle.rawCode, customIntervalDays: 0)
        #expect(decoded == cycle)
    }
}

@Test func customRoundTrips() {
    let c = BillingCycle.custom(days: 14)
    #expect(c.rawCode == "custom")
    #expect(c.customDays == 14)
    #expect(BillingCycle(rawCode: "custom", customIntervalDays: 14) == c)
}

@Test func presetsHaveNilCustomDays() {
    #expect(BillingCycle.monthly.customDays == nil)
    #expect(BillingCycle.yearly.customDays == nil)
}

@Test func unknownRawCodeDefaultsToMonthly() {
    #expect(BillingCycle(rawCode: "nonsense", customIntervalDays: 0) == .monthly)
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `swift test --package-path SubscriptionKit`
Expected: FAIL — `rawCode` / `customDays` / `init(rawCode:customIntervalDays:)` not found.

- [ ] **Step 3: Implement the coding**

`BillingCycle+Coding.swift`:
```swift
public extension BillingCycle {
    /// Stable string identifier for persistence.
    var rawCode: String {
        switch self {
        case .weekly: return "weekly"
        case .monthly: return "monthly"
        case .quarterly: return "quarterly"
        case .semiAnnual: return "semiAnnual"
        case .yearly: return "yearly"
        case .custom: return "custom"
        }
    }

    /// The interval in days, only present for `.custom`.
    var customDays: Int? {
        if case .custom(let days) = self { return days }
        return nil
    }

    /// Reconstruct a cycle from its persisted `rawCode` (+ days for custom).
    /// Unknown codes fall back to `.monthly`.
    init(rawCode: String, customIntervalDays: Int) {
        switch rawCode {
        case "weekly": self = .weekly
        case "monthly": self = .monthly
        case "quarterly": self = .quarterly
        case "semiAnnual": self = .semiAnnual
        case "yearly": self = .yearly
        case "custom": self = .custom(days: customIntervalDays)
        default: self = .monthly
        }
    }
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `swift test --package-path SubscriptionKit`
Expected: PASS (all prior tests + 4 new = 21 total).

- [ ] **Step 5: Commit**

```bash
git add SubscriptionKit
git commit -m "feat: add testable BillingCycle raw coding

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: Refactor `Subscription.cycle` to use the coding; add `touch()`

**Files:**
- Modify: `App/Models/Subscription.swift`

- [ ] **Step 1: Replace the `cycle` computed property and add `touch()`**

In `App/Models/Subscription.swift`, replace the entire existing `var cycle: BillingCycle { get { ... } set { ... } }` computed property with:
```swift
    var cycle: BillingCycle {
        get { BillingCycle(rawCode: cycleRaw, customIntervalDays: customIntervalDays) }
        set {
            cycleRaw = newValue.rawCode
            if let days = newValue.customDays { customIntervalDays = days }
        }
    }

    /// Mark the record as modified now.
    func touch() { updatedAt = .now }
```
Leave `money`, `refreshNextChargeDate`, and all stored properties unchanged.

- [ ] **Step 2: Build to verify**

Run:
```bash
xcodegen generate
xcodebuild -project Subs.xcodeproj -scheme Subs -destination 'generic/platform=iOS Simulator' build
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add App/Models/Subscription.swift
git commit -m "refactor: Subscription.cycle uses SubscriptionKit coding; add touch()

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: `SubscriptionDraft` value type

**Files:**
- Create: `App/Features/AddEdit/SubscriptionDraft.swift`

- [ ] **Step 1: Create the draft**

`App/Features/AddEdit/SubscriptionDraft.swift`:
```swift
import Foundation
import SubscriptionKit

/// The editable fields of a subscription, shared by the Add and Edit forms.
struct SubscriptionDraft {
    var name: String = ""
    var amountText: String = ""
    var currencyCode: String = "EUR"
    var cycle: BillingCycle = .monthly
    var firstBillingDate: Date = .now
    var category: Category?
    var notes: String = ""

    init() {}

    init(from s: Subscription) {
        name = s.name
        amountText = NSDecimalNumber(decimal: s.amountValue).stringValue
        currencyCode = s.currencyCode
        cycle = s.cycle
        firstBillingDate = s.firstBillingDate
        category = s.category
        notes = s.notes ?? ""
    }

    var amountDecimal: Decimal? {
        Decimal(string: amountText.replacingOccurrences(of: ",", with: "."))
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && (amountDecimal ?? 0) > 0
    }

    /// Write the draft's values onto a subscription, refresh its next charge date, and bump updatedAt.
    func apply(to s: Subscription) {
        s.name = name.trimmingCharacters(in: .whitespaces)
        if let amount = amountDecimal { s.amountValue = amount }
        s.currencyCode = currencyCode
        s.cycle = cycle
        s.firstBillingDate = firstBillingDate
        if s.startedDate == nil { s.startedDate = firstBillingDate }
        s.category = category
        let trimmedNotes = notes.trimmingCharacters(in: .whitespaces)
        s.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
        s.refreshNextChargeDate()
        s.touch()
    }
}
```

- [ ] **Step 2: Build to verify**

Run:
```bash
xcodegen generate
xcodebuild -project Subs.xcodeproj -scheme Subs -destination 'generic/platform=iOS Simulator' build
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add App/Features/AddEdit/SubscriptionDraft.swift
git commit -m "feat: add SubscriptionDraft shared form model

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: Shared `SubscriptionFormView`; refactor `AddSubscriptionView`

**Files:**
- Create: `App/Features/AddEdit/SubscriptionFormView.swift`
- Modify (replace contents): `App/Features/AddEdit/AddSubscriptionView.swift`

- [ ] **Step 1: Create the shared form**

`App/Features/AddEdit/SubscriptionFormView.swift`:
```swift
import SwiftUI
import SubscriptionKit

struct SubscriptionFormView: View {
    @Binding var draft: SubscriptionDraft
    let categories: [Category]
    let title: String
    let onCancel: () -> Void
    let onSave: () -> Void

    private let currencyOptions = ["EUR", "USD", "GBP", "CHF", "JPY", "CAD", "AUD"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Service") {
                    TextField("Name", text: $draft.name)
                }
                Section("Price") {
                    TextField("Amount", text: $draft.amountText)
                    #if os(iOS)
                        .keyboardType(.decimalPad)
                    #endif
                    Picker("Currency", selection: $draft.currencyCode) {
                        ForEach(currencyOptions, id: \.self) { Text($0).tag($0) }
                    }
                }
                Section("Billing") {
                    Picker("Cycle", selection: $draft.cycle) {
                        ForEach(BillingCycle.presets, id: \.self) { c in
                            Text(c.displayName).tag(c)
                        }
                    }
                    DatePicker("First charge", selection: $draft.firstBillingDate, displayedComponents: .date)
                }
                Section("Category") {
                    Picker("Category", selection: $draft.category) {
                        Text("Other").tag(Category?.none)
                        ForEach(categories) { cat in
                            Text(cat.name).tag(Category?.some(cat))
                        }
                    }
                }
                Section("Notes") {
                    TextField("Optional", text: $draft.notes, axis: .vertical)
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave).disabled(!draft.isValid)
                }
            }
        }
    }
}
```

- [ ] **Step 2: Replace `AddSubscriptionView` with a thin wrapper**

`App/Features/AddEdit/AddSubscriptionView.swift` (replace entire file):
```swift
import SwiftUI
import SwiftData

struct AddSubscriptionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var draft = SubscriptionDraft()

    var body: some View {
        SubscriptionFormView(
            draft: $draft,
            categories: categories,
            title: "New subscription",
            onCancel: { dismiss() },
            onSave: {
                let sub = Subscription()
                draft.apply(to: sub)
                context.insert(sub)
                try? context.save()
                dismiss()
            }
        )
    }
}
```

- [ ] **Step 3: Build to verify**

Run:
```bash
xcodegen generate
xcodebuild -project Subs.xcodeproj -scheme Subs -destination 'generic/platform=iOS Simulator' build
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add App/Features/AddEdit/SubscriptionFormView.swift App/Features/AddEdit/AddSubscriptionView.swift
git commit -m "refactor: extract shared SubscriptionFormView; Add uses draft

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 5: `EditSubscriptionView`

**Files:**
- Create: `App/Features/AddEdit/EditSubscriptionView.swift`

- [ ] **Step 1: Create the edit view**

`App/Features/AddEdit/EditSubscriptionView.swift`:
```swift
import SwiftUI
import SwiftData

struct EditSubscriptionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    let subscription: Subscription
    @State private var draft: SubscriptionDraft

    init(subscription: Subscription) {
        self.subscription = subscription
        _draft = State(initialValue: SubscriptionDraft(from: subscription))
    }

    var body: some View {
        SubscriptionFormView(
            draft: $draft,
            categories: categories,
            title: "Edit subscription",
            onCancel: { dismiss() },
            onSave: {
                draft.apply(to: subscription)
                try? context.save()
                dismiss()
            }
        )
    }
}
```

- [ ] **Step 2: Build to verify**

Run:
```bash
xcodegen generate
xcodebuild -project Subs.xcodeproj -scheme Subs -destination 'generic/platform=iOS Simulator' build
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add App/Features/AddEdit/EditSubscriptionView.swift
git commit -m "feat: add EditSubscriptionView reusing the shared form

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 6: `DetailRow` component + `SubscriptionDetailView`

**Files:**
- Create: `App/DesignSystem/Components/DetailRow.swift`
- Create: `App/Features/Detail/SubscriptionDetailView.swift`

- [ ] **Step 1: Create the reusable description-list row**

`App/DesignSystem/Components/DetailRow.swift`:
```swift
import SwiftUI

/// A hairline-topped label/value row — the Trade Republic description-list style.
struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(Theme.text2)
            Spacer(minLength: 12)
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.text)
        }
        .padding(.vertical, 11)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.hairline).frame(height: 1)
        }
    }
}
```

- [ ] **Step 2: Create the detail screen**

`App/Features/Detail/SubscriptionDetailView.swift`:
```swift
import SwiftUI
import SwiftData
import SubscriptionKit

struct SubscriptionDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let subscription: Subscription
    @State private var showingEdit = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                VStack(spacing: 0) {
                    DetailRow(label: "Next charge", value: mediumDate(subscription.nextChargeDate))
                    DetailRow(label: "Billing cycle", value: subscription.cycle.displayName)
                    DetailRow(label: "Amount", value: CurrencyFormatter.string(for: subscription.money))
                    DetailRow(label: "Category", value: subscription.category?.name ?? "Other")
                    DetailRow(label: "Payment method", value: subscription.paymentMethod?.label ?? "—")
                    DetailRow(label: "Started", value: subscription.startedDate.map(mediumDate) ?? "—")
                    DetailRow(label: "Reminder", value: reminderText)
                    DetailRow(label: "Status", value: subscription.isActive ? "Active" : "Canceled")
                }
                .padding(.top, 12)

                actions.padding(.top, 24)
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.bottom, 40)
        }
        .background(Theme.bg)
        .sheet(isPresented: $showingEdit) {
            EditSubscriptionView(subscription: subscription)
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            MonogramView(name: subscription.name, size: 50)
            Text(subscription.name)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.text)
            if let category = subscription.category {
                CategoryTag(text: category.name)
            }
            Text(CurrencyFormatter.string(for: subscription.money))
                .font(.system(size: 32, weight: .bold).monospacedDigit())
                .foregroundStyle(Theme.text)
                .padding(.top, 6)
            Text(subscription.cycle.displayName)
                .font(.trSecondary)
                .foregroundStyle(Theme.text2)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button("Edit subscription") { showingEdit = true }
                .buttonStyle(PrimaryButtonStyle())
            Button(subscription.isActive ? "Mark as canceled" : "Reactivate") {
                subscription.isActive.toggle()
                subscription.touch()
                try? context.save()
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Theme.negative)
            Button("Delete") {
                context.delete(subscription)
                try? context.save()
                dismiss()
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Theme.text2)
        }
    }

    private var reminderText: String {
        guard let days = subscription.reminderLeadDays else { return "Off" }
        return days == 1 ? "1 day before" : "\(days) days before"
    }

    private func mediumDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}
```

- [ ] **Step 3: Build to verify**

Run:
```bash
xcodegen generate
xcodebuild -project Subs.xcodeproj -scheme Subs -destination 'generic/platform=iOS Simulator' build
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add App/DesignSystem/Components/DetailRow.swift App/Features/Detail/SubscriptionDetailView.swift
git commit -m "feat: add DetailRow and SubscriptionDetailView

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 7: Navigate list → detail; build and run

**Files:**
- Modify: `App/Features/Subscriptions/SubscriptionsView.swift`

- [ ] **Step 1: Wrap each row in a NavigationLink to the detail screen**

In `App/Features/Subscriptions/SubscriptionsView.swift`, replace the `ForEach(subscriptions) { sub in ... }` body so each row navigates to the detail screen. The `ForEach` becomes:
```swift
            ForEach(subscriptions) { sub in
                NavigationLink {
                    SubscriptionDetailView(subscription: sub)
                } label: {
                    SubscriptionRow(
                        name: sub.name,
                        money: sub.money,
                        subtitle: "\(relativeDate(sub.nextChargeDate)) · \(sub.category?.name ?? "Other")"
                    )
                }
                .listRowInsets(EdgeInsets(top: 0, leading: Spacing.screenH, bottom: 0, trailing: Spacing.screenH))
                .listRowBackground(Theme.bg)
                .listRowSeparatorTint(Theme.hairline)
            }
            .onDelete(perform: delete)
```
Leave the rest of the file (empty state, toolbar, `delete`, `relativeDate`, the Add sheet) unchanged.

- [ ] **Step 2: Build to verify**

Run:
```bash
xcodegen generate
xcodebuild -project Subs.xcodeproj -scheme Subs -destination 'generic/platform=iOS Simulator' build
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Run on the simulator and verify by hand**

Run:
```bash
SIM=$(xcrun simctl list devices available | grep -m1 "iPhone 16 (" | grep -oE "[0-9A-F-]{36}")
xcrun simctl boot "$SIM" 2>/dev/null; open -a Simulator
xcodebuild -project Subs.xcodeproj -scheme Subs -destination "id=$SIM" -derivedDataPath build build
xcrun simctl install "$SIM" "build/Build/Products/Debug-iphonesimulator/Subs.app"
xcrun simctl launch "$SIM" com.ahmedabouelleil.subs
```
Manual checks:
1. Add a subscription, then tap its row → the **detail screen** opens (centered monogram + name + category tag + big value-first price + the hairline description list).
2. Tap **Edit subscription** → the form opens pre-filled; change the amount → Save → the detail + list reflect the new value.
3. Tap **Mark as canceled** → Status row flips to "Canceled" and the button becomes "Reactivate".
4. Tap **Delete** → returns to the list and the row is gone.

- [ ] **Step 4: Commit**

```bash
git add App/Features/Subscriptions/SubscriptionsView.swift
git commit -m "feat: navigate from list rows to subscription detail

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Done criteria

- `swift test --package-path SubscriptionKit` → 21 tests pass (17 + 4 new).
- iOS build succeeds; app runs.
- Tap a row → detail; Edit pre-fills and persists changes (with `updatedAt` bumped); Mark-as-canceled toggles status; Delete removes.
- Add and Edit share `SubscriptionFormView` + `SubscriptionDraft.apply(to:)` — one persistence path.
- Next plan: M2 — Home overview (monthly/yearly totals, upcoming, month-over-month) via `CurrencyConverter` + `SpendCalculator`.
