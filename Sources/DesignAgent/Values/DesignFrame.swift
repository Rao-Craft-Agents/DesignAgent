import Foundation

/// What a run says as it goes.
public enum DesignFrame: Sendable {
    /// The lines and the project were read: how many palette colours, roles and font faces.
    case read(colors: Int, roles: Int, faces: Int)
    /// The files are written.
    case written(DesignResult)

    public var result: DesignResult? {
        if case .written(let result) = self { return result }
        return nil
    }
}
