import SwiftUI
import SwiftData

struct EditSubscriptionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    let subscription: Subscription
    @State private var draft: SubscriptionDraft

    init(subscription: Subscription) {
        self.subscription = subscription
        _draft = State(initialValue: SubscriptionDraft(from: subscription))
    }

    var body: some View {
        SubscriptionFormView(
            draft: $draft,
            categories: categories,
            title: "Edit subscription",
            onCancel: { dismiss() },
            onSave: {
                draft.apply(to: subscription)
                try? context.save()
                dismiss()
            }
        )
    }
}
