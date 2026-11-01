//  WHAT: The project's files a design call reads, found by one walk of the host's folder: its asset catalogs, its
//        Xcode projects' settings and its Swift sources.
//  PIN:  ONLY THE APP'S OWN. Build products, dependencies, version control and hidden folders are not walked, and
//        neither is a nested Swift package: its catalogs go into its own bundle, where `Color("name")` does not look.

import Foundation

struct ProjectWalk: Sendable {
    /// Every `.xcassets` folder.
    var catalogs: [URL] = []
    /// Every Xcode project's `project.pbxproj`.
    var projects: [URL] = []
    /// Every `.swift` file.
    var sources: [URL] = []

    static let skipped: Set<String> = ["DerivedData", "Pods", "Carthage", "node_modules", "build"]

    init(root: URL, limit: Int = 50_000) {
        let manager = FileManager.default
        guard let walk = manager.enumerator(at: root, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else { return }
        var seen = 0
        for case let url as URL in walk {
            seen += 1
            if seen > limit { break }
            let name = url.lastPathComponent
            guard (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true else {
                if name.hasSuffix(".swift") { sources.append(url) }
                continue
            }
            if name.hasSuffix(".xcassets") {
                catalogs.append(url)
                walk.skipDescendants()
            } else if name.hasSuffix(".xcodeproj") {
                let settings = url.appendingPathComponent("project.pbxproj")
                if manager.fileExists(atPath: settings.path) { projects.append(settings) }
                walk.skipDescendants()
            } else if Self.skipped.contains(name) || name.hasSuffix(".xcworkspace") || name.hasSuffix(".app")
                        || manager.fileExists(atPath: url.appendingPathComponent("Package.swift").path) {
                walk.skipDescendants()
            }
        }
        catalogs.sort { $0.path < $1.path }
        projects.sort { $0.path < $1.path }
    }
}
