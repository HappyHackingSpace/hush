import Foundation

/// User-tunable appearance and motion for the teleprompter overlay. Persisted alongside scripts.
public struct TeleprompterSettings: Equatable, Codable, Sendable {
    public var fontSize: Double
    public var lineSpacing: Double
    public var opacity: Double
    public var panelWidth: Double
    /// Vertical gap below the notch, in points.
    public var topOffset: Double
    /// Auto-scroll rate in points per second.
    public var scrollSpeed: Double
    public var startDelay: TimeInterval
    /// Flips text horizontally for use behind beam-splitter teleprompter glass.
    public var mirrored: Bool
    public var theme: TeleprompterTheme
    public var boldText: Bool
    public var highlight: HighlightStyle
    /// Seconds to count down before scrolling begins; 0 disables it.
    public var countdown: Int
    /// Dims already-read words so the current line stands out (voice mode).
    public var focusDimming: Bool

    public init(
        fontSize: Double = 18,
        lineSpacing: Double = 4,
        opacity: Double = 0.78,
        panelWidth: Double = 540,
        topOffset: Double = 4,
        scrollSpeed: Double = 30,
        startDelay: TimeInterval = 1,
        mirrored: Bool = false,
        theme: TeleprompterTheme = .classic,
        boldText: Bool = false,
        highlight: HighlightStyle = .accent,
        countdown: Int = 0,
        focusDimming: Bool = false
    ) {
        self.fontSize = fontSize
        self.lineSpacing = lineSpacing
        self.opacity = opacity
        self.panelWidth = panelWidth
        self.topOffset = topOffset
        self.scrollSpeed = scrollSpeed
        self.startDelay = startDelay
        self.mirrored = mirrored
        self.theme = theme
        self.boldText = boldText
        self.highlight = highlight
        self.countdown = countdown
        self.focusDimming = focusDimming
    }

    public static let `default` = TeleprompterSettings()

    // Decode field by field so adding new settings never discards a user's saved preferences.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = TeleprompterSettings.default
        fontSize = try container.decodeIfPresent(Double.self, forKey: .fontSize) ?? fallback.fontSize
        lineSpacing = try container.decodeIfPresent(Double.self, forKey: .lineSpacing) ?? fallback.lineSpacing
        opacity = try container.decodeIfPresent(Double.self, forKey: .opacity) ?? fallback.opacity
        panelWidth = try container.decodeIfPresent(Double.self, forKey: .panelWidth) ?? fallback.panelWidth
        topOffset = try container.decodeIfPresent(Double.self, forKey: .topOffset) ?? fallback.topOffset
        scrollSpeed = try container.decodeIfPresent(Double.self, forKey: .scrollSpeed) ?? fallback.scrollSpeed
        startDelay = try container.decodeIfPresent(TimeInterval.self, forKey: .startDelay) ?? fallback.startDelay
        mirrored = try container.decodeIfPresent(Bool.self, forKey: .mirrored) ?? fallback.mirrored
        theme = try container.decodeIfPresent(TeleprompterTheme.self, forKey: .theme) ?? fallback.theme
        boldText = try container.decodeIfPresent(Bool.self, forKey: .boldText) ?? fallback.boldText
        highlight = try container.decodeIfPresent(HighlightStyle.self, forKey: .highlight) ?? fallback.highlight
        countdown = try container.decodeIfPresent(Int.self, forKey: .countdown) ?? fallback.countdown
        focusDimming = try container.decodeIfPresent(Bool.self, forKey: .focusDimming) ?? fallback.focusDimming
    }
}
