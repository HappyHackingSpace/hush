@testable import HushCore
import Testing

struct ScrollMetricsTests {
    @Test func holdsAtZeroDuringStartDelay() {
        let offset = ScrollMetrics.offset(elapsed: 0.5, speed: 30, startDelay: 1, maxOffset: 1000)
        #expect(offset == 0)
    }

    @Test func advancesAtSpeedAfterDelay() {
        let offset = ScrollMetrics.offset(elapsed: 3, speed: 30, startDelay: 1, maxOffset: 1000)
        #expect(offset == 60)
    }

    @Test func clampsToMaxOffset() {
        let offset = ScrollMetrics.offset(elapsed: 100, speed: 30, startDelay: 1, maxOffset: 200)
        #expect(offset == 200)
    }

    @Test func neverNegativeWhenContentFitsViewport() {
        let offset = ScrollMetrics.offset(elapsed: 100, speed: 30, startDelay: 1, maxOffset: -50)
        #expect(offset == 0)
    }
}
