import XCTest
@testable import DesignAgent

/// The lines a model writes, read: every form the guide promises, and a reason for every line refused.
final class DesignLineTests: XCTestCase {
    func testHex() {
        XCTAssertEqual(Hex.parse("#A19A8E"), Hex(rgb: 0xA19A8E, opacity: 1))
        XCTAssertEqual(Hex.parse("#fa0"), Hex(rgb: 0xFFAA00, opacity: 1))
        XCTAssertEqual(Hex.parse("0x121212"), Hex(rgb: 0x121212, opacity: 1))
        XCTAssertEqual(Hex.parse("#00000066")?.rgb, 0)
        XCTAssertEqual(Hex.parse("#00000066")?.opacity ?? 0, 0.4, accuracy: 0.001)
        XCTAssertEqual(Hex.parse("#00000066")?.text, "#00000066")
        for bad in ["A19A8E", "#GG0000", "#12345", "#", "facade"] { XCTAssertNil(Hex.parse(bad), bad) }
    }

    func testPaletteLines() throws {
        let pair = try PaletteColor.parse("cream: #FBF7F0 / #1A1714")
        XCTAssertEqual(pair.color.value, .adaptive(light: Hex(rgb: 0xFBF7F0, opacity: 1), dark: Hex(rgb: 0x1A1714, opacity: 1)))
        let documented = try PaletteColor.parse(#"saffron "the spice jar": #E8A33D"#)
        XCTAssertEqual(documented.doc, "the spice jar")
        XCTAssertEqual(documented.color.value, .fixed(Hex(rgb: 0xE8A33D, opacity: 1)))
        let named = try PaletteColor.parse("brand-ink = colors/brandInk 80%")
        XCTAssertEqual(named.name, "brandInk", "said as a person says it, named as Swift does")
        XCTAssertEqual(named.color, ColorExpression(value: .named("colors/brandInk"), opacity: 0.8))
        XCTAssertEqual(DesignLine.member("SF Mono"), "sfMono")
        XCTAssertEqual(DesignLine.member("Brand_Blue v2"), "brandBlueV2")
    }

    func testRoleLines() throws {
        let faded = try RoleLine.parse("secondary foreground = ink 60%")
        XCTAssertEqual(faded.name, "secondaryForeground")
        XCTAssertEqual(faded.color, ColorExpression(value: .named("ink"), opacity: 0.6))
        let own = try RoleLine.parse(#"highlight: #E8A33D/#F2B95E "a recipe someone starred""#)
        XCTAssertEqual(own.doc, "a recipe someone starred")
        guard case .adaptive = own.color.value else { return XCTFail("a light and a dark hex") }
        let alone = try RoleLine.parse("alternateSecondaryBackground")
        XCTAssertEqual(alone.color, ColorExpression(value: .named("alternateSecondaryBackground"), opacity: nil), "named alone: the colour of its name")
    }

    func testTypeLines() throws {
        let title = try TypeStyle.parse("title: 28 bold rounded")
        XCTAssertEqual([title.member, "\(title.size)", title.weight.rawValue, title.design.rawValue, title.style.rawValue],
                       ["brandTitle", "28.0", "bold", "rounded", "title"])
        let headline = try TypeStyle.parse("headline: serif")
        XCTAssertEqual(headline.size, 17, "a text style's own size when the line gives none")
        XCTAssertEqual(headline.weight, .semibold, "and its own weight")
        let display = try TypeStyle.parse("display: 44pt heavy")
        XCTAssertEqual(display.style, .largeTitle, "scales with the style nearest its size")
        XCTAssertEqual(try TypeStyle.parse("label: 17 semibold").style, .headline, "a semibold 17 reads as the headline")
        XCTAssertEqual(try TypeStyle.parse("note: 14").style, .subheadline, "a tie goes to the larger style")
        let code = try TypeStyle.parse("code: 13, medium, mono, italic, footnote")
        XCTAssertEqual([code.design.rawValue, code.style.rawValue, "\(code.italic)"], ["monospaced", "footnote", "true"])
    }

    func testGradientLines() throws {
        let sunrise = try GradientLine.parse("sunrise: saffron → tomato")
        XCTAssertEqual(sunrise.stops.map(\.value), [.named("saffron"), .named("tomato")])
        XCTAssertEqual(sunrise.direction, .diagonal)
        let glass = try GradientLine.parse("glass: #FFFFFF 60% to #FFFFFF 0% horizontal")
        XCTAssertEqual(glass.stops.map(\.opacity), [0.6, 0])
        XCTAssertEqual(glass.direction, .horizontal)
        XCTAssertEqual(try GradientLine.parse("dusk: #2B2522/#1A1714 #6B4E71 down").stops.count, 2)
        XCTAssertEqual(try RadiusToken.parse("sheet: 20pt").points, 20)
    }

    func testLinesThatAreRefusedSayWhy() {
        let refused: [(String, (String) throws -> Any, String)] = [
            ("cream #FBF7F0", PaletteColor.parse, "no colon"),
            ("2tone: #FFFFFF", PaletteColor.parse, "start it with a letter"),
            ("cream: #FBF7F", PaletteColor.parse, "not a hex colour"),
            ("cream: #FFFFFF 120%", PaletteColor.parse, "opacity from 0% to 100%"),
            ("red = #FF0000", RoleLine.parse, "SwiftUI's own"),
            ("accent green", RoleLine.parse, "no `=`"),
            ("title: huge bold", TypeStyle.parse, "`huge` is not a size"),
            ("display: bold", TypeStyle.parse, "needs a size"),
            ("tiny: 2", TypeStyle.parse, "from 6 to 200"),
            ("sunrise: saffron", GradientLine.parse, "two colours or more"),
            ("card: round", RadiusToken.parse, "not a radius"),
        ]
        for (line, parse, reason) in refused {
            XCTAssertThrowsError(try parse(line), line) { error in
                XCTAssertTrue("\(error)".contains(reason), "\(line) → \(error)")
            }
        }
    }

    func testEveryProblemOfACallAtOnce() {
        let input = DesignAgent.Input(palette: ["cream: #FBF7F0", "cream: #FFFFFF", "bad"], roles: ["red = cream"], spacing: [4, 8, 8],
                                      type: ["title: huge"], gradients: ["one: cream"])
        let problems = DesignSpec.read(input).problems
        XCTAssertEqual(problems.count, 6, problems.joined(separator: "\n"))
        XCTAssertTrue(problems.contains("the colour `cream` is given twice"), "\(problems)")
        XCTAssertTrue(problems.contains { $0.contains("layer3 (8) is not larger than layer2 (8)") }, "\(problems)")
        XCTAssertNil(DesignSpec.problem([2, 4, 8, 16]))
        XCTAssertNotNil(DesignSpec.problem([]))
        XCTAssertNotNil(DesignSpec.problem([0, 4]))
        XCTAssertNotNil(DesignSpec.problem(Array(1...13)))
    }

    func testLinesChangeTheDefaultsTheyNameAndAddTheRest() {
        let spec = DesignSpec.read(.init(radii: ["card: 14", "chip: 6"], type: ["body: 16", "display: 44 heavy"])).spec
        XCTAssertEqual(spec.radii.map(\.name), ["small", "medium", "card", "large", "chip"])
        XCTAssertEqual(spec.radii.first { $0.name == "card" }?.points, 14)
        XCTAssertEqual(spec.typeScale.count, 12)
        XCTAssertEqual(spec.typeScale.first { $0.name == "body" }?.size, 16)
        XCTAssertEqual(spec.typeScale.last?.name, "display")
    }
}
