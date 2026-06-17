import SwiftUI
import SwiftData
import SubscriptionKit

struct SubscriptionsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Subscription.nextChargeDate, order: .forward)
    private var subscriptions: [Subscription]

    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            Group {
                if subscriptions.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .background(Theme.bg)
            .navigationTitle("Subscriptions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus").foregroundStyle(Theme.text)
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddSubscriptionView()
            }
        }
    }

    private var list: some View {
        List {
            ForEach(subscriptions) { sub in
                SubscriptionRow(
                    name: sub.name,
                    money: sub.money,
                    subtitle: "\(relativeDate(sub.nextChargeDate)) · \(sub.category?.name ?? "Other")"
                )
                .listRowInsets(EdgeInsets(top: 0, leading: Spacing.screenH, bottom: 0, trailing: Spacing.screenH))
                .listRowBackground(Theme.bg)
                .listRowSeparatorTint(Theme.hairline)
            }
            .onDelete(perform: delete)
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("No subscriptions yet")
                .font(.trSectionTitle).foregroundStyle(Theme.text)
            Text("Tap + to add your first one.")
                .font(.trSecondary).foregroundStyle(Theme.text2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func delete(_ offsets: IndexSet) {
        for index in offsets { context.delete(subscriptions[index]) }
        try? context.save()
    }

    private func relativeDate(_ date: Date) -> String {
        if Calendar.current.isDateInTomorrow(date) { return "Tomorrow" }
        if Calendar.current.isDateInToday(date) { return "Today" }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}
