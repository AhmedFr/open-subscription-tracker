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
