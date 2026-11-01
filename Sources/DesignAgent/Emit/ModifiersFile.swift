//  WHAT: View+Style.swift, written only when a call asks: `.cardStyle()`, `.sectionStyle()` and `.brandBackground()`,
//        made from the design's own tokens (the roles, a layer, the card radius, the hairline and the card shadow).
//  PIN:  THE LAYERS THE DESIGN HAS. A card is padded by the layer nearest 16 points, so a call with its own spacing
//        never names a layer it does not declare.

import Foundation

enum ModifiersFile {
    static func text(_ design: Design) -> String {
        let padding = layer(nearest: 16, in: design.layers), gap = layer(nearest: 12, in: design.layers)
        return [
            "import SwiftUI",
            "",
            "extension View {",
            "    /// A card: the content padded, on the secondary background, rounded at the card radius, with the card's shadow.",
            "    func cardStyle() -> some View {",
            "        padding(\(padding))",
            "            .background(Color.secondaryBackground, in: RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous))",
            "            .shadow(Brand.Shadow.card)",
            "    }",
            "",
            "    /// A section of a list or a page: the full width, the content padded, a hairline separator under it.",
            "    func sectionStyle() -> some View {",
            "        frame(maxWidth: .infinity, alignment: .leading)",
            "            .padding(.horizontal, \(padding))",
            "            .padding(.vertical, \(gap))",
            "            .overlay(alignment: .bottom) {",
            "                Rectangle()",
            "                    .fill(Color.separator)",
            "                    .frame(height: Brand.Stroke.hairline)",
            "            }",
            "    }",
            "",
            "    /// The brand's background behind this view, edge to edge and under the safe areas.",
            "    func brandBackground() -> some View {",
            "        background(Color.background.ignoresSafeArea())",
            "    }",
            "}",
        ].joined(separator: "\n") + "\n"
    }

    /// `.layerN` for the layer nearest `points`.
    static func layer(nearest points: Int, in layers: [Int]) -> String {
        let index = layers.indices.min { abs(layers[$0] - points) < abs(layers[$1] - points) } ?? 0
        return ".layer\(index + 1)"
    }
}
