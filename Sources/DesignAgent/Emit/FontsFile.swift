//  WHAT: Fonts/Fonts.swift: `Font.brand(_:size:relativeTo:)`, the one way the app draws its type. With font files, it
//        registers them with the system from the app's bundle (`Fonts.register()`, called on first use) and draws the
//        file nearest the weight asked, at the size asked, scaling with Dynamic Type; without, it draws the system's
//        face in the design asked, at the text style's size, which is how the system scales.
//  PIN:  FACES BY THEIR REAL NAMES. Each PostScript name and weight was read off the files themselves, so
//        `Font.custom` never asks for a face that is not there and falls back to the system's without a word.

import Foundation

enum FontsFile {
    static func text(_ design: Design) -> String {
        design.families.isEmpty ? system() : custom(design)
    }

    /// The brand draws in the system's faces.
    static func system() -> String {
        [
            "import SwiftUI",
            "",
            "extension Font {",
            "    /// The brand's font: the system's face in `design` and `weight`, drawn at the size of `style` so it grows and",
            "    /// shrinks with Dynamic Type and reads as each platform's own. The app ships no font files of its own, and only",
            "    /// one of those is drawn at exactly `size`.",
            "    static func brand(_ weight: Font.Weight = .regular, size: CGFloat, relativeTo style: Font.TextStyle = .body,",
            "                      design: Font.Design = .default, italic: Bool = false) -> Font {",
            "        let font = Font.system(style, design: design, weight: weight)",
            "        return italic ? font.italic() : font",
            "    }",
            "}",
        ].joined(separator: "\n") + "\n"
    }

    /// The brand draws in its own files.
    static func custom(_ design: Design) -> String {
        let italics = design.families.flatMap(\.faces).filter(\.italic).map(\.postScript)
        var lines = ["import CoreText", "import Foundation", "import SwiftUI", ""]
        lines.append("/// The brand's typefaces: the font files beside this one, registered with the system for the app the first time a")
        lines.append("/// brand font is drawn, or at launch with `Fonts.register()`.")
        lines.append("enum Fonts {")
        lines.append("    /// The font files the app ships, as its bundle names them.")
        lines.append("    static let files = [\(design.fontFiles.map(SwiftName.literal).joined(separator: ", "))]")
        if !italics.isEmpty {
            lines.append("")
            lines.append("    /// The italic faces among them.")
            lines.append("    static let italicFaces: Set<String> = [\(italics.map(SwiftName.literal).joined(separator: ", "))]")
        }
        lines += [
            "",
            "    /// Registers every font file found in `bundle` for this process, so text can be drawn in it. Calling it again",
            "    /// changes nothing.",
            "    static func register(from bundle: Bundle = .main) {",
            "        for file in files {",
            "            let name = (file as NSString).deletingPathExtension, kind = (file as NSString).pathExtension",
            "            guard let url = bundle.url(forResource: name, withExtension: kind)",
            "                ?? bundle.url(forResource: name, withExtension: kind, subdirectory: \"Fonts\") else { continue }",
            "            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)",
            "        }",
            "    }",
            "",
            "    /// The files, registered from the app's bundle once, before the first brand font is drawn.",
            "    private static let registered: Void = register()",
            "",
            "    /// The face for `weight` in `design`: the PostScript name of the file nearest it, italic when asked and the",
            "    /// family has one; nil for a design the files have no family of, which the system's face draws.",
            "    static func face(_ weight: Font.Weight, design: Font.Design = .default, italic: Bool = false) -> String? {",
            "        _ = registered",
            "        switch design {",
        ]
        var served: [(designs: [FontDesign], family: FontFamily)] = []
        for kind in [FontDesign.default, .serif, .monospaced] {
            guard let family = design.family(for: kind) else { continue }
            if let index = served.firstIndex(where: { $0.family == family }) { served[index].designs.append(kind) } else { served.append(([kind], family)) }
        }
        // Two families whose names say the same in Swift (`Pantry Sans`, `Pantry-Sans`) get a function each.
        var taken: Set<String> = []
        for index in served.indices {
            var member = served[index].family.member, count = 2
            while taken.contains(member) { member = served[index].family.member + "\(count)"; count += 1 }
            taken.insert(member)
            served[index].family.member = member
        }
        for entry in served {
            let call = entry.family.hasItalics ? "\(entry.family.member)(weight, italic: italic)" : "\(entry.family.member)(weight)"
            lines.append("        case \(entry.designs.map { ".\($0.rawValue)" }.joined(separator: ", ")):")
            lines.append("            return \(call)")
        }
        lines += ["        default:", "            return nil", "        }", "    }"]
        for entry in served { lines += [""] + faceFunction(entry.family) }
        lines += [
            "}",
            "",
            "extension Font {",
            "    /// The brand's font: `weight` of the brand's face in `design`, at `size` points, growing and shrinking with",
            "    /// Dynamic Type as `style` does. A design the brand ships no face for is drawn in the system's.",
            "    static func brand(_ weight: Font.Weight = .regular, size: CGFloat, relativeTo style: Font.TextStyle = .body,",
            "                      design: Font.Design = .default, italic: Bool = false) -> Font {",
            "        guard let face = Fonts.face(weight, design: design, italic: italic) else {",
            "            let system = Font.system(style, design: design, weight: weight)",
            "            return italic ? system.italic() : system",
            "        }",
            "        let font = Font.custom(face, size: size, relativeTo: style)",
            italics.isEmpty ? "        return italic ? font.italic() : font" : "        return italic && !Fonts.italicFaces.contains(face) ? font.italic() : font",
            "    }",
            "}",
        ]
        return lines.joined(separator: "\n") + "\n"
    }

    /// A family's face for each weight: the weights that come to the same faces share a case, regular's is the default.
    static func faceFunction(_ family: FontFamily) -> [String] {
        let files = Array(Set(family.faces.map(\.file.lastPathComponent))).sorted()
        var groups: [(weights: [FontWeight], upright: String, italic: String)] = []
        for weight in FontWeight.allCases {
            let upright = family.face(weight, italic: false).postScript
            let italic = family.hasItalics ? family.face(weight, italic: true).postScript : upright
            if let index = groups.firstIndex(where: { $0.upright == upright && $0.italic == italic }) {
                groups[index].weights.append(weight)
            } else {
                groups.append(([weight], upright, italic))
            }
        }
        func value(_ group: (weights: [FontWeight], upright: String, italic: String)) -> String {
            group.upright == group.italic ? SwiftName.literal(group.upright) : "italic ? \(SwiftName.literal(group.italic)) : \(SwiftName.literal(group.upright))"
        }
        let signature = family.hasItalics ? "(_ weight: Font.Weight, italic: Bool) -> String" : "(_ weight: Font.Weight) -> String"
        var lines = ["    /// \(SwiftName.doc(family.name)), from \(list(files)): the face nearest `weight`.",
                     "    private static func \(family.member)\(signature) {"]
        guard groups.count > 1, let regular = groups.firstIndex(where: { $0.weights.contains(.regular) }) else {
            lines.append("        \(value(groups[0]))")
            lines.append("    }")
            return lines
        }
        lines.append("        switch weight {")
        for (index, group) in groups.enumerated() where index != regular {
            lines.append("        case \(group.weights.map { ".\($0.rawValue)" }.joined(separator: ", ")):")
            lines.append("            return \(value(group))")
        }
        lines += ["        default:", "            return \(value(groups[regular]))", "        }", "    }"]
        return lines
    }

    /// `a`, `a and b`, `a, b and c`.
    static func list(_ items: [String]) -> String {
        guard items.count > 1 else { return items.first ?? "" }
        return items.dropLast().joined(separator: ", ") + " and " + items[items.count - 1]
    }
}
