//  WHAT: A design, resolved: every token the files hold, with each colour found in the palette, the asset catalogs or
//        the system, and each font face read from its file. What the emitters write from, and nothing else.

import Foundation

struct Design: Sendable {
    struct NamedColor: Equatable, Sendable {
        var name: String
        var color: ResolvedColor
        var doc: String?
    }

    struct Gradient: Equatable, Sendable {
        var name: String
        var stops: [ResolvedColor]
        var direction: GradientLine.Direction
        var doc: String?
    }

    var name: String
    var colors: [NamedColor] = []
    var roles: [ColorRole] = []
    var gradients: [Gradient] = []
    var layers: [Int] = DesignSpec.loomLayers
    var radii: [RadiusToken] = RadiusToken.defaults
    var typeScale: [TypeStyle] = TypeStyle.defaults
    /// The brand's font families, in the order the files came; empty when the system's faces draw everything.
    var families: [FontFamily] = []
    /// The font files, as the app's bundle names them.
    var fontFiles: [String] = []
    var modifiers = false

    /// The family a design draws in: the first family for `default`, a serif family for `serif` and a monospaced one
    /// for `monospaced` (the first family when it is one); nil when the files have none, and the system's draws it.
    func family(for design: FontDesign) -> FontFamily? {
        guard let main = families.first else { return nil }
        switch design {
        case .default: return main
        case .serif: return main.serif ? main : families.first(where: \.serif)
        case .monospaced: return main.monospaced ? main : families.first(where: \.monospaced)
        case .rounded: return nil
        }
    }
}
