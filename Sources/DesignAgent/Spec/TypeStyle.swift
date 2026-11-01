//  WHAT: A type line: one style of the brand's type scale, `title: 28 bold rounded`. After the name come, in any order,
//        a size in points, a weight, a design (`serif`, `rounded`, `monospaced`), `italic`, and the text style it grows
//        and shrinks with under Dynamic Type. A name that is a text style (`title`, `body`) scales with that style and
//        takes its size and weight when the line leaves them out; any other name scales with the style nearest its size.

import Foundation

struct TypeStyle: Equatable, Sendable {
    var name: String
    var size: Double
    var weight: FontWeight
    var design: FontDesign
    var italic: Bool
    var style: TextStyle
    var doc: String?

    /// As `Font` names it: `brandTitle`, `brandCaption2`.
    var member: String { "brand" + name.prefix(1).uppercased() + name.dropFirst() }

    /// The scale every design has: each text style at Apple's size and weight, each changed by a line of its name.
    static let defaults: [TypeStyle] = TextStyle.allCases.map {
        TypeStyle(name: $0.rawValue, size: $0.size, weight: $0.weight, design: .default, italic: false, style: $0, doc: nil)
    }

    static func parse(_ line: String) throws -> TypeStyle {
        guard let parts = DesignLine.split(line) else {
            throw DesignError.line(line, "a type line is `name: size weight design`, like `title: 28 bold rounded`, and this has no colon")
        }
        guard let name = DesignLine.member(parts.name) else {
            throw DesignError.line(line, "`\(parts.name)` is not a style's name: start it with a letter")
        }
        var size: Double?, weight: FontWeight?, design: FontDesign?, style: TextStyle?, italic = false
        for word in parts.value.replacingOccurrences(of: ",", with: " ").split(separator: " ").map(String.init) {
            if let points = DesignLine.points(word) {
                guard size == nil else { throw DesignError.line(line, "\(name) gives two sizes") }
                size = points
            } else if word.lowercased() == "pt" {
                continue
            } else if let found = FontWeight.word(word) {
                weight = found
            } else if let found = FontDesign.word(word) {
                design = found
            } else if word.lowercased() == "italic" {
                italic = true
            } else if let found = TextStyle.word(word) {
                style = found
            } else {
                throw DesignError.line(line, "`\(word)` is not a size, a weight (regular, medium, semibold, bold…), a design (serif, rounded, monospaced), `italic`, or a text style (body, headline, title…)")
            }
        }
        let named = style ?? TextStyle.word(name)
        guard let points = size ?? named?.size else {
            throw DesignError.line(line, "\(name) needs a size in points, like `\(name): 18 semibold`")
        }
        guard (6...200).contains(points) else { throw DesignError.line(line, "\(name)'s size, \(points), is not from 6 to 200 points") }
        let chosen = weight ?? named?.weight ?? .regular
        return TypeStyle(name: name, size: points, weight: chosen, design: design ?? .default, italic: italic,
                         style: named ?? TextStyle.nearest(to: points, weight: chosen), doc: parts.doc)
    }
}
