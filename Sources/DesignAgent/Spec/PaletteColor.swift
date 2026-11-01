//  WHAT: A palette line: one colour of the brand, by name, as `Brand.Colors` holds it.
//
//            cream: #FBF7F0/#1A1714        one for light and one for dark
//            saffron: #E8A33D              one for both
//            ink: brandInk                 a colour set of the project's asset catalogs
//            scrim: #000000 40%            any of them, less opaque

import Foundation

struct PaletteColor: Equatable, Sendable {
    var name: String
    var color: ColorExpression
    var doc: String?

    static func parse(_ line: String) throws -> PaletteColor {
        guard let parts = DesignLine.split(line) else {
            throw DesignError.line(line, "a palette line is `name: #hex`, `name: #light/#dark` or `name: colourSet`, and this has no colon")
        }
        guard let name = DesignLine.member(parts.name) else {
            throw DesignError.line(line, "`\(parts.name)` is not a colour's name: start it with a letter")
        }
        guard !parts.value.isEmpty else { throw DesignError.line(line, "\(name) names no colour") }
        return PaletteColor(name: name, color: try ColorExpression.parse(parts.value, in: line), doc: parts.doc)
    }
}
