//  WHAT: A colour as a line says it: `#E8A33D`, `#FBF7F0/#1A1714` (light, then dark), or a name (a palette colour, or a
//        colour set of the project's asset catalogs), with an opacity after any of them (`ink 60%`).

import Foundation

struct ColorExpression: Equatable, Sendable {
    enum Value: Equatable, Sendable {
        /// One hex for both appearances.
        case fixed(Hex)
        /// The light appearance's hex, then the dark's.
        case adaptive(light: Hex, dark: Hex)
        /// A palette colour or a colour set: found when the project is read.
        case named(String)
    }

    var value: Value
    /// From 0 to 1, from `60%`; nil when the line gave none.
    var opacity: Double?

    /// Reads `text`, a part of `line`, or says why it cannot.
    static func parse(_ text: String, in line: String) throws -> ColorExpression {
        var body = text.trimmingCharacters(in: .whitespaces)
        var opacity: Double?
        if let match = body.range(of: #"\s+[0-9]+(\.[0-9]+)?\s*%$"#, options: .regularExpression) {
            let number = body[match].trimmingCharacters(in: CharacterSet(charactersIn: " %"))
            opacity = try percent(number, in: line)
            body = body[..<match.lowerBound].trimmingCharacters(in: .whitespaces)
        }
        guard let first = body.first else { throw DesignError.line(line, "it names no colour") }
        let halves = body.split(separator: "/", omittingEmptySubsequences: false).map { $0.trimmingCharacters(in: .whitespaces) }
        if halves.count == 2, let light = Hex.parse(halves[0]), let dark = Hex.parse(halves[1]) {
            return ColorExpression(value: .adaptive(light: light, dark: dark), opacity: opacity)
        }
        if first == "#" || body.lowercased().hasPrefix("0x") {
            guard let hex = Hex.parse(body) else {
                throw DesignError.line(line, "`\(body)` is not a hex colour: #RRGGBB, #RGB or #RRGGBBAA, or #light/#dark")
            }
            return ColorExpression(value: .fixed(hex), opacity: opacity)
        }
        guard first.isLetter else {
            throw DesignError.line(line, "`\(body)` is not a colour: a hex, #light/#dark, or a palette colour's name")
        }
        return ColorExpression(value: .named(body), opacity: opacity)
    }

    /// `60` (of `60%`) as 0.6, or why it is not an opacity.
    static func percent(_ number: String, in line: String) throws -> Double {
        guard let value = Double(number), (0...100).contains(value) else {
            throw DesignError.line(line, "`\(number)%` is not an opacity from 0% to 100%")
        }
        return value / 100
    }
}
