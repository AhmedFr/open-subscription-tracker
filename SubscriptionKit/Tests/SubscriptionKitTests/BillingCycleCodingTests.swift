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
