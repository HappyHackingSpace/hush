import Foundation

/// A block-level line of a parsed script, so the overlay can lay out Markdown structure
/// (headings, lists, quotes, code, rules) instead of one flat stream of words.
public struct ScriptLine: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        case paragraph
        case heading(Int)
        case listItem(ordinal: Int?)
        case blockQuote
        case code
        case thematicBreak
    }

    public let kind: Kind
    public let indent: Int
    public let tokens: [Token]

    public init(kind: Kind, indent: Int, tokens: [Token]) {
        self.kind = kind
        self.indent = indent
        self.tokens = tokens
    }
}
