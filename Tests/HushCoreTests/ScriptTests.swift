import Foundation
@testable import HushCore
import Testing

struct ScriptTests {
    @Test func tokenizesBody() {
        let script = Script(title: "Demo", body: "Eyes on the lens.")
        #expect(script.tokens.map(\.normalized) == ["eyes", "on", "the", "lens"])
    }

    @Test func roundTripsThroughCodable() throws {
        let original = Script(title: "Pitch", body: "Hello there.")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Script.self, from: data)
        #expect(decoded == original)
    }
}
