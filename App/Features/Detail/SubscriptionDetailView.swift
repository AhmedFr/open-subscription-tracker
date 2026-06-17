import SwiftUI
import SwiftData
import SubscriptionKit

struct SubscriptionDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let subscription: Subscription
    @State private var showingEdit = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                VStack(spacing: 0) {
                    DetailRow(label: "Next charge", value: mediumDate(subscription.nextChargeDate))
                    DetailRow(label: "Billing cycle", value: subscription.cycle.displayName)
                    DetailRow(label: "Amount", value: CurrencyFormatter.string(for: subscription.money))
                    DetailRow(label: "Category", value: subscription.category?.name ?? "Other")
                    DetailRow(label: "Payment method", value: subscription.paymentMethod?.label ?? "—")
                    DetailRow(label: "Started", value: subscription.startedDate.map(mediumDate) ?? "—")
                    DetailRow(label: "Reminder", value: reminderText)
                    DetailRow(label: "Status", value: subscription.isActive ? "Active" : "Canceled")
                    if let notes = subscription.notes, !notes.isEmpty {
                        DetailRow(label: "Notes", value: notes)
                    }
                }
                .padding(.top, 12)

                actions.padding(.top, 24)
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.bottom, 40)
        }
        .background(Theme.bg)
        .navigationTitle(subscription.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(isPresented: $showingEdit) {
            EditSubscriptionView(subscription: subscription)
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            MonogramView(name: subscription.name, size: 50)
            Text(subscription.name)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.text)
            if let category = subscription.category {
                CategoryTag(text: category.name)
            }
            Text(CurrencyFormatter.string(for: subscription.money))
                .font(.system(size: 32, weight: .bold).monospacedDigit())
                .foregroundStyle(Theme.text)
                .padding(.top, 6)
            Text(subscription.cycle.displayName)
                .font(.trSecondary)
                .foregroundStyle(Theme.text2)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button("Edit subscription") { showingEdit = true }
                .buttonStyle(PrimaryButtonStyle())
            Button(subscription.isActive ? "Mark as canceled" : "Reactivate") {
                subscription.isActive.toggle()
                subscription.touch()
                try? context.save()
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Theme.negative)
            Button("Delete") {
                context.delete(subscription)
                try? context.save()
                dismiss()
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Theme.text2)
        }
    }

    private var reminderText: String {
        guard let days = subscription.reminderLeadDays else { return "Off" }
        return days == 1 ? "1 day before" : "\(days) days before"
    }

    private func mediumDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}
