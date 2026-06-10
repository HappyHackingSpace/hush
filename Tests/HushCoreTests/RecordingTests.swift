import Foundation
@testable import HushCore
import Testing

struct RecordingTests {
    @Test func buildsSortableTimestampedName() {
        var components = DateComponents()
        components.year = 2026; components.month = 6; components.day = 10
        components.hour = 12; components.minute = 3; components.second = 5
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let date = calendar.date(from: components)!

        let name = Recording.fileName(at: date, timeZone: TimeZone(identifier: "UTC")!)
        #expect(name == "Hush-2026-06-10-120305.mov")
    }
}
