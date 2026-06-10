import Foundation

/// Splits script text into `Token`s and `ScriptLine`s, normalizing each word so spoken input can
/// be aligned regardless of case, accents, or punctuation, and parsing Markdown structure.
public enum Tokenizer {
    /// Whitespace-delimited words, each paired with a normalized key. Empty/punctuation-only
    /// words still yield a token (preserving display order) but are flagged non-matchable.
    public static func tokenize(_ text: String) -> [Token] {
        text.split(whereSeparator: { $0 == " " || $0 == "\n" || $0 == "\t" || $0 == "\r" })
            .enumerated()
            .map { Token(index: $0.offset, text: String($0.element), normalized: normalize(String($0.element))) }
    }

    /// Flat token list with Markdown emphasis applied, for alignment and counts.
    public static func tokenizeMarkdown(_ text: String) -> [Token] {
        parseLines(text).flatMap(\.tokens)
    }

    /// Parses Markdown into block-level lines with inline emphasis. Links, images, and other
    /// constructs are discarded for safety, leaving plain text that can never become clickable
    /// or fetch remote content.
    public static func parseLines(_ text: String) -> [ScriptLine] {
        let options = AttributedString.MarkdownParsingOptions(
            allowsExtendedAttributes: false,
            interpretedSyntax: .full,
            failurePolicy: .returnPartiallyParsedIfPossible
        )
        guard let attributed = try? AttributedString(markdown: text, options: options) else {
            let tokens = tokenize(text)
            return tokens.isEmpty ? [] : [ScriptLine(kind: .paragraph, indent: 0, tokens: tokens)]
        }

        var lines: [ScriptLine] = []
        var index = 0
        var buffer: [StyledChar] = []
        var key: Int?
        var kind: ScriptLine.Kind = .paragraph
        var indent = 0
        var started = false

        func flush() {
            defer { buffer.removeAll() }
            if case .thematicBreak = kind {
                lines.append(ScriptLine(kind: .thematicBreak, indent: indent, tokens: []))
                return
            }
            let tokens = buildTokens(buffer, kind: kind, from: index)
            index += tokens.count
            if !tokens.isEmpty { lines.append(ScriptLine(kind: kind, indent: indent, tokens: tokens)) }
        }

        for run in attributed.runs {
            let runKey = run.presentationIntent?.components.map(\.identity).reduce(0) { $0 &* 31 &+ $1 }
            if !started {
                started = true
                key = runKey
                (kind, indent) = blockInfo(run.presentationIntent)
            } else if runKey != key {
                flush()
                key = runKey
                (kind, indent) = blockInfo(run.presentationIntent)
            }
            let inline = Inline(run)
            for character in attributed.characters[run.range] {
                buffer.append(StyledChar(character: character, inline: inline))
            }
        }
        if started { flush() }
        return lines
    }

    private struct Inline {
        var bold = false
        var italic = false
        var strike = false
        var code = false

        init() {}

        init(_ run: AttributedString.Runs.Run) {
            let intent = run.inlinePresentationIntent ?? []
            bold = intent.contains(.stronglyEmphasized)
            italic = intent.contains(.emphasized)
            strike = intent.contains(.strikethrough)
            code = intent.contains(.code)
        }
    }

    private struct StyledChar {
        let character: Character
        let inline: Inline
    }

    private static func buildTokens(_ chars: [StyledChar], kind: ScriptLine.Kind, from start: Int) -> [Token] {
        let level = headingLevel(kind)
        let codeBlock = isCodeBlock(kind)
        var tokens: [Token] = []
        var word = ""
        var style = Inline()
        func emit() {
            guard !word.isEmpty else { return }
            tokens.append(Token(
                index: start + tokens.count, text: word, normalized: normalize(word),
                bold: style.bold, italic: style.italic,
                strikethrough: style.strike, code: style.code || codeBlock, headingLevel: level
            ))
            word = ""
        }
        for styled in chars {
            if styled.character.isWhitespace {
                emit()
            } else {
                if word.isEmpty { style = styled.inline }
                word.append(styled.character)
            }
        }
        emit()
        return tokens
    }

    private struct BlockFlags {
        var heading: Int?
        var quote = false
        var code = false
        var thematic = false
        var ordered = false
        var ordinal: Int?
        var indent = 0
    }

    private static func blockFlags(_ intent: PresentationIntent?) -> BlockFlags {
        var flags = BlockFlags()
        guard let intent else { return flags }
        for component in intent.components {
            switch component.kind {
            case .header(let level): flags.heading = level
            case .blockQuote: flags.quote = true; flags.indent += 1
            case .codeBlock: flags.code = true
            case .thematicBreak: flags.thematic = true
            case .orderedList: flags.ordered = true; flags.indent += 1
            case .unorderedList: flags.indent += 1
            case .listItem(let position): flags.ordinal = position
            default: break
            }
        }
        return flags
    }

    private static func blockInfo(_ intent: PresentationIntent?) -> (ScriptLine.Kind, Int) {
        let flags = blockFlags(intent)
        if flags.thematic { return (.thematicBreak, flags.indent) }
        if let heading = flags.heading { return (.heading(heading), flags.indent) }
        if let ordinal = flags.ordinal {
            return (.listItem(ordinal: flags.ordered ? ordinal : nil), max(flags.indent, 1))
        }
        if flags.quote { return (.blockQuote, max(flags.indent, 1)) }
        if flags.code { return (.code, flags.indent) }
        return (.paragraph, flags.indent)
    }

    private static func headingLevel(_ kind: ScriptLine.Kind) -> Int {
        if case .heading(let level) = kind { return level }
        return 0
    }

    private static func isCodeBlock(_ kind: ScriptLine.Kind) -> Bool {
        if case .code = kind { return true }
        return false
    }

    /// Lowercased, accent-folded, alphanumerics only. Empty when the word is pure punctuation.
    public static func normalize(_ word: String) -> String {
        word.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
            .unicodeScalars
            .filter { CharacterSet.alphanumerics.contains($0) }
            .reduce(into: "") { $0.unicodeScalars.append($1) }
    }
}
