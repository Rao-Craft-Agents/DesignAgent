import Foundation
import XCTest
@testable import DesignAgent

/// What the files say: the shapes the guide promises, what the project holds read into them, and nothing written when
/// a call is refused.
final class DesignEmitTests: XCTestCase {
    private func write(_ input: DesignAgent.Input, in given: URL? = nil) throws -> (DesignResult, URL) {
        let folder = try given ?? Fixture.folder()
        var input = input
        input.directory = folder.path
        return (try DesignAgent.write(input, note: { _ in }, yield: { _ in }), folder)
    }

    private func text(_ result: DesignResult, _ name: String) throws -> String {
        let path = try XCTUnwrap(result.paths.first { $0.hasSuffix("/" + name) }, "\(name) is written")
        return try String(contentsOfFile: path, encoding: .utf8)
    }

    private var larder: DesignAgent.Input {
        DesignAgent.Input(name: "Larder", palette: Fixture.palette, roles: Fixture.roles, radii: Fixture.radii, type: Fixture.type,
                          gradients: Fixture.gradients, modifiers: true)
    }

    func testTheBrandHoldsThePaletteAndGradientsAsValues() throws {
        let (result, _) = try write(larder)
        let brand = try text(result, "Brand.swift")
        XCTAssertTrue(brand.contains("enum Brand {"))
        XCTAssertTrue(brand.contains(#"static let name = "Larder""#))
        XCTAssertTrue(brand.contains("static let cream = Brand.color(light: 0xFBF7F0, dark: 0x1A1714)"))
        XCTAssertTrue(brand.contains("/// The spice jar. `#E8A33D`.\n        static let saffron = Brand.color(0xE8A33D)"))
        XCTAssertTrue(brand.contains("static let scrim = Brand.color(0x000000, opacity: 0.4)"))
        XCTAssertTrue(brand.contains("LinearGradient(colors: [Brand.Colors.saffron, Brand.Colors.tomato], startPoint: .topLeading, endPoint: .bottomTrailing)"))
        XCTAssertTrue(brand.contains("[Brand.color(0x2B2522), Brand.color(0x6B4E71)], startPoint: .top, endPoint: .bottom"))
        XCTAssertTrue(brand.contains("Brand.color(0xFFFFFF, opacity: 0)], startPoint: .leading, endPoint: .trailing"))
        XCTAssertTrue(brand.contains("NSColor(name: nil) { appearance in") && brand.contains("UIColor { traits in"), "a colour a appearance, both platforms")
        XCTAssertFalse(brand.contains("Color(hex:") || brand.contains("init(hex"), "never a `Color(hex:)`, which apps keep for themselves")
        XCTAssertNil(brand.range(of: #"static var \w+: Color ="#, options: .regularExpression), "no stored `static var`, which Swift 6 refuses")
    }

    func testRolesReadThePaletteTheLineNamesOrThePlatform() throws {
        let (result, _) = try write(larder)
        let roles = try text(result, "Brand.Color.swift")
        XCTAssertTrue(roles.contains("extension Color {"))
        XCTAssertTrue(roles.contains("/// Behind everything: windows, pages and lists. The palette's cream.\n    static var background: Color { Brand.Colors.cream }"))
        XCTAssertTrue(roles.contains("static var secondaryForeground: Color { Brand.Colors.ink.opacity(0.6) }"))
        XCTAssertTrue(roles.contains("/// A recipe someone starred. The palette's saffron.\n    static var highlight: Color { Brand.Colors.saffron }"))
        XCTAssertTrue(roles.contains("""
                static var tertiaryBackground: Color {
                    #if os(macOS)
                    Color(nsColor: .unemphasizedSelectedContentBackgroundColor)
                    #else
                    Color(uiColor: .tertiarySystemBackground)
                    #endif
                }
            """), roles)
        XCTAssertTrue(roles.contains("static var success: Color { .green }"))
        for role in ColorRole.defaults.map(\.name) { XCTAssertTrue(roles.contains("static var \(role): Color"), role) }
    }

    func testRolesReadTheAssetCatalogByNameWithItsNamespace() throws {
        let folder = try Fixture.folder()
        try Fixture.catalog(in: folder, sets: ["background": ("#FFFFFF", "#121212"), "foreground": ("#121212", "#F5F5F5"),
                                               "herbGreen": ("#3F7D58", "#6FBF8E"), "danger": ("#D90000", "#FF453A")],
                            top: ["AccentColor": ("#3F7D58", "#6FBF8E")])
        try Fixture.catalog(in: folder, at: "Packages/Kit/Sources/Kit/Kit.xcassets", namespace: nil, sets: ["separator": ("#000000", "#FFFFFF")])
        try Fixture.write("// swift-tools-version:6.0", to: folder.appendingPathComponent("Packages/Kit/Package.swift"))
        let (result, _) = try write(.init(palette: ["herb: herbGreen", "tomato: #D2492A"], roles: ["danger = tomato", "herbGreen"]), in: folder)
        let roles = try text(result, "Brand.Color.swift")
        XCTAssertTrue(roles.contains(#"static var background: Color { Color("colors/background") }"#), "the namespace is part of the name")
        XCTAssertTrue(roles.contains(#"static var accent: Color { Color("AccentColor") }"#), "AccentColor is the accent, as Xcode names it")
        XCTAssertTrue(roles.contains("static var danger: Color { Brand.Colors.tomato }"), "a line wins over the set of the role's name")
        XCTAssertTrue(roles.contains("Color(nsColor: .separatorColor)"), "a nested package's catalog is its own bundle's, not the app's")
        XCTAssertTrue(roles.contains(#"static var herbGreen: Color { Color("colors/herbGreen") }"#), "a role named alone reads the set of its name")
        XCTAssertTrue(try text(result, "Brand.swift").contains(#"static let herb = Color("colors/herbGreen")"#))
    }

    func testARoleXcodeAlreadyWritesIsLeftToItAndALineAgainstItIsRefused() throws {
        let folder = try Fixture.folder()
        try Fixture.catalog(in: folder, namespace: nil, sets: ["AccentColor": ("#3F7D58", "#6FBF8E"), "background": ("#FFFFFF", "#121212")])
        try Fixture.projectGeneratingSymbols(in: folder)
        let (result, _) = try write(.init(palette: ["cream: #FBF7F0"]), in: folder)
        let roles = try text(result, "Brand.Color.swift")
        XCTAssertFalse(roles.contains("static var accent:"), "Xcode writes Color.accent from AccentColor")
        XCTAssertFalse(roles.contains("static var background:"))
        XCTAssertTrue(roles.contains("// Color.accent: The brand on controls: buttons, links, toggles and selection. Xcode writes it from the asset catalog's `AccentColor`."))
        XCTAssertTrue(result.notes.contains { $0.contains("Color.accent (from AccentColor)") }, "\(result.notes)")
        XCTAssertThrowsError(try write(.init(palette: ["cream: #FBF7F0"], roles: ["background = cream"]), in: folder)) { error in
            XCTAssertTrue("\(error)".contains("Xcode already writes `Color.background` from the colour set background"), "\(error)")
        }
    }

    func testStyleHoldsTheLayersTokensAndTypeScale() throws {
        let (result, _) = try write(larder)
        let style = try text(result, "Style.swift")
        XCTAssertTrue(style.contains("/// 16 pt: the usual padding around content.\n    static var layer4: CGFloat { 16 }"))
        XCTAssertTrue(style.contains("static var layer6: CGFloat { 32 }"))
        XCTAssertTrue(style.contains("/// Cards and grouped sections. 14 pt.\n        static let card: CGFloat = 14"), "a default's doc kept, its value changed")
        XCTAssertTrue(style.contains("/// Filters and tags. 6 pt.\n        static let chip: CGFloat = 6"))
        for token in ["static let hairline: CGFloat = 0.5", "struct Shadow: Sendable", "static let card = Shadow(", "static let quick: Double = 0.2",
                      "#if os(macOS)\n        /// The sidebar's width.\n        static let sidebarWidth: CGFloat = 240", "static let readableWidth: CGFloat = 720",
                      "func shadow(_ shadow: Brand.Shadow) -> some View"] {
            XCTAssertTrue(style.contains(token), token)
        }
        XCTAssertTrue(style.contains("static var brandTitle: Font { .brand(.bold, size: 28, relativeTo: .title, design: .rounded) }"))
        XCTAssertTrue(style.contains("static var brandDisplay: Font { .brand(.heavy, size: 44, relativeTo: .largeTitle, design: .rounded) }"))
        XCTAssertTrue(style.contains("static var brandQuote: Font { .brand(.regular, size: 17, relativeTo: .body, design: .serif, italic: true) }"))
        XCTAssertTrue(style.contains("static var brandCaption2: Font { .brand(.regular, size: 11, relativeTo: .caption2) }"), "Apple's scale fills in")
        XCTAssertNil(style.range(of: #"static var (largeTitle|title|headline|body|caption): Font"#, options: .regularExpression), "SwiftUI's own are never hidden")
        let (spaced, _) = try write(.init(spacing: [2, 6, 10]))
        let layers = try text(spaced, "Style.swift")
        XCTAssertTrue(layers.contains("static var layer3: CGFloat { 10 }") && !layers.contains("layer4"))
    }

    func testFontsWithNoFilesDrawTheSystemsFaceAndSaySo() throws {
        let (result, _) = try write(larder)
        let fonts = try text(result, "Fonts/Fonts.swift")
        XCTAssertTrue(fonts.contains("static func brand(_ weight: Font.Weight = .regular, size: CGFloat, relativeTo style: Font.TextStyle = .body,"))
        XCTAssertTrue(fonts.contains("let font = Font.system(style, design: design, weight: weight)"))
        XCTAssertFalse(fonts.contains("enum Fonts"))
        XCTAssertEqual(result.notes, ["With no font files, the system draws each style at its text style's size so it follows Dynamic Type: display (44 pt) at largeTitle's 34 pt on iPhone; give `fonts` to draw exact sizes"])
    }

    func testFontFilesAreCopiedRegisteredAndMatchedByWeight() throws {
        let folder = try Fixture.folder()
        guard let mono = try Fixture.monoFonts(into: folder) else { throw XCTSkip("this Mac's Terminal has no SF Mono files") }
        try FileManager.default.copyItem(at: Fixture.georgia, to: folder.appendingPathComponent("Resources/Fonts/Georgia.ttf"))
        let (result, _) = try write(.init(type: ["title: 28 bold serif", "code: 13 mono footnote", "label: 15 rounded"], fonts: ["Resources/Fonts"]), in: folder)
        XCTAssertEqual(result.faces, ["Georgia", "SFMono-Bold", "SFMono-Regular", "SFMono-RegularItalic"], "a folder's files, sorted")
        let copied = result.paths.filter { !$0.hasSuffix(".swift") }.map { URL(fileURLWithPath: $0).lastPathComponent }
        XCTAssertEqual(copied, ["Georgia.ttf", "SF-Mono-Bold.otf", "SF-Mono-Regular.otf", "SF-Mono-RegularItalic.otf"])
        for path in result.paths { XCTAssertTrue(FileManager.default.fileExists(atPath: path), path) }
        XCTAssertEqual(mono.count, 3)
        let fonts = try text(result, "Fonts/Fonts.swift")
        XCTAssertTrue(fonts.contains(#"static let files = ["Georgia.ttf", "SF-Mono-Bold.otf", "SF-Mono-Regular.otf", "SF-Mono-RegularItalic.otf"]"#))
        XCTAssertTrue(fonts.contains("CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)"))
        XCTAssertTrue(fonts.contains("case .default, .serif:\n            return georgia(weight)"), "the first family is the brand's, and a serif")
        XCTAssertTrue(fonts.contains("case .monospaced:\n            return sfMono(weight, italic: italic)"))
        XCTAssertTrue(fonts.contains("""
                    switch weight {
                    case .semibold, .bold, .heavy, .black:
                        return "SFMono-Bold"
                    default:
                        return italic ? "SFMono-RegularItalic" : "SFMono-Regular"
                    }
            """), fonts)
        XCTAssertTrue(fonts.contains("private static func georgia(_ weight: Font.Weight) -> String {\n        \"Georgia\"\n    }"), "one face, no switch")
        XCTAssertTrue(fonts.contains("return italic && !Fonts.italicFaces.contains(face) ? font.italic() : font"))
        let style = try text(result, "Style.swift")
        XCTAssertTrue(style.contains("/// Title: Georgia at 28 pt, growing and shrinking with Dynamic Type as `.title` does."), style)
        XCTAssertTrue(result.notes.contains("The font files have no face for label (rounded), so the system's face draws them"), "\(result.notes)")
        let again = try write(.init(fonts: ["Shared/Design/Fonts/SF-Mono-Bold.otf"]), in: folder).0
        XCTAssertFalse(again.paths.contains { $0.hasSuffix(".otf") }, "a file already in the Fonts folder is not copied onto itself")
        XCTAssertEqual(again.faces, ["SFMono-Bold"])
    }

    func testModifiersAreWrittenOnlyWhenAskedFromTheLayersTheDesignHas() throws {
        let (plain, _) = try write(.init())
        XCTAssertFalse(plain.paths.contains { $0.hasSuffix("View+Style.swift") })
        let (asked, folder) = try write(.init(into: "App/Theme", spacing: [2, 6, 10, 20], modifiers: true))
        let path = try XCTUnwrap(asked.paths.last)
        XCTAssertEqual(path, folder.appendingPathComponent("App/Extensions/View+Style.swift").path, "beside the design's folder")
        let modifiers = try String(contentsOfFile: path, encoding: .utf8)
        for said in ["func cardStyle() -> some View", "func sectionStyle() -> some View", "func brandBackground() -> some View",
                     "padding(.layer4)", ".padding(.vertical, .layer3)", "RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous)",
                     ".shadow(Brand.Shadow.card)", ".fill(Color.separator)", "background(Color.background.ignoresSafeArea())"] {
            XCTAssertTrue(modifiers.contains(said), said)
        }
    }

    func testARefusedCallWritesNothingAndNamesEveryReason() throws {
        let folder = try Fixture.folder()
        let input = DesignAgent.Input(palette: ["ink: brandInk", "cream: #FBF7F0"], roles: ["accent = basil", "red = cream"],
                                      type: ["title: huge"], fonts: ["Resources/Missing.ttf"], gradients: ["sunrise: cream mango"], directory: folder.path)
        XCTAssertThrowsError(try DesignAgent.write(input, note: { _ in }, yield: { _ in })) { error in
            let said = "\(error)"
            XCTAssertTrue(said.hasPrefix("6 problems, so nothing was written"), said)
            for reason in ["the colour ink names brandInk", "the accent role names basil", "SwiftUI's own", "`huge` is not a size",
                           "Resources/Missing.ttf, which is not a font file", "the gradient sunrise names mango"] {
                XCTAssertTrue(said.contains(reason), "\(reason) in \(said)")
            }
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: folder.appendingPathComponent("Shared").path), "nothing written")
    }

    func testAFileThatDoesNotParseLandsNothingNotEvenACopy() throws {
        let folder = try Fixture.folder()
        let source = folder.appendingPathComponent("font.ttf")
        try Data("font".utf8).write(to: source)
        let files = AgentFiles(directory: folder.path)
        let copy = folder.appendingPathComponent("Shared/Design/Fonts/font.ttf")
        XCTAssertThrowsError(try files.write([(folder.appendingPathComponent("Shared/Design/Odd.swift"), "struct {")], copying: [(source, copy)])) { error in
            XCTAssertTrue("\(error)".contains("Shared/Design/Odd.swift"), "\(error)")
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: copy.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: folder.appendingPathComponent("Shared/Design/Odd.swift").path))
    }

    func testTheSameCallWritesTheSameFilesAndSaysWhatElseDeclaresThem() throws {
        let (first, folder) = try write(larder)
        let before = try first.paths.map { try String(contentsOfFile: $0, encoding: .utf8) }
        try Fixture.write("import SwiftUI\n\nstruct Brand {}\n\nextension Color {\n    static var background: Color { .white }\n}\n",
                          to: folder.appendingPathComponent("Shared/Old/Theme.swift"))
        let (second, _) = try write(larder, in: folder)
        XCTAssertEqual(try second.paths.map { try String(contentsOfFile: $0, encoding: .utf8) }, before, "no model: the same lines, the same files")
        XCTAssertTrue(second.notes.contains("Shared/Old/Theme.swift also declares `Brand` and a colour role, so the build will find two: keep one"), "\(second.notes)")
    }
}
