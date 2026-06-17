import Foundation

public enum BillingCycle: Equatable, Hashable, Sendable {
    case weekly
    case monthly
    case quarterly
    case semiAnnual
    case yearly
    case custom(days: Int)

    public var displayName: String {
        switch self {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .semiAnnual: return "Every 6 months"
        case .yearly: return "Yearly"
        case .custom(let days): return "Every \(days) days"
        }
    }

    /// All non-custom cases, for pickers.
    public static var presets: [BillingCycle] {
        [.weekly, .monthly, .quarterly, .semiAnnual, .yearly]
    }
}
