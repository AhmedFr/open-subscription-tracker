# Subscription Tracker (iOS / macOS) — Design Spec

**Date:** 2026-06-16
**Status:** Approved design, ready for implementation planning
**Working name:** open-subscription-tracker

## 1. Summary

A native, open-source subscription tracker for iPhone and Mac that matches the
feature intent of [subsday](https://subsday.appps.od.ua/) and adopts the
Trade Republic visual language. It is **local-first** with **CloudKit** sync —
no servers, no accounts — using the user's own iCloud. The repository is public
(MIT). A web app / self-hostable backend is explicitly **deferred** and is a
non-goal for this milestone, even if revisiting it later means a rewrite.

## 2. Goals & non-goals

### Goals (v1)
- Native iPhone + Mac app, one shared SwiftUI codebase.
- Core subscription tracking: add / edit / list / detail / delete.
- Home overview with monthly & yearly totals and upcoming charges.
- Local notification reminders before charges.
- iCloud (CloudKit) sync + backup across the user's devices.
- **Multi-currency** with live exchange rates (160+ currencies), offline-capable.
- **Auto-detect**: typing a service name fills category, brand color, and logo.
- Trade Republic design language, executed faithfully (this is make-or-break).

### Non-goals (deferred, post-v1)
Calendar view; dedicated statistics/Insights screen; import manager
(App Store / Notion / Sheets); CSV export; Apple Watch; widgets; Mac menu-bar
app; multi-user accounts; web app / self-hostable backend.

## 3. Stack & architecture

| Layer | Choice | Rationale |
|---|---|---|
| Language / UI | Swift 6 + SwiftUI, single multiplatform target | Native iPhone & Mac; Watch/widgets/menu-bar remain easy to add later |
| Min OS | iOS 18 / macOS 15 | Mature SwiftData + modern SwiftUI |
| Persistence + sync | **SwiftData + CloudKit** (private DB) | Offline-first local store with automatic iCloud sync & backup; no server |
| Reminders | UserNotifications (local) | On-device "charge in N days" notifications |
| FX rates | open.er-api.com (free, no key); frankfurter.app fallback | Daily fetch, cached; offline on last snapshot |
| Auto-detect | Bundled `services.json` + runtime favicon fetch w/ disk cache | OSS-friendly, community-extendable, no bundled proprietary logos |
| Tests | Swift Testing | Pure logic (date math, FX, catalog match, totals) is testable without UI |
| License | MIT, public repo | Standard for an OSS utility |

**Persistence decision:** Use SwiftData + CloudKit. Keep the data layer behind a
small repository protocol so we can swap to Core Data +
`NSPersistentCloudKitContainer` if we hit CloudKit sync edge cases — without
touching the UI.

**CloudKit constraints (must follow in the model):** every attribute has a
default value, all relationships are optional, no `@Attribute(.unique)`
constraints, no `.deny` delete rules.

### Module / folder structure
Adapts the user's "single responsibility / small files" rule to Swift idioms.

```
App/                 App entry, ModelContainer + CloudKit config
Models/              Subscription, Category, PaymentMethod, FXSnapshot, enums
Services/            One folder per service: protocol + impl + tests
  BillingScheduler/  cycle date math, upcoming charges, month-end handling
  CurrencyConverter/ normalize cycle -> monthly/yearly, FX conversion
  SpendCalculator/   totals, by-category, month-over-month delta
  FXRateService/     fetch + cache exchange rates
  CatalogService/    auto-detect fuzzy match against services.json
  LogoProvider/      bundled asset -> cached favicon -> monogram fallback
  NotificationScheduler/ schedule/cancel/reconcile reminders
DesignSystem/        Tokens (color/type/spacing) + reusable TR components
Features/            Home, Subscriptions, AddEdit, Detail, Settings
  <Feature>/         View(s) + ViewModel + subviews
Resources/           services.json, fallback FX snapshot, Assets
Tests/               Unit tests for services
```

## 4. Data model (SwiftData `@Model`)

**Subscription**
- `id: UUID`, `name: String`
- `amount: Decimal`, `currencyCode: String` (ISO 4217)
- `billingCycle: BillingCycle` (enum: weekly, monthly, quarterly, semiAnnual, yearly, custom), `customIntervalDays: Int?`
- `firstBillingDate: Date`, `nextChargeDate: Date` (cached, derived; used for sort & notifications)
- `category: Category?`, `paymentMethod: PaymentMethod?`
- `colorHex: String`, `catalogServiceId: String?`
- `notes: String?`, `reminderLeadDays: Int?` (nil = no reminder)
- `isActive: Bool` (active vs canceled/archived), `startedDate: Date?`
- `createdAt: Date`, `updatedAt: Date`

**Category** — `id`, `name`, `colorHex`, `sfSymbol`, `isBuiltIn: Bool`, `sortOrder: Int`
Built-in seed set: Entertainment, Music, Productivity, Utilities, Health & Fitness,
News, Gaming, Cloud & Storage, Shopping, Education, Finance, Other.

**PaymentMethod** — `id`, `label`, `type` (card/paypal/bank/applePay/other), `last4: String?`

**FXSnapshot** — `baseCurrency: String`, `fetchedAt: Date`, `ratesJSON: Data` (encoded `[String: Decimal]`)

**Preferences** (UserDefaults via `@AppStorage`, not CloudKit-synced domain data):
`displayCurrencyCode`, `appearance` (system/light/dark), `defaultReminderLeadDays`.

## 5. Domain logic (pure, unit-tested)

- **BillingScheduler** — next charge date from anchor + cycle; charges within a date
  range; month-end clamping (e.g. Jan 31 monthly → Feb 28/29).
- **CurrencyConverter** — normalize any cycle to a monthly and yearly equivalent
  (weekly ×52/12, quarterly /3, yearly /12, custom by days); convert `Decimal`
  amounts via an `FXSnapshot`.
- **SpendCalculator** — active-subscription aggregates: monthly total, yearly total,
  by-category breakdown, month-over-month delta (drives the home meter).
- **CatalogService** — normalize input, match by prefix/alias/contains + fuzzy
  distance against `services.json`, return best suggestion(s).

Network/side-effecting services (`FXRateService`, `LogoProvider`,
`NotificationScheduler`) sit behind protocols with mockable implementations.

## 6. Screens (v1)

Navigation: **3 tabs** on iPhone via a floating pill nav — Home · Subscriptions ·
Settings. macOS uses a `NavigationSplitView` sidebar with the same destinations.

1. **Home / Overview** — hero monthly total + month-over-month meter; Month/Year
   segmented toggle; Upcoming charges list. *Stretch within v1:* spend trend line
   chart + by-category breakdown bars.
2. **Subscriptions** — full list with search, sort (next charge / amount / name /
   category), and active/all filter.
3. **Add / Edit** — name field triggers auto-detect (prefills category, color,
   logo); amount + currency picker; billing cycle; first/next date; payment method;
   reminder lead; notes.
4. **Detail** — description-list of fields (next charge, billing cycle, payment
   method, started, total paid, reminder) + Edit and Mark-as-canceled actions.
5. **Settings** — display currency; appearance; default reminder; manage categories;
   manage payment methods; iCloud sync status; about / open-source / licenses.
6. **Supporting sheets** — currency picker, category picker, payment-method picker.

## 7. Design system — Trade Republic language

Derived from the real Trade Republic web markup. **Faithfulness here is the
make-or-break criterion.** Exact green/red/grey hex to be finalized against the
live app; values below are the working tokens.

### Principles
- One hero number dominates each primary screen; everything else recedes.
- Near-monochrome. Color is **semantic only** (green = good, red = bad); no
  decorative accent, no brand-colored tiles.
- Rows separated by **hairlines**, not cards.
- Restraint over decoration; generous, controlled negative space.

### Color tokens
**Light:** bg `#FFFFFF` · surface `#F4F4F6` · track `#ECECEF` · text `#0D0D0F` ·
text-secondary `#A0A0A7` · hairline `rgba(0,0,0,.06)` · positive `#00C46A` ·
negative `#F5475B` · primary-button `#0D0D0F`.
**Dark:** inverted — bg near-black · raised surface `#161618` · text `#FFFFFF` ·
text-secondary ~`#86868B` · hairline `rgba(255,255,255,.08)`; positive/negative
as light. Both themes ship; default follows the system setting.

### Typography (SF Pro, system)
- Hero number: 34–36pt, **weight 700**, tracking −0.03em, **tabular** figures.
- Section title: 15pt, weight 600.
- Row name: 14pt, weight 500.
- Amount (right column): 14pt, weight 600, tabular.
- Secondary / labels: 12pt, weight 400, secondary-grey.
- Hierarchy comes from **weight + size contrast**, not color.

### Number & currency formatting
- **Value first, symbol after, with a non-breaking space**: `86.97 €`,
  `1,043.64 €` (locale-aware grouping via `NumberFormatter`).
- Performance meter: triangle arrow + value + parenthesized percent, e.g.
  `▼ 4.99 € (5.4 %)`. **Down = green** when monthly spend decreases (good);
  **up = red** when it increases.

### Components (DesignSystem)
- Circular muted logo — 32pt in lists, 50pt on detail; monogram fallback.
- Grey pill **tag** for category.
- Hairline divider rows (top-border).
- **Segmented pill** toggle (Month/Year).
- Thin **2px line chart** (stretch).
- Horizontal **breakdown bars** (stretch).
- **Floating bottom nav**: detached blurred rounded pill, shadow, ~19pt icons,
  active tab = filled dark circle (iPhone only).
- Buttons: full-width 44pt black pill primary; red text destructive.

### Motion
Restrained and fast; standard SwiftUI transitions. No flourish.

## 8. External dependencies & de-risking

- **FX rates** — `open.er-api.com` primary, `frankfurter.app` (ECB) fallback.
  Fetch base once per day → `FXSnapshot`. Offline uses the last snapshot; a
  **bundled fallback snapshot** guarantees first-launch-offline still converts.
  Surface a subtle "rates as of <date>" note.
- **Auto-detect catalog** — bundled `services.json` (~300 popular services:
  `name`, `aliases[]`, `category`, `brandColorHex`, `domain`). Logos resolved at
  runtime by domain (favicon endpoint), disk-cached, monogram fallback — no
  bundled proprietary logos. The JSON is the open-source contribution surface.
  The app works fully when a typed name has no catalog match (manual entry).

## 9. Testing

Swift Testing unit coverage for the pure logic: `BillingScheduler` (cycle math,
month-end clamping), `CurrencyConverter` (cycle normalization + conversion),
`SpendCalculator` (totals, by-category, MoM), `CatalogService` (fuzzy match),
`FXSnapshot` decode. Network providers mocked. UI testing kept light.

## 10. Milestones (each → its own implementation plan)

- **M0 — Scaffold:** Xcode multiplatform project, SwiftData + CloudKit
  entitlement, DesignSystem tokens + core components, git init, MIT license,
  README, `.gitignore`.
- **M1 — Core CRUD:** Subscription model + repository, Add/Edit form (no
  auto-detect yet), Subscriptions list, Detail screen, built-in categories &
  payment methods.
- **M2 — Home overview:** BillingScheduler + SpendCalculator; hero monthly/yearly
  totals; Month/Year toggle; Upcoming list; MoM meter.
- **M3 — Multi-currency:** currency picker; FXRateService + CurrencyConverter;
  display-currency setting; totals in display currency; offline cache + bundled
  fallback.
- **M4 — Auto-detect:** `services.json`; CatalogService matching; LogoProvider
  (assets + favicon cache + monogram); wire into Add/Edit.
- **M5 — Reminders:** NotificationScheduler; reminder-lead setting; permission
  flow; reconcile on data changes.
- **M6 — iCloud polish & platform:** appearance toggle; Settings; sync status;
  empty states; macOS sidebar adaptation; accessibility (Dynamic Type, contrast);
  final design-polish pass. *Stretch:* home trend chart + by-category bars.

## 11. Open questions to resolve during planning
- Exact Trade Republic green/red/grey hex (finalize from the live app).
- Display typeface: SF Pro (default) vs. a closer grotesque if SF Pro reads off.
- `services.json` initial seed list (which ~300 services, sourced how).
