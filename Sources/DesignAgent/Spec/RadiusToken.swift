//  WHAT: A radius line: a corner radius by what it rounds, `card: 14`, as `Brand.Radius` holds it. A call's lines
//        change or add to the four every design has.

import Foundation

struct RadiusToken: Equatable, Sendable {
    var name: String
    var points: Double
    var doc: String?

    /// The radii every design has, each changed by a line of its name.
    static let defaults = [
        RadiusToken(name: "small", points: 4, doc: "Small pieces: tags, badges and thumbnails."),
        RadiusToken(name: "medium", points: 8, doc: "Controls: buttons, fields and menus."),
        RadiusToken(name: "card", points: 12, doc: "Cards and grouped sections."),
        RadiusToken(name: "large", points: 16, doc: "Sheets, panels and large images."),
    ]

    static func parse(_ line: String) throws -> RadiusToken {
        guard let parts = DesignLine.split(line) else {
            throw DesignError.line(line, "a radius line is `name: points`, like `card: 14`, and this has no colon")
        }
        guard let name = DesignLine.member(parts.name) else {
            throw DesignError.line(line, "`\(parts.name)` is not a radius's name: start it with a letter")
        }
        guard let points = DesignLine.points(parts.value), (0...1_000).contains(points) else {
            throw DesignError.line(line, "`\(parts.value)` is not a radius in points, like `14`")
        }
        return RadiusToken(name: name, points: points, doc: parts.doc)
    }
}
