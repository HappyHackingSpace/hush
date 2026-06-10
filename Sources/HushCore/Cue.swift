import Foundation

/// A delivery cue written inline in a script as `[pause]`, `[breathe]`, etc. Cues are shown as
/// markers in the overlay and skipped by voice tracking (they are not spoken words).
public enum Cue: String, Sendable, CaseIterable {
    case pause
    case breathe
    case smile
    case slow
    case emphasis

    /// Parses a script word into a cue, tolerating trailing punctuation. Returns nil otherwise.
    public static func parse(_ text: String) -> Cue? {
        let trimmed = text.trimmingCharacters(in: CharacterSet(charactersIn: " \t,.;:!?"))
        guard trimmed.hasPrefix("["), trimmed.hasSuffix("]"), trimmed.count > 2 else { return nil }
        let inner = trimmed.dropFirst().dropLast().lowercased()
        return Cue(rawValue: inner)
    }

    public var label: String { rawValue.capitalized }
}
