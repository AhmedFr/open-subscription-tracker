import SwiftUI
import SwiftData

struct AddSubscriptionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var draft = SubscriptionDraft()

    var body: some View {
        SubscriptionFormView(
            draft: $draft,
            categories: categories,
            title: "New subscription",
            onCancel: { dismiss() },
            onSave: {
                let sub = Subscription()
                draft.apply(to: sub)
                context.insert(sub)
                try? context.save()
                dismiss()
            }
        )
    }
}
