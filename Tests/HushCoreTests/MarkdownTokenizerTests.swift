@testable import HushCore
import Testing

struct MarkdownTokenizerTests {
    @Test func stripsSyntaxAndKeepsWords() {
        let tokens = Tokenizer.tokenizeMarkdown("This is **bold** and *italic* text")
        #expect(tokens.map(\.normalized) == ["this", "is", "bold", "and", "italic", "text"])
        #expect(tokens.allSatisfy { !$0.text.contains("*") })
    }

    @Test func flagsEmphasis() {
        let tokens = Tokenizer.tokenizeMarkdown("plain **strong** word")
        let strong = tokens.first { $0.normalized == "strong" }
        #expect(strong?.bold == true)
        #expect(tokens.first { $0.normalized == "plain" }?.bold == false)
    }

    @Test func dropsLinkSyntaxKeepingText() {
        let tokens = Tokenizer.tokenizeMarkdown("see [the docs](https://example.com) now")
        #expect(tokens.contains { $0.normalized == "docs" })
        #expect(tokens.allSatisfy { !$0.text.contains("http") })
    }

    @Test func flagsHeadingsStrikethroughAndCode() {
        let heading = Tokenizer.tokenizeMarkdown("# Big Title")
        #expect(heading.allSatisfy { $0.headingLevel == 1 })

        let struck = Tokenizer.tokenizeMarkdown("this is ~~gone~~")
        #expect(struck.first { $0.normalized == "gone" }?.strikethrough == true)

        let coded = Tokenizer.tokenizeMarkdown("run `swift test` now")
        #expect(coded.first { $0.normalized == "swift" }?.code == true)
    }
}
