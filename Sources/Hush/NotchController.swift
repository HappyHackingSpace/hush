import AppKit
import HushCore
import SwiftUI

/// Owns the notch overlay panel: builds it, hosts the SwiftUI overlay bound to the model, and
/// keeps its size and position in sync with layout settings and visibility.
@MainActor
final class NotchController {
    private var panel: NotchPanel?
    private weak var model: AppModel?

    func attach(_ model: AppModel) {
        self.model = model
        guard let screen = targetScreen() else { return }

        let panel = NotchPanel(contentRect: frame(for: model.settings, on: screen))
        panel.contentView = NSHostingView(rootView: NotchOverlayView(model: model))
        panel.orderFrontRegardless()
        self.panel = panel

        model.onLayoutChange = { [weak self] settings in self?.updateLayout(settings) }
        model.onVisibilityChange = { [weak self] visible in self?.setVisible(visible) }
    }

    private func setVisible(_ visible: Bool) {
        guard let panel else { return }
        if visible { panel.orderFrontRegardless() } else { panel.orderOut(nil) }
    }

    private func updateLayout(_ settings: TeleprompterSettings) {
        guard let panel, let screen = targetScreen() else { return }
        panel.setFrame(frame(for: settings, on: screen), display: true)
    }

    private func targetScreen() -> NSScreen? {
        let screens = NSScreen.screens
        let index = model?.displayIndex ?? 0
        return screens.indices.contains(index) ? screens[index] : NSScreen.main
    }

    private func frame(for settings: TeleprompterSettings, on screen: NSScreen) -> NSRect {
        let height = settings.fontSize * 5 + 24
        return NotchGeometry.panelFrame(
            width: settings.panelWidth,
            height: height,
            topOffset: settings.topOffset,
            on: screen
        )
    }
}
