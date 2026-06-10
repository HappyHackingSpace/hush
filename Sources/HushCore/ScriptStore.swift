import Foundation

/// Persistence boundary for scripts. The protocol keeps the app and tests off the filesystem.
public protocol ScriptStore: Sendable {
    func load() throws -> [Script]
    func save(_ scripts: [Script]) throws
}

/// Stores scripts as a single JSON file inside the given directory.
public struct FileScriptStore: ScriptStore {
    private let fileURL: URL

    public init(directory: URL) {
        self.fileURL = directory.appendingPathComponent("scripts.json")
    }

    public func load() throws -> [Script] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([Script].self, from: data)
    }

    public func save(_ scripts: [Script]) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try JSONEncoder().encode(scripts)
        try data.write(to: fileURL, options: .atomic)
    }
}
