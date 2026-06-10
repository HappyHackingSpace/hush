import Foundation

/// A single unit of a script: the text as written, plus a normalized form used for
/// matching spoken words against the script. `index` is the token's position in the script.
public struct Token: Equatable, Sendable {
    public let index: Int
    public let text: String
    public let normalized: String
    public let bold: Bool
    public let italic: Bool
    public let strikethrough: Bool
    public let code: Bool
    /// Markdown heading level (1-6), or 0 when the word is not a heading.
    public let headingLevel: Int

    public init(
        index: Int,
        text: String,
        normalized: String,
        bold: Bool = false,
        italic: Bool = false,
        strikethrough: Bool = false,
        code: Bool = false,
        headingLevel: Int = 0
    ) {
        self.index = index
        self.text = text
        self.normalized = normalized
        self.bold = bold
        self.italic = italic
        self.strikethrough = strikethrough
        self.code = code
        self.headingLevel = headingLevel
    }

    /// A token that carries no matchable content (pure punctuation or whitespace).
    public var isMatchable: Bool { !normalized.isEmpty }
}
