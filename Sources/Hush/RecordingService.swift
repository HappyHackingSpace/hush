import AVFoundation
import Foundation
import HushCore
import Observation

/// Captures the camera and microphone to a local movie file, with a preview layer for the UI.
/// Standalone capture for recording takes; the virtual camera (system extension) is separate.
@MainActor
@Observable
final class RecordingService: NSObject, AVCaptureFileOutputRecordingDelegate {
    private(set) var isRecording = false
    private(set) var lastOutputURL: URL?
    private(set) var isConfigured = false

    @ObservationIgnored let session = AVCaptureSession()
    @ObservationIgnored private let output = AVCaptureMovieFileOutput()
    @ObservationIgnored private let sessionQueue = DispatchQueue(label: "com.happyhackingspace.hush.session")

    func requestAuthorization() async -> Bool {
        let camera = await AVCaptureDevice.requestAccess(for: .video)
        let microphone = await AVCaptureDevice.requestAccess(for: .audio)
        return camera && microphone
    }

    func configureIfNeeded() {
        guard !isConfigured else { return }
        isConfigured = true
        sessionQueue.async { [session, output] in
            session.beginConfiguration()
            session.sessionPreset = .high
            if let camera = AVCaptureDevice.default(for: .video),
               let input = try? AVCaptureDeviceInput(device: camera), session.canAddInput(input) {
                session.addInput(input)
            }
            if let mic = AVCaptureDevice.default(for: .audio),
               let input = try? AVCaptureDeviceInput(device: mic), session.canAddInput(input) {
                session.addInput(input)
            }
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
            session.commitConfiguration()
        }
    }

    func startSession() {
        sessionQueue.async { [session] in
            if !session.isRunning { session.startRunning() }
        }
    }

    func stopSession() {
        sessionQueue.async { [session] in
            if session.isRunning { session.stopRunning() }
        }
    }

    func toggleRecording() {
        if isRecording { stop() } else { start() }
    }

    private func start() {
        let url = Self.recordingsDirectory().appendingPathComponent(Recording.fileName(at: Date()))
        output.startRecording(to: url, recordingDelegate: self)
        isRecording = true
    }

    private func stop() {
        output.stopRecording()
    }

    nonisolated func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        Task { @MainActor in
            self.isRecording = false
            self.lastOutputURL = error == nil ? outputFileURL : nil
        }
    }

    private static func recordingsDirectory() -> URL {
        let base = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent("Hush", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}
