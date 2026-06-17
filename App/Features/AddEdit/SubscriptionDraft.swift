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
