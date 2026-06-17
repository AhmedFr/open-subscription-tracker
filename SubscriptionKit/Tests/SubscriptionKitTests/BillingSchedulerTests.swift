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
