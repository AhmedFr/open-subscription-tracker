import SwiftUI

enum Theme {
    static let bg        = Color.dynamic(light: Color(hex: "#FFFFFF"), dark: Color(hex: "#000000"))
    static let surface   = Color.dynamic(light: Color(hex: "#F4F4F6"), dark: Color(hex: "#161618"))
    static let track     = Color.dynamic(light: Color(hex: "#ECECEF"), dark: Color(hex: "#26262A"))
    static let text      = Color.dynamic(light: Color(hex: "#0D0D0F"), dark: Color(hex: "#FFFFFF"))
    static let text2     = Color.dynamic(light: Color(hex: "#A0A0A7"), dark: Color(hex: "#86868B"))
    static let hairline  = Color.dynamic(light: Color.black.opacity(0.06), dark: Color.white.opacity(0.08))
    static let positive  = Color(hex: "#00C46A")
    static let negative  = Color(hex: "#F5475B")
}
