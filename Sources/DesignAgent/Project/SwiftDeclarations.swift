//  WHAT: Declarations elsewhere in the project that the design files would make twice: a second `Brand`, another
//        `.layer4`, an older `Color.background`, another `Font.brand`. Said as notes, so a build that fails on two of
//        them is understood at once; the files this call writes are not counted, since it replaces them.

import Foundation

enum SwiftDeclarations {
    /// One note a file that declares what the design does, at most four.
    static func clashes(in sources: [URL], replacing written: [URL], design: Design, files: AgentFiles) -> [String] {
        let replaced = Set(written.map { $0.resolvingSymlinksInPath().path })
        let roles = design.roles.filter { if case .generated = $0.source { return false } else { return true } }.map(\.name)
        var checks: [(pattern: String, what: String)] = [
            (#"(?m)^\s*(public\s+|internal\s+|fileprivate\s+|private\s+)?(final\s+)?(struct|enum|class|actor|typealias)\s+Brand\b"#, "`Brand`"),
            (#"static\s+(var|let)\s+layer[0-9]+\b"#, "the `.layer` spacing"),
            (#"(?m)^\s*(public\s+|internal\s+)?(struct|enum|class)\s+Fonts\b"#, "`Fonts`"),
            (#"static\s+func\s+brand\s*\("#, "`Font.brand`"),
        ]
        if design.modifiers { checks.append((#"func\s+(cardStyle|sectionStyle|brandBackground)\s*\("#, "the style modifiers")) }
        if !roles.isEmpty { checks.append((#"static\s+(var|let)\s+("# + roles.joined(separator: "|") + #")\s*:\s*(SwiftUI\.)?Color\b"#, "a colour role")) }
        var notes: [String] = []
        for source in sources where !replaced.contains(source.resolvingSymlinksInPath().path) {
            guard notes.count < 4, let text = try? String(contentsOf: source, encoding: .utf8) else { continue }
            let found = checks.filter { text.range(of: $0.pattern, options: .regularExpression) != nil }.map(\.what)
            guard !found.isEmpty else { continue }
            notes.append("\(files.relative(source)) also declares \(found.joined(separator: " and ")), so the build will find two: keep one")
        }
        return notes
    }
}
