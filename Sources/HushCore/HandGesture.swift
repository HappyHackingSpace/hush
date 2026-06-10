import Foundation

/// A recognized hand shape, derived purely from which fingers are extended. Keeping the
/// classification here makes it testable without Vision or a camera.
public enum HandGesture: Equatable, Sendable {
    case none
    case fist
    case index
    case two
    case palm
    case unknown

    /// Classifies a detected hand from its extended fingers. `none` is reserved for "no hand".
    public static func classify(index: Bool, middle: Bool, ring: Bool, little: Bool) -> HandGesture {
        let extended = [index, middle, ring, little].filter { $0 }.count
        if extended == 0 { return .fist }
        if index && !middle && !ring && !little { return .index }
        if index && middle && !ring && !little { return .two }
        if extended >= 4 { return .palm }
        return .unknown
    }
}
