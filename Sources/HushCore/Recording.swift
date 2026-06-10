import Foundation

/// Pure helpers for recording outputs, kept here so naming is testable without touching capture.
public enum Recording {
    /// A sortable, collision-resistant file name for a take, e.g. `Hush-2026-06-10-120305.mov`.
    public static func fileName(at date: Date, timeZone: TimeZone = .current) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        return String(
            format: "Hush-%04d-%02d-%02d-%02d%02d%02d.mov",
            parts.year ?? 0, parts.month ?? 0, parts.day ?? 0,
            parts.hour ?? 0, parts.minute ?? 0, parts.second ?? 0
        )
    }
}
