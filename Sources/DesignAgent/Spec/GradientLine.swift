//  WHAT: A gradient line: a named gradient, its colours in order and the way it runs, as `Brand.Gradients` holds it.
//
//            sunrise: saffron tomato                         palette colours, corner to corner
//            dusk: #2B2522 #6B4E71 vertical                  hex, top to bottom
//            glass: #FFFFFF 60% #FFFFFF 0% horizontal       any colour with an opacity, leading edge to trailing

import Foundation

struct GradientLine: Equatable, Sendable {
    enum Direction: String, Equatable, Sendable {
        /// From the top leading corner to the bottom trailing one.
        case diagonal
        /// From the top edge to the bottom.
        case vertical
        /// From the leading edge to the trailing.
        case horizontal

        static func word(_ text: String) -> Direction? {
            switch text.lowercased() {
            case "diagonal": return .diagonal
            case "vertical", "down": return .vertical
            case "horizontal", "across": return .horizontal
            default: return nil
            }
        }
    }

    var name: String
    var stops: [ColorExpression]
    var direction: Direction
    var doc: String?

    static func parse(_ line: String) throws -> GradientLine {
        guard let parts = DesignLine.split(line) else {
            throw DesignError.line(line, "a gradient line is `name: colour colour`, like `sunrise: saffron tomato`, and this has no colon")
        }
        guard let name = DesignLine.member(parts.name) else {
            throw DesignError.line(line, "`\(parts.name)` is not a gradient's name: start it with a letter")
        }
        let text = parts.value.replacingOccurrences(of: "→", with: " ").replacingOccurrences(of: "->", with: " ")
            .replacingOccurrences(of: ",", with: " ").replacingOccurrences(of: #"\s*/\s*"#, with: "/", options: .regularExpression)
        var stops: [ColorExpression] = [], direction: Direction?
        for word in text.split(separator: " ").map(String.init) {
            if ["to", "then", "and"].contains(word.lowercased()) { continue }
            if let found = Direction.word(word) {
                direction = found
            } else if word.hasSuffix("%"), !stops.isEmpty {
                stops[stops.count - 1].opacity = try ColorExpression.percent(String(word.dropLast()), in: line)
            } else {
                stops.append(try ColorExpression.parse(word, in: line))
            }
        }
        guard stops.count >= 2 else { throw DesignError.line(line, "\(name) needs two colours or more") }
        return GradientLine(name: name, stops: stops, direction: direction ?? .diagonal, doc: parts.doc)
    }
}
