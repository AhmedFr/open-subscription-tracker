import SwiftUI
import SwiftData
import SubscriptionKit

struct AddSubscriptionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var name = ""
    @State private var amountText = ""
    @State private var currencyCode = "EUR"
    @State private var cycle: BillingCycle = .monthly
    @State private var firstBillingDate = Date()
    @State private var selectedCategory: Category?
    @State private var notes = ""

    private let currencyOptions = ["EUR", "USD", "GBP", "CHF", "JPY", "CAD", "AUD"]

    private var amountDecimal: Decimal? {
        Decimal(string: amountText.replacingOccurrences(of: ",", with: "."))
    }
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && (amountDecimal ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Service") {
                    TextField("Name", text: $name)
                }
                Section("Price") {
                    TextField("Amount", text: $amountText)
                    #if os(iOS)
                        .keyboardType(.decimalPad)
                    #endif
                    Picker("Currency", selection: $currencyCode) {
                        ForEach(currencyOptions, id: \.self) { Text($0).tag($0) }
                    }
                }
                Section("Billing") {
                    Picker("Cycle", selection: $cycle) {
                        ForEach(BillingCycle.presets, id: \.self) { c in
                            Text(c.displayName).tag(c)
                        }
                    }
                    DatePicker("First charge", selection: $firstBillingDate, displayedComponents: .date)
                }
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("Other").tag(Category?.none)
                        ForEach(categories) { cat in
                            Text(cat.name).tag(Category?.some(cat))
                        }
                    }
                }
                Section("Notes") {
                    TextField("Optional", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle("New subscription")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        guard let amount = amountDecimal else { return }
        let sub = Subscription()
        sub.name = name.trimmingCharacters(in: .whitespaces)
        sub.amountValue = amount
        sub.currencyCode = currencyCode
        sub.cycle = cycle
        sub.firstBillingDate = firstBillingDate
        sub.startedDate = firstBillingDate
        sub.category = selectedCategory
        sub.notes = notes.isEmpty ? nil : notes
        sub.refreshNextChargeDate()
        context.insert(sub)
        try? context.save()
        dismiss()
    }
}
