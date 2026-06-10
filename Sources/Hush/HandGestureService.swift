import AVFoundation
import Foundation
import HushCore
import Observation
import Vision

/// Watches the camera for hand gestures and maps them to teleprompter actions, fully on device.
/// Open palm toggles play/pause; one finger scrolls up; two fingers scroll down.
@MainActor
@Observable
final class HandGestureService: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    enum Action: Sendable { case togglePlay, scrollUp, scrollDown }

    private(set) var isRunning = false

    @ObservationIgnored private let session = AVCaptureSession()
    @ObservationIgnored private let output = AVCaptureVideoDataOutput()
    @ObservationIgnored private let queue = DispatchQueue(label: "com.happyhackingspace.hush.hand")
    @ObservationIgnored private nonisolated(unsafe) let request: VNDetectHumanHandPoseRequest = {
        let request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = 1
        return request
    }()
    @ObservationIgnored private var onAction: ((Action) -> Void)?
    @ObservationIgnored private var configured = false
    @ObservationIgnored private var stableGesture: HandGesture = .none
    @ObservationIgnored private var stableCount = 0
    @ObservationIgnored private var armed = true

    var isAvailable: Bool { AVCaptureDevice.default(for: .video) != nil }

    func start(onAction: @escaping (Action) -> Void) async {
        guard await AVCaptureDevice.requestAccess(for: .video) else { return }
        self.onAction = onAction
        configureIfNeeded()
        queue.async { [session] in
            if !session.isRunning { session.startRunning() }
        }
        isRunning = true
    }

    func stop() {
        queue.async { [session] in
            if session.isRunning { session.stopRunning() }
        }
        isRunning = false
    }

    private func configureIfNeeded() {
        guard !configured else { return }
        configured = true
        queue.async { [session, output, self] in
            session.beginConfiguration()
            session.sessionPreset = .vga640x480
            if let camera = AVCaptureDevice.default(for: .video),
               let input = try? AVCaptureDeviceInput(device: camera), session.canAddInput(input) {
                session.addInput(input)
            }
            output.alwaysDiscardsLateVideoFrames = true
            output.setSampleBufferDelegate(self, queue: self.queue)
            if session.canAddOutput(output) { session.addOutput(output) }
            session.commitConfiguration()
        }
    }

    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
        try? handler.perform([request])
        let gesture = Self.gesture(from: request.results?.first)
        Task { @MainActor in self.handle(gesture) }
    }

    private nonisolated static func gesture(from observation: VNHumanHandPoseObservation?) -> HandGesture {
        guard let observation, let points = try? observation.recognizedPoints(.all) else { return .none }
        typealias Joint = VNHumanHandPoseObservation.JointName
        func extended(_ tip: Joint, _ pip: Joint) -> Bool {
            guard let tipPoint = points[tip], let pipPoint = points[pip],
                  tipPoint.confidence > 0.3, pipPoint.confidence > 0.3 else { return false }
            return tipPoint.location.y > pipPoint.location.y
        }
        return HandGesture.classify(
            index: extended(.indexTip, .indexPIP),
            middle: extended(.middleTip, .middlePIP),
            ring: extended(.ringTip, .ringPIP),
            little: extended(.littleTip, .littlePIP)
        )
    }

    private func handle(_ gesture: HandGesture) {
        if gesture == stableGesture { stableCount += 1 } else { stableGesture = gesture; stableCount = 1 }
        guard stableCount >= 3 else { return }

        switch gesture {
        case .palm:
            if armed { onAction?(.togglePlay); armed = false }
        case .index where stableCount % 5 == 0:
            onAction?(.scrollUp)
        case .two where stableCount % 5 == 0:
            onAction?(.scrollDown)
        case .fist, .none, .unknown:
            armed = true
        default:
            break
        }
    }
}
