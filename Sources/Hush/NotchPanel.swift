import AppKit

/// The overlay window that sits at the notch. It is excluded from screen capture so it stays
/// visible to the presenter but invisible to Zoom, Meet, Teams, OBS, and QuickTime recordings.
final class NotchPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        hidesOnDeactivate = false
        // Not movable-by-background: on a borderless window that would turn the whole surface
        // into a drag region and swallow clicks and focus meant for the controls and scroll view.
        becomesKeyOnlyIfNeeded = false
        acceptsMouseMovedEvents = true

        // The reason the whole product works: opt the window out of all screen capture.
        sharingType = .none
    }

    // A nonactivating panel can become key (so its controls and scrolling receive events)
    // without activating Hush, leaving the app you are presenting from frontmost.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
