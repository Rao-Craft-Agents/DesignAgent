//  WHAT: One face of a font file, as CoreText reads it: the PostScript name `Font.custom` takes, its family, its
//        weight, and whether it is italic, monospaced or a serif.

import Foundation

struct FontFace: Equatable, Sendable {
    /// What `Font.custom` takes: `SFMono-Bold`.
    var postScript: String
    /// `SF Mono`.
    var family: String
    /// 100 to 900, as CSS numbers weights.
    var weight: Int
    var italic: Bool
    var monospaced: Bool
    var serif: Bool
    /// The file it is in.
    var file: URL
}
