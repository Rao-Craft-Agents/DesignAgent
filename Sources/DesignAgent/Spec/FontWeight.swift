//  WHAT: A font weight as a type line says it, numbered as CSS numbers weights (100 to 900): how the faces of a
//        brand's font files are matched to the weights the type scale asks for.

import Foundation

enum FontWeight: String, CaseIterable, Sendable {
    case ultraLight, thin, light, regular, medium, semibold, bold, heavy, black

    /// 100 for ultraLight to 900 for black.
    var css: Int { ((Self.allCases.firstIndex(of: self) ?? 3) + 1) * 100 }

    /// The weight nearest to `css`.
    static func nearest(css: Int) -> FontWeight {
        allCases.min { abs($0.css - css) < abs($1.css - css) } ?? .regular
    }

    /// `bold`, `Bold`, `semi-bold`, `ultralight`, `extrabold` → the weight; nil when the word is not one.
    static func word(_ text: String) -> FontWeight? {
        let key = text.lowercased().filter(\.isLetter)
        if let weight = allCases.first(where: { $0.rawValue.lowercased() == key }) { return weight }
        let aliases: [String: FontWeight] = ["extralight": .ultraLight, "hairline": .thin, "normal": .regular, "book": .regular,
                                             "demibold": .semibold, "extrabold": .heavy, "ultrabold": .heavy]
        return aliases[key]
    }
}
