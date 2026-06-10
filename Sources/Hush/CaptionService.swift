import AVFoundation
import Foundation
import Observation
import Speech

/// Live, on-device captions of the speaker's own voice. Used in the recorder so Deaf and
/// hard-of-hearing presenters can see what was captured. Independent of voice-follow.
@MainActor
@Observable
final class CaptionService {
    private(set) var text = ""
    private(set) var isOn = false

    @ObservationIgnored private let recognizer = SFSpeechRecognizer()
    @ObservationIgnored private let engine = AVAudioEngine()
    @ObservationIgnored private var request: SFSpeechAudioBufferRecognitionRequest?
    @ObservationIgnored private var task: SFSpeechRecognitionTask?

    func start() async {
        let authorized = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0 == .authorized) }
        }
        // Require on-device recognition so audio never leaves the Mac; skip captions otherwise.
        guard authorized, recognizer?.supportsOnDeviceRecognition == true else { return }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true
        self.request = request

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak request] buffer, _ in
            request?.append(buffer)
        }
        engine.prepare()
        try? engine.start()
        isOn = true

        task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            if let result {
                let transcript = result.bestTranscription.formattedString
                Task { @MainActor in self?.text = transcript }
            }
            if error != nil {
                Task { @MainActor in self?.stop() }
            }
        }
    }

    func stop() {
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        isOn = false
        text = ""
    }
}
