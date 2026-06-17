import SwiftData

enum AppModelContainer {
    static let shared: ModelContainer = {
        do {
            return try ModelContainer(for: Subscription.self, Category.self, PaymentMethod.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
}
