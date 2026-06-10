import Foundation
@testable import HushCore
import Testing

struct ScriptStoreTests {
    private func makeTempStore() -> (FileScriptStore, URL) {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("hush-tests-\(UUID().uuidString)")
        return (FileScriptStore(directory: dir), dir)
    }

    @Test func loadsEmptyWhenNothingSaved() throws {
        let (store, dir) = makeTempStore()
        defer { try? FileManager.default.removeItem(at: dir) }
        #expect(try store.load().isEmpty)
    }

    @Test func savesAndReloadsScripts() throws {
        let (store, dir) = makeTempStore()
        defer { try? FileManager.default.removeItem(at: dir) }
        let scripts = [Script(title: "One", body: "First."), Script(title: "Two", body: "Second.")]
        try store.save(scripts)
        #expect(try store.load() == scripts)
    }

    @Test func overwritesOnResave() throws {
        let (store, dir) = makeTempStore()
        defer { try? FileManager.default.removeItem(at: dir) }
        try store.save([Script(title: "Old", body: "x")])
        let kept = [Script(title: "New", body: "y")]
        try store.save(kept)
        #expect(try store.load() == kept)
    }
}
