import Foundation
import XCTest
@testable import DesignAgent

/// What a call reads of the project: its asset catalogs' colour sets as code names them, its Xcode settings, its font
/// files' faces, and the host's own paths.
final class ProjectReadingTests: XCTestCase {
    func testColourSetsAreNamedAsCodeNamesThem() throws {
        let folder = try Fixture.folder()
        try Fixture.catalog(in: folder, sets: ["background": ("#FFFFFF", "#121212")], top: ["AccentColor": ("#3F7D58", "#6FBF8E")])
        try Fixture.colorSet(folder.appendingPathComponent("Shared/Assets.xcassets/Brand/warning-red.colorset"), light: "#D90000", dark: "#FF453A")
        try Fixture.catalog(in: folder, at: ".build/Stale.xcassets", namespace: nil, sets: ["stale": ("#000000", "#000000")])
        try Fixture.catalog(in: folder, at: "Packages/Kit/Kit.xcassets", namespace: nil, sets: ["kit": ("#000000", "#000000")])
        try Fixture.write("// swift-tools-version:6.0", to: folder.appendingPathComponent("Packages/Kit/Package.swift"))
        let catalogs = AssetCatalogs(walk: ProjectWalk(root: folder))
        XCTAssertEqual(catalogs.sets.map(\.name), ["AccentColor", "warning-red", "colors/background"],
                       "outside a namespace first; a folder without one adds nothing; build folders and nested packages are not the app's")
        XCTAssertEqual(catalogs.sets.map(\.symbol), ["accent", "warningRed", "background"])
        XCTAssertFalse(catalogs.symbolExtensions)
        XCTAssertEqual(catalogs.find("background")?.name, "colors/background")
        XCTAssertEqual(catalogs.find("Colors/Background")?.name, "colors/background")
        XCTAssertEqual(catalogs.find("warningRed")?.name, "warning-red")
        XCTAssertEqual(catalogs.set(forRole: "accent")?.name, "AccentColor")
        XCTAssertNil(catalogs.find("stale"))
        XCTAssertNil(catalogs.generated("accent"), "Xcode writes no Color members unless the project says so")
        try Fixture.projectGeneratingSymbols(in: folder)
        let generating = AssetCatalogs(walk: ProjectWalk(root: folder))
        XCTAssertTrue(generating.symbolExtensions)
        XCTAssertEqual(generating.generated("accent")?.name, "AccentColor")
        XCTAssertNil(generating.generated("background"), "a namespaced set becomes Color.Colors.background, not Color.background")
    }

    func testXcodesSymbolNames() {
        let names = ["AccentColor": "accent", "BrandColor": "brand", "Separator": "separator", "warning-red": "warningRed",
                     "background": "background", "Color": "color", "brand ink": "brandInk"]
        for (asset, symbol) in names { XCTAssertEqual(SymbolName.of(asset), symbol, asset) }
    }

    func testFontFilesAreReadForTheirRealFaces() throws {
        let regular = Fixture.terminalFonts.appendingPathComponent("SF-Mono-Regular.otf")
        let italic = Fixture.terminalFonts.appendingPathComponent("SF-Mono-RegularItalic.otf")
        guard FileManager.default.fileExists(atPath: regular.path) else { throw XCTSkip("this Mac's Terminal has no SF Mono files") }
        let faces = FontFiles.faces(in: regular) + FontFiles.faces(in: italic) + FontFiles.faces(in: Fixture.georgia)
        XCTAssertEqual(faces.map(\.postScript), ["SFMono-Regular", "SFMono-RegularItalic", "Georgia"])
        XCTAssertEqual(faces.map(\.family), ["SF Mono", "SF Mono", "Georgia"])
        XCTAssertEqual(faces.map(\.weight), [400, 400, 400])
        XCTAssertEqual(faces.map(\.italic), [false, true, false])
        XCTAssertEqual(faces.map(\.monospaced), [true, true, false])
        XCTAssertEqual(faces.map(\.serif), [false, false, true])
        XCTAssertEqual(FontFamily.grouped(faces).map(\.member), ["sfMono", "georgia"])
        let notAFont = try Fixture.folder().appendingPathComponent("notes.ttf")
        try Data("not a font".utf8).write(to: notAFont)
        XCTAssertEqual(FontFiles.faces(in: notAFont), [])
        XCTAssertEqual(FontFiles.css(0.4), 700)
        XCTAssertEqual(FontFiles.css(0.23), 500)
        XCTAssertEqual(FontFiles.css(-0.4), 300)
    }

    func testWeightsAreMatchedAsCSSMatchesThem() {
        XCTAssertEqual(FontFamily.match(400, among: [300, 700]), 300, "400 with no 400 or 500: lighter first")
        XCTAssertEqual(FontFamily.match(400, among: [500, 300]), 500, "then up to 500 before that")
        XCTAssertEqual(FontFamily.match(600, among: [400, 800]), 800, "above 500: heavier first")
        XCTAssertEqual(FontFamily.match(300, among: [100, 400]), 100, "below 400: lighter first")
        XCTAssertEqual(FontFamily.match(900, among: [400, 700]), 700)
        let file = URL(fileURLWithPath: "/fonts/x.otf")
        let family = FontFamily(name: "Pantry Sans", faces: [
            FontFace(postScript: "Pantry-Regular", family: "Pantry Sans", weight: 400, italic: false, monospaced: false, serif: false, file: file),
            FontFace(postScript: "Pantry-Bold", family: "Pantry Sans", weight: 700, italic: false, monospaced: false, serif: false, file: file),
            FontFace(postScript: "Pantry-Italic", family: "Pantry Sans", weight: 400, italic: true, monospaced: false, serif: false, file: file),
        ])
        XCTAssertEqual(family.face(.semibold, italic: false).postScript, "Pantry-Bold")
        XCTAssertEqual(family.face(.regular, italic: true).postScript, "Pantry-Italic")
        XCTAssertEqual(family.face(.bold, italic: true).postScript, "Pantry-Bold", "weight before slant: the bold face, slanted by the system")
        XCTAssertEqual(family.member, "pantrySans")
        let mono = FontFace(postScript: "PantryMono-Regular", family: "Pantry-Sans", weight: 400, italic: false, monospaced: true, serif: false, file: file)
        var design = Design(name: "Larder")
        design.families = [family, FontFamily(name: "Pantry-Sans", faces: [mono])]
        design.fontFiles = ["x.otf"]
        let fonts = FontsFile.text(design)
        XCTAssertTrue(fonts.contains("return pantrySans(weight, italic: italic)") && fonts.contains("return pantrySans2(weight)"),
                      "two families that say the same in Swift get a function each:\n\(fonts)")
        XCTAssertTrue(fonts.contains("private static func pantrySans2(_ weight: Font.Weight) -> String {\n        \"PantryMono-Regular\"\n    }"))
    }
}

/// The host's folder, kept as the host wrote it.
final class AgentFilesTests: XCTestCase {
    func testPathsKeepTheHostsFormAndResolveParents() {
        let files = AgentFiles(directory: "/private/tmp/app")
        XCTAssertEqual(files.resolve("Shared/Design").path, "/private/tmp/app/Shared/Design", "/private is not dropped")
        XCTAssertEqual(files.resolve("Shared/../Resources/./Fonts").path, "/private/tmp/app/Resources/Fonts")
        XCTAssertEqual(files.resolve("/abs/a/../b").path, "/abs/b")
        XCTAssertEqual(files.relative(files.resolve("Shared/Design/Brand.swift")), "Shared/Design/Brand.swift")
        XCTAssertEqual(files.relative(URL(fileURLWithPath: "/elsewhere/x")), "/elsewhere/x")
    }
}
