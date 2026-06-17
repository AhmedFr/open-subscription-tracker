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
        get { BillingCycle(rawCode: cycleRaw, customIntervalDays: customIntervalDays) }
        set {
            cycleRaw = newValue.rawCode
            if let days = newValue.customDays { customIntervalDays = days }
        }
    }

    /// Mark the record as modified now.
    func touch() { updatedAt = .now }

    /// Recompute and store the next charge date from the anchor + cycle.
    func refreshNextChargeDate(now: Date = .now, calendar: Calendar = .current) {
        nextChargeDate = BillingScheduler(calendar: calendar)
            .nextChargeDate(firstBillingDate: firstBillingDate, cycle: cycle, after: now)
    }
}
