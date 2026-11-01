//  WHAT: A call's lines joined to what the project holds: each colour name found in the palette or the asset
//        catalogs, each role given what it reads, each font file read for its faces and planned as a copy into the
//        design's Fonts folder. What cannot be found is a problem with its reason; what the call should know is a note.
//  PIN:  A ROLE READS, IN ORDER: what its line says, the colour set of its name, the palette colour of its name, the
//        system's. A project that keeps its colours in an asset catalog (Loom's `colors/background`) needs no lines.

import Foundation

enum DesignResolver {
    struct Resolution {
        var design: Design?
        var copies: [(from: URL, to: URL)] = []
        var notes: [String] = []
        var problems: [String] = []
    }

    static func resolve(_ spec: DesignSpec, files: AgentFiles, folder: URL, walk: ProjectWalk) -> Resolution {
        var resolution = Resolution()
        let catalogs = AssetCatalogs(walk: walk)
        let paletteNames = spec.palette.map(\.name)
        var design = Design(name: spec.name ?? projectName(root: files.root, projects: walk.projects))
        design.layers = spec.layers
        design.radii = spec.radii
        design.typeScale = spec.typeScale
        design.modifiers = spec.modifiers

        for color in spec.palette {
            let resolved: ResolvedColor.Source
            switch color.color.value {
            case .fixed(let hex): resolved = .fixed(hex)
            case .adaptive(let light, let dark): resolved = .adaptive(light: light, dark: dark)
            case .named(let text):
                guard let set = catalogs.find(text) else {
                    resolution.problems.append("the colour \(color.name) names \(text), and no colour set of the project's asset catalogs is named so (\(catalogs.sample)); a palette colour is a hex, #light/#dark, or a colour set")
                    continue
                }
                resolved = .asset(set.name)
            }
            design.colors.append(.init(name: color.name, color: ResolvedColor(source: resolved, opacity: color.color.opacity), doc: color.doc))
        }

        /// A colour a role or a gradient names: a palette colour first, then a colour set.
        func find(_ expression: ColorExpression, for what: String) -> ResolvedColor? {
            switch expression.value {
            case .fixed(let hex): return ResolvedColor(source: .fixed(hex), opacity: expression.opacity)
            case .adaptive(let light, let dark): return ResolvedColor(source: .adaptive(light: light, dark: dark), opacity: expression.opacity)
            case .named(let text):
                if let member = DesignLine.member(text), paletteNames.contains(member) {
                    return ResolvedColor(source: .palette(member), opacity: expression.opacity)
                }
                if let set = catalogs.find(text) { return ResolvedColor(source: .asset(set.name), opacity: expression.opacity) }
                let palette = paletteNames.isEmpty ? "the call gives no palette" : "the palette has " + paletteNames.joined(separator: ", ")
                resolution.problems.append("\(what) names \(text), which is neither a palette colour (\(palette)) nor a colour set of the project's asset catalogs (\(catalogs.sample))")
                return nil
            }
        }

        let lines = Dictionary(spec.roles.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })
        let defaults = ColorRole.defaults.map(\.name)
        for name in defaults + spec.roles.map(\.name).filter({ !defaults.contains($0) }) {
            let use = lines[name]?.doc.map(sentence) ?? ColorRole.defaults.first { $0.name == name }?.use ?? "\(sentence(SwiftName.words(name)))"
            let source: ColorRole.Source
            if let line = lines[name] {
                guard let color = find(line.color, for: "the \(name) role") else { continue }
                if let set = catalogs.generated(name) {
                    guard color == ResolvedColor(source: .asset(set.name), opacity: nil) else {
                        resolution.problems.append("the \(name) role: Xcode already writes `Color.\(name)` from the colour set \(set.name), as Swift asset symbol extensions are on, so it cannot be declared again; leave the line out to read that set, rename the set, or turn ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS off")
                        continue
                    }
                    source = .generated(set.name)
                } else {
                    source = .color(color)
                }
            } else if let set = catalogs.set(forRole: name) {
                source = catalogs.generated(name) == set ? .generated(set.name) : .color(ResolvedColor(source: .asset(set.name), opacity: nil))
            } else if paletteNames.contains(name) {
                source = .color(ResolvedColor(source: .palette(name), opacity: nil))
            } else {
                source = .system
            }
            design.roles.append(ColorRole(name: name, use: use, source: source))
        }

        for gradient in spec.gradients {
            let stops = gradient.stops.compactMap { find($0, for: "the gradient \(gradient.name)") }
            guard stops.count == gradient.stops.count else { continue }
            design.gradients.append(.init(name: gradient.name, stops: stops, direction: gradient.direction, doc: gradient.doc))
        }

        var faces: [FontFace] = []
        var named: [String: URL] = [:]
        let fontsFolder = folder.appendingPathComponent("Fonts", isDirectory: true)
        for path in spec.fonts {
            let found = FontFiles.files(at: files.resolve(path))
            guard !found.isEmpty else {
                resolution.problems.append("`fonts` names \(path), which is not a font file or a folder of them (.ttf, .otf or .ttc)")
                continue
            }
            for file in found {
                let fileName = file.lastPathComponent
                guard FontFiles.kinds.contains(file.pathExtension.lowercased()) else {
                    resolution.problems.append("`fonts` names \(files.relative(file)), which is not a .ttf, .otf or .ttc file")
                    continue
                }
                if let earlier = named[fileName] {
                    if earlier.path != file.path { resolution.problems.append("`fonts` names two files called \(fileName), and the app's bundle holds one") }
                    continue
                }
                named[fileName] = file
                let read = FontFiles.faces(in: file)
                guard !read.isEmpty else {
                    resolution.problems.append("`fonts` names \(files.relative(file)), and CoreText reads no font in it")
                    continue
                }
                faces += read
                design.fontFiles.append(fileName)
                let destination = fontsFolder.appendingPathComponent(fileName)
                if AgentFiles.resolvingParents(file.path) != AgentFiles.resolvingParents(destination.path) {
                    resolution.copies.append((file, destination))
                }
            }
        }
        var seen: Set<String> = []
        for face in faces where !seen.insert(face.postScript).inserted {
            resolution.problems.append("`fonts` holds the face \(face.postScript) twice; keep one of its files")
        }
        design.families = FontFamily.grouped(faces)

        resolution.notes = notes(design)
        resolution.design = resolution.problems.isEmpty ? design : nil
        return resolution
    }

    /// What the call should know about the design it got.
    static func notes(_ design: Design) -> [String] {
        var notes: [String] = []
        if design.families.isEmpty {
            let drawn = design.typeScale.filter { abs($0.size - $0.style.size) >= 0.5 }
            if !drawn.isEmpty {
                let list = drawn.map { "\($0.name) (\(SwiftNumber.text($0.size)) pt) at \($0.style.rawValue)'s \(SwiftNumber.text($0.style.size)) pt" }
                notes.append("With no font files, the system draws each style at its text style's size so it follows Dynamic Type: " + list.joined(separator: ", ") + " on iPhone; give `fonts` to draw exact sizes")
            }
        } else {
            let unserved = design.typeScale.filter { $0.design != .default && design.family(for: $0.design) == nil }
            if !unserved.isEmpty {
                let list = unserved.map { "\($0.name) (\($0.design.rawValue))" }
                notes.append("The font files have no face for " + list.joined(separator: ", ") + ", so the system's face draws them")
            }
        }
        let generated = design.roles.compactMap { role -> String? in
            if case .generated(let set) = role.source { return "Color.\(role.name) (from \(set))" }
            return nil
        }
        if !generated.isEmpty {
            notes.append("Xcode writes " + generated.joined(separator: ", ") + " itself, as the project turns on Swift asset symbol extensions, so Brand.Color.swift leaves them to it")
        }
        return notes
    }

    /// The brand's name when the call gives none: the Xcode project at the top of the folder, or the folder's own name.
    static func projectName(root: URL, projects: [URL]) -> String {
        let top = projects.map { $0.deletingLastPathComponent() }.first { $0.deletingLastPathComponent().lastPathComponent == root.lastPathComponent }
        return (top ?? root).deletingPathExtension().lastPathComponent
    }

    /// `the dish's name` → `The dish's name.`
    static func sentence(_ text: String) -> String {
        guard let first = text.first else { return text }
        let capped = first.uppercased() + text.dropFirst()
        return capped.hasSuffix(".") ? capped : capped + "."
    }
}
