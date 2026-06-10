@testable import HushCore
import Testing

struct CueTests {
    @Test func parsesKnownCues() {
        #expect(Cue.parse("[pause]") == .pause)
        #expect(Cue.parse("[breathe]") == .breathe)
        #expect(Cue.parse("[SMILE]") == .smile)
    }

    @Test func toleratesTrailingPunctuation() {
        #expect(Cue.parse("[pause],") == .pause)
        #expect(Cue.parse("[slow].") == .slow)
    }

    @Test func rejectsNonCues() {
        #expect(Cue.parse("hello") == nil)
        #expect(Cue.parse("[unknown]") == nil)
        #expect(Cue.parse("[]") == nil)
    }
}
