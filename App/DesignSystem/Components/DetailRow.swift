import SwiftUI

/// A hairline-topped label/value row — the Trade Republic description-list style.
struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(Theme.text2)
            Spacer(minLength: 12)
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.text)
        }
        .padding(.vertical, 11)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.hairline).frame(height: 1)
        }
    }
}
