@testable import HushCore
import Testing

struct ParseLinesTests {
    @Test func separatesHeadingsParagraphsAndLists() {
        let lines = Tokenizer.parseLines("# Title\n\nA short paragraph.\n\n- one\n- two")
        #expect(lines.count == 4)
        #expect(lines[0].kind == .heading(1))
        #expect(lines[1].kind == .paragraph)
        if case .listItem = lines[2].kind {} else { Issue.record("expected list item") }
        if case .listItem = lines[3].kind {} else { Issue.record("expected list item") }
    }

    @Test func detectsBlockQuoteCodeAndRule() {
        let quote = Tokenizer.parseLines("> a wise quote")
        #expect(quote.first?.kind == .blockQuote)

        let code = Tokenizer.parseLines("```\nlet x = 1\n```")
        #expect(code.first?.kind == .code)

        let rule = Tokenizer.parseLines("text\n\n---\n\nmore")
        #expect(rule.contains { $0.kind == .thematicBreak })
    }

    @Test func tokenIndicesAreSequentialAcrossLines() {
        let lines = Tokenizer.parseLines("# Title\n\nbody here")
        let indices = lines.flatMap { $0.tokens }.map(\.index)
        #expect(indices == Array(0..<indices.count))
    }
}
