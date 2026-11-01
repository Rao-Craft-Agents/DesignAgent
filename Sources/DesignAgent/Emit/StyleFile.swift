//  WHAT: Style.swift: the spacing layers as `CGFloat` members (`.padding(.layer4)`), and under `Brand` the radii,
//        strokes, shadows, durations and the platform's window and column sizes; then the type scale as `Font` members
//        (`.font(.brandTitle)`), each drawn by `Font.brand` (Fonts/Fonts.swift) and scaling with Dynamic Type.
//  PIN:  THE TYPE SCALE NEVER HIDES SWIFTUI'S. `Font.title` is SwiftUI's; the brand's is `Font.brandTitle`, so a view
//        says which one it means and a system style left in a view still draws as the system's.

import Foundation

enum StyleFile {
    static func text(_ design: Design) -> String {
        var lines = ["import SwiftUI", ""]
        lines += layers(design.layers)
        lines += ["", "extension Brand {"]
        lines += radii(design.radii)
        lines += [
            "",
            "    /// Line widths for borders and dividers.",
            "    enum Stroke {",
            "        /// Dividers.",
            "        static let hairline: CGFloat = 0.5",
            "        /// Borders.",
            "        static let regular: CGFloat = 1",
            "        /// A selected or focused border.",
            "        static let bold: CGFloat = 2",
            "    }",
            "",
            "    /// A shadow: its colour, how far it blurs and how far it falls. Darker in the dark appearance, where a light",
            "    /// one would not show.",
            "    struct Shadow: Sendable {",
            "        let color: Color",
            "        let radius: CGFloat",
            "        let x: CGFloat",
            "        let y: CGFloat",
            "",
            "        /// Under a card resting on the background.",
            "        static let card = Shadow(color: Brand.color(light: Brand.color(0x000000, opacity: 0.08), dark: Brand.color(0x000000, opacity: 0.4)),",
            "                                 radius: 8, x: 0, y: 2)",
            "        /// Under what floats above the page: a menu, a popover, a card being dragged.",
            "        static let raised = Shadow(color: Brand.color(light: Brand.color(0x000000, opacity: 0.16), dark: Brand.color(0x000000, opacity: 0.6)),",
            "                                   radius: 18, x: 0, y: 8)",
            "    }",
            "",
            "    /// How long things take to move, in seconds.",
            "    enum Motion {",
            "        /// A press, a toggle or a hover.",
            "        static let quick: Double = 0.2",
            "        /// A sheet, a card or a list changing.",
            "        static let standard: Double = 0.35",
            "        /// Something large arriving: a page or a step of onboarding.",
            "        static let slow: Double = 0.6",
            "    }",
            "",
            "    /// The sizes each platform sets for the app's windows and columns.",
            "    enum Metrics {",
            "        #if os(macOS)",
            "        /// The sidebar's width.",
            "        static let sidebarWidth: CGFloat = 240",
            "        /// The narrowest a window may be.",
            "        static let minWindowWidth: CGFloat = 750",
            "        /// The shortest a window may be.",
            "        static let minWindowHeight: CGFloat = 420",
            "        #else",
            "        /// The sidebar's width on iPad.",
            "        static let sidebarWidth: CGFloat = 320",
            "        /// The narrowest the app is drawn: an iPhone's width.",
            "        static let minWindowWidth: CGFloat = 320",
            "        /// The shortest the app is drawn.",
            "        static let minWindowHeight: CGFloat = 480",
            "        #endif",
            "        /// The widest a column of text reads well at.",
            "        static let readableWidth: CGFloat = 720",
            "    }",
            "}",
            "",
            "extension View {",
            "    /// Casts `shadow` under this view.",
            "    func shadow(_ shadow: Brand.Shadow) -> some View {",
            "        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)",
            "    }",
            "}",
            "",
        ]
        lines += typeScale(design)
        return lines.joined(separator: "\n") + "\n"
    }

    /// `.layer1` to `.layerN`.
    static func layers(_ layers: [Int]) -> [String] {
        let usual = layers.count >= 3 ? layers.indices.dropFirst().dropLast().min { abs(layers[$0] - 16) < abs(layers[$1] - 16) } : nil
        var lines = ["extension CGFloat {"]
        for (index, value) in layers.enumerated() {
            var doc = "\(value) pt"
            if index == 0 && layers.count > 1 { doc += ": the tightest gap, between an icon and its label" }
            else if index == layers.count - 1 && layers.count > 1 { doc += ": the widest gap, between sections" }
            else if index == usual { doc += ": the usual padding around content" }
            lines.append("    /// \(doc).")
            lines.append("    static var layer\(index + 1): CGFloat { \(value) }")
        }
        lines.append("}")
        return lines
    }

    static func radii(_ radii: [RadiusToken]) -> [String] {
        var lines = ["    /// Corner radii, by what they round.", "    enum Radius {"]
        for radius in radii {
            let own = radius.doc ?? RadiusToken.defaults.first { $0.name == radius.name }?.doc
            lines.append("        /// " + BrandFile.doc(own, "\(SwiftNumber.text(radius.points)) pt"))
            lines.append("        static let \(SwiftName.member(radius.name)): CGFloat = \(SwiftNumber.text(radius.points))")
        }
        lines.append("    }")
        return lines
    }

    /// The type scale: a `Font` member a style.
    static func typeScale(_ design: Design) -> [String] {
        var lines = ["extension Font {"]
        for (index, style) in design.typeScale.enumerated() {
            if index > 0 { lines.append("") }
            lines.append("    /// " + BrandFile.doc(style.doc, describe(style, in: design)))
            var arguments = [".\(style.weight.rawValue)", "size: \(SwiftNumber.text(style.size))", "relativeTo: .\(style.style.rawValue)"]
            if style.design != .default { arguments.append("design: .\(style.design.rawValue)") }
            if style.italic { arguments.append("italic: true") }
            lines.append("    static var \(style.member): Font { .brand(\(arguments.joined(separator: ", "))) }")
        }
        lines.append("}")
        return lines
    }

    /// What a style draws, as its doc comment says it.
    static func describe(_ style: TypeStyle, in design: Design) -> String {
        let manner = [style.weight.rawValue, style.design == .default ? nil : style.design.rawValue, style.italic ? "italic" : nil]
            .compactMap { $0 }.joined(separator: ", ")
        let name = SwiftName.words(style.name).prefix(1).uppercased() + SwiftName.words(style.name).dropFirst()
        let scale = "`.\(style.style.rawValue)`"
        if let family = design.family(for: style.design) {
            let face = family.face(style.weight, italic: style.italic).postScript
            return "\(name): \(face) at \(SwiftNumber.text(style.size)) pt, growing and shrinking with Dynamic Type as \(scale) does"
        }
        return "\(name): the system's face, \(manner), at \(scale)'s size (\(SwiftNumber.text(style.style.size)) pt on iPhone), following Dynamic Type"
    }
}
