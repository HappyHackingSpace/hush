import AppKit

/// Places the overlay directly beneath the camera so the presenter's eyeline stays on the lens.
/// On notch Macs the panel hugs the menu bar at screen-top-center; on notchless displays the
/// same top-center anchor reads as a clean banner.
enum NotchGeometry {
    static func panelFrame(width: CGFloat, height: CGFloat, topOffset: CGFloat, on screen: NSScreen) -> NSRect {
        let frame = screen.frame
        let menuBarHeight = frame.maxY - screen.visibleFrame.maxY
        let topInset = max(screen.safeAreaInsets.top, menuBarHeight)
        let x = frame.midX - width / 2
        let y = frame.maxY - topInset - topOffset - height
        return NSRect(x: x, y: y, width: width, height: height)
    }
}
