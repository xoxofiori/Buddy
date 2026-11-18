@preconcurrency import AVFoundation
import Vision

/// Front camera → Apple Vision body pose. Runs on its own background queue and hands each
/// frame's joints to `onFrame` on the main thread. Video is never saved or sent anywhere.
nonisolated final class CameraPoseSource: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "com.fiorilee.buddy.camera")
    private let request = VNDetectHumanBodyPoseRequest()
    private var configured = false

    /// Called on the main thread for every frame. `nil` means no body was found.
    var onFrame: (@MainActor @Sendable (PoseFrame?) -> Void)?

    /// False in the Simulator and on Macs without a front camera.
    static var isAvailable: Bool {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) != nil
    }

    /// Sets up the front camera. Returns false if it can't be used.
    func configure() -> Bool {
        if configured { return true }
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else { return false }

        session.beginConfiguration()
        // A 3:4 picture (not 16:9) so the wide camera panel shows head to toe without cropping
        // raised hands or feet. Prefer the smallest one at least 1280 wide (fast for Vision).
        let fourByThree = device.formats
            .filter { format in
                let d = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                return d.width * 3 == d.height * 4 && d.width >= 1280 && d.width <= 2016
            }
            .min { CMVideoFormatDescriptionGetDimensions($0.formatDescription).width
                 < CMVideoFormatDescriptionGetDimensions($1.formatDescription).width }
        if let fourByThree, (try? device.lockForConfiguration()) != nil {
            session.sessionPreset = .inputPriority
            device.activeFormat = fourByThree
            device.unlockForConfiguration()
        } else {
            session.sessionPreset = .hd1280x720
        }
        guard session.canAddInput(input) else {
            session.commitConfiguration()
            return false
        }
        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: queue)
        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            return false
        }
        session.addOutput(output)

        // Upright (portrait) and mirrored, so it matches what the kid sees on screen.
        if let connection = output.connection(with: .video) {
            if connection.isVideoRotationAngleSupported(90) { connection.videoRotationAngle = 90 }
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = true
            }
        }
        session.commitConfiguration()
        configured = true
        return true
    }

    func start() {
        queue.async { [self] in
            if !session.isRunning { session.startRunning() }
        }
    }

    func stop() {
        queue.async { [self] in
            if session.isRunning { session.stopRunning() }
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixels = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let size = CGSize(width: CVPixelBufferGetWidth(pixels), height: CVPixelBufferGetHeight(pixels))
        let handler = VNImageRequestHandler(cvPixelBuffer: pixels, orientation: .up)
        try? handler.perform([request])
        let frame = request.results?.first.map { Self.frame(from: $0, imageSize: size) }
        let callback = onFrame
        Task { @MainActor in callback?(frame) }
    }

    private static let jointNames: [Joint: VNHumanBodyPoseObservation.JointName] = [
        .nose: .nose, .neck: .neck,
        .leftShoulder: .leftShoulder, .rightShoulder: .rightShoulder,
        .leftElbow: .leftElbow, .rightElbow: .rightElbow,
        .leftWrist: .leftWrist, .rightWrist: .rightWrist,
        .leftHip: .leftHip, .rightHip: .rightHip,
        .leftKnee: .leftKnee, .rightKnee: .rightKnee,
        .leftAnkle: .leftAnkle, .rightAnkle: .rightAnkle,
    ]

    private static func frame(from observation: VNHumanBodyPoseObservation, imageSize: CGSize) -> PoseFrame {
        var joints: [Joint: TrackedJoint] = [:]
        for (joint, name) in jointNames {
            guard let p = try? observation.recognizedPoint(name) else { continue }
            // Vision's origin is bottom-left; flip to top-left like the screen.
            joints[joint] = TrackedJoint(point: CGPoint(x: p.location.x, y: 1 - p.location.y), confidence: p.confidence)
        }
        return PoseFrame(joints: joints, imageSize: imageSize)
    }
}
