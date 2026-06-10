import AVFoundation
import Foundation
import HushCore
import Speech

/// On-device speech recognition that drives the `Aligner`. It captures the microphone, feeds
/// the recognizer, and reports the current script position back on the main actor. Audio never
/// leaves the device.
@MainActor
final class SpeechService {
    struct Update: Sendable {
        let tokenIndex: Int?
        let progress: Double
    }

    private let recognizer = SFSpeechRecognizer()
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    private var aligner: Aligner?
    private var processedWords = 0
    private var lastCommandWord = -1
    private var onUpdate: ((Update) -> Void)?
    var onCommand: ((VoiceCommand) -> Void)?

    var isOnDeviceAvailable: Bool {
        recognizer?.supportsOnDeviceRecognition ?? false
    }

    func requestAuthorization() async -> Bool {
        let speechAuthorized = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0 == .authorized) }
        }
        guard speechAuthorized else { return false }
        return await AVCaptureDevice.requestAccess(for: .audio)
    }

    func start(tokens: [Token], onUpdate: @escaping (Update) -> Void) throws {
        aligner = Aligner(tokens: tokens.filter { Cue.parse($0.text) == nil })
        processedWords = 0
        lastCommandWord = -1
        self.onUpdate = onUpdate

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true
        self.request = request

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak request] buffer, _ in
            request?.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()

        task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                let transcript = result.bestTranscription.formattedString
                let isFinal = result.isFinal
                Task { @MainActor in self.process(transcript: transcript, isFinal: isFinal) }
            }
            if error != nil {
                Task { @MainActor in self.stop() }
            }
        }
    }

    func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
    }

    /// Feeds newly stabilized words to the aligner. The most recent word is held back until a
    /// following word appears, since speech recognition revises its tail.
    private func process(transcript: String, isFinal: Bool) {
        let words = transcript.split(whereSeparator: { $0 == " " || $0 == "\n" }).map(String.init)
        let stable = isFinal ? words.count : max(0, words.count - 1)
        guard stable > processedWords else { return }
        for index in processedWords..<stable {
            aligner?.feed(words[index])
        }
        processedWords = stable

        if stable - 1 > lastCommandWord, let command = VoiceCommand.detect(in: Array(words.prefix(stable))) {
            lastCommandWord = stable - 1
            onCommand?(command)
        }

        guard let aligner else { return }
        onUpdate?(Update(tokenIndex: aligner.currentTokenIndex, progress: aligner.progress))
    }

    func resetAlignment() {
        aligner?.reset()
        onUpdate?(Update(tokenIndex: nil, progress: 0))
    }
}
