import Foundation
import HushCore

/// Persists `TeleprompterSettings` in user defaults as JSON.
struct SettingsStore {
    private let defaults: UserDefaults
    private let key = "teleprompter.settings"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> TeleprompterSettings? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(TeleprompterSettings.self, from: data)
    }

    func save(_ settings: TeleprompterSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: key)
    }
}
