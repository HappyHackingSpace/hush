import Foundation

/// A spoken control command. Recognized only when prefixed with the wake word "hush" so the
/// same word read from a script does not trigger it.
public enum VoiceCommand: Equatable, Sendable {
    case pause
    case resume
    case next
    case back
    case top

    /// Detects a trailing "hush <command>" in the recent spoken words.
    public static func detect(in words: [String]) -> VoiceCommand? {
        let normalized = words.map(Tokenizer.normalize).filter { !$0.isEmpty }
        guard normalized.count >= 2, normalized[normalized.count - 2] == "hush" else { return nil }
        switch normalized[normalized.count - 1] {
        case "pause", "stop", "wait": return .pause
        case "resume", "start", "play", "go": return .resume
        case "next", "forward", "down": return .next
        case "back", "up", "previous": return .back
        case "top", "restart", "beginning": return .top
        default: return nil
        }
    }
}
