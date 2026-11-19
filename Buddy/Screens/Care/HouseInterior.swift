import SwiftUI

/// Buddy's house, inside: a striped wall, a curtained window letting sun in, a framed picture,
/// a plant, a wooden floor in perspective, a rug under Buddy and a ball. Used for Snack time.
struct HouseInterior: View {
    /// Where the floor starts, as a fraction of the height.
    var floorTop: CGFloat = 0.52
    /// Where the rug sits (Buddy's feet), as a fraction of the height.
    var rugAt: CGFloat = 0.7

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let floorY = h * floorTop
            let floorH = h - floorY
            let windowCenter = CGPoint(x: w * 0.2, y: floorY - w * 0.3)

            ZStack(alignment: .topLeading) {
                // Wall, a touch warmer toward the floor
                LinearGradient(colors: [Color(hex: 0xFFF9EF), Color(hex: 0xF6E4C8)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: floorY)
                HStack(spacing: 0) {
                    ForEach(0..<14) { i in
                        Rectangle().fill(i.isMultiple(of: 2) ? Color.lavender.opacity(0.16) : .clear)
                    }
                }
                .frame(height: floorY)

                // Sunlight glowing around the window
                RadialGradient(colors: [.white.opacity(0.7), .white.opacity(0)],
                               center: .center, startRadius: 10, endRadius: w * 0.45)
                    .frame(width: w * 0.9, height: w * 0.9)
                    .position(windowCenter)

                RoomWindow()
                    .frame(width: w * 0.42, height: w * 0.38)
                    .position(windowCenter)

                PictureFrame()
                    .frame(width: w * 0.17, height: w * 0.21)
                    .position(x: w * 0.8, y: floorY - w * 0.42)

                // Floor
                WoodFloor()
                    .frame(width: w, height: floorH)
                    .clipped()
                    .offset(y: floorY)

                // Shadow where wall meets floor, then the baseboard
                LinearGradient(colors: [.black.opacity(0.14), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 26)
                    .offset(y: floorY + 8)
                LinearGradient(colors: [Color.paper, Color(hex: 0xEADFCF)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 12)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                    .offset(y: floorY - 2)

                // Patch of sunlight on the floor
                SunPatch()
                    .fill(.white.opacity(0.22))
                    .frame(width: w * 0.45, height: floorH * 0.32)
                    .blur(radius: 10)
                    .position(x: w * 0.3, y: floorY + floorH * 0.2)

                // Rug under Buddy's feet
                Ellipse()
                    .fill(RadialGradient(colors: [Color.coral.shade(0.35), Color.coral.shade(0.15)],
                                         center: .center, startRadius: 5, endRadius: w * 0.4))
                    .overlay(Ellipse().stroke(Color.coral.shade(-0.05).opacity(0.6),
                                              style: StrokeStyle(lineWidth: 3, dash: [8, 6])).padding(10))
                    .overlay(Ellipse().strokeBorder(Color.coral.shade(-0.1), lineWidth: 5))
                    .frame(width: w * 0.82, height: w * 0.2)
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 3)
                    .position(x: w / 2, y: h * rugAt)

                PottedPlant()
                    .frame(width: w * 0.2, height: w * 0.36)
                    .position(x: w * 0.89, y: floorY - w * 0.02)

                Ball()
                    .frame(width: 32, height: 32)
                    .position(x: w * 0.13, y: floorY + floorH * 0.32)

                // Gentle darkening at the edges, like a real photo
                RadialGradient(colors: [.clear, .black.opacity(0.14)],
                               center: .center, startRadius: h * 0.3, endRadius: h * 0.75)
                    .allowsHitTesting(false)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Wooden planks that narrow toward the back wall.
private struct WoodFloor: View {
    var body: some View {
        Canvas { ctx, size in
            let rect = CGRect(origin: .zero, size: size)
            ctx.clip(to: Path(rect))
            ctx.fill(Path(rect), with: .linearGradient(
                Gradient(colors: [Color(hex: 0xD9A866), Color(hex: 0xEDC88E), Color(hex: 0xF4D49E)]),
                startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: size.height)))

            let vanish = CGPoint(x: size.width / 2, y: -size.height * 1.4)
            let seam = Color(hex: 0xC99556).opacity(0.55)
            for i in -9...9 {
                let bottom = CGPoint(x: size.width / 2 + CGFloat(i) * size.width / 6.5, y: size.height)
                var p = Path()
                p.move(to: bottom)
                p.addLine(to: vanish)
                ctx.stroke(p, with: .color(seam), lineWidth: 1.5)
            }
            // Cross seams get further apart toward the front
            for k in 1...6 {
                let y = size.height * pow(Double(k) / 6.5, 1.5)
                for lane in stride(from: -8, through: 8, by: 2) {
                    let laneShift = (k % 2 == 0) ? 1 : 0
                    let t = y / size.height
                    let spread = size.width / 6.5 * (0.42 + 0.58 * t)
                    let x = size.width / 2 + CGFloat(lane + laneShift) * spread
                    var p = Path()
                    p.move(to: CGPoint(x: x, y: y))
                    p.addLine(to: CGPoint(x: x + spread, y: y))
                    ctx.stroke(p, with: .color(seam.opacity(0.7)), lineWidth: 1.2)
                }
            }
        }
    }
}

private struct SunPatch: Shape {
    nonisolated func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX + r.width * 0.2, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - r.width * 0.15, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

private struct RoomWindow: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let glassW = w * 0.62
            let glassH = h * 0.78

            ZStack {
                // Glass: sky, sun, clouds and distant hills
                ZStack {
                    LinearGradient(colors: [Color.sky.shade(-0.05), Color.sky.shade(0.45)],
                                   startPoint: .top, endPoint: .bottom)
                    Circle().fill(RadialGradient(colors: [.white, Color.sunny.shade(0.5).opacity(0)],
                                                 center: .center, startRadius: 2, endRadius: 30))
                        .frame(width: 60).offset(x: glassW * 0.22, y: -glassH * 0.22)
                    Ellipse().fill(Color.sprout.shade(-0.1)).frame(width: glassW * 1.2, height: glassH * 0.5)
                        .offset(x: -glassW * 0.2, y: glassH * 0.42)
                    Ellipse().fill(Color.sprout).frame(width: glassW * 1.1, height: glassH * 0.45)
                        .offset(x: glassW * 0.3, y: glassH * 0.47)
                    HStack(spacing: -10) {
                        Circle().frame(width: 20)
                        Circle().frame(width: 28).offset(y: -5)
                        Circle().frame(width: 20)
                    }
                    .foregroundStyle(.white.opacity(0.95))
                    .offset(x: -glassW * 0.15, y: -glassH * 0.12)
                    // window bars
                    Rectangle().fill(Color.paper).frame(width: 5)
                    Rectangle().fill(Color.paper).frame(height: 5)
                    // reflection
                    LinearGradient(colors: [.white.opacity(0.35), .clear, .white.opacity(0.15), .clear],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                }
                .frame(width: glassW, height: glassH)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(7)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: [Color.paper, Color(hex: 0xE9DCC8)], startPoint: .top, endPoint: .bottom))
                        .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 4)
                )
                .offset(y: h * 0.04)

                // Sill
                RoundedRectangle(cornerRadius: 3)
                    .fill(LinearGradient(colors: [Color.paper, Color(hex: 0xE2D3BC)], startPoint: .top, endPoint: .bottom))
                    .frame(width: glassW + 34, height: 9)
                    .shadow(color: .black.opacity(0.18), radius: 3, x: 0, y: 3)
                    .offset(y: h * 0.04 + glassH / 2 + 10)

                // Curtains
                HStack {
                    Curtain().frame(width: w * 0.2)
                    Spacer()
                    Curtain().frame(width: w * 0.2).scaleEffect(x: -1)
                }
                .frame(height: h * 0.98)
                .offset(y: h * 0.02)

                // Rod
                Capsule()
                    .fill(LinearGradient(colors: [Color.deepTeal.shade(0.3), .deepTeal], startPoint: .top, endPoint: .bottom))
                    .frame(width: w, height: 6)
                    .offset(y: -h / 2 + 4)
            }
        }
    }
}

private struct Curtain: View {
    var body: some View {
        CurtainShape()
            .fill(LinearGradient(
                stops: [.init(color: Color.lavender.shade(-0.12), location: 0),
                        .init(color: Color.lavender.shade(0.2), location: 0.25),
                        .init(color: Color.lavender.shade(-0.1), location: 0.5),
                        .init(color: Color.lavender.shade(0.2), location: 0.75),
                        .init(color: Color.lavender.shade(-0.15), location: 1)],
                startPoint: .leading, endPoint: .trailing))
            .shadow(color: .black.opacity(0.15), radius: 4, x: 2, y: 3)
    }
}

/// Hangs straight, then gathers in toward the bottom like a tied-back curtain.
private struct CurtainShape: Shape {
    nonisolated func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.minX + r.width * 0.45, y: r.minY + r.height * 0.62),
                       control: CGPoint(x: r.maxX, y: r.minY + r.height * 0.45))
        p.addQuadCurve(to: CGPoint(x: r.maxX * 0.85, y: r.maxY),
                       control: CGPoint(x: r.minX + r.width * 0.3, y: r.minY + r.height * 0.8))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

private struct PictureFrame: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(LinearGradient(colors: [Color.sunny.shade(0.2), Color.sunny.shade(-0.2)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.paper)
                .padding(8)
                .shadow(color: .black.opacity(0.2), radius: 1.5, x: 0, y: 1)
            Image(systemName: "pawprint.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color.coral.opacity(0.85))
        }
        .rotationEffect(.degrees(2))
        .shadow(color: .black.opacity(0.2), radius: 5, x: 2, y: 5)
    }
}

private struct PottedPlant: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack(alignment: .bottom) {
                // Leaves
                ForEach(0..<7) { i in
                    let angle = -60.0 + Double(i) * 20
                    Ellipse()
                        .fill(LinearGradient(colors: [Color.sprout.shade(-0.05), Color.sprout.shade(-0.35)],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(width: w * 0.24, height: h * 0.5)
                        .offset(y: -h * 0.25)
                        .rotationEffect(.degrees(angle), anchor: .bottom)
                        .offset(y: -h * 0.36)
                }
                // Pot
                PotShape()
                    .fill(LinearGradient(colors: [Color.coral.shade(-0.15), Color.coral.shade(0.15), Color.coral.shade(-0.2)],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: w * 0.62, height: h * 0.38)
                    .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
            }
            .frame(width: w, height: h, alignment: .bottom)
        }
    }
}

private struct PotShape: Shape {
    nonisolated func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - r.width * 0.12, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.12, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

private struct Ball: View {
    var body: some View {
        ZStack {
            Ellipse().fill(.black.opacity(0.22)).frame(width: 30, height: 8).blur(radius: 2).offset(y: 15)
            Circle()
                .fill(RadialGradient(colors: [Color.sky.shade(0.5), .sky, Color.sky.shade(-0.3)],
                                     center: UnitPoint(x: 0.35, y: 0.3), startRadius: 1, endRadius: 20))
                .overlay(Capsule().fill(.white.opacity(0.85)).frame(height: 5).rotationEffect(.degrees(-15)))
                .clipShape(Circle())
        }
    }
}
