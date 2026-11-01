//  WHAT: Brand.swift: `enum Brand` with the brand's name, every colour of its palette by name (`Brand.Colors`), its
//        gradients (`Brand.Gradients`), and the two ways a colour is made from hex, fixed or one for each appearance.
//  PIN:  ONE FOR EACH APPEARANCE, PICKED AS THE SYSTEM DRAWS. A light/dark pair is a dynamic UIColor or NSColor, so a
//        change of appearance, or a view kept in one (`.preferredColorScheme`), shows the right colour with no
//        environment read in the view.
//  PIN:  SWIFT 6 SAFE. Colours are `static let` (Color is Sendable) and gradients computed, never a `static var` that
//        holds a value, which Swift 6 refuses as shared mutable state.

import Foundation

enum BrandFile {
    static func text(_ design: Design) -> String {
        var lines = ["import SwiftUI", "#if os(macOS)", "import AppKit", "#else", "import UIKit", "#endif", ""]
        lines.append("/// \(SwiftName.doc(design.name))'s brand: its name, its colours by name and its gradients. Views read colours by")
        lines.append("/// role, `Color.background` or `Color.accent` (Brand.Color.swift), and the roles read these.")
        lines.append("enum Brand {")
        lines.append("    /// The brand's name, as people see it.")
        lines.append("    static let name = \(SwiftName.literal(design.name))")
        if !design.colors.isEmpty {
            lines += ["", "    /// Every colour of the brand, by name.", "    enum Colors {"]
            for color in design.colors {
                lines.append("        /// " + doc(color.doc, ColorCode.said(color.color)))
                lines.append("        static let \(SwiftName.member(color.name)) = \(ColorCode.expression(color.color))")
            }
            lines.append("    }")
        }
        if !design.gradients.isEmpty {
            lines += ["", "    /// The brand's gradients, by name.", "    enum Gradients {"]
            for gradient in design.gradients {
                let (start, end, way) = points(gradient.direction)
                let stops = gradient.stops.map(ColorCode.expression)
                let named = gradient.stops.map(stopName).joined(separator: " to ")
                lines.append("        /// " + doc(gradient.doc, "\(named), \(way)"))
                lines.append("        static var \(SwiftName.member(gradient.name)): LinearGradient {")
                lines.append("            LinearGradient(colors: [\(stops.joined(separator: ", "))], startPoint: \(start), endPoint: \(end))")
                lines.append("        }")
            }
            lines.append("    }")
        }
        lines.append("}")
        lines += [
            "",
            "extension Brand {",
            "    /// An sRGB colour from its hex, `0xRRGGBB`: the same in light and dark.",
            "    static func color(_ hex: UInt32, opacity: Double = 1) -> Color {",
            "        Color(.sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,",
            "              blue: Double(hex & 0xFF) / 255, opacity: opacity)",
            "    }",
            "",
            "    /// A colour that is `light` (`0xRRGGBB`) in the light appearance and `dark` in the dark one.",
            "    static func color(light: UInt32, dark: UInt32) -> Color {",
            "        color(light: color(light), dark: color(dark))",
            "    }",
            "",
            "    /// A colour that is `light` in the light appearance and `dark` in the dark one, picked each time the system",
            "    /// draws it, so a change of appearance, or a view kept in one, shows the right one.",
            "    static func color(light: Color, dark: Color) -> Color {",
            "        #if os(macOS)",
            "        return Color(nsColor: NSColor(name: nil) { appearance in",
            "            NSColor(appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light)",
            "        })",
            "        #else",
            "        return Color(uiColor: UIColor { traits in",
            "            UIColor(traits.userInterfaceStyle == .dark ? dark : light)",
            "        })",
            "        #endif",
            "    }",
            "}",
        ]
        return lines.joined(separator: "\n") + "\n"
    }

    /// A doc comment's line: the line's own doc, then what the code holds.
    static func doc(_ own: String?, _ holds: String) -> String {
        guard let own, !own.isEmpty else { return DesignResolver.sentence(holds) }
        return DesignResolver.sentence(SwiftName.doc(own)) + " " + DesignResolver.sentence(holds)
    }

    /// Where a gradient starts and ends, and how a doc says it.
    static func points(_ direction: GradientLine.Direction) -> (String, String, String) {
        switch direction {
        case .diagonal: return (".topLeading", ".bottomTrailing", "corner to corner")
        case .vertical: return (".top", ".bottom", "top to bottom")
        case .horizontal: return (".leading", ".trailing", "leading edge to trailing")
        }
    }

    /// A stop as a doc names it: a palette colour by its name, anything else as it is said.
    static func stopName(_ color: ResolvedColor) -> String {
        if case .palette(let name) = color.source, color.opacity == nil { return SwiftName.words(name) }
        return ColorCode.said(color).replacingOccurrences(of: "the palette's ", with: "")
    }
}
