import Foundation
import GraniteAgents
import XCTest
@testable import DesignAgent

/// The package as an app finds it: by its record, with the schema a model is shown and the guide a host prompts with.
final class DesignAgentTests: XCTestCase {
    func testTheRecordIsFoundWithNothingListed() throws {
        let design = try XCTUnwrap(GraniteRoster.discovered().package("design"), "the record is in this test binary")
        XCTAssertEqual(design.module, "DesignAgent")
        XCTAssertEqual(design.summary, DesignAgent.summary)
    }

    func testTheSchemaIsWhatAModelIsShown() {
        let design = AnyAgentPackage(DesignAgent.self)
        XCTAssertEqual(design.schema, .object([
            .init(name: "into", schema: .string, required: false),
            .init(name: "name", schema: .string, required: false),
            .init(name: "palette", schema: .array(.string), required: false),
            .init(name: "roles", schema: .array(.string), required: false),
            .init(name: "spacing", schema: .array(.integer), required: false),
            .init(name: "radii", schema: .array(.string), required: false),
            .init(name: "type", schema: .array(.string), required: false),
            .init(name: "fonts", schema: .array(.string), required: false),
            .init(name: "gradients", schema: .array(.string), required: false),
            .init(name: "modifiers", schema: .boolean, required: false),
            .init(name: "directory", schema: .string, required: false),
        ]))
        XCTAssertTrue(design.takesDirectory)
        XCTAssertEqual(Set(design.fields.keys), ["into", "name", "palette", "roles", "spacing", "radii", "type", "fonts", "gradients", "modifiers"],
                       "a note beside every field the model sees, and none for the host's folder")
        XCTAssertEqual(design.lanes, 2)
        XCTAssertNotNil(DesignAgent.word.range(of: #"^[a-z][a-z0-9]{1,31}$"#, options: .regularExpression), "a store-safe word")
    }

    func testTheGuideTeachesEachLineAndItsExamplesAreCalls() throws {
        let guide = AnyAgentPackage(DesignAgent.self).guide
        for said in ["cream: #FBF7F0/#1A1714", "background = cream", "ink 60%", "title: 28 bold rounded", "card: 14", "sunrise: saffron tomato",
                     "`fonts`", "`modifiers: true`", ".padding(.layer4)", ".font(.brandTitle)", "Color.secondaryForeground", "Brand.Colors.cream",
                     "Font.brand(.bold, size: 28, relativeTo: .title)", "nothing is written"] {
            XCTAssertTrue(guide.contains(said), "the guide says \(said)")
        }
        let examples = Self.objects(in: guide)
        XCTAssertEqual(examples.count, 3, "one example call a mode: hex colours, the asset catalog, its own fonts")
        for example in examples {
            XCTAssertNoThrow(try JSONDecoder().decode(DesignAgent.Input.self, from: Data(example.utf8)), example)
        }
        let first = try JSONDecoder().decode(DesignAgent.Input.self, from: Data(examples[0].utf8))
        XCTAssertEqual(DesignSpec.read(first).problems, [], "the hex example reads with no problem")
    }

    /// The call as a host makes it: JSON in, the host's folder filled, JSON out naming the files.
    func testACallThroughTheRosterWritesTheFilesItNames() async throws {
        let folder = try Fixture.folder()
        var call = Fixture.larder()
        call["directory"] = folder.path
        let answer = try await AnyAgentPackage(DesignAgent.self).perform(try JSONSerialization.data(withJSONObject: call),
                                                                         host: AgentHost(directory: folder.path, ask: "the recipe app's design"))
        let result = try JSONDecoder().decode(DesignResult.self, from: answer)
        XCTAssertEqual(result.paths.map { $0.replacingOccurrences(of: folder.path + "/", with: "") },
                       ["Shared/Design/Brand.swift", "Shared/Design/Brand.Color.swift", "Shared/Design/Style.swift",
                        "Shared/Design/Fonts/Fonts.swift", "Shared/Extensions/View+Style.swift"])
        XCTAssertEqual(result.path, result.paths.first)
        for path in result.paths { XCTAssertTrue(FileManager.default.fileExists(atPath: path), path) }
        XCTAssertEqual(result.colors, ["cream", "paper", "ink", "basil", "tomato", "saffron", "scrim"])
        XCTAssertEqual(result.roles.count, 12, "the eleven roles every design has and the app's highlight")
        XCTAssertTrue(result.roles.contains("secondaryForeground = ink 60%"), "\(result.roles)")
        XCTAssertTrue(result.roles.contains("tertiaryBackground = system"), "\(result.roles)")
        XCTAssertEqual(result.layers, [4, 8, 12, 16, 24, 32])
        XCTAssertEqual(result.radii, ["small", "medium", "card", "large", "chip"])
        XCTAssertEqual(Array(result.type.suffix(3)), ["brandDisplay", "brandCode", "brandQuote"])
        XCTAssertEqual(result.gradients, ["sunrise", "dusk", "glass"])
        XCTAssertEqual(result.faces, [])
        XCTAssertEqual(result.notes.count, 1, "the sizes the system draws its own way: \(result.notes)")
        XCTAssertLessThan(answer.count, 4_000, "the answer stays small: the model reads it")
    }

    func testACallWithNothingWritesADesignOfDefaults() throws {
        let folder = try Fixture.folder()
        let result = try DesignAgent.write(.init(directory: folder.path), note: { _ in }, yield: { _ in })
        XCTAssertEqual(result.paths.count, 4)
        XCTAssertEqual(result.layers, DesignSpec.loomLayers)
        XCTAssertTrue(result.roles.allSatisfy { $0.hasSuffix("= system") }, "\(result.roles)")
        XCTAssertEqual(result.type.count, 11)
        XCTAssertEqual(result.notes, [])
        let brand = try String(contentsOfFile: result.paths[0], encoding: .utf8)
        XCTAssertTrue(brand.contains("static let name = \"\(folder.lastPathComponent)\""), "the project's name when the call gives none")
        XCTAssertFalse(brand.contains("enum Colors"), "no palette, no empty namespace")
    }

    /// Every `{…}` in `text` that holds a key, outermost first.
    static func objects(in text: String) -> [String] {
        var found: [String] = [], depth = 0, start: String.Index?
        for index in text.indices {
            if text[index] == "{" {
                if depth == 0 { start = index }
                depth += 1
            } else if text[index] == "}", depth > 0 {
                depth -= 1
                if depth == 0, let begin = start { found.append(String(text[begin...index])) }
            }
        }
        return found.filter { $0.contains("\":") }
    }
}

/// A host that names its folder only in `AgentHost`, as one calling over the wire may.
final class HostFolderTests: XCTestCase {
    func testTheHostsFolderIsUsedWhenTheInputHasNone() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("design-host-\(UUID().uuidString.prefix(8))", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let input = try JSONSerialization.data(withJSONObject: ["palette": ["ink: #111111/#EEEEEE"], "roles": ["foreground = ink"]])
        let answer = try await AnyAgentPackage(DesignAgent.self).perform(input, host: AgentHost(directory: folder.path))
        let paths = try XCTUnwrap(try JSONSerialization.jsonObject(with: answer) as? [String: Any])["paths"] as? [String]
        XCTAssertFalse(paths?.isEmpty ?? true)
        for path in paths ?? [] { XCTAssertTrue(path.hasPrefix(folder.path + "/"), path) }
    }
}
