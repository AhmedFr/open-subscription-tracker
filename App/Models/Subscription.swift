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
