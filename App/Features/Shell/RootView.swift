import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @State private var selection: AppTab = .subscriptions

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selection {
                case .home: HomePlaceholderView()
                case .subscriptions: SubscriptionsView()
                case .settings: SettingsPlaceholderView()
                }
            }
            FloatingTabBar(selection: $selection)
                .padding(.bottom, 8)
        }
        .background(Theme.bg)
        .task { CategorySeed.seedIfNeeded(context) }
    }
}
