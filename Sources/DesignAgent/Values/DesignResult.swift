import Foundation

/// What a call answers: the files written, as absolute paths, and the names views write to use them.
public struct DesignResult: Codable, Sendable, Equatable {
    /// The first file written.
    public var path: String?
    /// Every file written: the design files, the font files copied beside them, and the modifiers when asked.
    public var paths: [String]
    /// The palette, as `Brand.Colors` names it.
    public var colors: [String]
    /// Every colour role and what it reads: `background = cream`, `accent = asset AccentColor`, `success = system`.
    public var roles: [String]
    /// The spacing layers, `.layer1` first, in points.
    public var layers: [Int]
    /// The corner radii, as `Brand.Radius` names them.
    public var radii: [String]
    /// The type scale, as `Font` names it: `brandTitle`, `brandBody`.
    public var type: [String]
    /// The gradients, as `Brand.Gradients` names them.
    public var gradients: [String]
    /// The font faces the copied files hold, by PostScript name.
    public var faces: [String]
    /// One sentence each: what the call could not do as asked, and what to know before using it.
    public var notes: [String]

    public init(path: String?, paths: [String], colors: [String], roles: [String], layers: [Int], radii: [String],
                type: [String], gradients: [String], faces: [String], notes: [String]) {
        self.path = path; self.paths = paths; self.colors = colors; self.roles = roles; self.layers = layers
        self.radii = radii; self.type = type; self.gradients = gradients; self.faces = faces; self.notes = notes
    }
}
