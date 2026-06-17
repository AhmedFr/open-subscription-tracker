# Subs

> An open-source subscription tracker for iPhone and Mac — native, private, and beautiful.

Subs helps you see exactly what you're paying for and when. It's a native
**SwiftUI** app with a **Trade Republic–inspired** design language: one hero
number, near-monochrome surfaces, semantic color, and a quiet, precise type
system. Your data lives on-device and syncs across your own Apple devices via
**iCloud** — no accounts, no servers.

**Status:** Early development. The foundation (tested domain core, design system,
data model) and the first add/list/delete flow are being built. See
[`status.html`](status.html) for a live snapshot of progress.

## Design

The interface follows the Trade Republic discipline, codified in
[`docs/superpowers/specs`](docs/superpowers/specs):

- Value-first currency formatting (`86.97 €`, symbol after, European grouping)
- Sentence-case section headers; weight + size hierarchy, not color
- Semantic green/red only (e.g. spend down = good), with triangle meters
- Hairline-separated rows instead of cards; restrained circular logos
- A floating bottom navigation pill; full-width primary buttons

## Tech stack

- **Swift 6 / SwiftUI** — one codebase for iPhone and Mac
- **SwiftData + CloudKit** — local-first storage with iCloud sync (CloudKit wiring lands in a later milestone)
- **`SubscriptionKit`** — a dependency-free Swift package holding the pure, unit-tested domain logic (money, billing cycles, next-charge math, formatting)
- **Swift Testing** — fast, UI-free tests for the domain core
- **XcodeGen** — the `.xcodeproj` is generated from `project.yml`, not committed

## Repository layout

```
SubscriptionKit/   Pure, tested domain logic (no UI, no SwiftData)
App/
  Models/          SwiftData models (Subscription, Category, PaymentMethod)
  DesignSystem/    Trade Republic tokens + reusable components
  Features/        SwiftUI screens (Subscriptions, Add/Edit, Shell, …)
  Persistence/     Model container + seed data
docs/superpowers/  Design spec and implementation plans
project.yml        XcodeGen project definition
```

## Develop

Requirements: macOS with **Xcode 26+** and **Homebrew**.

```bash
# one-time: install the project generator
brew install xcodegen

# run the domain unit tests (no Xcode needed)
cd SubscriptionKit && swift test

# generate and open the app
cd .. && xcodegen generate && open Subs.xcodeproj
```

`Subs.xcodeproj` is regenerated from `project.yml` and is intentionally
gitignored — run `xcodegen generate` after pulling changes.

## Roadmap

- **M0–M1 (in progress):** foundation + core CRUD (add / list / delete)
- **M2:** Home overview — monthly/yearly totals, upcoming, month-over-month
- **M3:** multi-currency with live exchange rates (offline-capable)
- **M4:** auto-detect — type a service name to fill category, color, and logo
- **M5:** local reminders before charges
- **M6:** iCloud sync polish, macOS sidebar, accessibility, design polish

Deferred (post-v1): calendar view, statistics screen, import manager, CSV
export, Apple Watch, widgets, Mac menu-bar app, and a self-hostable web app.

## License

MIT (license file pending).
