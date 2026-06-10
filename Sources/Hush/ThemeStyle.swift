import HushCore
import SwiftUI

/// Maps the pure theme model to SwiftUI colors for the overlay.
extension TeleprompterTheme {
    var textColor: Color {
        switch self {
        case .classic, .highContrast: .white
        case .blackOnWhite: .black
        case .yellowOnBlack: .yellow
        }
    }

    var usesSolidBackground: Bool { self != .classic }

    var solidBackground: Color {
        self == .blackOnWhite ? .white : .black
    }
}

extension Cue {
    var symbol: String {
        switch self {
        case .pause: "pause.circle"
        case .breathe: "wind"
        case .smile: "face.smiling"
        case .slow: "tortoise"
        case .emphasis: "exclamationmark.circle"
        }
    }
}

extension HighlightStyle {
    var color: Color {
        switch self {
        case .accent: .accentColor
        case .yellow: .yellow
        case .green: .green
        case .orange: .orange
        }
    }

    /// Text color that contrasts with the highlight pill.
    var textColor: Color {
        self == .yellow ? .black : .white
    }
}
