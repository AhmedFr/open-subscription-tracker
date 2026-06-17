import Testing
import Foundation
@testable import SubscriptionKit

private let enUS = Locale(identifier: "en_US")

@Test func formatsEuroValueFirstSymbolAfter() {
    let s = CurrencyFormatter.string(for: Money(amount: Decimal(1043.64), currencyCode: "EUR"), locale: enUS)
    #expect(s == "1,043.64\u{00A0}€")
}

@Test func formatsUSD() {
    let s = CurrencyFormatter.string(for: Money(amount: Decimal(9.99), currencyCode: "USD"), locale: enUS)
    #expect(s == "9.99\u{00A0}$")
}

@Test func alwaysTwoFractionDigits() {
    let s = CurrencyFormatter.string(for: Money(amount: Decimal(5), currencyCode: "EUR"), locale: enUS)
    #expect(s == "5.00\u{00A0}€")
}
