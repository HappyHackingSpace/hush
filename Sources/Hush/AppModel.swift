import AppKit
import Foundation
import HushCore
import Observation
import SwiftUI

/// Single source of truth for the app: the script library, current selection, appearance
/// settings, and the running state of the overlay. Mutations persist immediately so a crash
/// or quit never loses work.
@MainActor
@Observable
final class AppModel {
    enum RunMode: Sendable { case timed, voice }

    var scripts: [Script]
    var selectedScriptID: Script.ID?
    var settings: TeleprompterSettings
    var voiceEnabled = true

    private(set) var isRunning = false
    private(set) var runStartedAt: Date?
    private(set) var runMode: RunMode = .timed
    private(set) var highlightedTokenIndex: Int?
    private(set) var voiceProgress: Double = 0
    private(set) var countdownRemaining: Int?
    var overlayVisible = true
    var handControlEnabled = false
    var globalShortcutsEnabled = false
    var autoPauseEnabled = false
    /// Index into NSScreen.screens for the display the overlay appears on.
    private(set) var displayIndex = 0
    /// Word index the manual scroll is parked at; nudged by hand gestures.
    private(set) var manualAnchor = 0

    var aiError: String?

    @ObservationIgnored let recording = RecordingService()
    @ObservationIgnored let captions = CaptionService()
    @ObservationIgnored let ai = AIService()
    @ObservationIgnored private let scriptStore: ScriptStore
    @ObservationIgnored private let settingsStore: SettingsStore
    @ObservationIgnored private let speech = SpeechService()
    @ObservationIgnored private let hand = HandGestureService()
    @ObservationIgnored private let hotkeys = GlobalHotkeys()
    @ObservationIgnored private let silence = SilenceMonitor()
    @ObservationIgnored private var pausedSince: Date?
    @ObservationIgnored private var pausedAccumulated: TimeInterval = 0
    /// Notifies the overlay window that layout-affecting settings changed.
    @ObservationIgnored var onLayoutChange: ((TeleprompterSettings) -> Void)?
    @ObservationIgnored var onVisibilityChange: ((Bool) -> Void)?

    init(scriptStore: ScriptStore, settingsStore: SettingsStore) {
        self.scriptStore = scriptStore
        self.settingsStore = settingsStore
        self.settings = settingsStore.load() ?? .default
        let loaded = (try? scriptStore.load()) ?? []
        self.scripts = loaded.isEmpty ? [AppModel.starterScript] : loaded
        self.selectedScriptID = scripts.first?.id
    }

    var selectedScript: Script? {
        scripts.first { $0.id == selectedScriptID }
    }

    func addScript(title: String = "New script", body: String = "") {
        let script = Script(title: title, body: body)
        scripts.append(script)
        selectedScriptID = script.id
        persistScripts()
    }

    func addScriptFromClipboard() {
        let text = NSPasteboard.general.string(forType: .string) ?? ""
        addScript(title: "Pasted script", body: text)
    }

    func deleteSelected() {
        guard let id = selectedScriptID else { return }
        scripts.removeAll { $0.id == id }
        selectedScriptID = scripts.first?.id
        persistScripts()
    }

    func updateSelected(_ change: (inout Script) -> Void) {
        guard let id = selectedScriptID, let index = scripts.firstIndex(where: { $0.id == id }) else { return }
        change(&scripts[index])
        scripts[index].updatedAt = Date()
        persistScripts()
    }

    func setting<Value>(_ keyPath: WritableKeyPath<TeleprompterSettings, Value>) -> Binding<Value> {
        Binding(
            get: { self.settings[keyPath: keyPath] },
            set: { newValue in
                self.settings[keyPath: keyPath] = newValue
                self.settingsStore.save(self.settings)
                self.onLayoutChange?(self.settings)
            }
        )
    }

    func toggleRun() {
        if isRunning { stop() } else { start() }
    }

    func setOverlayVisible(_ visible: Bool) {
        overlayVisible = visible
        onVisibilityChange?(visible)
    }

    func setDisplay(_ index: Int) {
        displayIndex = index
        onLayoutChange?(settings)
    }

    func setHandControl(_ enabled: Bool) {
        handControlEnabled = enabled
        if enabled {
            Task { await hand.start { [weak self] action in self?.handle(action) } }
        } else {
            hand.stop()
        }
    }

    private func handle(_ action: HandGestureService.Action) {
        switch action {
        case .togglePlay: toggleRun()
        case .scrollUp: scrollUp()
        case .scrollDown: scrollDown()
        }
    }

    private func handle(_ command: VoiceCommand) {
        switch command {
        case .pause: stop()
        case .resume: break
        case .next: scrollDown()
        case .back: scrollUp()
        case .top: speech.resetAlignment()
        }
    }

    func scrollUp() {
        manualAnchor = max(0, manualAnchor - 2)
    }

    func scrollDown() {
        let limit = max(0, (selectedScript?.tokens.count ?? 1) - 1)
        manualAnchor = min(limit, manualAnchor + 2)
    }

    func adjustSpeed(by delta: Double) {
        var updated = settings
        updated.scrollSpeed = min(120, max(5, updated.scrollSpeed + delta))
        settings = updated
        settingsStore.save(settings)
        onLayoutChange?(settings)
    }

    func setGlobalShortcuts(_ enabled: Bool) {
        globalShortcutsEnabled = enabled
        if enabled {
            hotkeys.register(keyCode: 49, action: { [weak self] in self?.toggleRun() })
            hotkeys.register(keyCode: 126, action: { [weak self] in self?.scrollUp() })
            hotkeys.register(keyCode: 125, action: { [weak self] in self?.scrollDown() })
        } else {
            hotkeys.unregisterAll()
        }
    }

    func applyAI(instruction: String) {
        guard let text = selectedScript?.body, !ai.isWorking else { return }
        Task {
            do {
                let result = try await ai.transform(text, instruction: instruction)
                updateSelected { $0.body = result }
            } catch {
                aiError = error.localizedDescription
            }
        }
    }

    func start() {
        guard let script = selectedScript else { return }
        setOverlayVisible(true)
        isRunning = true
        if settings.countdown > 0 {
            countdownRemaining = settings.countdown
            Task { await runCountdown(then: script) }
        } else {
            beginRun(script)
        }
    }

    func stop() {
        speech.stop()
        silence.stop()
        isRunning = false
        runStartedAt = nil
        runMode = .timed
        highlightedTokenIndex = nil
        countdownRemaining = nil
    }

    private func runCountdown(then script: Script) async {
        for _ in 0..<settings.countdown {
            try? await Task.sleep(for: .seconds(1))
            guard isRunning, let remaining = countdownRemaining else { return }
            countdownRemaining = remaining - 1
        }
        guard isRunning else { return }
        countdownRemaining = nil
        beginRun(script)
    }

    private func beginRun(_ script: Script) {
        runStartedAt = Date()
        pausedSince = nil
        pausedAccumulated = 0
        highlightedTokenIndex = nil
        voiceProgress = 0
        runMode = (voiceEnabled && speech.isOnDeviceAvailable) ? .voice : .timed
        if runMode == .voice {
            startVoice(for: script)
        } else if autoPauseEnabled {
            Task { await silence.start { [weak self] speaking in self?.speakingChanged(speaking) } }
        }
    }

    /// Elapsed run time excluding auto-paused silences, used by the timed scroller.
    func activeElapsed(at now: Date) -> TimeInterval {
        guard let start = runStartedAt else { return 0 }
        var paused = pausedAccumulated
        if let since = pausedSince { paused += now.timeIntervalSince(since) }
        return max(0, now.timeIntervalSince(start) - paused)
    }

    func setAutoPause(_ enabled: Bool) {
        autoPauseEnabled = enabled
        guard isRunning, runMode == .timed else { return }
        if enabled {
            Task { await silence.start { [weak self] speaking in self?.speakingChanged(speaking) } }
        } else {
            silence.stop()
            speakingChanged(true)
        }
    }

    private func speakingChanged(_ speaking: Bool) {
        if speaking {
            if let since = pausedSince {
                pausedAccumulated += Date().timeIntervalSince(since)
                pausedSince = nil
            }
        } else if pausedSince == nil {
            pausedSince = Date()
        }
    }

    private func startVoice(for script: Script) {
        Task {
            guard await speech.requestAuthorization() else {
                runMode = .timed
                return
            }
            guard isRunning else { return }
            speech.onCommand = { [weak self] command in self?.handle(command) }
            do {
                try speech.start(tokens: script.tokens) { [weak self] update in
                    self?.highlightedTokenIndex = update.tokenIndex
                    self?.voiceProgress = update.progress
                }
            } catch {
                runMode = .timed
            }
        }
    }

    private func persistScripts() {
        try? scriptStore.save(scripts)
    }

    private static let starterScript = Script(
        title: "Welcome to Hush",
        body: """
        Welcome to Hush, your invisible teleprompter.

        This text lives under your camera, so your eyes stay on the lens. \
        It is invisible during screen sharing, visible only to you.

        Press Start, then read aloud. Adjust the speed, size, and position \
        until it feels natural. When you are ready, replace this with your own script.
        """
    )
}
