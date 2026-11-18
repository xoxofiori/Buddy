import SwiftUI
import UIKit

/// Buddy's palette: "soft, sunny, never neon".
extension Color {
    static let sky      = Color(hex: 0x5DB6E8)
    static let sprout   = Color(hex: 0xB5DD7A)
    static let coral    = Color(hex: 0xE8765A)
    static let sunny    = Color(hex: 0xFFB547)
    static let lavender = Color(hex: 0xD9D2F2)
    static let cream    = Color(hex: 0xFFF6E5)
    static let paper    = Color(hex: 0xFFFDF8)
    static let deepTeal = Color(hex: 0x24403E)

    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// Chunky SF Rounded type sizes used across the app.
extension Font {
    static func buddy(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static let buddyTitle  = buddy(40, .heavy)
    static let buddyHeader = buddy(28, .bold)
    static let buddyBody   = buddy(20, .semibold)
    static let buddyButton = buddy(24, .heavy)
}

enum Theme {
    /// Smallest tap target for small hands.
    static let minTap: CGFloat = 60
    static let corner: CGFloat = 28
    static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
}

extension Color {
    /// Lighter (positive) or darker (negative) version of this color, -1...1.
    func shade(_ amount: Double) -> Color {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        let t = CGFloat(abs(amount))
        let target: CGFloat = amount > 0 ? 1 : 0
        return Color(red: r + (target - r) * t, green: g + (target - g) * t, blue: b + (target - b) * t, opacity: a)
    }
}

/// A faint speckle that makes flat shapes feel like printed paper.
struct PaperTexture: View {
    var opacity: Double = 0.05

    var body: some View {
        Canvas { ctx, size in
            var seed: UInt64 = 12345
            func next() -> CGFloat {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                return CGFloat(seed >> 33) / CGFloat(1 << 31)
            }
            let count = Int(size.width * size.height / 90)
            for _ in 0..<count {
                let rect = CGRect(x: next() * size.width, y: next() * size.height, width: 1.4, height: 1.4)
                ctx.fill(Path(ellipseIn: rect), with: .color(next() > 0.5 ? .black.opacity(opacity) : .white.opacity(opacity * 2)))
            }
        }
        .allowsHitTesting(false)
    }
}

/// Soft storybook card: warm paper, rounded, gentle shadow.
struct StoryCard<S: InsettableShape>: View {
    var shape: S
    var fill: Color = .paper

    var body: some View {
        shape
            .fill(fill)
            .overlay(PaperTexture(opacity: 0.035).clipShape(shape))
            .overlay(shape.strokeBorder(Color.deepTeal.opacity(0.06), lineWidth: 1))
            .shadow(color: .deepTeal.opacity(0.12), radius: 12, x: 0, y: 6)
    }
}

/// A cartoon dog bone.
struct BoneShape: Shape {
    nonisolated func path(in r: CGRect) -> Path {
        var p = Path()
        let knob = r.height * 0.5
        p.addRoundedRect(in: CGRect(x: r.minX + knob * 0.6, y: r.midY - r.height * 0.2,
                                    width: r.width - knob * 1.2, height: r.height * 0.4),
                         cornerSize: CGSize(width: 2, height: 2))
        for x in [r.minX, r.maxX - knob] {
            p.addEllipse(in: CGRect(x: x, y: r.minY, width: knob, height: knob))
            p.addEllipse(in: CGRect(x: x, y: r.maxY - knob, width: knob, height: knob))
        }
        return p
    }
}
