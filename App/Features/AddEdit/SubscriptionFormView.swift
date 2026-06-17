import SwiftUI
import SubscriptionKit

struct SubscriptionFormView: View {
    @Binding var draft: SubscriptionDraft
    let categories: [Category]
    let title: String
    let onCancel: () -> Void
    let onSave: () -> Void

    private let currencyOptions = ["EUR", "USD", "GBP", "CHF", "JPY", "CAD", "AUD"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Service") {
                    TextField("Name", text: $draft.name)
                }
                Section("Price") {
                    TextField("Amount", text: $draft.amountText)
                    #if os(iOS)
                        .keyboardType(.decimalPad)
                    #endif
                    Picker("Currency", selection: $draft.currencyCode) {
                        ForEach(currencyOptions, id: \.self) { Text($0).tag($0) }
                    }
                }
                Section("Billing") {
                    Picker("Cycle", selection: $draft.cycle) {
                        ForEach(BillingCycle.presets, id: \.self) { c in
                            Text(c.displayName).tag(c)
                        }
                    }
                    DatePicker("First charge", selection: $draft.firstBillingDate, displayedComponents: .date)
                }
                Section("Category") {
                    Picker("Category", selection: $draft.category) {
                        Text("Other").tag(Category?.none)
                        ForEach(categories) { cat in
                            Text(cat.name).tag(Category?.some(cat))
                        }
                    }
                }
                Section("Notes") {
                    TextField("Optional", text: $draft.notes, axis: .vertical)
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave).disabled(!draft.isValid)
                }
            }
        }
    }
}
