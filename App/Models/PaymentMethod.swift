import Foundation
import SwiftData

@Model
final class PaymentMethod {
    var label: String = ""
    var typeRaw: String = "card"   // card | paypal | bank | applePay | other
    var last4: String?

    init() {}
}
