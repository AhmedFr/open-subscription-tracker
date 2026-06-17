import SwiftUI

struct MonogramView: View {
    let name: String
    var size: CGFloat = 32

    private var letter: String {
        String(name.trimmingCharacters(in: .whitespaces).prefix(1)).uppercased()
    }

    var body: some View {
        Circle()
            .fill(Theme.surface)
            .frame(width: size, height: size)
            .overlay(
                Text(letter.isEmpty ? "•" : letter)
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundStyle(Theme.text2)
            )
    }
}
