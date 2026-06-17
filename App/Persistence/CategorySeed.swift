import SwiftData

enum CategorySeed {
    // (name, hex, SF Symbol)
    static let builtIns: [(String, String, String)] = [
        ("Entertainment", "#F5475B", "play.tv"),
        ("Music",         "#00C46A", "music.note"),
        ("Productivity",  "#3A8DDE", "checkmark.circle"),
        ("Cloud & Storage", "#7C8DDE", "icloud"),
        ("Utilities",     "#9A9AA1", "bolt"),
        ("Health & Fitness", "#FF7A45", "heart"),
        ("News",          "#0D0D0F", "newspaper"),
        ("Gaming",        "#A35BFF", "gamecontroller"),
        ("Shopping",      "#FFB018", "bag"),
        ("Education",     "#16A4C7", "book"),
        ("Finance",       "#00A86B", "creditcard"),
        ("Other",         "#9A9AA1", "square.grid.2x2"),
    ]

    @MainActor
    static func seedIfNeeded(_ context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<Category>())) ?? 0
        guard count == 0 else { return }
        for (index, item) in builtIns.enumerated() {
            let c = Category()
            c.name = item.0
            c.colorHex = item.1
            c.sfSymbol = item.2
            c.isBuiltIn = true
            c.sortOrder = index
            context.insert(c)
        }
        try? context.save()
    }
}
