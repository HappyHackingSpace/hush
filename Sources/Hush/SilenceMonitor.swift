import AVFoundation
import Foundation

/// Reports whether the speaker is currently talking, from microphone level only (no speech
/// recognition). Used to auto-pause the timed scroll during silences.
@MainActor
final class SilenceMonitor {
    private let engine = AVAudioEngine()
    private var onChange: ((Bool) -> Void)?
    private var speaking = true
    private var lastLoud = Date()

    private let thresholdDB: Float = -40
    private let silenceWindow: TimeInterval = 0.6

    func start(onChange: @escaping (Bool) -> Void) async {
        guard await AVCaptureDevice.requestAccess(for: .audio) else { return }
        self.onChange = onChange
        lastLoud = Date()
        speaking = true

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            let level = SilenceMonitor.levelDB(buffer)
            DispatchQueue.main.async { self?.evaluate(level) }
        }
        engine.prepare()
        try? engine.start()
    }

    func stop() {
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        onChange = nil
    }

    private func evaluate(_ level: Float) {
        let now = Date()
        if level > thresholdDB { lastLoud = now }
        let nowSpeaking = now.timeIntervalSince(lastLoud) < silenceWindow
        if nowSpeaking != speaking {
            speaking = nowSpeaking
            onChange?(speaking)
        }
    }

    private static func levelDB(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let channel = buffer.floatChannelData?[0] else { return -160 }
        let count = Int(buffer.frameLength)
        guard count > 0 else { return -160 }
        var sum: Float = 0
        for index in 0..<count { sum += channel[index] * channel[index] }
        let rms = (sum / Float(count)).squareRoot()
        return 20 * log10(max(rms, 1e-7))
    }
}
