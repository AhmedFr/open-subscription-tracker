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
