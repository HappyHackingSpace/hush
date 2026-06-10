@testable import HushCore
import Testing

struct VoiceCommandTests {
    @Test func detectsWakeWordCommands() {
        #expect(VoiceCommand.detect(in: ["hush", "pause"]) == .pause)
        #expect(VoiceCommand.detect(in: ["so", "then", "hush", "next"]) == .next)
        #expect(VoiceCommand.detect(in: ["Hush", "Top!"]) == .top)
    }

    @Test func requiresWakeWord() {
        #expect(VoiceCommand.detect(in: ["pause"]) == nil)
        #expect(VoiceCommand.detect(in: ["just", "pause"]) == nil)
    }

    @Test func unknownCommandIsNil() {
        #expect(VoiceCommand.detect(in: ["hush", "banana"]) == nil)
    }
}
