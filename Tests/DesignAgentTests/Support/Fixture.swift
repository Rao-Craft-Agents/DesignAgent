import Foundation

enum Fixture {
    /// A folder of its own for one test, removed with the process's temporary files.
    static func folder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("design-\(UUID().uuidString.prefix(8))", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// A recipe app's brand: what the package is held to writing well.
    static let palette = [
        "cream: #FBF7F0/#1A1714", "paper: #FFFFFF/#24201C", "ink: #2B2522/#F3EEE8", "basil: #3F7D58/#6FBF8E",
        "tomato: #D2492A/#F06A4A", #"saffron "the spice jar": #E8A33D"#, "scrim: #00000066",
    ]
    static let roles = [
        "background = cream", "secondaryBackground = paper", "foreground = ink", "secondaryForeground = ink 60%",
        "accent = basil", "danger = tomato", #"highlight = saffron "a recipe someone starred""#,
    ]
    static let type = [
        "largeTitle: 34 bold serif", "title: 28 bold rounded", "headline: 17 semibold", "body: 17",
        "display: 44 heavy rounded", "code: 13 medium monospaced footnote", "quote: 17 italic serif body",
    ]
    static let gradients = ["sunrise: saffron tomato", "dusk: #2B2522 #6B4E71 vertical", "glass: #FFFFFF 60% #FFFFFF 0% horizontal"]
    static let radii = ["card: 14", #"chip: 6 "filters and tags""#]

    /// The whole recipe brand as one call.
    static func larder(into: String? = nil, fonts: [String]? = nil, modifiers: Bool = true) -> [String: Any] {
        var call: [String: Any] = ["name": "Larder", "palette": palette, "roles": roles, "type": type, "gradients": gradients,
                                   "radii": radii, "modifiers": modifiers]
        if let into { call["into"] = into }
        if let fonts { call["fonts"] = fonts }
        return call
    }

    // MARK: - An asset catalog

    /// Writes an asset catalog the way Loom keeps its colours: the sets in `namespace` (a folder that provides one,
    /// Loom's `colors`), and `top` sets outside it, each a light and a dark hex.
    @discardableResult
    static func catalog(in folder: URL, at path: String = "Shared/Assets.xcassets", namespace: String? = "colors",
                        sets: [String: (String, String)], top: [String: (String, String)] = [:]) throws -> URL {
        let catalog = folder.appendingPathComponent(path, isDirectory: true)
        try write(#"{ "info" : { "author" : "xcode", "version" : 1 } }"#, to: catalog.appendingPathComponent("Contents.json"))
        var inside = catalog
        if let namespace {
            inside = catalog.appendingPathComponent(namespace, isDirectory: true)
            try write(#"{ "info" : { "author" : "xcode", "version" : 1 }, "properties" : { "provides-namespace" : true } }"#,
                      to: inside.appendingPathComponent("Contents.json"))
        }
        for (name, pair) in sets { try colorSet(inside.appendingPathComponent("\(name).colorset"), light: pair.0, dark: pair.1) }
        for (name, pair) in top { try colorSet(catalog.appendingPathComponent("\(name).colorset"), light: pair.0, dark: pair.1) }
        return catalog
    }

    /// A colour set with a light and a dark sRGB colour, as Xcode writes one.
    static func colorSet(_ url: URL, light: String, dark: String) throws {
        func components(_ hex: String) -> String {
            let value = UInt32(hex.dropFirst(), radix: 16) ?? 0
            let parts = [("red", value >> 16 & 0xFF), ("green", value >> 8 & 0xFF), ("blue", value & 0xFF)]
            return parts.map { #""\#($0.0)" : "0x\#(String(format: "%02X", $0.1))""# }.joined(separator: ", ")
        }
        try write("""
            { "colors" : [
              { "color" : { "color-space" : "srgb", "components" : { "alpha" : "1.000", \(components(light)) } }, "idiom" : "universal" },
              { "appearances" : [ { "appearance" : "luminosity", "value" : "dark" } ],
                "color" : { "color-space" : "srgb", "components" : { "alpha" : "1.000", \(components(dark)) } }, "idiom" : "universal" } ],
              "info" : { "author" : "xcode", "version" : 1 } }
            """, to: url.appendingPathComponent("Contents.json"))
    }

    /// An Xcode project whose settings turn Swift asset symbol extensions on, as Xcode's own new projects do.
    static func projectGeneratingSymbols(in folder: URL, at path: String = "", name: String = "Larder") throws {
        try write("""
            // !$*UTF8*$!
            { objectVersion = 77; objects = { 0A1B2C3D4E5F60718293A4B5 = { isa = XCBuildConfiguration; buildSettings = {
            ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES; }; name = Debug; }; }; }
            """, to: folder.appendingPathComponent(path).appendingPathComponent("\(name).xcodeproj/project.pbxproj"))
    }

    // MARK: - Font files

    /// SF Mono as Terminal ships it: font files every Mac has, which no app has registered.
    static let terminalFonts = URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app/Contents/Resources/Fonts")

    /// Copies SF Mono's `faces` (Regular, Bold, RegularItalic…) into `path` under `folder`; nil when this Mac has none.
    static func monoFonts(into folder: URL, at path: String = "Resources/Fonts", faces: [String] = ["Regular", "Bold", "RegularItalic"]) throws -> [String]? {
        let sources = faces.map { terminalFonts.appendingPathComponent("SF-Mono-\($0).otf") }
        guard sources.allSatisfy({ FileManager.default.fileExists(atPath: $0.path) }) else { return nil }
        let target = folder.appendingPathComponent(path, isDirectory: true)
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
        for source in sources { try FileManager.default.copyItem(at: source, to: target.appendingPathComponent(source.lastPathComponent)) }
        return sources.map { "\(path)/\($0.lastPathComponent)" }
    }

    /// A serif every Mac has: Georgia, read for its faces (it is registered already, so it is never built with).
    static let georgia = URL(fileURLWithPath: "/System/Library/Fonts/Supplemental/Georgia.ttf")

    static func write(_ text: String, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(text.utf8).write(to: url)
    }
}
