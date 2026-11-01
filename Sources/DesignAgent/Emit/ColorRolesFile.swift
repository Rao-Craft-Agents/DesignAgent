//  WHAT: Brand.Color.swift: the colour roles as `Color` members, `Color.background` to `Color.danger` and any the call
//        names, each reading its palette colour, its asset catalog colour set, or the platform's own colour.
//  PIN:  THE SYSTEM'S, PLATFORM BY PLATFORM. A role nothing names reads the colour each platform gives that job
//        (`systemBackground` on iOS, `windowBackgroundColor` on macOS), so a design with no palette still has every
//        role, in light and dark.
//  PIN:  A ROLE XCODE ALREADY WRITES IS LEFT OUT. With Swift asset symbol extensions on, `Color.accent` exists from the
//        AccentColor set; a second declaration would not build, so the file says where it comes from instead.

import Foundation

enum ColorRolesFile {
    /// The platform's colour for a role: AppKit's and UIKit's names.
    static let platform: [String: (mac: String, ios: String)] = [
        "background": ("windowBackgroundColor", "systemBackground"),
        "secondaryBackground": ("underPageBackgroundColor", "secondarySystemBackground"),
        "tertiaryBackground": ("unemphasizedSelectedContentBackgroundColor", "tertiarySystemBackground"),
        "alternateBackground": ("controlBackgroundColor", "systemGroupedBackground"),
        "separator": ("separatorColor", "separator"),
    ]

    /// The colour SwiftUI gives a role on every platform.
    static let shared: [String: String] = [
        "foreground": ".primary", "secondaryForeground": ".secondary", "accent": ".accentColor",
        "success": ".green", "warning": ".orange", "danger": ".red",
    ]

    static func text(_ design: Design) -> String {
        var lines = ["import SwiftUI", "#if os(macOS)", "import AppKit", "#else", "import UIKit", "#endif", ""]
        lines.append("/// The colours views ask for by what they are for: `Color.background` behind everything, `Color.foreground` for")
        lines.append("/// text, `Color.accent` on controls. Each reads the brand's palette, the asset catalog or the platform.")
        lines.append("extension Color {")
        var first = true
        for role in design.roles {
            if !first { lines.append("") }
            first = false
            let member = SwiftName.member(role.name)
            switch role.source {
            case .color(let color):
                lines.append("    /// \(SwiftName.doc(role.use)) \(DesignResolver.sentence(ColorCode.said(color)))")
                lines.append("    static var \(member): Color { \(ColorCode.expression(color)) }")
            case .generated(let set):
                lines.append("    // Color.\(role.name): \(SwiftName.doc(role.use)) Xcode writes it from the asset catalog's `\(set)`.")
            case .system:
                lines.append("    /// \(SwiftName.doc(role.use)) The platform's own.")
                if let pair = platform[role.name] {
                    lines += ["    static var \(member): Color {", "        #if os(macOS)", "        Color(nsColor: .\(pair.mac))",
                              "        #else", "        Color(uiColor: .\(pair.ios))", "        #endif", "    }"]
                } else {
                    lines.append("    static var \(member): Color { \(shared[role.name] ?? ".primary") }")
                }
            }
        }
        lines.append("}")
        return lines.joined(separator: "\n") + "\n"
    }
}
