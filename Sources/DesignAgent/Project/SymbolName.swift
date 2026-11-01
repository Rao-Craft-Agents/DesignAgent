//  WHAT: The name Xcode gives an asset's generated symbol: the asset's words in lowerCamelCase, a trailing `Color`
//        dropped from a colour's name (`AccentColor` → `accent`, `warning-red` → `warningRed`, `Separator` →
//        `separator`). What a role is matched to a colour set by, and what Xcode declares on `Color` when a project
//        turns on Swift asset symbol extensions.

import Foundation

enum SymbolName {
    static func of(_ name: String) -> String {
        var base = name
        if base.hasSuffix("Color"), base.count > 5 { base.removeLast(5) }
        let words = base.split(whereSeparator: { !($0.isLetter || $0.isNumber) }).map(String.init)
        guard let first = words.first else { return "" }
        return first.prefix(1).lowercased() + first.dropFirst()
            + words.dropFirst().map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined()
    }
}
