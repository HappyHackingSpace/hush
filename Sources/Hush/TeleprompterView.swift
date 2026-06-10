import HushCore
import SwiftUI

/// The notch overlay: a frosted HUD card that switches between manual, timed, and voice
/// scrolling, with controls revealed on hover.
struct NotchOverlayView: View {
    let model: AppModel

    @State private var hovering = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private static let placeholder = "Press Start to run your script here, invisible to anyone on the call."

    var body: some View {
        ZStack(alignment: .top) {
            content
            controlBar
                .opacity(hovering ? 1 : 0)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: hovering)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(cardBackground)
        .overlay(alignment: .bottom) { progressBar }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.14), lineWidth: 1)
        )
        .onHover { hovering = $0 }
    }

    @ViewBuilder
    private var cardBackground: some View {
        if model.settings.theme.usesSolidBackground || reduceTransparency {
            model.settings.theme.solidBackground.opacity(model.settings.opacity)
        } else {
            ZStack {
                VisualEffectView()
                Color.black.opacity(0.32)
            }
            .opacity(model.settings.opacity)
        }
    }

    @ViewBuilder
    private var progressBar: some View {
        if model.isRunning, model.runMode == .voice {
            GeometryReader { geo in
                Capsule()
                    .fill(.tint)
                    .frame(width: geo.size.width * model.voiceProgress)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: model.voiceProgress)
            }
            .frame(height: 3)
            .padding(.horizontal, 12)
            .padding(.bottom, 5)
        }
    }

    @ViewBuilder
    private var content: some View {
        let lines = model.selectedScript?.lines ?? []
        if let remaining = model.countdownRemaining {
            Text("\(remaining)")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(model.settings.theme.textColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentTransition(.numericText())
        } else if model.isRunning, model.runMode == .voice {
            VoiceTeleprompterView(
                lines: lines,
                currentTokenIndex: model.highlightedTokenIndex,
                settings: model.settings
            )
        } else if model.isRunning, model.runStartedAt != nil {
            TimedTeleprompterView(model: model, lines: lines)
        } else {
            ManualTeleprompterView(model: model, lines: lines, placeholder: Self.placeholder)
        }
    }

    private var controlBar: some View {
        HStack(spacing: 6) {
            iconButton(
                model.isRunning ? "pause.fill" : "play.fill",
                label: model.isRunning ? "Pause" : "Start"
            ) { model.toggleRun() }
            iconButton("xmark", label: "Hide overlay") { model.setOverlayVisible(false) }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.15), lineWidth: 1))
        .padding(.top, 6)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.trailing, 10)
    }

    private func iconButton(_ systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 24, height: 24)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// Manual scrolling via the trackpad, and via hand gestures that nudge a word anchor.
struct ManualTeleprompterView: View {
    let model: AppModel
    let lines: [ScriptLine]
    let placeholder: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                if lines.isEmpty {
                    placeholderText(placeholder, settings: model.settings)
                } else {
                    ScriptLinesView(lines: lines, currentTokenIndex: nil, settings: model.settings)
                }
            }
            .onChange(of: model.manualAnchor) { _, anchor in
                if reduceMotion {
                    proxy.scrollTo(anchor, anchor: .center)
                } else {
                    withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo(anchor, anchor: .center) }
                }
            }
        }
    }
}

/// Auto-scrolls the script upward at the configured speed. Elapsed time comes from the model,
/// which excludes auto-paused silences.
struct TimedTeleprompterView: View {
    let model: AppModel
    let lines: [ScriptLine]

    @State private var contentHeight: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                let elapsed = model.activeElapsed(at: timeline.date)
                let maxOffset = max(0, contentHeight - geo.size.height)
                let offset = ScrollMetrics.offset(
                    elapsed: elapsed,
                    speed: model.settings.scrollSpeed,
                    startDelay: model.settings.startDelay,
                    maxOffset: maxOffset
                )
                ScriptLinesView(lines: lines, currentTokenIndex: nil, settings: model.settings)
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(key: ContentHeightKey.self, value: proxy.size.height)
                        }
                    )
                    .offset(y: -offset)
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                    .clipped()
            }
        }
        .onPreferenceChange(ContentHeightKey.self) { contentHeight = $0 }
    }
}

/// Highlights the word being spoken and scrolls to keep it in view.
struct VoiceTeleprompterView: View {
    let lines: [ScriptLine]
    let currentTokenIndex: Int?
    let settings: TeleprompterSettings

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                ScriptLinesView(lines: lines, currentTokenIndex: currentTokenIndex, settings: settings)
            }
            .scrollDisabled(true)
            .onChange(of: currentTokenIndex) { _, newValue in
                guard let newValue else { return }
                let anchor = UnitPoint(x: 0.5, y: 0.42)
                if reduceMotion {
                    proxy.scrollTo(newValue, anchor: anchor)
                } else {
                    withAnimation(.easeOut(duration: 0.3)) { proxy.scrollTo(newValue, anchor: anchor) }
                }
            }
        }
    }
}

private func placeholderText(_ text: String, settings: TeleprompterSettings) -> some View {
    Text(text)
        .font(.system(size: settings.fontSize, weight: settings.boldText ? .bold : .medium, design: .rounded))
        .foregroundStyle(settings.theme.textColor.opacity(0.85))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
}

private struct ContentHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
