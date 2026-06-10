import Foundation

/// Tracks where a speaker is in a script as words arrive from speech recognition.
///
/// Normal reading advances the head one word at a time. Small skips are absorbed by a forward
/// lookahead window. When the speaker goes off script (ad-libs, jumps, or restarts) the head
/// holds steady; once enough words in a row fail to match nearby, it re-anchors to the nearest
/// occurrence anywhere in the script.
public struct Aligner {
    private let matchable: [(tokenIndex: Int, word: String)]
    private let lookahead: Int
    private let recoveryThreshold: Int

    /// Index into `matchable` of the last matched word; -1 before the first match.
    private var head: Int = -1
    private var consecutiveMisses = 0

    public init(tokens: [Token], lookahead: Int = 6, recoveryThreshold: Int = 3) {
        self.matchable = tokens.filter(\.isMatchable).map { ($0.index, $0.normalized) }
        self.lookahead = max(1, lookahead)
        self.recoveryThreshold = max(1, recoveryThreshold)
    }

    /// The script token index currently being spoken, or nil before any match.
    public var currentTokenIndex: Int? {
        guard head >= 0, head < matchable.count else { return nil }
        return matchable[head].tokenIndex
    }

    /// Fraction of the script reached, in 0...1.
    public var progress: Double {
        guard !matchable.isEmpty else { return 0 }
        return Double(head + 1) / Double(matchable.count)
    }

    public mutating func feed(_ spokenWord: String) {
        let word = Tokenizer.normalize(spokenWord)
        guard !word.isEmpty else { return }

        let start = head + 1
        let end = min(matchable.count, start + lookahead)
        if let hit = (start..<end).first(where: { matchable[$0].word == word }) {
            head = hit
            consecutiveMisses = 0
            return
        }

        consecutiveMisses += 1
        guard consecutiveMisses >= recoveryThreshold, let anchor = nearestOccurrence(of: word) else { return }
        head = anchor
        consecutiveMisses = 0
    }

    public mutating func reset() {
        head = -1
        consecutiveMisses = 0
    }

    private func nearestOccurrence(of word: String) -> Int? {
        let reference = max(0, head)
        return matchable.indices
            .filter { matchable[$0].word == word }
            .min { abs($0 - reference) < abs($1 - reference) }
    }
}
