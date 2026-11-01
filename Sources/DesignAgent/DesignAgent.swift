//  WHAT: An app's design system, as a Granite agent package. A call gives the brand's colours, the colour roles views
//        read, gradients, spacing layers, radii, a type scale and font files, each as compact lines (or nothing, for
//        Loom's defaults); the run writes Brand.swift, Brand.Color.swift, Style.swift and Fonts/Fonts.swift into the
//        folder the call names, copies the font files beside them, adds View+Style.swift when asked, and answers where.
//  IN:   Input: the folder, the brand's name, the palette, the roles, the spacing, the radii, the type scale, the font
//        files, the gradients, whether to write the style modifiers.
//  OUT:  DesignResult: the files written and the names views write to use them.
//  PIN:  NO MODEL. Every file is made from the lines and what the project holds (its asset catalogs, its font files),
//        the same way every time; a line that cannot be honoured is refused with its reason, every reason at once,
//        and the call writes nothing until every line is understood and every file parses.

import Foundation
import GraniteAgents

/// The `design` agent: an app's design system written as Swift from compact lines.
public struct DesignAgent: GraniteAgentPackage {
    /// What a call gives: every field may be left out.
    public struct Input: Codable, Sendable {
        /// The folder the design files go in, relative to the project; `Shared/Design` when left out.
        public var into: String?
        /// The brand's name, as people see it; the project's when left out.
        public var name: String?
        /// One line a colour of the brand: `cream: #FBF7F0/#1A1714` (light/dark), `saffron: #E8A33D`, or a colour set
        /// of the project's asset catalogs, `ink: brandInk`.
        public var palette: [String]?
        /// One line a colour role: `background = cream`, `secondaryForeground = ink 60%`, `accent = #3F7D58/#6FBF8E`.
        public var roles: [String]?
        /// The spacing layers in points, smallest first: `.layer1` on. Loom's 4, 8, 12, 16, 24, 32 when left out.
        public var spacing: [Int]?
        /// One line a corner radius: `card: 14`.
        public var radii: [String]?
        /// One line a style of the type scale: `title: 28 bold rounded`.
        public var type: [String]?
        /// Font files to ship with the app, or folders of them, relative to the project.
        public var fonts: [String]?
        /// One line a gradient: `sunrise: saffron tomato`, `dusk: #2B2522 #6B4E71 vertical`.
        public var gradients: [String]?
        /// Whether to write `.cardStyle()`, `.sectionStyle()` and `.brandBackground()`; false when left out.
        public var modifiers: Bool?
        /// The host's folder.
        public var directory: String?

        public init(into: String? = nil, name: String? = nil, palette: [String]? = nil, roles: [String]? = nil,
                    spacing: [Int]? = nil, radii: [String]? = nil, type: [String]? = nil, fonts: [String]? = nil,
                    gradients: [String]? = nil, modifiers: Bool? = nil, directory: String? = nil) {
            self.into = into; self.name = name; self.palette = palette; self.roles = roles; self.spacing = spacing
            self.radii = radii; self.type = type; self.fonts = fonts; self.gradients = gradients; self.modifiers = modifiers
            self.directory = directory
        }
    }

    public typealias Event = DesignFrame
    public typealias Output = DesignResult
    public typealias Compute = Void

    public static let word = "design"
    public static let summary = "writes an app's design system as Swift — brand colours, the colour roles views read, gradients, spacing layers, radii, a type scale and fonts — from compact lines, in light and dark and with Dynamic Type."
    public static let fields = [
        "into": "the folder for the design files, relative to the project; Shared/Design when left out",
        "name": "the brand's name, as people see it; the project's when left out",
        "palette": "one line a brand colour: `cream: #FBF7F0/#1A1714` (light/dark), `saffron: #E8A33D`, or a colour set of the project's asset catalogs, `ink: brandInk`; read as `Brand.Colors.cream`",
        "roles": "one line a colour role views read: `background = cream`, `secondaryForeground = ink 60%`, `accent = #3F7D58/#6FBF8E`, or a role of the app's own, `highlight = saffron`; a role named alone reads the colour set of its name; read as `Color.background`",
        "spacing": "the spacing layers in points, smallest first, read as `.layer1` on; Loom's [4, 8, 12, 16, 24, 32] when left out",
        "radii": "one line a corner radius: `card: 14`; read as `Brand.Radius.card`; small 4, medium 8, card 12 and large 16 unless a line changes them",
        "type": "one line a type style: `title: 28 bold rounded`, `body: 17`, `code: 13 medium monospaced footnote`; read as `.font(.brandTitle)`; Apple's scale unless a line changes it",
        "fonts": "font files (.ttf, .otf, .ttc), or folders of them, relative to the project; copied into the design's Fonts folder and drawn by `Font.brand`",
        "gradients": "one line a gradient: `sunrise: saffron tomato`, `dusk: #2B2522 #6B4E71 vertical`; read as `Brand.Gradients.sunrise`",
        "modifiers": "true to also write `.cardStyle()`, `.sectionStyle()` and `.brandBackground()` in Shared/Extensions/View+Style.swift",
    ]
    public static let guide = """
        Tag design for the app's design system, written as Swift into Shared/Design: the brand's colours by name \
        (`Brand.Colors.cream`), the colour roles views read (`Color.background`, `Color.secondaryBackground`, \
        `Color.foreground`, `Color.secondaryForeground`, `Color.accent`, `Color.separator`, `Color.success`, \
        `Color.warning`, `Color.danger`), gradients (`Brand.Gradients.sunrise`), spacing (`.padding(.layer4)`), radii, \
        strokes, shadows and durations (`Brand.Radius.card`, `Brand.Stroke.hairline`, `.shadow(Brand.Shadow.card)`, \
        `Brand.Motion.quick`), window sizes (`Brand.Metrics.sidebarWidth`), and a type scale (`.font(.brandTitle)`). \
        Every field may be left out: Loom's layers, four radii, Apple's type scale and the platform's colours fill in. \
        `palette` is one line a colour: `cream: #FBF7F0/#1A1714` is light/dark, `saffron: #E8A33D` is both, and \
        `ink: brandInk` reads a colour set of the project's asset catalog. `roles` says what a role reads: \
        `background = cream`, `secondaryForeground = ink 60%`, `accent = #3F7D58/#6FBF8E`, or a role of the app's own, \
        `highlight = saffron`, or a role named alone, `alternateSecondaryBackground`, read from the colour set of its \
        name; a role left out reads the asset catalog's colour set of its name, then the palette colour of its name, \
        then the platform's. `type` is one line a style, its words in any order: a size, a weight \
        (regular, medium, semibold, bold…), a design (serif, rounded, monospaced), `italic`, and the text style it \
        scales with under Dynamic Type: `title: 28 bold rounded`, `code: 13 medium monospaced footnote`. `radii` is \
        `card: 14`; `spacing` the layers in points, smallest first; `gradients` is `sunrise: saffron tomato` with \
        `vertical` or `horizontal` to turn it. `fonts` names font files or a folder of them, copied into \
        Shared/Design/Fonts and drawn by `Font.brand(.bold, size: 28, relativeTo: .title)`; a `serif` or `monospaced` \
        style draws in a family of that kind among the files. `modifiers: true` adds `.cardStyle()`, `.sectionStyle()` \
        and `.brandBackground()`. A line it cannot read is refused with the reason and nothing is written. Hex colours: \
        {"name": "Larder", "palette": ["cream: #FBF7F0/#1A1714", "paper: #FFFFFF/#24201C", "ink: #2B2522/#F3EEE8", \
        "basil: #3F7D58/#6FBF8E", "tomato: #D2492A/#F06A4A"], "roles": ["background = cream", \
        "secondaryBackground = paper", "foreground = ink", "secondaryForeground = ink 60%", "accent = basil", \
        "danger = tomato"], "radii": ["card: 14"], "type": ["largeTitle: 34 bold serif", "headline: 17 semibold"], \
        "gradients": ["sunrise: basil tomato"], "modifiers": true}. Colours kept in the asset catalog: \
        {"palette": ["herb: herbGreen"], "type": ["title: 28 bold rounded"]}, and each role reads the colour set of \
        its name. Its own fonts: {"fonts": ["Resources/Fonts"], "type": ["title: 28 bold", "body: 17", \
        "code: 13 monospaced footnote"]}. Not for app icons and images, and not for views.
        """

    public static func output(from events: [DesignFrame]) -> DesignResult? { events.compactMap(\.result).last }

    public init() {}

    public func run(_ input: Input, context: Context) -> AsyncThrowingStream<DesignFrame, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    // The folder is the input's, else the host's: a host calling over the wire may say it only there.
                    var input = input
                    if input.directory == nil { input.directory = context.host.directory }
                    let result = try Self.write(input, note: context.host.note) { continuation.yield($0) }
                    continuation.yield(.written(result))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// The whole call: the lines read, the project read, the files made, staged, checked and written.
    static func write(_ input: Input, note: @Sendable (String) -> Void, yield: (DesignFrame) -> Void) throws -> DesignResult {
        let (spec, problems) = DesignSpec.read(input)
        let files = AgentFiles(directory: input.directory)
        let (folder, layoutNote) = files.ownFolder(files.resolve(input.into ?? "Shared/Design"), own: "Design")
        let walk = ProjectWalk(root: files.root)
        let resolution = DesignResolver.resolve(spec, files: files, folder: folder, walk: walk)
        guard problems.isEmpty, resolution.problems.isEmpty, let design = resolution.design else {
            throw DesignError.problems(problems + resolution.problems)
        }
        let faces = design.families.flatMap(\.faces)
        yield(.read(colors: design.colors.count, roles: design.roles.count, faces: faces.count))
        note("writing \(design.name)'s design into \(files.relative(folder)): \(design.colors.count) colours, \(design.roles.count) roles, \(design.typeScale.count) type styles")

        var planned: [(url: URL, text: String)] = [
            (folder.appendingPathComponent("Brand.swift"), BrandFile.text(design)),
            (folder.appendingPathComponent("Brand.Color.swift"), ColorRolesFile.text(design)),
            (folder.appendingPathComponent("Style.swift"), StyleFile.text(design)),
            (folder.appendingPathComponent("Fonts/Fonts.swift"), FontsFile.text(design)),
        ]
        if design.modifiers {
            let extensions = folder.deletingLastPathComponent().appendingPathComponent("Extensions", isDirectory: true)
            planned.append((extensions.appendingPathComponent("View+Style.swift"), ModifiersFile.text(design)))
        }
        let clashes = SwiftDeclarations.clashes(in: walk.sources, replacing: planned.map(\.url), design: design, files: files)
        let written = try files.write(planned, copying: resolution.copies)
        note("wrote \(written.count) file\(written.count == 1 ? "" : "s")")
        return DesignResult(path: written.first, paths: written, colors: design.colors.map(\.name), roles: design.roles.map(\.summary),
                            layers: design.layers, radii: design.radii.map(\.name), type: design.typeScale.map(\.member),
                            gradients: design.gradients.map(\.name), faces: faces.map(\.postScript),
                            notes: [layoutNote].compactMap { $0 } + resolution.notes + clashes)
    }
}
