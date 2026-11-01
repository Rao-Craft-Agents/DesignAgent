//  WHAT: A number as Swift and a person write it: `12`, `0.5`, `6.25`, at most three decimals.

import Foundation

enum SwiftNumber {
    static func text(_ value: Double) -> String {
        let rounded = (value * 1_000).rounded() / 1_000
        if rounded == rounded.rounded(), abs(rounded) < 1e12 { return String(Int(rounded)) }
        var text = String(format: "%.3f", rounded)
        while text.hasSuffix("0") { text.removeLast() }
        return text
    }
}
