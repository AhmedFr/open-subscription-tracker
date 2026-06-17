import SwiftUI

struct SettingsPlaceholderView: View {
    var body: some View {
        VStack(spacing: 6) {
            Text("Settings").font(.trSectionTitle).foregroundStyle(Theme.text)
            Text("Currency, appearance, reminders arrive later.")
                .font(.trSecondary).foregroundStyle(Theme.text2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg)
    }
}
