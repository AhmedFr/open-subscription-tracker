import Foundation
import SwiftData

@Model
final class Category {
    var name: String = ""
    var colorHex: String = "#0D0D0F"
    var sfSymbol: String = "square.grid.2x2"
    var isBuiltIn: Bool = false
    var sortOrder: Int = 0

    init() {}
}
