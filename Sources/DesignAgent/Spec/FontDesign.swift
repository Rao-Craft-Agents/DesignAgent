//  WHAT: The design a type line asks for: SwiftUI's font designs. With the brand's own font files, a design picks the
//        files' family of that kind (a serif family for `serif`); without one, the system draws it.

import Foundation

enum FontDesign: String, CaseIterable, Sendable {
    case `default`, serif, rounded, monospaced

    /// `rounded`, `serif`, `mono`, `monospace`, `sans` → the design; nil when the word is not one.
    static func word(_ text: String) -> FontDesign? {
        let key = text.lowercased().filter(\.isLetter)
        if let design = allCases.first(where: { $0.rawValue == key }) { return design }
        let aliases: [String: FontDesign] = ["sans": .default, "sansserif": .default, "mono": .monospaced, "monospace": .monospaced]
        return aliases[key]
    }
}
