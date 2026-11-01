//  WHAT: The shape every design line shares: a name, `:` or `=`, a value, and a quoted doc anywhere after the name
//        (`cream "the page": #FBF7F0/#1A1714`, `card: 14 "cards and sheets"`). A name is said as a person says it
//        (`brand blue`, `brand-blue`, `Brand_Blue`) and written as Swift says it (`brandBlue`).

import Foundation

enum DesignLine {
    struct Parts: Equatable, Sendable {
        var name: String
        var value: String
        var doc: String?
    }

    /// `line` cut into its name, its value and its doc; nil when it has no `:` or `=` to cut at.
    static func split(_ line: String) -> Parts? {
        var text = line.trimmingCharacters(in: .whitespacesAndNewlines)
        var doc: String?
        if let open = text.firstIndex(of: "\""), let close = text[text.index(after: open)...].firstIndex(of: "\"") {
            doc = String(text[text.index(after: open)..<close]).trimmingCharacters(in: .whitespaces)
            text.removeSubrange(open...close)
        }
        guard let separator = text.firstIndex(where: { $0 == ":" || $0 == "=" }) else { return nil }
        let name = text[..<separator].trimmingCharacters(in: .whitespaces)
        let value = text[text.index(after: separator)...].trimmingCharacters(in: .whitespaces)
        return Parts(name: name, value: value, doc: (doc?.isEmpty ?? true) ? nil : doc)
    }

    /// `brand blue`, `brand-blue`, `Brand_Blue` → `brandBlue`; `SF Mono` → `sfMono`; nil when the words do not start
    /// with a letter.
    static func member(_ text: String) -> String? {
        let words = text.split(whereSeparator: { !($0.isASCII && ($0.isLetter || $0.isNumber)) }).map(String.init)
        guard let first = words.first, let initial = first.first, initial.isLetter else { return nil }
        let lead = first.allSatisfy { !$0.isLowercase } ? first.lowercased() : first.prefix(1).lowercased() + first.dropFirst()
        let joined = lead + words.dropFirst().map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined()
        return SwiftName.isMemberName(joined) ? joined : nil
    }

    /// `14`, `14pt`, `14 pt`, `6.5` → the number; nil for anything else.
    static func points(_ text: String) -> Double? {
        var body = text.trimmingCharacters(in: .whitespaces).lowercased()
        if body.hasSuffix("pt") { body = String(body.dropLast(2)).trimmingCharacters(in: .whitespaces) }
        guard let value = Double(body), value.isFinite else { return nil }
        return value
    }
}
