//  WHAT: A colour set of the project's asset catalogs, as code names it: its folders that provide a namespace and its
//        own name, `colors/background`, read with `Color("colors/background")`.

import Foundation

struct ColorSet: Equatable, Sendable {
    /// As code names it: `colors/background`, or `background` outside a namespace.
    var name: String
    /// Its own name: `background`.
    var base: String
    /// Whether a folder of the catalog gives it a namespace.
    var namespaced: Bool

    /// Xcode's symbol for it: `background`; `accent` for `AccentColor`.
    var symbol: String { SymbolName.of(base) }
}
