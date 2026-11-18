import SwiftUI

/// Buddy's collar with a round tag. The heart on the tag has four sections
/// (fed, clean, rested, played) that fill in when those needs are looked after.
/// Drawn in the 600 × 800 art coordinates so it sits right at his neck.
struct BuddyCollar: View {
    let needs: Needs

    var body: some View {
        ZStack(alignment: .topLeading) {
            CollarBand()
                .stroke(Color.coral.shade(-0.2), style: StrokeStyle(lineWidth: 18, lineCap: .round))
            CollarBand()
                .stroke(Color.coral, style: StrokeStyle(lineWidth: 13, lineCap: .round))

            // Tag (taps on it come through BuddyView as .tapCollar)
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color(hex: 0xFFE3A0), Color.sunny.shade(-0.1)],
                                         startPoint: .top, endPoint: .bottom))
                    .overlay(Circle().strokeBorder(Color.sunny.shade(-0.3), lineWidth: 3))
                    .frame(width: 72, height: 72)
                HeartSections(needs: needs)
                    .frame(width: 44, height: 40)
            }
            .position(x: 300, y: 440)

            // Ring linking tag to collar
            Circle()
                .strokeBorder(Color.sunny.shade(-0.3), lineWidth: 3)
                .frame(width: 14, height: 14)
                .position(x: 300, y: 404)
                .allowsHitTesting(false)
        }
        .frame(width: 600, height: 800, alignment: .topLeading)
    }
}

private struct CollarBand: Shape {
    nonisolated func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 246, y: 390))
        p.addQuadCurve(to: CGPoint(x: 354, y: 390), control: CGPoint(x: 300, y: 414))
        return p
    }
}

/// A heart split into four quarters: fed, clean, rested, played.
struct HeartSections: View {
    let needs: Needs

    var body: some View {
        let parts: [(Double, Color, Alignment)] = [
            (needs.hunger, .coral, .topLeading),
            (needs.clean, .sky, .topTrailing),
            (needs.energy, Color(hex: 0x9C8FD6), .bottomLeading),
            (needs.fun, Color.sprout.shade(-0.15), .bottomTrailing),
        ]
        GeometryReader { geo in
            ZStack {
                ForEach(parts.indices, id: \.self) { i in
                    let part = parts[i]
                    Rectangle()
                        .fill(part.1.opacity(part.0 >= 0.5 ? 1 : 0.25))
                        .frame(width: geo.size.width / 2, height: geo.size.height / 2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: part.2)
                }
            }
            .clipShape(HeartShape())
            .overlay(HeartShape().stroke(.white, lineWidth: 2))
        }
    }
}

struct HeartShape: Shape {
    nonisolated func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height
        p.move(to: CGPoint(x: r.midX, y: r.maxY))
        p.addCurve(to: CGPoint(x: r.minX, y: r.minY + h * 0.3),
                   control1: CGPoint(x: r.minX + w * 0.2, y: r.minY + h * 0.75),
                   control2: CGPoint(x: r.minX, y: r.minY + h * 0.55))
        p.addArc(center: CGPoint(x: r.minX + w * 0.25, y: r.minY + h * 0.28), radius: w * 0.25,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addArc(center: CGPoint(x: r.maxX - w * 0.25, y: r.minY + h * 0.28), radius: w * 0.25,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addCurve(to: CGPoint(x: r.midX, y: r.maxY),
                   control1: CGPoint(x: r.maxX, y: r.minY + h * 0.55),
                   control2: CGPoint(x: r.maxX - w * 0.2, y: r.minY + h * 0.75))
        p.closeSubpath()
        return p
    }
}

/// Opened by tapping the collar tag: the four sections of Buddy's heart in detail.
struct HeartDetailSheet: View {
    let needs: Needs
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            HeartSections(needs: needs)
                .frame(width: 88, height: 80)
                .padding(.top, 28)
            Text("Buddy's heart")
                .font(.buddyHeader)
                .foregroundStyle(Color.deepTeal)

            VStack(spacing: 14) {
                ForEach(NeedKind.allCases, id: \.self) { kind in
                    NeedMeter(kind: kind, value: needs[keyPath: kind.keyPath])
                }
            }
            .padding(20)
            .background(StoryCard(shape: RoundedRectangle(cornerRadius: 24)))
            .padding(.horizontal, 20)

            Text("Tap the bowl, the pool, the doghouse or the toy box to look after him.")
                .font(.buddy(16, .semibold))
                .foregroundStyle(Color.deepTeal.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Spacer(minLength: 0)
            BigButton(title: "Okay!", color: .coral, textColor: .paper) { dismiss() }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
        }
        .background(Color.cream.overlay(PaperTexture()).ignoresSafeArea())
        .presentationDetents([.large])
        .presentationCornerRadius(36)
    }
}
