import HushCore
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Bindable var model: AppModel
    @State private var showingRecorder = false
    @State private var showingInspector = true
    @AppStorage("hush.onboarded") private var onboarded = false

    var body: some View {
        NavigationSplitView {
            ScriptSidebar(model: model)
        } detail: {
            Group {
                if model.selectedScript != nil {
                    EditorPane(model: model)
                } else {
                    ContentUnavailableView(
                        "No script",
                        systemImage: "text.alignleft",
                        description: Text("Create a script to begin.")
                    )
                }
            }
            .toolbar { detailToolbar }
            .inspector(isPresented: $showingInspector) {
                AppearanceInspector(model: model)
                    .inspectorColumnWidth(min: 260, ideal: 300, max: 360)
            }
        }
        .frame(minWidth: 860, minHeight: 540)
        .sheet(isPresented: $showingRecorder) {
            RecorderView(model: model)
        }
        .sheet(isPresented: onboardingBinding) {
            WelcomeView { onboarded = true }
        }
        .alert("AI unavailable", isPresented: aiErrorPresented) {
            Button("OK", role: .cancel) { model.aiError = nil }
        } message: {
            Text(model.aiError ?? "")
        }
    }

    @ToolbarContentBuilder
    private var detailToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            if model.selectedScript != nil {
                aiMenu
                Button { showingRecorder = true } label: { Image(systemName: "record.circle") }
                    .help("Record a take")
                    .accessibilityLabel("Record a take")
                Button(model.isRunning ? "Stop" : "Start", systemImage: model.isRunning ? "stop.fill" : "play.fill") {
                    model.toggleRun()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: .command)
            }
            Button {
                model.setOverlayVisible(!model.overlayVisible)
            } label: {
                Image(systemName: model.overlayVisible ? "eye" : "eye.slash")
            }
            .help(model.overlayVisible ? "Hide overlay" : "Show overlay")
            .accessibilityLabel(model.overlayVisible ? "Hide overlay" : "Show overlay")
            Button { showingInspector.toggle() } label: { Image(systemName: "sidebar.trailing") }
                .help("Appearance")
                .accessibilityLabel("Appearance settings")
        }
    }

    private static let presets: [(label: String, instruction: String)] = [
        ("Tighten", "Tighten this script: cut filler and redundancy, keep the meaning."),
        ("Make conversational", "Rewrite this script to sound natural and conversational when spoken aloud."),
        ("Fix grammar", "Fix grammar, spelling, and punctuation. Do not change the wording otherwise."),
        ("Shorten by half", "Shorten this script to about half its length while keeping the key points.")
    ]

    private static let languages = ["Kurdish (Kurmancî)", "English", "Spanish", "Arabic", "Turkish"]

    private var aiMenu: some View {
        Menu {
            ForEach(Self.presets, id: \.label) { preset in
                Button(preset.label) { model.applyAI(instruction: preset.instruction) }
            }
            Divider()
            Menu("Translate") {
                ForEach(Self.languages, id: \.self) { language in
                    Button(language) { model.applyAI(instruction: "Translate this script into \(language).") }
                }
            }
        } label: {
            Label("AI", systemImage: "sparkles")
        }
        .menuIndicator(model.ai.isWorking ? .visible : .automatic)
        .disabled(!model.ai.isAvailable || model.ai.isWorking)
        .help(model.ai.isAvailable ? "Rewrite with on-device AI" : "Needs macOS 26 with Apple Intelligence")
    }

    private var aiErrorPresented: Binding<Bool> {
        Binding(get: { model.aiError != nil }, set: { if !$0 { model.aiError = nil } })
    }

    private var onboardingBinding: Binding<Bool> {
        Binding(get: { !onboarded }, set: { if !$0 { onboarded = true } })
    }
}

private struct ScriptSidebar: View {
    @Bindable var model: AppModel
    @State private var importing = false

    var body: some View {
        List(selection: $model.selectedScriptID) {
            ForEach(model.scripts) { script in
                VStack(alignment: .leading, spacing: 2) {
                    Text(script.title.isEmpty ? "Untitled" : script.title)
                        .font(.body)
                    Text(subtitle(script))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
                .tag(Optional(script.id))
            }
        }
        .navigationTitle("Scripts")
        .toolbar {
            Menu {
                Button("New") { model.addScript() }
                Button("From File…") { importing = true }
                Button("From Clipboard") { model.addScriptFromClipboard() }
            } label: {
                Image(systemName: "square.and.pencil")
            }
            .help("New script")
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.plainText, .text]) { result in
            guard case .success(let url) = result else { return }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { return }
            model.addScript(title: url.deletingPathExtension().lastPathComponent, body: text)
        }
    }

    private func subtitle(_ script: Script) -> String {
        let words = script.tokens.filter(\.isMatchable).count
        let seconds = Int(ReadingTime.seconds(words: words).rounded())
        let time = seconds < 60 ? "\(seconds)s" : "\(seconds / 60) min"
        return "\(words) words · ~\(time)"
    }
}

private struct EditorPane: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                TextField("Title", text: titleBinding)
                    .textFieldStyle(.plain)
                    .font(.title2.weight(.semibold))
                if model.ai.isWorking { ProgressView().controlSize(.small) }
                Spacer()
                Button(role: .destructive) { model.deleteSelected() } label: { Image(systemName: "trash") }
                    .buttonStyle(.borderless)
                    .help("Delete script")
            }

            TextEditor(text: bodyBinding)
                .font(.system(size: 15))
                .lineSpacing(3)
                .scrollContentBackground(.hidden)
                .padding(12)
                .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(.separator, lineWidth: 1)
                )

            if model.isRunning {
                Label("Running, invisible to screen sharing", systemImage: "eye.slash")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            } else {
                Text("Markdown supported · Cues: [pause] [breathe] [smile] [slow] [emphasis]")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(20)
    }

    private var titleBinding: Binding<String> {
        Binding(
            get: { model.selectedScript?.title ?? "" },
            set: { value in model.updateSelected { $0.title = value } }
        )
    }

    private var bodyBinding: Binding<String> {
        Binding(
            get: { model.selectedScript?.body ?? "" },
            set: { value in model.updateSelected { $0.body = value } }
        )
    }
}

private struct AppearanceInspector: View {
    @Bindable var model: AppModel

    var body: some View {
        Form {
            Section("Motion") {
                slider("Speed", model.setting(\.scrollSpeed), 5...120, unit: "pt/s")
                slider("Start delay", model.setting(\.startDelay), 0...10, unit: "s")
                Toggle("Voice follow", isOn: $model.voiceEnabled)
                Toggle("Auto-pause on silence", isOn: autoPauseBinding)
                Picker("Countdown", selection: model.setting(\.countdown)) {
                    Text("Off").tag(0)
                    Text("3s").tag(3)
                    Text("5s").tag(5)
                }
            }
            Section {
                Toggle("Hand control", isOn: handControlBinding)
            } header: {
                Text("Hands-free")
            } footer: {
                Text("✋ play or pause, ☝️ scroll up, ✌️ scroll down.")
            }
            Section {
                Toggle("Global shortcuts", isOn: globalShortcutsBinding)
            } header: {
                Text("Keyboard")
            } footer: {
                Text("Control-Option-Command with Space to play or pause, or Up/Down to scroll, even from another app.")
            }
            Section("Text") {
                Picker("Theme", selection: model.setting(\.theme)) {
                    ForEach(TeleprompterTheme.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
                Picker("Highlight", selection: model.setting(\.highlight)) {
                    ForEach(HighlightStyle.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
                Toggle("Bold text", isOn: model.setting(\.boldText))
                Toggle("Focus dimming", isOn: model.setting(\.focusDimming))
                slider("Size", model.setting(\.fontSize), 12...72, unit: "pt")
                slider("Line spacing", model.setting(\.lineSpacing), 0...24, unit: "pt")
            }
            Section("Overlay") {
                if NSScreen.screens.count > 1 {
                    Picker("Display", selection: displayBinding) {
                        ForEach(Array(NSScreen.screens.enumerated()), id: \.offset) { index, screen in
                            Text(screen.localizedName).tag(index)
                        }
                    }
                }
                slider("Width", model.setting(\.panelWidth), 320...900, unit: "pt")
                slider("Position", model.setting(\.topOffset), 0...80, unit: "pt")
                slider("Opacity", model.setting(\.opacity), 0.2...1, unit: "")
                Toggle("Mirror", isOn: model.setting(\.mirrored))
            }
        }
        .formStyle(.grouped)
    }

    private func slider(
        _ label: String,
        _ value: Binding<Double>,
        _ range: ClosedRange<Double>,
        unit: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                Spacer()
                Text(readout(value.wrappedValue, unit: unit))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: value, in: range)
        }
    }

    private func readout(_ value: Double, unit: String) -> String {
        unit.isEmpty ? String(format: "%.0f%%", value * 100) : "\(Int(value)) \(unit)"
    }

    private var handControlBinding: Binding<Bool> {
        Binding(get: { model.handControlEnabled }, set: { model.setHandControl($0) })
    }

    private var globalShortcutsBinding: Binding<Bool> {
        Binding(get: { model.globalShortcutsEnabled }, set: { model.setGlobalShortcuts($0) })
    }

    private var autoPauseBinding: Binding<Bool> {
        Binding(get: { model.autoPauseEnabled }, set: { model.setAutoPause($0) })
    }

    private var displayBinding: Binding<Int> {
        Binding(get: { model.displayIndex }, set: { model.setDisplay($0) })
    }
}

private struct RecorderView: View {
    let model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var captionsOn = false

    private var recording: RecordingService { model.recording }

    var body: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottom) {
                CameraPreview(session: recording.session)
                    .frame(width: 520, height: 320)
                    .background(Color.black)
                if captionsOn, !model.captions.text.isEmpty {
                    Text(model.captions.text)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(.black.opacity(0.6))
                }
            }
            .frame(width: 520, height: 320)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            HStack {
                Button {
                    recording.toggleRecording()
                } label: {
                    Label(
                        recording.isRecording ? "Stop" : "Record",
                        systemImage: recording.isRecording ? "stop.fill" : "record.circle"
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(recording.isRecording ? .red : .accentColor)
                Toggle("Captions", isOn: $captionsOn)
                    .toggleStyle(.button)
                if let url = recording.lastOutputURL {
                    Button("Show in Finder") { NSWorkspace.shared.activateFileViewerSelecting([url]) }
                }
                Spacer()
                Button("Done") { dismiss() }
            }
        }
        .padding(20)
        .task {
            _ = await recording.requestAuthorization()
            recording.configureIfNeeded()
            recording.startSession()
        }
        .onChange(of: captionsOn) { _, isOn in
            Task { if isOn { await model.captions.start() } else { model.captions.stop() } }
        }
        .onDisappear {
            if recording.isRecording { recording.toggleRecording() }
            recording.stopSession()
            model.captions.stop()
        }
    }
}
