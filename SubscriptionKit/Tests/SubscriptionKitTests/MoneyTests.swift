import Testing
import Foundation
@testable import SubscriptionKit

@Test func moneyStoresAmountAndCurrency() {
    let m = Money(amount: Decimal(string: "9.99")!, currencyCode: "EUR")
    #expect(m.amount == Decimal(string: "9.99")!)
    #expect(m.currencyCode == "EUR")
}

@Test func moneyEquatable() {
    #expect(Money(amount: 5, currencyCode: "USD") == Money(amount: 5, currencyCode: "USD"))
    #expect(Money(amount: 5, currencyCode: "USD") != Money(amount: 5, currencyCode: "EUR"))
}
