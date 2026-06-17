import Foundation

public enum CurrencyFormatter {
    /// Value first, symbol after, non-breaking space between — Trade Republic style.
    public static func string(for money: Money, locale: Locale = .current) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.locale = locale
        nf.minimumFractionDigits = 2
        nf.maximumFractionDigits = 2
        let number = NSDecimalNumber(decimal: money.amount)
        let value = nf.string(from: number) ?? "\(money.amount)"
        return "\(value)\u{00A0}\(symbol(for: money.currencyCode, locale: locale))"
    }

    public static func symbol(for currencyCode: String, locale: Locale = .current) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.locale = locale
        nf.currencyCode = currencyCode
        return nf.currencySymbol ?? currencyCode
    }
}
