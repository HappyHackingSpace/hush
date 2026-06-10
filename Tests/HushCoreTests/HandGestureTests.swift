@testable import HushCore
import Testing

struct HandGestureTests {
    @Test func noFingersIsFist() {
        #expect(HandGesture.classify(index: false, middle: false, ring: false, little: false) == .fist)
    }

    @Test func indexOnlyIsIndex() {
        #expect(HandGesture.classify(index: true, middle: false, ring: false, little: false) == .index)
    }

    @Test func indexAndMiddleIsTwo() {
        #expect(HandGesture.classify(index: true, middle: true, ring: false, little: false) == .two)
    }

    @Test func allFingersIsPalm() {
        #expect(HandGesture.classify(index: true, middle: true, ring: true, little: true) == .palm)
    }

    @Test func ambiguousShapeIsUnknown() {
        #expect(HandGesture.classify(index: true, middle: false, ring: true, little: false) == .unknown)
    }
}
