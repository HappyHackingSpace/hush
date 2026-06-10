import Foundation

/// Estimates how long a script takes to read aloud, at an average speaking pace.
public enum ReadingTime {
    public static let averageWordsPerMinute: Double = 130

    public static func seconds(words: Int, wordsPerMinute: Double = averageWordsPerMinute) -> TimeInterval {
        guard words > 0, wordsPerMinute > 0 else { return 0 }
        return Double(words) / wordsPerMinute * 60
    }
}
