import CoreGraphics

/// Where Buddy is drawn on screen. Converts points on the 600 × 800 art canvas
/// (CHARACTER.md) to screen points, so screens can find his mouth, head and body.
struct BuddyFrame {
    /// The rectangle BuddyView fills (3:4).
    let rect: CGRect

    /// Buddy standing with his paws at `feet`, `height` points tall.
    init(feetAt feet: CGPoint, height: CGFloat) {
        let width = height * 0.75
        rect = CGRect(x: feet.x - width / 2, y: feet.y - height * (752.0 / 800), width: width, height: height)
    }

    func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: rect.minX + x / 600 * rect.width, y: rect.minY + y / 800 * rect.height)
    }

    func area(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
        CGRect(origin: point(x, y), size: CGSize(width: w / 600 * rect.width, height: h / 800 * rect.height))
    }

    var center: CGPoint { CGPoint(x: rect.midX, y: rect.midY) }
    var mouth: CGPoint { point(300, 315) }
    /// Generous "feed me" zone: his whole face.
    var head: CGRect { area(130, 100, 340, 290) }
    /// Head, body and legs (where soap does something).
    var body: CGRect { area(150, 100, 300, 660) }
}
