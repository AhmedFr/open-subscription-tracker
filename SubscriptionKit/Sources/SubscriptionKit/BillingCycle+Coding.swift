import Foundation

public extension BillingCycle {
    /// Stable string identifier for persistence.
    var rawCode: String {
        switch self {
        case .weekly: return "weekly"
        case .monthly: return "monthly"
        case .quarterly: return "quarterly"
        case .semiAnnual: return "semiAnnual"
        case .yearly: return "yearly"
        case .custom: return "custom"
        }
    }

    /// The interval in days, only present for `.custom`.
    var customDays: Int? {
        if case .custom(let days) = self { return days }
        return nil
    }

    /// Reconstruct a cycle from its persisted `rawCode` (+ days for custom).
    /// Unknown codes fall back to `.monthly`.
    init(rawCode: String, customIntervalDays: Int) {
        switch rawCode {
        case "weekly": self = .weekly
        case "monthly": self = .monthly
        case "quarterly": self = .quarterly
        case "semiAnnual": self = .semiAnnual
        case "yearly": self = .yearly
        case "custom": self = .custom(days: customIntervalDays)
        default: self = .monthly
        }
    }
}
