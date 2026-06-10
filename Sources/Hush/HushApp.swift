import AppKit
import HushCore
import SwiftUI

@main
struct HushApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        Window("Hush", id: "main") {
            ContentView(model: appDelegate.model)
        }
        .commands { teleprompterCommands }

        MenuBarExtra("Hush", systemImage: "text.alignleft") {
            Button(appDelegate.model.isRunning ? "Stop" : "Start") { appDelegate.model.toggleRun() }
            Button("Open Hush") {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "main")
            }
            Toggle("Show overlay", isOn: overlayVisibleBinding)
            Divider()
            Button("Quit Hush") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
    }

    @CommandsBuilder
    private var teleprompterCommands: some Commands {
        CommandMenu("Teleprompter") {
            Button(appDelegate.model.isRunning ? "Pause" : "Start") { appDelegate.model.toggleRun() }
                .keyboardShortcut("r")
            Divider()
            Button("Scroll Up") { appDelegate.model.scrollUp() }
                .keyboardShortcut(.upArrow, modifiers: [.control, .command])
            Button("Scroll Down") { appDelegate.model.scrollDown() }
                .keyboardShortcut(.downArrow, modifiers: [.control, .command])
            Button("Faster") { appDelegate.model.adjustSpeed(by: 5) }
                .keyboardShortcut("]")
            Button("Slower") { appDelegate.model.adjustSpeed(by: -5) }
                .keyboardShortcut("[")
            Divider()
            Button(appDelegate.model.overlayVisible ? "Hide Overlay" : "Show Overlay") {
                appDelegate.model.setOverlayVisible(!appDelegate.model.overlayVisible)
            }
            .keyboardShortcut("l")
        }
    }

    private var overlayVisibleBinding: Binding<Bool> {
        Binding(
            get: { appDelegate.model.overlayVisible },
            set: { appDelegate.model.setOverlayVisible($0) }
        )
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model: AppModel
    private let notch = NotchController()

    override init() {
        let support = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Hush", isDirectory: true)
        model = AppModel(scriptStore: FileScriptStore(directory: support), settingsStore: SettingsStore())
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        notch.attach(model)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        true
    }
}
