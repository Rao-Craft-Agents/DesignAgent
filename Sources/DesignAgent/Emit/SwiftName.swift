//  WHAT: What Swift accepts as a name, and how a name is said: keywords escaped, words split for a doc comment.

import Foundation

enum SwiftName {
    static let keywords: Set<String> = ["associatedtype", "class", "deinit", "enum", "extension", "fileprivate", "func", "import", "init",
                                        "inout", "internal", "let", "open", "operator", "private", "precedencegroup", "protocol", "public",
                                        "rethrows", "static", "struct", "subscript", "typealias", "var", "break", "case", "catch", "continue",
                                        "default", "defer", "do", "else", "fallthrough", "for", "guard", "if", "in", "repeat", "return", "throw",
                                        "switch", "where", "while", "as", "Any", "false", "is", "nil", "self", "Self", "super", "throws", "true",
                                        "try", "some", "any"]

    static func isMemberName(_ text: String) -> Bool {
        text.range(of: #"^[a-z_][A-Za-z0-9_]*$"#, options: .regularExpression) != nil
    }

    /// A member name as code writes it: a keyword in backticks.
    static func member(_ name: String) -> String { keywords.contains(name) ? "`\(name)`" : name }

    /// `secondaryBackground` → `secondary background`; `title2` → `title2`.
    static func words(_ name: String) -> String {
        var out = "", previous: Character?
        for character in name {
            if character == "_" { out.append(" ") }
            else if character.isUppercase, let p = previous, p.isLowercase || p.isNumber { out.append(" "); out.append(Character(character.lowercased())) }
            else { out.append(Character(character.lowercased())) }
            previous = character
        }
        return out
    }

    /// `text` inside a Swift string literal: backslashes and quotes escaped, line breaks as spaces.
    static func literal(_ text: String) -> String {
        "\"" + text.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: " ") + "\""
    }

    /// `text` as one line of a doc comment.
    static func doc(_ text: String) -> String {
        text.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces)
    }
}
