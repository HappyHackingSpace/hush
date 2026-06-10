import Foundation

/// A teleprompter script. Pure value type; persistence and rendering live in the app layer.
public struct Script: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public var title: String
    public var body: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        body: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// The script parsed into Markdown block lines for layout.
    public var lines: [ScriptLine] { Tokenizer.parseLines(body) }

    /// The script body as matchable tokens, in reading order, with Markdown emphasis applied.
    public var tokens: [Token] { lines.flatMap(\.tokens) }
}
