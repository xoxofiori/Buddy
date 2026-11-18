import CoreGraphics
import Foundation

/// Pose-tracking math.
nonisolated enum JointAngle {
    /// Angle in degrees at point `b`, between the lines b→a and b→c.
    /// e.g. knee angle = degrees(hip, knee, ankle).
    static func degrees(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> Double {
        let v1 = CGVector(dx: a.x - b.x, dy: a.y - b.y)
        let v2 = CGVector(dx: c.x - b.x, dy: c.y - b.y)
        let dot = v1.dx * v2.dx + v1.dy * v2.dy
        let lengths = hypot(v1.dx, v1.dy) * hypot(v2.dx, v2.dy)
        guard lengths > 0 else { return 0 }
        let cosine = Double(max(-1, min(1, dot / lengths)))
        return Foundation.acos(cosine) * 180 / Double.pi
    }
}
