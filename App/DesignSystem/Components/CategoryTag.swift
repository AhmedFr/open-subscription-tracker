import SwiftUI

struct CategoryTag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(Theme.text2)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Theme.surface, in: Capsule())
    }
}
