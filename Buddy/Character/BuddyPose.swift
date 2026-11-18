import SwiftUI

/// Buddy's poses, matching BuddyCharacter/buddy_pose_sheet.png and CHARACTER.md.
/// `eating` and `happy` are extra poses for the care rooms, made only from the same art parts.
enum BuddyPose: String, Codable, CaseIterable {
    case idle, talking, waving, armRaise, sleeping, needsCare, squat, eating, happy
}

/// Which eyes / brows / mouth art to show. Raw values are the asset names.
enum BuddyEyes: String { case open = "buddy_eyes_open", happy = "buddy_eyes_happy", closed = "buddy_eyes_closed" }
enum BuddyBrows: String { case normal = "buddy_brows", worried = "buddy_brows_worried" }
enum BuddyMouth: String { case smile = "buddy_mouth_smile", open = "buddy_mouth_open", o = "buddy_mouth_o" }

/// One row of the pose table in CHARACTER.md. Angles are degrees, positive = clockwise.
struct BuddyPoseSpec {
    var eyes: BuddyEyes
    var brows: BuddyBrows
    var mouth: BuddyMouth
    var armLeft: Double
    var armRight: Double
    var head: Double
    var earLeft: Double
    var earRight: Double
    var tail: Double
}

extension BuddyPose {
    var spec: BuddyPoseSpec {
        switch self {
        case .idle:
            BuddyPoseSpec(eyes: .open, brows: .normal, mouth: .smile,
                          armLeft: 6, armRight: -6, head: 0, earLeft: 0, earRight: 0, tail: 0)
        case .talking:   // mouth alternates open ↔ smile every 0.12 s (see BuddyView)
            BuddyPoseSpec(eyes: .open, brows: .normal, mouth: .smile,
                          armLeft: 6, armRight: -6, head: -6, earLeft: -6, earRight: 4, tail: -12)
        case .waving:    // right arm wiggles ±12°
            BuddyPoseSpec(eyes: .happy, brows: .normal, mouth: .open,
                          armLeft: 6, armRight: -128, head: 5, earLeft: 0, earRight: 0, tail: 10)
        case .armRaise:  // arms animate 6 → 118 / −6 → −118
            BuddyPoseSpec(eyes: .happy, brows: .normal, mouth: .open,
                          armLeft: 6, armRight: -6, head: 0, earLeft: 0, earRight: 0, tail: -10)
        case .sleeping:
            BuddyPoseSpec(eyes: .closed, brows: .normal, mouth: .o,
                          armLeft: 6, armRight: -6, head: 10, earLeft: 10, earRight: -10, tail: 0)
        case .needsCare:
            BuddyPoseSpec(eyes: .open, brows: .worried, mouth: .o,
                          armLeft: 6, armRight: -6, head: -4, earLeft: 0, earRight: 0, tail: 0)
        case .squat:     // whole character down 40, legs squashed to 0.75 at the feet
            BuddyPoseSpec(eyes: .open, brows: .normal, mouth: .open,
                          armLeft: 40, armRight: -40, head: 0, earLeft: 0, earRight: 0, tail: 0)
        case .eating:    // mouth chomps open ↔ o every 0.15 s, head bobs (see BuddyView)
            BuddyPoseSpec(eyes: .happy, brows: .normal, mouth: .open,
                          armLeft: 6, armRight: -6, head: 0, earLeft: 4, earRight: -4, tail: 10)
        case .happy:
            BuddyPoseSpec(eyes: .happy, brows: .normal, mouth: .open,
                          armLeft: 6, armRight: -6, head: 5, earLeft: -4, earRight: 4, tail: 10)
        }
    }

    /// Happy poses wag the tail fast.
    var isHappy: Bool { spec.eyes == .happy }
}

/// Pivot points on the 600 × 800 art canvas (CHARACTER.md), as rotation anchors.
enum BuddyPivot {
    static let neck = UnitPoint(x: 300.0 / 600, y: 372.0 / 800)
    static let earLeft = UnitPoint(x: 190.0 / 600, y: 138.0 / 800)
    static let earRight = UnitPoint(x: 410.0 / 600, y: 138.0 / 800)
    static let shoulderLeft = UnitPoint(x: 226.0 / 600, y: 428.0 / 800)
    static let shoulderRight = UnitPoint(x: 374.0 / 600, y: 428.0 / 800)
    static let tailBase = UnitPoint(x: 378.0 / 600, y: 562.0 / 800)
    /// Bottom of the paws: legs squash and the whole body bounces from here.
    static let feet = UnitPoint(x: 0.5, y: 752.0 / 800)
    /// Bottom of the body: breathing grows upward from here.
    static let bodyBase = UnitPoint(x: 0.5, y: 648.0 / 800)
    /// Area around the collar tag (art pixels), so taps there reach the tag.
    static let collarTag = CGRect(x: 230, y: 380, width: 140, height: 130)
}

/// Where Buddy can be touched: his head and his body + legs (from the 600 × 800 art),
/// so taps beside him reach whatever is behind.
struct BuddyTouchShape: Shape {
    nonisolated func path(in r: CGRect) -> Path {
        func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
            CGRect(x: r.minX + x / 600 * r.width, y: r.minY + y / 800 * r.height,
                   width: w / 600 * r.width, height: h / 800 * r.height)
        }
        var p = Path()
        p.addEllipse(in: rect(120, 80, 360, 310))                                   // head and ears
        p.addRoundedRect(in: rect(170, 370, 260, 390), cornerSize: CGSize(width: 40, height: 40))  // body, arms, legs
        return p
    }
}

/// Things that happen when a kid touches Buddy, reported to the screen that shows him.
enum BuddyInteraction {
    case tapHead, tapBelly
    /// Tapped what he's wearing at the neck (the collar tag).
    case tapCollar
    /// Dragging across him; `distance` is how far the finger moved since the last report.
    case petting(at: CGPoint, distance: CGFloat)
    case petEnded
}
