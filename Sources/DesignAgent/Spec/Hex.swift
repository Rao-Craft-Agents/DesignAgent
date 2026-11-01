//  WHAT: A colour written in hex: `#RGB`, `#RRGGBB` or `#RRGGBBAA` (alpha last, as CSS writes it), or `0xRRGGBB`;
//        its sRGB value and how opaque it is.

import Foundation

struct Hex: Equatable, Sendable {
    /// `0xRRGGBB`.
    var rgb: UInt32
    /// From 0 to 1; 1 unless the hex gave alpha.
    var opacity: Double

    /// As Swift writes it: `0xA19A8E`.
    var literal: String { String(format: "0x%06X", rgb) }

    /// As a person reads it: `#A19A8E`, and the alpha when it is not opaque.
    var text: String {
        opacity < 1 ? String(format: "#%06X%02X", rgb, Int((opacity * 255).rounded())) : String(format: "#%06X", rgb)
    }

    /// `#A19A8E`, `#FA0`, `#00000033` or `0xA19A8E`; nil for anything else.
    static func parse(_ text: String) -> Hex? {
        var digits = text.trimmingCharacters(in: .whitespaces)
        if digits.hasPrefix("#") {
            digits.removeFirst()
        } else if digits.lowercased().hasPrefix("0x") {
            digits.removeFirst(2)
        } else {
            return nil
        }
        guard !digits.isEmpty, digits.allSatisfy({ $0.isASCII && $0.isHexDigit }) else { return nil }
        if digits.count == 3 { digits = digits.map { "\($0)\($0)" }.joined() }
        switch digits.count {
        case 6:
            guard let value = UInt32(digits, radix: 16) else { return nil }
            return Hex(rgb: value, opacity: 1)
        case 8:
            guard let value = UInt32(digits, radix: 16) else { return nil }
            return Hex(rgb: value >> 8, opacity: Double(value & 0xFF) / 255)
        default:
            return nil
        }
    }
}
