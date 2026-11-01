//  WHAT: A colour as the code reads it, once the project is read: a hex, a pair for light and dark, a colour set of
//        the asset catalogs, or a palette colour, each with an opacity.

import Foundation

struct ResolvedColor: Equatable, Sendable {
    enum Source: Equatable, Sendable {
        case fixed(Hex)
        case adaptive(light: Hex, dark: Hex)
        /// A colour set, as code names it: `colors/background`.
        case asset(String)
        /// A palette colour, as `Brand.Colors` names it.
        case palette(String)
    }

    var source: Source
    /// From 0 to 1; nil when the line gave none.
    var opacity: Double?

    /// As a role's summary says it: `cream`, `cream 60%`, `#3F7D58/#6FBF8E`, `colour set colors/background`.
    var summary: String {
        let said: String
        switch source {
        case .fixed(let hex): said = hex.text
        case .adaptive(let light, let dark): said = "\(light.text)/\(dark.text)"
        case .asset(let name): said = "colour set \(name)"
        case .palette(let name): said = name
        }
        guard let opacity else { return said }
        return said + " \(SwiftNumber.text(opacity * 100))%"
    }
}
