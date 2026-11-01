//  WHAT: A resolved colour as Swift makes it (`Brand.color(0xE8A33D)`, `Brand.color(light: 0xFBF7F0, dark: 0x1A1714)`,
//        `Color("colors/background")`, `Brand.Colors.ink.opacity(0.6)`) and as a doc comment says it.
//  PIN:  HEX IS WRITTEN AS ITS VALUE, NOT PARSED AT RUNTIME. `Brand.color(0xE8A33D)` cannot fail, and it leaves the
//        app's own `Color(hex:)`, which apps often have (Loom does), to the app: a second one would not build.

import Foundation

enum ColorCode {
    /// The Swift that makes `color`.
    static func expression(_ color: ResolvedColor) -> String {
        let opacity = color.opacity ?? 1
        switch color.source {
        case .fixed(let hex):
            return fixed(hex, opacity: hex.opacity * opacity)
        case .adaptive(let light, let dark):
            let lightOpacity = light.opacity * opacity, darkOpacity = dark.opacity * opacity
            if lightOpacity >= 1, darkOpacity >= 1 { return "Brand.color(light: \(light.literal), dark: \(dark.literal))" }
            return "Brand.color(light: \(fixed(light, opacity: lightOpacity)), dark: \(fixed(dark, opacity: darkOpacity)))"
        case .asset(let name):
            return "Color(\(SwiftName.literal(name)))" + suffix(color.opacity)
        case .palette(let name):
            return "Brand.Colors.\(SwiftName.member(name))" + suffix(color.opacity)
        }
    }

    /// As a doc comment says it: "`#FBF7F0` in light, `#1A1714` in dark", "the asset catalog's `brandInk`", "the
    /// palette's ink at 60%".
    static func said(_ color: ResolvedColor) -> String {
        let at = color.opacity.map { " at \(SwiftNumber.text($0 * 100))%" } ?? ""
        switch color.source {
        case .fixed(let hex): return "`\(hex.text)`" + at
        case .adaptive(let light, let dark): return "`\(light.text)` in light, `\(dark.text)` in dark" + at
        case .asset(let name): return "the asset catalog's `\(name)`" + at
        case .palette(let name): return "the palette's \(SwiftName.words(name))" + at
        }
    }

    private static func fixed(_ hex: Hex, opacity: Double) -> String {
        opacity >= 1 ? "Brand.color(\(hex.literal))" : "Brand.color(\(hex.literal), opacity: \(SwiftNumber.text(opacity)))"
    }

    private static func suffix(_ opacity: Double?) -> String {
        opacity.map { ".opacity(\(SwiftNumber.text($0)))" } ?? ""
    }
}
