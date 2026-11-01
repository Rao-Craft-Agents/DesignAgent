//  WHAT: A role line: what a colour role reads. A role is a colour views ask for by what it is for (`Color.background`,
//        `Color.secondaryForeground`, `Color.accent`), and the line names the colour it is.
//
//            background = cream
//            secondaryForeground = ink 60%
//            accent = #3F7D58/#6FBF8E
//            highlight = saffron "a recipe someone starred"      a role of the app's own
//            alternateSecondaryBackground                       named alone: the colour set, or palette colour, of its name

import Foundation

struct RoleLine: Equatable, Sendable {
    var name: String
    var color: ColorExpression
    var doc: String?

    /// `Color`'s own colours in SwiftUI: a role by one of these names would hide SwiftUI's.
    static let taken: Set<String> = ["accentColor", "black", "blue", "brown", "clear", "cyan", "gray", "green", "indigo",
                                     "mint", "orange", "pink", "primary", "purple", "red", "secondary", "teal", "white", "yellow"]

    static func parse(_ line: String) throws -> RoleLine {
        let alone = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if alone.range(of: #"^[A-Za-z][A-Za-z0-9_-]*$"#, options: .regularExpression) != nil, let name = DesignLine.member(alone) {
            return try parse("\(name) = \(alone)")
        }
        guard let parts = DesignLine.split(line) else {
            throw DesignError.line(line, "a role line is `role = colour`, like `background = cream`, and this has no `=`")
        }
        guard let name = DesignLine.member(parts.name) else {
            throw DesignError.line(line, "`\(parts.name)` is not a role's name: start it with a letter")
        }
        guard !taken.contains(name) else {
            throw DesignError.line(line, "`Color.\(name)` is SwiftUI's own; name the role for what it is for, like `danger` or `highlight`")
        }
        guard !parts.value.isEmpty else { throw DesignError.line(line, "the \(name) role names no colour") }
        return RoleLine(name: name, color: try ColorExpression.parse(parts.value, in: line), doc: parts.doc)
    }
}
