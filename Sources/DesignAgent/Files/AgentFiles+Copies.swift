//  WHAT: Files a call copies rather than writes (the font files a call names), landing with the call's Swift: staged
//        beside it first, moved into place only once every Swift file has parsed and landed.
//  PIN:  WHOLE OR NOTHING, AS `write` IS. A copy that cannot be staged stops the call before anything lands; Swift that
//        does not parse throws out of `write`, and the staged copies go with the staging folder.

import Foundation

extension AgentFiles {
    /// Writes `files` as `write` does and copies `copies` (from → to) with them. Answers the absolute paths written:
    /// the files in the order given, then the copies.
    func write(_ files: [(url: URL, text: String)], copying copies: [(from: URL, to: URL)]) throws -> [String] {
        guard !copies.isEmpty else { return try write(files) }
        let manager = FileManager.default
        let stage = manager.temporaryDirectory.appendingPathComponent("agent-copies-\(UUID().uuidString.prefix(8))", isDirectory: true)
        defer { try? manager.removeItem(at: stage) }
        try manager.createDirectory(at: stage, withIntermediateDirectories: true)
        var staged: [(from: URL, to: URL)] = []
        for (index, copy) in copies.enumerated() {
            let place = stage.appendingPathComponent("\(index)-" + copy.to.lastPathComponent)
            do { try manager.copyItem(at: copy.from, to: place) } catch { throw AgentFilesError.unwritable(copy.to.path) }
            staged.append((place, copy.to))
        }
        var written = try write(files)
        for pair in staged {
            do {
                try manager.createDirectory(at: pair.to.deletingLastPathComponent(), withIntermediateDirectories: true)
                if manager.fileExists(atPath: pair.to.path) { try manager.removeItem(at: pair.to) }
                try manager.moveItem(at: pair.from, to: pair.to)
            } catch {
                throw AgentFilesError.unwritable(pair.to.path)
            }
            written.append(pair.to.path)
        }
        return written
    }
}
