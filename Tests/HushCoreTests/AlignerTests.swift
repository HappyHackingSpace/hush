@testable import HushCore
import Testing

struct AlignerTests {
    private func aligner(_ body: String, lookahead: Int = 6, recovery: Int = 3) -> Aligner {
        Aligner(tokens: Tokenizer.tokenize(body), lookahead: lookahead, recoveryThreshold: recovery)
    }

    @Test func startsUnmatched() {
        let aligner = aligner("one two three")
        #expect(aligner.currentTokenIndex == nil)
        #expect(aligner.progress == 0)
    }

    @Test func advancesWordByWord() {
        var aligner = aligner("the quick brown fox")
        aligner.feed("the")
        #expect(aligner.currentTokenIndex == 0)
        aligner.feed("quick")
        #expect(aligner.currentTokenIndex == 1)
        aligner.feed("brown")
        #expect(aligner.currentTokenIndex == 2)
    }

    @Test func matchesIgnoringCaseAndPunctuation() {
        var aligner = aligner("Hello, world!")
        aligner.feed("HELLO")
        #expect(aligner.currentTokenIndex == 0)
        aligner.feed("world")
        #expect(aligner.currentTokenIndex == 1)
    }

    @Test func absorbsSmallSkipWithinLookahead() {
        var aligner = aligner("alpha beta gamma delta")
        aligner.feed("gamma")
        #expect(aligner.currentTokenIndex == 2)
    }

    @Test func ignoresAdLibbedWordsNotInScript() {
        var aligner = aligner("alpha beta gamma")
        aligner.feed("alpha")
        aligner.feed("basically")
        aligner.feed("um")
        #expect(aligner.currentTokenIndex == 0)
    }

    @Test func recoversByJumpingForwardAfterThreshold() {
        var aligner = aligner("a b c d e f g h i j", lookahead: 3, recovery: 2)
        aligner.feed("h")
        #expect(aligner.currentTokenIndex == nil)
        aligner.feed("h")
        #expect(aligner.currentTokenIndex == 7)
    }

    @Test func recoversByJumpingBackToNearestOccurrence() {
        var aligner = aligner("intro alpha beta gamma alpha omega", lookahead: 2, recovery: 1)
        aligner.feed("gamma")
        #expect(aligner.currentTokenIndex == 3)
        aligner.feed("intro")
        #expect(aligner.currentTokenIndex == 0)
    }

    @Test func progressReachesOneAtEnd() {
        var aligner = aligner("one two three")
        aligner.feed("one")
        aligner.feed("two")
        aligner.feed("three")
        #expect(aligner.progress == 1)
    }

    @Test func resetClearsPosition() {
        var aligner = aligner("one two three")
        aligner.feed("one")
        aligner.reset()
        #expect(aligner.currentTokenIndex == nil)
        #expect(aligner.progress == 0)
    }
}
