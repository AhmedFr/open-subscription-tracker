import SwiftUI

enum AppTab: CaseIterable {
    case home, subscriptions, settings
    var symbol: String {
        switch self {
        case .home: return "house.fill"
        case .subscriptions: return "list.bullet"
        case .settings: return "gearshape"
        }
    }
}

struct FloatingTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 6) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    selection = tab
                } label: {
                    Image(systemName: tab.symbol)
                        .font(.system(size: 19, weight: .medium))
                        .foregroundStyle(selection == tab ? Theme.bg : Theme.text2)
                        .frame(width: 40, height: 40)
                        .background(selection == tab ? Theme.text : Color.clear, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Theme.hairline, lineWidth: 1))
        .shadow(color: .black.opacity(0.16), radius: 15, y: 10)
    }
}
