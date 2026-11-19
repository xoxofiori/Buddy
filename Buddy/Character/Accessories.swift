import SwiftUI

// Shop items Buddy can wear, drawn on the same 600 × 800 canvas as his art parts
// (CHARACTER.md) so they line up: hats on his head, glasses on his eyes, bandanas at his
// neck, toys on the ground by his feet. Buddy's own art is never changed.

extension EnvironmentValues {
    /// What Buddy is wearing. Set once near the top of the app; the Shop overrides it to try things on.
    @Entry var buddyOutfit: Outfit = .none
}

extension ShopItem {
    /// Where the item sits on the 600 × 800 art canvas (used to make shop thumbnails).
    var artBounds: CGRect {
        switch category {
        case .hats:
            switch self {
            case .partyHat: CGRect(x: 225, y: 0, width: 160, height: 140)
            case .cap: CGRect(x: 175, y: 45, width: 320, height: 110)
            case .beanie: CGRect(x: 160, y: 10, width: 280, height: 150)
            default: CGRect(x: 215, y: 35, width: 170, height: 100)
            }
        case .glasses: CGRect(x: 145, y: 130, width: 310, height: 140)
        case .bandanas: CGRect(x: 215, y: 380, width: 170, height: 105)
        case .toys: CGRect(x: 75, y: 640, width: 130, height: 125)
        }
    }
}

/// One item, drawn in place on the 600 × 800 canvas.
struct AccessoryArt: View {
    let item: ShopItem

    var body: some View {
        ZStack(alignment: .topLeading) {
            art
        }
        .frame(width: 600, height: 800, alignment: .topLeading)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var art: some View {
        switch item {
        // MARK: Hats
        case .partyHat:
            ConeShape()
                .fill(LinearGradient(colors: [Color.coral.shade(0.15), Color.coral.shade(-0.1)], startPoint: .leading, endPoint: .trailing))
                .overlay(
                    ZStack {
                        ForEach(0..<5) { i in
                            Circle().fill(Color.sunny).frame(width: 14)
                                .position(x: [62, 92, 50, 80, 70][i], y: [110, 80, 70, 40, 100][i] - 0)
                        }
                    }
                    .clipShape(ConeShape())
                )
                .frame(width: 140, height: 125)
                .position(x: 305, y: 70)
                .shadow(color: .black.opacity(0.12), radius: 0, x: 0, y: 3)
            Capsule().fill(Color.paper).frame(width: 150, height: 18).position(x: 305, y: 128)
            Circle().fill(Color.sunny).frame(width: 34).position(x: 305, y: 10)
        case .cap:
            Ellipse()
                .fill(Color.sky.shade(-0.2))
                .frame(width: 180, height: 34)
                .rotationEffect(.degrees(6))
                .position(x: 405, y: 132)
            DomeShape()
                .fill(LinearGradient(colors: [Color.sky.shade(0.2), Color.sky.shade(-0.05)], startPoint: .top, endPoint: .bottom))
                .overlay(Rectangle().fill(Color.sky.shade(-0.25)).frame(width: 4).padding(.top, 6))
                .frame(width: 240, height: 86)
                .position(x: 300, y: 92)
                .shadow(color: .black.opacity(0.12), radius: 0, x: 0, y: 3)
            Circle().fill(Color.sky.shade(-0.25)).frame(width: 16).position(x: 300, y: 52)
        case .beanie:
            DomeShape()
                .fill(LinearGradient(colors: [Color(hex: 0xB3A8E6), Color(hex: 0x9184D2)], startPoint: .top, endPoint: .bottom))
                .frame(width: 270, height: 112)
                .position(x: 300, y: 82)
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: 0x8274C8))
                .overlay(
                    HStack(spacing: 10) {
                        ForEach(0..<13) { _ in Capsule().fill(.white.opacity(0.25)).frame(width: 5) }
                    }
                    .padding(.vertical, 6)
                )
                .frame(width: 280, height: 38)
                .position(x: 300, y: 138)
                .shadow(color: .black.opacity(0.12), radius: 0, x: 0, y: 3)
            Circle()
                .fill(Color.paper)
                .overlay(Circle().strokeBorder(Color(hex: 0xB3A8E6), lineWidth: 4))
                .frame(width: 52)
                .position(x: 300, y: 30)
        case .crown:
            CrownShape()
                .fill(LinearGradient(colors: [Color(hex: 0xFFE08A), Color.sunny.shade(-0.1)], startPoint: .top, endPoint: .bottom))
                .overlay(CrownShape().stroke(Color.sunny.shade(-0.35), lineWidth: 3))
                .frame(width: 160, height: 84)
                .position(x: 300, y: 84)
                .shadow(color: .black.opacity(0.12), radius: 0, x: 0, y: 3)
            ForEach(0..<3) { i in
                Circle().fill([Color.coral, Color.sky, Color.coral][i]).frame(width: 16)
                    .position(x: 255 + CGFloat(i) * 45, y: 110)
            }

        // MARK: Glasses
        case .roundGlasses:
            glassesFrames(color: .deepTeal, lens: Color.white.opacity(0.18)) { Circle() }
        case .heartGlasses:
            glassesFrames(color: .coral, lens: Color.coral.opacity(0.25)) { HeartShape() }
        case .starSunglasses:
            glassesFrames(color: .sunny, lens: Color.deepTeal.opacity(0.75), size: 130) { StarShape() }

        // MARK: Bandanas
        case .redBandana:
            bandana(color: .coral) {
                ForEach(0..<10) { i in
                    Circle().fill(Color.paper).frame(width: 11)
                        .position(x: 20 + CGFloat(i % 5) * 32, y: 18 + CGFloat(i / 5) * 32 + CGFloat(i % 2) * 6)
                }
            }
        case .skyBandana:
            bandana(color: .sky) {
                ForEach(0..<6) { i in
                    Rectangle().fill(Color.paper.opacity(0.85)).frame(width: 9, height: 200)
                        .rotationEffect(.degrees(35))
                        .position(x: CGFloat(i) * 34, y: 50)
                }
            }
        case .starBandana:
            bandana(color: Color.sprout.shade(-0.15)) {
                ForEach(0..<4) { i in
                    StarShape().fill(Color.sunny).frame(width: 24, height: 24)
                        .position(x: [40, 85, 130, 85][i], y: [20, 30, 20, 62][i])
                }
            }

        // MARK: Toys (on the ground by his feet)
        case .tennisBall:
            Circle()
                .fill(RadialGradient(colors: [Color(hex: 0xEDF58A), Color(hex: 0xC5D83A)], center: UnitPoint(x: 0.35, y: 0.3), startRadius: 2, endRadius: 50))
                .overlay(
                    ZStack {
                        Circle().stroke(.white, lineWidth: 5).frame(width: 70).offset(x: -40)
                        Circle().stroke(.white, lineWidth: 5).frame(width: 70).offset(x: 40)
                    }
                    .clipShape(Circle())
                )
                .frame(width: 80, height: 80)
                .position(x: 140, y: 712)
                .shadow(color: .black.opacity(0.15), radius: 0, x: 0, y: 4)
        case .squeakyBone:
            BoneShape()
                .fill(LinearGradient(colors: [Color.paper, Color(hex: 0xEBD3A6)], startPoint: .top, endPoint: .bottom))
                .overlay(BoneShape().stroke(Color(hex: 0xC9A46A), lineWidth: 3))
                .frame(width: 118, height: 50)
                .rotationEffect(.degrees(-14))
                .position(x: 140, y: 724)
                .shadow(color: .black.opacity(0.15), radius: 0, x: 0, y: 4)
        case .frisbee:
            Ellipse()
                .fill(Color.coral)
                .overlay(Ellipse().strokeBorder(Color.coral.shade(0.35), lineWidth: 6).padding(10))
                .frame(width: 124, height: 44)
                .position(x: 140, y: 734)
                .shadow(color: .black.opacity(0.15), radius: 0, x: 0, y: 4)
        case .rubberDuck:
            Text("🐥").font(.system(size: 92)).position(x: 140, y: 708)
        case .teddy:
            Text("🧸").font(.system(size: 104)).position(x: 136, y: 696)
        }
    }

    /// Two frames around his eyes (centers 246, 198 and 354, 198) joined by a bridge.
    private func glassesFrames<S: Shape>(color: Color, lens: Color, size: CGFloat = 112,
                                         shape: () -> S) -> some View {
        let frame = shape()
        return ZStack(alignment: .topLeading) {
            ForEach([246.0, 354.0], id: \.self) { x in
                frame.fill(lens)
                    .overlay(frame.stroke(color, lineWidth: 9))
                    .frame(width: size, height: size * 0.92)
                    .position(x: x, y: 200)
            }
            BridgeShape()
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 28, height: 14)
                .position(x: 300, y: 190)
        }
        .frame(width: 600, height: 800, alignment: .topLeading)
        .shadow(color: .black.opacity(0.12), radius: 0, x: 0, y: 3)
    }

    /// A triangle bandana tied at his neck, with a pattern.
    private func bandana<P: View>(color: Color, @ViewBuilder pattern: () -> P) -> some View {
        BandanaShape()
            .fill(color)
            .overlay(ZStack(alignment: .topLeading) { pattern() }.frame(width: 160, height: 92, alignment: .topLeading).clipShape(BandanaShape()))
            .frame(width: 160, height: 92)
            .position(x: 300, y: 432)
            .shadow(color: .black.opacity(0.13), radius: 0, x: 0, y: 3)
    }
}

/// Buddy's shop item drawn small, cropped to just the item (for shop cards).
struct AccessoryThumbnail: View {
    let item: ShopItem

    var body: some View {
        GeometryReader { geo in
            let b = item.artBounds
            let scale = min(geo.size.width / b.width, geo.size.height / b.height)
            AccessoryArt(item: item)
                .scaleEffect(scale, anchor: .topLeading)
                .offset(x: -b.minX * scale + (geo.size.width - b.width * scale) / 2,
                        y: -b.minY * scale + (geo.size.height - b.height * scale) / 2)
        }
        .accessibilityHidden(true)
    }
}

// MARK: Shapes

private struct ConeShape: Shape {
    nonisolated func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY), control: CGPoint(x: r.midX, y: r.maxY + 10))
        p.closeSubpath()
        return p
    }
}

private struct DomeShape: Shape {
    nonisolated func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addCurve(to: CGPoint(x: r.maxX, y: r.maxY),
                   control1: CGPoint(x: r.minX, y: r.minY - r.height * 0.25),
                   control2: CGPoint(x: r.maxX, y: r.minY - r.height * 0.25))
        p.closeSubpath()
        return p
    }
}

private struct CrownShape: Shape {
    nonisolated func path(in r: CGRect) -> Path {
        var p = Path()
        let points = 5
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.15))
        for i in 0..<points {
            let x1 = r.minX + r.width * (CGFloat(i) + 0.5) / CGFloat(points)
            let x2 = r.minX + r.width * CGFloat(i + 1) / CGFloat(points)
            p.addLine(to: CGPoint(x: x1, y: r.minY + r.height * 0.55))
            p.addLine(to: CGPoint(x: x2, y: r.minY + (i == points - 1 ? r.height * 0.15 : 0)))
        }
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

struct StarShape: Shape {
    nonisolated func path(in r: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: r.midX, y: r.midY)
        let outer = min(r.width, r.height) / 2
        let inner = outer * 0.48
        for i in 0..<10 {
            let radius = i.isMultiple(of: 2) ? outer : inner
            let angle = Double(i) * .pi / 5 - .pi / 2
            let point = CGPoint(x: c.x + CGFloat(cos(angle)) * radius, y: c.y + CGFloat(sin(angle)) * radius)
            if i == 0 { p.move(to: point) } else { p.addLine(to: point) }
        }
        p.closeSubpath()
        return p
    }
}

private struct BridgeShape: Shape {
    nonisolated func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY), control: CGPoint(x: r.midX, y: r.minY))
        return p
    }
}

private struct BandanaShape: Shape {
    nonisolated func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.maxY), control: CGPoint(x: r.maxX - r.width * 0.15, y: r.maxY * 0.7))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY), control: CGPoint(x: r.minX + r.width * 0.15, y: r.maxY * 0.7))
        p.closeSubpath()
        return p
    }
}
