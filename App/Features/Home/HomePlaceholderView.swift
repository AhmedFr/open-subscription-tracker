import SwiftUI

struct HomePlaceholderView: View {
    var body: some View {
        VStack(spacing: 6) {
            Text("Overview").font(.trSectionTitle).foregroundStyle(Theme.text)
            Text("Totals and upcoming arrive in M2.")
                .font(.trSecondary).foregroundStyle(Theme.text2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg)
    }
}
