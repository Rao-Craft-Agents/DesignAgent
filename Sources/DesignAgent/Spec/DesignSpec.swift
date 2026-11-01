//  WHAT: A call's lines, read: the palette, the roles, the gradients, the spacing layers, the radii and the type scale,
//        each line on its own. What a call leaves out is what every design has: Loom's layers, four radii, Apple's
//        type scale, and roles that read the project or the system.
//  PIN:  EVERY PROBLEM AT ONCE. A line that cannot be read is kept with its reason and reading goes on, so a refused
//        call names everything to fix and the next call can be right.

import Foundation

struct DesignSpec: Sendable {
    var name: String?
    var palette: [PaletteColor] = []
    var roles: [RoleLine] = []
    var gradients: [GradientLine] = []
    var layers: [Int] = DesignSpec.loomLayers
    var radii: [RadiusToken] = RadiusToken.defaults
    var typeScale: [TypeStyle] = TypeStyle.defaults
    var fonts: [String] = []
    var modifiers = false

    /// Loom's spacing: `.layer1` to `.layer6`.
    static let loomLayers = [4, 8, 12, 16, 24, 32]

    /// Every line of `input` read; the problems are each line that cannot be, with its reason.
    static func read(_ input: DesignAgent.Input) -> (spec: DesignSpec, problems: [String]) {
        var spec = DesignSpec()
        var problems: [String] = []
        func lines(_ list: [String]?) -> [String] {
            (list ?? []).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        }
        func each<T>(_ list: [String]?, what: String, _ parse: (String) throws -> T, name: (T) -> String) -> [T] {
            var read: [T] = [], seen: Set<String> = []
            for line in lines(list) {
                do {
                    let item = try parse(line)
                    if seen.insert(name(item)).inserted { read.append(item) } else { problems.append("\(what) `\(name(item))` is given twice") }
                } catch {
                    problems.append("\(error)")
                }
            }
            return read
        }
        if let name = input.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty { spec.name = name }
        spec.palette = each(input.palette, what: "the colour", PaletteColor.parse, name: \.name)
        spec.roles = each(input.roles, what: "the role", RoleLine.parse, name: \.name)
        spec.gradients = each(input.gradients, what: "the gradient", GradientLine.parse, name: \.name)
        spec.radii = merged(RadiusToken.defaults, each(input.radii, what: "the radius", RadiusToken.parse, name: \.name), name: \.name)
        spec.typeScale = merged(TypeStyle.defaults, each(input.type, what: "the type style", TypeStyle.parse, name: \.name), name: \.name)
        if let layers = input.spacing {
            if let problem = Self.problem(layers) { problems.append(problem) } else { spec.layers = layers }
        }
        spec.fonts = lines(input.fonts).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        spec.modifiers = input.modifiers ?? false
        return (spec, problems)
    }

    /// Why `layers` cannot be the spacing; nil when it can.
    static func problem(_ layers: [Int]) -> String? {
        guard !layers.isEmpty else { return "`spacing` gives no layers: leave it out for Loom's 4, 8, 12, 16, 24, 32" }
        guard layers.count <= 12 else { return "`spacing` gives \(layers.count) layers; twelve is the most" }
        if let bad = layers.first(where: { $0 <= 0 || $0 > 400 }) { return "`spacing` has \(bad), which is not a gap from 1 to 400 points" }
        for index in layers.indices.dropFirst() where layers[index] <= layers[index - 1] {
            return "`spacing` must grow: layer\(index + 1) (\(layers[index])) is not larger than layer\(index) (\(layers[index - 1]))"
        }
        return nil
    }

    /// `base` with each of `lines` in the place of the one of its name, or after them all when it is new.
    static func merged<T>(_ base: [T], _ lines: [T], name: (T) -> String) -> [T] {
        var result = base
        for line in lines {
            if let index = result.firstIndex(where: { name($0) == name(line) }) { result[index] = line } else { result.append(line) }
        }
        return result
    }
}
