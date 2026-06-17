import SwiftUI
import SubscriptionKit

struct SubscriptionRow: View {
    let name: String
    let money: Money
    let subtitle: String

    var body: some View {
        HStack(spacing: 11) {
            MonogramView(name: name)
            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.trRowName)
                    .foregroundStyle(Theme.text)
                Text(subtitle)
                    .font(.trSecondary)
                    .foregroundStyle(Theme.text2)
            }
            Spacer(minLength: 8)
            Text(CurrencyFormatter.string(for: money))
                .font(.trAmount)
                .foregroundStyle(Theme.text)
        }
        .padding(.vertical, Spacing.rowV)
    }
}
