import Foundation
import XCTest
@testable import DesignAgent

/// The files compiled as an app compiles them, and run: each design written into a package with a view that uses every
/// token, built with `swift build` for macOS and `xcodebuild` for the iOS simulator in Swift 6 and Swift 5, and a
/// program that checks on macOS what the colours and the fonts do. Gated (`DESIGN_BUILD=1`): the builds take minutes.
final class DesignBuildTests: XCTestCase {
    private var gated: Bool { ProcessInfo.processInfo.environment["DESIGN_BUILD"] == "1" }
    private let simulator = "generic/platform=iOS Simulator"

    /// Hex colours, the brand's own font files and the modifiers: built in both language modes on both platforms, and
    /// run: each colour drawn in light and dark, the fonts absent until registered from the bundle, the faces chosen.
    func testAHexPaletteWithFontsBuildsEverywhereAndDrawsLightAndDark() throws {
        try XCTSkipUnless(gated, "set DESIGN_BUILD=1 to build the output")
        let folder = try Fixture.folder()
        guard let fonts = try Fixture.monoFonts(into: folder) else { throw XCTSkip("this Mac's Terminal has no SF Mono files") }
        var input = DesignAgent.Input(name: "Larder", palette: Fixture.palette, roles: Fixture.roles, radii: Fixture.radii,
                                      type: Fixture.type, fonts: fonts, gradients: Fixture.gradients, modifiers: true)
        input.directory = folder.path
        let result = try DesignAgent.write(input, note: { _ in }, yield: { _ in })
        var sample = SamplePackage(folder: folder)
        sample.resources = result.paths.filter { $0.hasSuffix(".otf") }.map { "Design/Fonts/" + URL(fileURLWithPath: $0).lastPathComponent }
        try sample.writeGallery(result, modifiers: true, fonts: true)
        try sample.writeCheck(#"""
            expect(drawn(Color.background, .aqua), "#FBF7F0", "the background in light")
            expect(drawn(Color.background, .darkAqua), "#1A1714", "the background in dark")
            expect(resolved(Color.background, .light), "#FBF7F0", "the background as SwiftUI resolves light")
            expect(resolved(Color.background, .dark), "#1A1714", "the background as SwiftUI resolves dark")
            expect(drawn(Color.secondaryBackground, .darkAqua), "#24201C", "the secondary background in dark")
            expect(resolved(Color.secondaryForeground, .dark), "#F3EEE8 0.60", "the secondary foreground: ink at 60% in dark")
            expect(resolved(Color.secondaryForeground, .light), "#2B2522 0.60", "the secondary foreground: ink at 60% in light")
            expect(drawn(Color.accent, .darkAqua), "#6FBF8E", "the accent in dark")
            expect(drawn(Color.danger, .aqua), "#D2492A", "danger in light")
            expect(drawn(Color.highlight, .darkAqua), "#E8A33D", "a role of the app's own")
            expect(drawn(Brand.Colors.saffron, .darkAqua), "#E8A33D", "a colour for both appearances")
            expect(drawn(Brand.Colors.scrim, .aqua), "#000000 0.40", "a colour with alpha")
            expect(drawn(Brand.Shadow.card.color, .aqua), "#000000 0.08", "the card's shadow in light")
            expect(drawn(Brand.Shadow.card.color, .darkAqua), "#000000 0.40", "the card's shadow in dark")
            expect("\(CGFloat.layer1) \(CGFloat.layer4) \(CGFloat.layer6)", "4.0 16.0 32.0", "Loom's layers")
            expect("\(Brand.Radius.card) \(Brand.Radius.chip) \(Brand.Radius.small)", "14.0 6.0 4.0", "the radii")
            expect(Fonts.face(.bold) ?? "nil", "SFMono-Bold", "bold's face")
            expect(Fonts.face(.light) ?? "nil", "SFMono-Regular", "light, with no light file, is the regular face")
            expect(Fonts.face(.regular, italic: true) ?? "nil", "SFMono-RegularItalic", "the italic face")
            expect(Fonts.face(.bold, italic: true) ?? "nil", "SFMono-Bold", "bold italic: the bold face, for the system to slant")
            expect(Fonts.face(.regular, design: .monospaced) ?? "nil", "SFMono-Regular", "monospaced reads the mono family")
            expect(Fonts.face(.regular, design: .serif) ?? "nil", "nil", "no serif file: the system's serif")
            if NSFont(name: "SFMono-Bold", size: 12) == nil {
                Fonts.register(from: .module)
                expect(NSFont(name: "SFMono-Bold", size: 12)?.fontName ?? "nil", "SFMono-Bold", "SF Mono once registered from the bundle")
                expect(NSFont(name: "SFMono-RegularItalic", size: 12)?.fontName ?? "nil", "SFMono-RegularItalic", "its italic too")
            } else {
                print("SF Mono was installed on this Mac already, so registering proves nothing here")
            }
            _ = NSHostingView(rootView: DesignGalleryPair()).fittingSize
            """#)
        try buildEverywhere(sample, run: true)
    }

    /// Colours kept in an asset catalog the way Loom keeps them (a `colors` folder that provides a namespace) and a
    /// palette that names one: built in both language modes on both platforms.
    func testAnAssetCatalogDesignBuildsEverywhere() throws {
        try XCTSkipUnless(gated, "set DESIGN_BUILD=1 to build the output")
        let folder = try Fixture.folder()
        try Fixture.catalog(in: folder, sets: [
            "background": ("#FFFFFF", "#121212"), "secondaryBackground": ("#ECEFF1", "#1A1A1A"), "tertiaryBackground": ("#CFD8DC", "#282828"),
            "alternateBackground": ("#FFFFFF", "#090909"), "foreground": ("#121212", "#F5F5F5"), "secondaryForeground": ("#6B6B6B", "#A0A0A0"),
            "herbGreen": ("#3F7D58", "#6FBF8E"),
        ], top: ["AccentColor": ("#3F7D58", "#6FBF8E")])
        var input = DesignAgent.Input(name: "Larder", palette: ["herb: herbGreen", "marble: #A19A8E"], roles: ["success = herb"],
                                      type: ["title: 28 bold rounded", "display: 44 heavy"], gradients: ["stone: marble herb vertical"])
        input.directory = folder.path
        let result = try DesignAgent.write(input, note: { _ in }, yield: { _ in })
        XCTAssertTrue(result.roles.contains("background = colour set colors/background"), "\(result.roles)")
        XCTAssertTrue(result.roles.contains("accent = colour set AccentColor"), "\(result.roles)")
        var sample = SamplePackage(folder: folder)
        sample.resources = ["Assets.xcassets"]
        try sample.writeGallery(result, modifiers: false, fonts: false)
        try sample.writeCheck(#"""
            expect(drawn(Brand.Colors.marble, .darkAqua), "#A19A8E", "a hex colour beside the catalog's")
            expect("\(CGFloat.layer4)", "16.0", "Loom's layers")
            _ = NSHostingView(rootView: DesignGalleryPair()).fittingSize
            """#)
        try buildEverywhere(sample, run: true)
    }

    /// A project whose Xcode settings write `Color` members for its colour sets: the roles Xcode writes are left to it,
    /// and the design builds with those settings on, for macOS and the iOS simulator.
    func testAProjectThatWritesAssetSymbolsBuilds() throws {
        try XCTSkipUnless(gated, "set DESIGN_BUILD=1 to build the output")
        let folder = try Fixture.folder()
        try Fixture.catalog(in: folder, namespace: nil, sets: ["background": ("#FFFFFF", "#121212"), "AccentColor": ("#3F7D58", "#6FBF8E"),
                                                                "separator": ("#E0E0E0", "#2A2A2A"), "brandInk": ("#2B2522", "#F3EEE8")])
        // Beside the package rather than at its top, so xcodebuild builds the package and the design call still reads it.
        try Fixture.projectGeneratingSymbols(in: folder, at: "App")
        var input = DesignAgent.Input(palette: ["cream: #FBF7F0/#1A1714", "ink: brandInk"], roles: ["secondaryBackground = cream", "foreground = ink"],
                                      modifiers: true)
        input.directory = folder.path
        let result = try DesignAgent.write(input, note: { _ in }, yield: { _ in })
        XCTAssertEqual(result.roles.filter { $0.hasSuffix("(Xcode's symbol)") }.count, 3, "\(result.roles)")
        var sample = SamplePackage(folder: folder)
        sample.resources = ["Assets.xcassets"]
        try sample.writeManifest()
        try sample.writeGallery(result, modifiers: true, fonts: false)
        try sample.writeCheck("")
        let symbols = ["ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS=YES"]
        let (mac, macLog) = try sample.xcodebuild("platform=macOS", settings: symbols, derived: "dd-mac")
        XCTAssertTrue(mac, "macOS, asset symbol extensions on:\n\(macLog)")
        let (iOS, iOSLog) = try sample.xcodebuild(simulator, settings: symbols, derived: "dd-ios")
        XCTAssertTrue(iOS, "iOS simulator, asset symbol extensions on:\n\(iOSLog)")
    }

    /// Swift 6, then Swift 5: `swift build` for macOS (and the check run, in Swift 6), `xcodebuild` for the simulator.
    private func buildEverywhere(_ package: SamplePackage, run: Bool) throws {
        var sample = package
        for mode in [6, 5] {
            sample.mode = mode
            try sample.writeManifest()
            let (mac, macLog) = try sample.buildForMac()
            XCTAssertTrue(mac, "macOS, Swift \(mode):\n\(macLog)")
            if run && mode == 6 {
                let (ok, log) = try sample.runCheck()
                XCTAssertTrue(ok, "the check, on macOS:\n\(log)")
            }
            let (iOS, iOSLog) = try sample.xcodebuild(simulator, derived: "dd-ios-\(mode)")
            XCTAssertTrue(iOS, "iOS simulator, Swift \(mode):\n\(iOSLog)")
        }
    }
}
