//  WHAT: SwiftUI's text styles, each with the size and weight Apple gives it on iPhone at the default text size: the
//        style a type line grows and shrinks with under Dynamic Type, and what a size reads as when a line names none.

import Foundation

enum TextStyle: String, CaseIterable, Sendable {
    case largeTitle, title, title2, title3, headline, subheadline, body, callout, footnote, caption, caption2

    /// Its size on iPhone at the default text size, in points.
    var size: Double {
        switch self {
        case .largeTitle: return 34
        case .title: return 28
        case .title2: return 22
        case .title3: return 20
        case .headline, .body: return 17
        case .callout: return 16
        case .subheadline: return 15
        case .footnote: return 13
        case .caption: return 12
        case .caption2: return 11
        }
    }

    /// The weight SwiftUI draws it in.
    var weight: FontWeight { self == .headline ? .semibold : .regular }

    /// `title`, `largeTitle`, `large-title`, `Caption2` → the style; nil when the word is not one.
    static func word(_ text: String) -> TextStyle? {
        let key = text.lowercased().filter { $0.isLetter || $0.isNumber }
        return allCases.first { $0.rawValue.lowercased() == key }
    }

    /// The style a size reads as: the nearest; at a tie the one whose weight is nearer (headline for a semibold 17),
    /// then the larger.
    static func nearest(to size: Double, weight: FontWeight) -> TextStyle {
        allCases.min { a, b in
            let da = abs(a.size - size), db = abs(b.size - size)
            if da != db { return da < db }
            let wa = abs(a.weight.css - weight.css), wb = abs(b.weight.css - weight.css)
            if wa != wb { return wa < wb }
            return a.size > b.size
        } ?? .body
    }
}
