//  WHAT: A colour role: a colour views ask for by what it is for (`Color.background`, `Color.accent`), what it is for,
//        and what it reads: a colour the call names, the colour set of its name, the palette colour of its name, the
//        system's, or the member Xcode already writes for the colour set of its name.

import Foundation

struct ColorRole: Equatable, Sendable {
    enum Source: Equatable, Sendable {
        case color(ResolvedColor)
        /// The platform's own colour for the role.
        case system
        /// Xcode writes `Color.<role>` from this colour set (Swift asset symbol extensions are on).
        case generated(String)
    }

    var name: String
    /// What it is for, as its doc comment says first.
    var use: String
    var source: Source

    /// The roles every design has, with what each is for.
    static let defaults: [(name: String, use: String)] = [
        ("background", "Behind everything: windows, pages and lists."),
        ("secondaryBackground", "A step above the background: cards, grouped rows and fields."),
        ("tertiaryBackground", "A step above that: chips, badges and selected rows."),
        ("alternateBackground", "Beside the background: sidebars, sheets and overlays."),
        ("foreground", "Text and icons."),
        ("secondaryForeground", "Supporting text: captions, timestamps and counts."),
        ("accent", "The brand on controls: buttons, links, toggles and selection."),
        ("separator", "Dividers and hairline borders."),
        ("success", "Done and well: a saved draft, a passed check."),
        ("warning", "Needs a look: a slow connection, an unsaved change."),
        ("danger", "Destructive or failed: a delete, an error."),
    ]

    /// As the call's answer says it: `background = cream`, `success = system`.
    var summary: String {
        switch source {
        case .color(let color): return "\(name) = \(color.summary)"
        case .system: return "\(name) = system"
        case .generated(let set): return "\(name) = colour set \(set) (Xcode's symbol)"
        }
    }
}
