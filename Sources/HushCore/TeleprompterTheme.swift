import Foundation

/// High-contrast color schemes for the overlay, for low-vision and color needs.
public enum TeleprompterTheme: String, Codable, Sendable, CaseIterable {
    case classic
    case highContrast
    case blackOnWhite
    case yellowOnBlack

    public var displayName: String {
        switch self {
        case .classic: "Classic"
        case .highContrast: "High contrast"
        case .blackOnWhite: "Black on white"
        case .yellowOnBlack: "Yellow on black"
        }
    }
}

/// Color used to mark the word currently being spoken.
public enum HighlightStyle: String, Codable, Sendable, CaseIterable {
    case accent
    case yellow
    case green
    case orange

    public var displayName: String {
        switch self {
        case .accent: "Accent"
        case .yellow: "Yellow"
        case .green: "Green"
        case .orange: "Orange"
        }
    }
}
