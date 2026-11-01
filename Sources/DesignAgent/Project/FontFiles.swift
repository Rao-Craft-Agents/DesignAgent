//  WHAT: The faces in a brand's font files, read with CoreText before anything is copied, so the code names each face
//        by the PostScript name it really has and picks the nearest weight from what the files really hold.
//  PIN:  A FILE CORETEXT CANNOT READ IS REFUSED. A font that does not load draws nothing at runtime, so it is better
//        named now, with the call, than found later on a device.

import CoreText
import Foundation

enum FontFiles {
    /// What a font file is called: the kinds CoreText registers on iOS and macOS alike.
    static let kinds: Set<String> = ["ttf", "otf", "ttc"]

    /// The font files at `url`: the file, or the font files directly inside a folder, sorted.
    static func files(at url: URL) -> [URL] {
        var isFolder: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isFolder) else { return [] }
        guard isFolder.boolValue else { return [url] }
        let names = (try? FileManager.default.contentsOfDirectory(atPath: url.path)) ?? []
        return names.sorted().filter { kinds.contains(($0 as NSString).pathExtension.lowercased()) }.map { url.appendingPathComponent($0) }
    }

    /// Every face of the file at `url`; empty when CoreText reads none.
    static func faces(in url: URL) -> [FontFace] {
        guard let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor] else { return [] }
        return descriptors.map { descriptor in
            let font = CTFontCreateWithFontDescriptor(descriptor, 12, nil)
            let traits = CTFontCopyTraits(font) as NSDictionary
            let weight = (traits[kCTFontWeightTrait] as? NSNumber)?.doubleValue ?? 0
            let symbolic = (traits[kCTFontSymbolicTrait] as? NSNumber)?.uint32Value ?? 0
            let kind = symbolic >> 28
            return FontFace(postScript: CTFontCopyPostScriptName(font) as String, family: CTFontCopyFamilyName(font) as String,
                            weight: css(weight), italic: symbolic & CTFontSymbolicTraits.traitItalic.rawValue != 0,
                            monospaced: symbolic & CTFontSymbolicTraits.traitMonoSpace.rawValue != 0,
                            serif: [1, 2, 3, 4, 5, 7].contains(kind), file: url)
        }
    }

    /// CoreText's weight (-1 to 1) as CSS numbers it: the nearest of the weights SwiftUI names.
    static func css(_ weight: Double) -> Int {
        let table: [(Double, Int)] = [(-0.8, 100), (-0.6, 200), (-0.4, 300), (0, 400), (0.23, 500), (0.3, 600), (0.4, 700), (0.56, 800), (0.62, 900)]
        return table.min { abs($0.0 - weight) < abs($1.0 - weight) }?.1 ?? 400
    }
}
