import SwiftUI

/// Buddy's Backyard: one cozy storybook scene. Care happens by tapping things in it:
/// the bowl (feed), the pool (bath), the doghouse (nap), the toy box (shop), and the
/// garden path through the arch (Recovery Trail).
struct BackyardScene: View {
    let time: TimeOfDay
    let needs: Needs
    var onTap: (CareSpot) -> Void

    @State private var taps = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let horizon = h * 0.565

            ZStack(alignment: .topLeading) {
                // Sky
                LinearGradient(colors: [time.skyTop, time.skyBottom], startPoint: .top, endPoint: .bottom)
                    .frame(height: horizon + 20)

                if time == .night {
                    Stars().frame(width: w, height: horizon)
                }

                SunOrMoon(time: time)
                    .position(sunPosition(w: w, h: h))

                if time != .night {
                    Cloud(tint: time == .sunset ? Color(hex: 0xFFE2D2) : .white)
                        .frame(width: w * 0.3, height: w * 0.12)
                        .position(x: w * 0.3, y: h * 0.43)
                    Cloud(tint: time == .sunset ? Color(hex: 0xFFE2D2) : .white)
                        .frame(width: w * 0.22, height: w * 0.09)
                        .position(x: w * 0.7, y: h * 0.4)
                }

                // Rolling hills (paper-cut layers)
                Ellipse()
                    .fill(Color.sprout.shade(-0.28))
                    .frame(width: w * 1.3, height: h * 0.2)
                    .position(x: w * 0.2, y: horizon + h * 0.01)
                    .cutout()
                Ellipse()
                    .fill(Color.sprout.shade(-0.16))
                    .frame(width: w * 1.2, height: h * 0.17)
                    .position(x: w * 0.92, y: horizon + h * 0.015)
                    .cutout()

                // Lawn
                LinearGradient(colors: [Color.sprout.shade(0.08), Color.sprout.shade(-0.12)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: h - horizon)
                    .offset(y: horizon)

                Fence(gateFrom: 0.6, gateTo: 0.76)
                    .frame(width: w, height: h * 0.075)
                    .position(x: w / 2, y: horizon - h * 0.006)

                GardenPath()
                    .fill(Color(hex: 0xF3DDB3))
                    .overlay(GardenPath().stroke(Color(hex: 0xE2C38E), lineWidth: 2))
                    .frame(width: w, height: h - horizon)
                    .offset(y: horizon)
                SteppingStones()
                    .frame(width: w, height: h - horizon)
                    .offset(y: horizon)

                Flowers()
                    .frame(width: w, height: h - horizon)
                    .offset(y: horizon)

                // Arch over the path: tap to visit the Recovery Trail
                spot(.trail) {
                    TrailArch().frame(width: w * 0.2, height: w * 0.2)
                }
                .position(x: w * 0.68, y: horizon - w * 0.07)

                spot(.doghouse) {
                    Doghouse(night: time == .night).frame(width: w * 0.34, height: w * 0.3)
                }
                .position(x: w * 0.18, y: horizon + w * 0.04)

                spot(.toyBox) {
                    ToyBox().frame(width: w * 0.22, height: w * 0.18)
                }
                .position(x: w * 0.87, y: horizon + w * 0.12)

                spot(.bowl) {
                    FoodBowl().frame(width: w * 0.22, height: w * 0.12)
                }
                .position(x: w * 0.15, y: h * 0.885)

                spot(.pool) {
                    KiddiePool().frame(width: w * 0.36, height: w * 0.15)
                }
                .position(x: w * 0.8, y: h * 0.88)

                PaperTexture()
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: taps)
    }

    private func sunPosition(w: CGFloat, h: CGFloat) -> CGPoint {
        switch time {
        case .morning: CGPoint(x: w * 0.14, y: h * 0.47)
        case .day: CGPoint(x: w * 0.86, y: h * 0.42)
        case .sunset: CGPoint(x: w * 0.82, y: h * 0.53)
        case .night: CGPoint(x: w * 0.85, y: h * 0.42)
        }
    }

    /// A tappable thing in the yard. It bobs gently when the need it looks after is low.
    private func spot<Content: View>(_ spot: CareSpot, @ViewBuilder content: () -> Content) -> some View {
        let low = (spot.need(in: needs) ?? 1) < 0.3
        return Button {
            taps += 1
            onTap(spot)
        } label: {
            content()
                .overlay(alignment: .top) {
                    SpotBadge(icon: spot.icon, color: spot.color, needsCare: low)
                        .alignmentGuide(.top) { $0[.bottom] + 4 }
                }
                .modifier(Bob(active: low))
                .frame(minWidth: Theme.minTap, minHeight: Theme.minTap)
                .contentShape(Rectangle())
        }
        .buttonStyle(SquishStyle())
        .accessibilityLabel(spot.title)
    }
}

// MARK: Little helpers

private extension View {
    /// Paper-cut look: a crisp shadow just under the shape.
    func cutout(_ depth: CGFloat = 3) -> some View {
        shadow(color: .black.opacity(0.13), radius: 0, x: 0, y: depth)
    }
}

/// Gentle up-and-down bob that says "Buddy needs this!".
private struct Bob: ViewModifier {
    var active: Bool

    func body(content: Content) -> some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: !active)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            content
                .offset(y: active ? -abs(sin(t * 3)) * 6 : 0)
        }
    }
}

/// A round paper badge with an icon, floating above a yard object so kids know they can
/// tap it. It drifts gently all the time; when Buddy needs this thing, it glows and sparkles.
private struct SpotBadge: View {
    let icon: String
    let color: Color
    let needsCare: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            VStack(spacing: -3) {
                ZStack {
                    if needsCare {
                        Circle()
                            .fill(color.opacity(0.35))
                            .frame(width: 54, height: 54)
                            .scaleEffect(1 + 0.15 * sin(t * 4))
                    }
                    Circle()
                        .fill(Color.paper)
                        .overlay(Circle().strokeBorder(color, lineWidth: 3))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(color)
                }
                Triangle()
                    .fill(color)
                    .frame(width: 12, height: 7)
            }
            .overlay(alignment: .topTrailing) {
                if needsCare {
                    Image(systemName: "sparkle")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.sunny)
                        .opacity(0.6 + 0.4 * sin(t * 4))
                        .offset(x: 8, y: -6)
                }
            }
            .shadow(color: .black.opacity(0.13), radius: 0, x: 0, y: 2)
            .offset(y: sin(t * 1.8) * 3)
        }
        .accessibilityHidden(true)
    }
}

private struct Triangle: Shape {
    nonisolated func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: Sky

private struct SunOrMoon: View {
    let time: TimeOfDay

    var body: some View {
        switch time {
        case .night:
            ZStack {
                Circle().fill(Color(hex: 0xFFF3C4).opacity(0.25)).frame(width: 80).blur(radius: 10)
                Circle().fill(Color(hex: 0xFFF3C4)).frame(width: 40)
                    .mask(
                        Circle().frame(width: 40)
                            .overlay(Circle().frame(width: 36).offset(x: 12, y: -6).blendMode(.destinationOut))
                            .compositingGroup()
                    )
            }
        case .sunset:
            ZStack {
                Circle().fill(Color.sunny.opacity(0.35)).frame(width: 120).blur(radius: 16)
                Circle().fill(LinearGradient(colors: [Color(hex: 0xFFD27A), .coral], startPoint: .top, endPoint: .bottom))
                    .frame(width: 58)
            }
        default:
            ZStack {
                Circle().fill(Color.sunny.opacity(0.3)).frame(width: 100).blur(radius: 14)
                Circle().fill(LinearGradient(colors: [Color(hex: 0xFFE79A), .sunny], startPoint: .top, endPoint: .bottom))
                    .frame(width: 46)
            }
        }
    }
}

private struct Cloud: View {
    var tint: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack(alignment: .bottom) {
                Capsule().frame(width: w, height: h * 0.55)
                Circle().frame(width: h * 0.85).offset(x: -w * 0.18, y: -h * 0.18)
                Circle().frame(width: h).offset(x: w * 0.1, y: -h * 0.25)
            }
            .foregroundStyle(tint.opacity(0.92))
            .frame(width: w, height: h, alignment: .bottom)
            .shadow(color: .black.opacity(0.06), radius: 0, x: 0, y: 2)
        }
    }
}

/// Twinkling stars for night time.
private struct Stars: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 20)) { ctx in
            Canvas { gc, size in
                let t = ctx.date.timeIntervalSinceReferenceDate
                var seed: UInt64 = 99
                func next() -> CGFloat {
                    seed = seed &* 6364136223846793005 &+ 1442695040888963407
                    return CGFloat(seed >> 33) / CGFloat(1 << 31)
                }
                for i in 0..<34 {
                    let p = CGPoint(x: next() * size.width, y: next() * size.height * 0.9)
                    let r = 1 + next() * 1.6
                    let twinkle = 0.45 + 0.55 * (0.5 + 0.5 * sin(t * (1 + Double(i % 5) * 0.4) + Double(i)))
                    gc.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)),
                            with: .color(.white.opacity(twinkle)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// Glowing fireflies drifting over the lawn at night (drawn above the night wash).
struct Fireflies: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { ctx in
            Canvas { gc, size in
                let t = ctx.date.timeIntervalSinceReferenceDate
                for i in 0..<9 {
                    let d = Double(i)
                    let x = size.width * (0.08 + 0.1 * d) + sin(t * 0.5 + d * 1.7) * 18
                    let y = size.height * (0.6 + 0.035 * Double(i % 4)) + cos(t * 0.7 + d) * 14
                    let glow = 0.4 + 0.6 * (0.5 + 0.5 * sin(t * 2 + d * 2.3))
                    let center = CGPoint(x: x, y: y)
                    gc.fill(Path(ellipseIn: CGRect(x: center.x - 9, y: center.y - 9, width: 18, height: 18)),
                            with: .color(Color(hex: 0xFFF2A0).opacity(0.25 * glow)))
                    gc.fill(Path(ellipseIn: CGRect(x: center.x - 2.5, y: center.y - 2.5, width: 5, height: 5)),
                            with: .color(Color(hex: 0xFFF7C2).opacity(glow)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: Yard

/// A white picket fence with a gap for the garden path.
private struct Fence: View {
    /// Where the gate gap is, as fractions of the width.
    var gateFrom: CGFloat
    var gateTo: CGFloat

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let picket: CGFloat = 16
            let gap: CGFloat = 9
            let count = Int(w / (picket + gap)) + 1

            ZStack(alignment: .topLeading) {
                ForEach([0.35, 0.72], id: \.self) { y in
                    Rectangle()
                        .fill(Color(hex: 0xF4ECDD))
                        .frame(width: w, height: 6)
                        .offset(y: h * y)
                        .mask(alignment: .topLeading) { railMask(w: w, h: h) }
                }
                ForEach(0..<count, id: \.self) { i in
                    let x = CGFloat(i) * (picket + gap)
                    if !(x > w * gateFrom && x < w * gateTo) {
                        PicketShape()
                            .fill(LinearGradient(colors: [.paper, Color(hex: 0xEFE4D1)], startPoint: .top, endPoint: .bottom))
                            .frame(width: picket, height: h)
                            .offset(x: x)
                            .shadow(color: .black.opacity(0.12), radius: 0, x: 0, y: 2)
                    }
                }
            }
        }
    }

    private func railMask(w: CGFloat, h: CGFloat) -> some View {
        HStack(spacing: 0) {
            Rectangle().frame(width: w * gateFrom)
            Color.clear.frame(width: w * (gateTo - gateFrom))
            Rectangle()
        }
        .frame(height: h)
    }
}

private struct PicketShape: Shape {
    nonisolated func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + r.width * 0.5))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + r.width * 0.5), control: CGPoint(x: r.midX, y: r.minY - r.width * 0.3))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// A winding dirt path from the front of the yard back to the arch.
private struct GardenPath: Shape {
    nonisolated func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        var p = Path()
        p.move(to: CGPoint(x: w * 0.3, y: h))
        p.addCurve(to: CGPoint(x: w * 0.63, y: 0),
                   control1: CGPoint(x: w * 0.38, y: h * 0.55),
                   control2: CGPoint(x: w * 0.7, y: h * 0.3))
        p.addLine(to: CGPoint(x: w * 0.73, y: 0))
        p.addCurve(to: CGPoint(x: w * 0.72, y: h),
                   control1: CGPoint(x: w * 0.76, y: h * 0.3),
                   control2: CGPoint(x: w * 0.62, y: h * 0.55))
        p.closeSubpath()
        return p
    }
}

private struct SteppingStones: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ForEach(0..<5) { i in
                let t = CGFloat(i) / 5
                Ellipse()
                    .fill(Color(hex: 0xE5C895))
                    .frame(width: (20 + 26 * t), height: (8 + 10 * t))
                    .position(x: w * (0.68 - 0.18 * t + 0.04 * sin(t * 6)), y: h * (0.08 + 0.2 * t))
            }
        }
    }
}

private struct Flowers: View {
    private let spots: [(x: CGFloat, y: CGFloat, color: Color)] = [
        (0.05, 0.3, .coral), (0.34, 0.12, .sunny), (0.38, 0.48, .lavender),
        (0.93, 0.5, .coral), (0.6, 0.6, .sunny), (0.28, 0.72, .paper), (0.97, 0.18, .lavender),
    ]

    var body: some View {
        GeometryReader { geo in
            ForEach(spots.indices, id: \.self) { i in
                let s = spots[i]
                ZStack {
                    ForEach(0..<5) { k in
                        Circle().fill(s.color).frame(width: 7, height: 7)
                            .offset(y: -5).rotationEffect(.degrees(Double(k) * 72))
                    }
                    Circle().fill(Color.sunny.shade(0.3)).frame(width: 5, height: 5)
                }
                .shadow(color: .black.opacity(0.1), radius: 0, x: 0, y: 1)
                .position(x: geo.size.width * s.x, y: geo.size.height * s.y)
            }
        }
        .allowsHitTesting(false)
    }
}

/// Flowered arch over the path, with a little paw sign for the trail.
private struct TrailArch: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                ArchShape()
                    .stroke(Color.lavender.shade(-0.15), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: w * 0.8, height: h)
                ForEach(0..<7) { i in
                    let a = Double(i) / 6 * .pi
                    Circle()
                        .fill(i.isMultiple(of: 2) ? Color.coral : Color.sunny)
                        .frame(width: 8, height: 8)
                        .offset(x: -cos(a) * w * 0.4, y: -sin(a) * h * 0.55 + h * 0.05)
                }
                // Sign
                VStack(spacing: 0) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.paper)
                        .frame(width: 28, height: 20)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color(hex: 0xC98D55)))
                    Rectangle().fill(Color(hex: 0xA8743F)).frame(width: 4, height: 16)
                }
                .offset(x: w * 0.55, y: h * 0.22)
            }
            .cutout(2)
        }
    }
}

private struct ArchShape: Shape {
    nonisolated func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.midY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.midY), control: CGPoint(x: r.midX, y: r.minY - r.height * 0.3))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        return p
    }
}

private struct Doghouse: View {
    var night: Bool

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack(alignment: .bottom) {
                // Walls
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(colors: [Color.sunny.shade(0.15), Color.sunny.shade(-0.08)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.78, height: h * 0.58)
                // Door
                DoorShape()
                    .fill(night ? Color(hex: 0x6B4A2A) : Color.deepTeal.shade(0.15))
                    .overlay(night ? DoorShape().fill(Color.sunny.opacity(0.35)) : nil)
                    .frame(width: w * 0.3, height: h * 0.4)
                // Roof
                RoofShape()
                    .fill(LinearGradient(colors: [Color.coral.shade(0.1), Color.coral.shade(-0.1)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: w, height: h * 0.5)
                    .offset(y: -h * 0.5)
                    .cutout(3)
                // Bone sign
                BoneShape()
                    .fill(Color.paper)
                    .frame(width: w * 0.22, height: w * 0.08)
                    .offset(y: -h * 0.47)
            }
            .frame(width: w, height: h, alignment: .bottom)
            .cutout(4)
        }
    }
}

/// A solid gable roof with slightly rounded eaves.
private struct RoofShape: Shape {
    nonisolated func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.midX - r.width * 0.04, y: r.minY + r.height * 0.04))
        p.addQuadCurve(to: CGPoint(x: r.midX + r.width * 0.04, y: r.minY + r.height * 0.04),
                       control: CGPoint(x: r.midX, y: r.minY - r.height * 0.02))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

private struct DoorShape: Shape {
    nonisolated func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + r.width / 2))
        p.addArc(center: CGPoint(x: r.midX, y: r.minY + r.width / 2), radius: r.width / 2,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

private struct ToyBox: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack(alignment: .bottom) {
                // Ball and star peeking out
                Circle()
                    .fill(Color.sky)
                    .overlay(Capsule().fill(.white.opacity(0.85)).frame(height: 4))
                    .frame(width: w * 0.36)
                    .offset(x: -w * 0.16, y: -h * 0.52)
                Image(systemName: "star.fill")
                    .font(.system(size: w * 0.26))
                    .foregroundStyle(Color.sunny)
                    .rotationEffect(.degrees(15))
                    .offset(x: w * 0.2, y: -h * 0.55)
                // Box
                RoundedRectangle(cornerRadius: 5)
                    .fill(LinearGradient(colors: [Color(hex: 0xE6A56B), Color(hex: 0xC9834A)], startPoint: .top, endPoint: .bottom))
                    .overlay(
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: w * 0.2))
                            .foregroundStyle(Color.paper.opacity(0.8))
                    )
                    .frame(width: w, height: h * 0.6)
                // Lid
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.lavender.shade(-0.1))
                    .frame(width: w * 1.06, height: h * 0.14)
                    .offset(y: -h * 0.56)
            }
            .frame(width: w, height: h, alignment: .bottom)
            .cutout(3)
        }
    }
}

private struct FoodBowl: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack(alignment: .bottom) {
                // Kibble
                ForEach(0..<6) { i in
                    Circle()
                        .fill(Color(hex: 0xA8743F).shade(Double(i % 3) * 0.1))
                        .frame(width: w * 0.13)
                        .offset(x: w * (-0.25 + 0.1 * CGFloat(i)), y: -h * (0.55 + 0.08 * CGFloat(i % 2)))
                }
                BowlShape()
                    .fill(LinearGradient(colors: [Color.coral.shade(0.15), Color.coral.shade(-0.12)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: w, height: h * 0.62)
                    .overlay(alignment: .top) {
                        Capsule().fill(Color.coral.shade(0.3)).frame(width: w, height: h * 0.14)
                    }
            }
            .frame(width: w, height: h, alignment: .bottom)
            .cutout(3)
        }
    }
}

private struct BowlShape: Shape {
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

private struct KiddiePool: View {
    var body: some View {
        ZStack {
            Ellipse().fill(Color.sky.shade(0.45))
            Ellipse()
                .fill(LinearGradient(colors: [Color.sky.shade(0.2), Color.sky], startPoint: .top, endPoint: .bottom))
                .padding(9)
            Capsule().fill(.white.opacity(0.55)).frame(width: 30, height: 4).offset(x: -18, y: -4)
            Capsule().fill(.white.opacity(0.4)).frame(width: 18, height: 3).offset(x: 20, y: 6)
            Text("🐥").font(.system(size: 18)).offset(x: 14, y: -6)
        }
        .cutout(3)
    }
}
