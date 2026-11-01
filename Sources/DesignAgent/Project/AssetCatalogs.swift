//  WHAT: The colour sets of the project's asset catalogs, and whether Xcode writes `Color` members for them. A role
//        reads the colour set of its name when there is one; a palette line names one by its name.
//  PIN:  NAMESPACES ARE PART OF THE NAME. A folder whose Contents.json provides a namespace (Loom's `colors`) puts its
//        name before its sets': `Color("colors/background")`. Without it the colour does not load.
//  PIN:  WHAT XCODE ALREADY DECLARES, NOT DECLARED AGAIN. With ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS
//        on (Xcode's own new projects turn it on), every colour set outside a namespace becomes a `Color` member
//        (`AccentColor` → `Color.accent`), and a second `Color.accent` does not build.

import Foundation

struct AssetCatalogs: Sendable {
    /// Every colour set, outside namespaces first, then by name.
    var sets: [ColorSet]
    /// Whether an Xcode project of the folder turns on Swift asset symbol extensions.
    var symbolExtensions: Bool

    init(sets: [ColorSet], symbolExtensions: Bool) {
        self.sets = sets.sorted { ($0.namespaced ? 1 : 0, $0.name) < ($1.namespaced ? 1 : 0, $1.name) }
        self.symbolExtensions = symbolExtensions
    }

    init(walk: ProjectWalk) {
        let sets = walk.catalogs.flatMap { Self.colorSets(in: $0) }
        let on = walk.projects.contains { settings in
            ((try? String(contentsOf: settings, encoding: .utf8)) ?? "").contains("ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES")
        }
        self.init(sets: sets, symbolExtensions: on)
    }

    /// The set a line names: by its full name, its own name, or Xcode's symbol for it (`brandInk`, `BrandInk`,
    /// `colors/ink`, `brand-ink`).
    func find(_ text: String) -> ColorSet? {
        if let exact = sets.first(where: { $0.name == text }) { return exact }
        if let folded = sets.first(where: { $0.name.lowercased() == text.lowercased() }) { return folded }
        let tail = text.split(separator: "/").last.map(String.init) ?? text
        if let base = sets.first(where: { $0.base == tail }) { return base }
        let symbol = SymbolName.of(tail)
        return sets.first { $0.symbol == symbol || $0.symbol.lowercased() == symbol.lowercased() }
    }

    /// The set a role of this name reads when no line says: the one Xcode would name the same.
    func set(forRole role: String) -> ColorSet? {
        sets.first { $0.symbol == role }
    }

    /// The `Color` member Xcode writes for a set outside a namespace, when it writes them.
    func generated(_ member: String) -> ColorSet? {
        guard symbolExtensions else { return nil }
        return sets.first { !$0.namespaced && $0.symbol == member }
    }

    /// A few set names, to say what a catalog holds when a line names one it does not.
    var sample: String {
        let names = sets.prefix(6).map(\.name)
        guard !names.isEmpty else { return "the project has no colour sets" }
        return "it has " + names.joined(separator: ", ") + (sets.count > names.count ? ", …" : "")
    }

    /// The colour sets of one catalog, each named as code names it.
    static func colorSets(in catalog: URL) -> [ColorSet] {
        var found: [ColorSet] = []
        func walk(_ folder: URL, namespace: [String]) {
            guard let names = try? FileManager.default.contentsOfDirectory(atPath: folder.path) else { return }
            for name in names.sorted() where !name.hasPrefix(".") {
                let url = folder.appendingPathComponent(name)
                var isFolder: ObjCBool = false
                guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isFolder), isFolder.boolValue else { continue }
                if name.hasSuffix(".colorset") {
                    let base = String(name.dropLast(".colorset".count))
                    found.append(ColorSet(name: (namespace + [base]).joined(separator: "/"), base: base, namespaced: !namespace.isEmpty))
                } else if !name.contains(".") {
                    walk(url, namespace: providesNamespace(url) ? namespace + [name] : namespace)
                }
            }
        }
        walk(catalog, namespace: [])
        return found
    }

    /// Whether a catalog folder's Contents.json provides a namespace.
    static func providesNamespace(_ folder: URL) -> Bool {
        guard let data = try? Data(contentsOf: folder.appendingPathComponent("Contents.json")),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let properties = json["properties"] as? [String: Any] else { return false }
        return (properties["provides-namespace"] as? Bool) == true
    }
}
