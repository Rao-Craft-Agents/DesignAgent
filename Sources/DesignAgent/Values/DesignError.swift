import Foundation

/// What a call can say instead of writing.
public enum DesignError: Error, Equatable, CustomStringConvertible {
    /// A line, a path or a value that cannot be honoured, and why.
    case line(String, String)
    /// Everything that cannot be honoured, each with its reason, so all are fixed in one call.
    case problems([String])

    public var description: String {
        switch self {
        case .line(let line, let reason): return "`\(line)`: \(reason)"
        case .problems(let reasons):
            let count = reasons.count == 1 ? "1 problem" : "\(reasons.count) problems"
            return "\(count), so nothing was written:\n" + reasons.map { "- \($0)" }.joined(separator: "\n")
        }
    }
}
