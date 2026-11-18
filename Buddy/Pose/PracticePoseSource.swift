import CoreGraphics
import Foundation

/// Stand-in for the camera when there isn't one (Simulator, Mac) or it isn't allowed:
/// a pretend kid doing the exercise, so the whole session can be tried and reviewed.
/// Most reps are good; a few stop short or go too deep so every cue can be heard.
/// Also draws the "follow along" guide figure (perfect reps at a steady pace).
final class PracticePoseSource {
    let kind: ExerciseKind
    var onFrame: ((PoseFrame?) -> Void)?

    private var task: Task<Void, Never>?
    private var started = Date()

    /// Seconds per rep (a short rest, then down and up).
    static let repTime = 2.6
    /// Same 3:4 shape as the camera picture.
    static let imageSize = CGSize(width: 1440, height: 1920)

    init(kind: ExerciseKind) {
        self.kind = kind
    }

    func start() {
        started = Date()
        task?.cancel()
        task = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(33))
                guard let self else { return }
                self.onFrame?(self.frame(at: Date().timeIntervalSince(self.started)))
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    // MARK: Pretend movement

    /// Peak shoulder angle (arm raises) or lowest knee angle (squats) for each pretend rep.
    private var pattern: [Double] {
        switch kind {
        case .armRaises: [165, 160, 170, 128, 165, 168, 162, 172, 166, 160]
        case .miniSquats: [105, 100, 112, 136, 102, 64, 108, 104, 110, 100]
        }
    }

    private static func restAngle(_ kind: ExerciseKind) -> Double { kind == .armRaises ? 15 : 175 }

    /// One rep shape: rest briefly, then ease to `target` and back, over `repTime` seconds.
    private static func repAngle(_ kind: ExerciseKind, phase: Double, target: Double, repTime: Double) -> Double {
        let rest = restAngle(kind)
        guard phase > 0.5 else { return rest }
        let p = (1 - cos((phase - 0.5) / (repTime - 0.5) * 2 * .pi)) / 2
        return rest + (target - rest) * p
    }

    func angle(at t: Double) -> Double {
        let index = Int(t / Self.repTime)
        let phase = t.truncatingRemainder(dividingBy: Self.repTime)
        return Self.repAngle(kind, phase: phase, target: pattern[index % pattern.count], repTime: Self.repTime)
    }

    func frame(at t: Double) -> PoseFrame {
        Self.figure(kind, angle: angle(at: t))
    }

    // MARK: Follow-along guide

    /// Seconds per guide rep: a calm, steady pace to copy.
    static let guideRepTime = 3.2

    /// The guide's angle at time `t`: perfect, middle-of-the-target reps.
    static func guideAngle(_ kind: ExerciseKind, at t: Double) -> Double {
        let target = kind == .armRaises ? 165.0 : 100.0
        return repAngle(kind, phase: t.truncatingRemainder(dividingBy: guideRepTime), target: target, repTime: guideRepTime)
    }

    /// The part of the picture the guide figure moves in (so it can be shown nice and big).
    static func guideCrop(_ kind: ExerciseKind) -> CGRect {
        kind == .armRaises
            ? CGRect(x: 0.15, y: 0.18, width: 0.7, height: 0.76)
            : CGRect(x: 0.25, y: 0.3, width: 0.5, height: 0.64)
    }

    /// A simple stick figure facing the camera, holding the exercise at `angle`
    /// (shoulder angle for arm raises, knee angle for squats).
    static func figure(_ kind: ExerciseKind, angle: Double) -> PoseFrame {
        let shoulderAngle = kind == .armRaises ? angle : 12
        let kneeAngle = kind == .miniSquats ? angle : 178
        let W = imageSize.width, H = imageSize.height

        // Legs: feet stay put; the knees bend outward and the body sinks.
        let leg: CGFloat = 0.09 * H
        let ankleY: CGFloat = 0.9 * H
        let span = 2 * leg * CGFloat(sin(kneeAngle * .pi / 360))
        let kneeOut = sqrt(max(0, leg * leg - (span / 2) * (span / 2)))
        let hipY = ankleY - span   // hips sink as the knees bend

        var points: [Joint: CGPoint] = [:]
        let hipL = 0.455 * W, hipR = 0.545 * W
        points[.leftAnkle] = CGPoint(x: hipL, y: ankleY)
        points[.rightAnkle] = CGPoint(x: hipR, y: ankleY)
        points[.leftKnee] = CGPoint(x: hipL - kneeOut, y: ankleY - span / 2)
        points[.rightKnee] = CGPoint(x: hipR + kneeOut, y: ankleY - span / 2)
        points[.leftHip] = CGPoint(x: hipL, y: hipY)
        points[.rightHip] = CGPoint(x: hipR, y: hipY)

        // Upper body sits on the hips.
        let shoulderY = hipY - 0.24 * H
        points[.leftShoulder] = CGPoint(x: 0.425 * W, y: shoulderY)
        points[.rightShoulder] = CGPoint(x: 0.575 * W, y: shoulderY)
        points[.neck] = CGPoint(x: 0.5 * W, y: shoulderY - 0.01 * H)
        points[.nose] = CGPoint(x: 0.5 * W, y: shoulderY - 0.09 * H)

        // Arms swing up through the sides, measured from the shoulder→hip line (like Buddy measures).
        let arm: CGFloat = 0.13 * H
        let r = CGFloat(shoulderAngle * .pi / 180)
        for (shoulder, hip, elbow, wrist, side) in [
            (Joint.leftShoulder, Joint.leftHip, Joint.leftElbow, Joint.leftWrist, CGFloat(1)),
            (.rightShoulder, .rightHip, .rightElbow, .rightWrist, -1),
        ] {
            let s = points[shoulder]!
            let h = points[hip]!
            let length = hypot(h.x - s.x, h.y - s.y)
            let down = CGPoint(x: (h.x - s.x) / length, y: (h.y - s.y) / length)
            let a = side * r   // turn outward from "down"
            let dir = CGPoint(x: down.x * cos(a) - down.y * sin(a), y: down.x * sin(a) + down.y * cos(a))
            points[elbow] = CGPoint(x: s.x + dir.x * arm / 2, y: s.y + dir.y * arm / 2)
            points[wrist] = CGPoint(x: s.x + dir.x * arm, y: s.y + dir.y * arm)
        }

        var joints: [Joint: TrackedJoint] = [:]
        for (joint, p) in points {
            joints[joint] = TrackedJoint(point: CGPoint(x: p.x / W, y: p.y / H), confidence: 0.9)
        }
        return PoseFrame(joints: joints, imageSize: imageSize)
    }
}
