import CoreGraphics
import Foundation

/// The body joints Buddy looks at.
nonisolated enum Joint: String, CaseIterable, Sendable {
    case nose, neck
    case leftShoulder, rightShoulder, leftElbow, rightElbow, leftWrist, rightWrist
    case leftHip, rightHip, leftKnee, rightKnee, leftAnkle, rightAnkle
}

/// One joint: where it is (0–1 across and down the image, top-left origin) and how sure Vision is.
nonisolated struct TrackedJoint: Sendable, Equatable {
    var point: CGPoint
    var confidence: Float
}

/// One camera frame's worth of body pose.
nonisolated struct PoseFrame: Sendable, Equatable {
    var joints: [Joint: TrackedJoint]
    /// Pixel size of the camera image, so angles aren't squashed by the tall picture.
    var imageSize: CGSize

    /// CLAUDE.md: ignore joints with confidence < 0.3.
    static let minConfidence: Float = 0.3

    func point(_ joint: Joint) -> CGPoint? {
        guard let j = joints[joint], j.confidence >= Self.minConfidence else { return nil }
        return j.point
    }

    /// Joint position in pixels (true proportions), for measuring angles.
    func pixel(_ joint: Joint) -> CGPoint? {
        point(joint).map { CGPoint(x: $0.x * imageSize.width, y: $0.y * imageSize.height) }
    }

    /// True when Buddy can see the kid head to toe (at least one of each pair of joints),
    /// which is what a propped-up phone needs before counting starts.
    var showsWholeBody: Bool {
        let pairs: [(Joint, Joint)] = [(.leftShoulder, .rightShoulder), (.leftWrist, .rightWrist),
                                       (.leftHip, .rightHip), (.leftKnee, .rightKnee), (.leftAnkle, .rightAnkle)]
        return pairs.allSatisfy { point($0.0) != nil || point($0.1) != nil }
    }

    /// Angle at `b` between a and c, in degrees, if all three joints are visible.
    func angle(_ a: Joint, _ b: Joint, _ c: Joint) -> Double? {
        guard let pa = pixel(a), let pb = pixel(b), let pc = pixel(c) else { return nil }
        return JointAngle.degrees(pa, pb, pc)
    }
}

extension ExerciseKind {
    /// The angle this exercise is measured by (CLAUDE.md), averaged over the sides Buddy can see.
    /// - Arm raises: at the shoulder, between hip, shoulder and wrist.
    /// - Mini squats: at the knee, between hip, knee and ankle.
    func angle(in frame: PoseFrame) -> Double? {
        let sides: [Double?]
        switch self {
        case .armRaises:
            sides = [frame.angle(.leftHip, .leftShoulder, .leftWrist),
                     frame.angle(.rightHip, .rightShoulder, .rightWrist)]
        case .miniSquats:
            sides = [frame.angle(.leftHip, .leftKnee, .leftAnkle),
                     frame.angle(.rightHip, .rightKnee, .rightAnkle)]
        }
        let seen = sides.compactMap { $0 }
        guard !seen.isEmpty else { return nil }
        return seen.reduce(0, +) / Double(seen.count)
    }

    /// How far into the move the angle is, 0 (resting) to 1 (target). Drives Buddy so he moves with the kid.
    func progress(for angle: Double) -> Double {
        switch self {
        case .armRaises: min(1, max(0, (angle - 40) / (150 - 40)))
        case .miniSquats: min(1, max(0, (160 - angle) / (160 - 120)))
        }
    }

    /// What Buddy says if he can't see the joints he needs.
    var stepBackCue: String {
        self == .armRaises ? "Step back so Buddy can see you." : "Step back so Buddy can see your knees."
    }

    /// Simple instructions shown and spoken during the demo.
    var howTo: String {
        switch self {
        case .armRaises: "Lift both arms up high over your head, then bring them down slowly."
        case .miniSquats: "Bend your knees a little like you're sitting down, then stand up tall."
        }
    }
}
