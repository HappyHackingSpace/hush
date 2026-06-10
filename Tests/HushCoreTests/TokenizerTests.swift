@testable import HushCore
import Testing

struct TokenizerTests {
    @Test func splitsOnWhitespaceAndNewlines() {
        let tokens = Tokenizer.tokenize("Hello world\nhow\tare you")
        #expect(tokens.map(\.text) == ["Hello", "world", "how", "are", "you"])
        #expect(tokens.map(\.index) == [0, 1, 2, 3, 4])
    }

    @Test func normalizesCaseAccentsAndPunctuation() {
        #expect(Tokenizer.normalize("Café,") == "cafe")
        #expect(Tokenizer.normalize("DON'T") == "dont")
        #expect(Tokenizer.normalize("résumé!") == "resume")
    }

    @Test func punctuationOnlyTokenIsNotMatchable() {
        let tokens = Tokenizer.tokenize("well ... done")
        #expect(tokens.count == 3)
        #expect(tokens[1].normalized.isEmpty)
        #expect(tokens[1].isMatchable == false)
        #expect(tokens[0].isMatchable)
    }

    @Test func collapsesRepeatedWhitespace() {
        let tokens = Tokenizer.tokenize("  spaced   out  ")
        #expect(tokens.map(\.text) == ["spaced", "out"])
    }
}
