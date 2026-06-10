@testable import HushCore
import Testing

struct ReadingTimeTests {
    @Test func estimatesAtAveragePace() {
        #expect(ReadingTime.seconds(words: 130) == 60)
        #expect(ReadingTime.seconds(words: 65) == 30)
    }

    @Test func zeroWordsIsZero() {
        #expect(ReadingTime.seconds(words: 0) == 0)
    }
}
