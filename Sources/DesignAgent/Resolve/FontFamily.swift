//  WHAT: A family of the brand's font files (SF Mono's Regular, Bold and Italic), what kind of family it is, and the
//        face nearest any weight, matched the way CSS matches weights.

import Foundation

struct FontFamily: Equatable, Sendable {
    var name: String
    /// Never empty.
    var faces: [FontFace]
    /// As code names its face function: `sfMono`.
    var member: String

    init(name: String, faces: [FontFace]) {
        self.name = name
        self.faces = faces
        member = DesignLine.member(name).map(SwiftName.member) ?? "brandFace"
    }

    var monospaced: Bool { faces.contains(where: \.monospaced) }
    var serif: Bool { faces.contains(where: \.serif) }
    var hasItalics: Bool { faces.contains(where: \.italic) }

    /// The face for `weight`: the upright face CSS would choose, and when italic is asked, the italic face of that same
    /// weight. Without one the upright face is answered, for the system to slant: weight says more than the slant does.
    func face(_ weight: FontWeight, italic: Bool) -> FontFace {
        let uprights = faces.filter { !$0.italic }
        let pool = uprights.isEmpty ? faces : uprights
        let chosen = Self.match(weight.css, among: pool.map(\.weight))
        let upright = pool.first { $0.weight == chosen } ?? faces[0]
        guard italic else { return upright }
        return faces.first { $0.italic && $0.weight == upright.weight } ?? upright
    }

    /// CSS's choice of weight: the one asked; from 400 to 500, the heavier ones up to 500, then the lighter, then the
    /// rest; below 400 the lighter first; above 500 the heavier first.
    static func match(_ wanted: Int, among weights: [Int]) -> Int {
        let available = Set(weights)
        if available.contains(wanted) { return wanted }
        let lighter = available.filter { $0 < wanted }.sorted(by: >)
        let heavier = available.filter { $0 > wanted }.sorted()
        let order: [Int]
        if (400...500).contains(wanted) {
            order = heavier.filter { $0 <= 500 } + lighter + heavier.filter { $0 > 500 }
        } else if wanted < 400 {
            order = lighter + heavier
        } else {
            order = heavier + lighter
        }
        return order.first ?? wanted
    }

    /// The families of `faces`, in the order their first face comes.
    static func grouped(_ faces: [FontFace]) -> [FontFamily] {
        var families: [FontFamily] = []
        for face in faces {
            if let index = families.firstIndex(where: { $0.name == face.family }) {
                families[index].faces.append(face)
            } else {
                families.append(FontFamily(name: face.family, faces: [face]))
            }
        }
        return families
    }
}
