import SwiftUI

/// The onboarding backdrop: bright sky, a sun peeking from behind a cloud,
/// a small cloud drifting in from the left, and two soft green hills Buddy stands on.
struct OnboardingScene: View {
    /// Where the hills start, as a fraction of the height.
    var hillTop: CGFloat = 0.72

    @State private var drift = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack(alignment: .topLeading) {
                Color.sky

                // Sun with a cloud in front of it
                Circle()
                    .fill(Color.sunny)
                    .frame(width: w * 0.55, height: w * 0.55)
                    .position(x: w * 0.98, y: h * 0.19)
                SceneCloud()
                    .fill(.white)
                    .frame(width: w * 0.42, height: w * 0.13)
                    .position(x: w * 0.76 + (drift ? 6 : -6), y: h * 0.262)

                // Little cloud sliding in from the left edge
                Capsule()
                    .fill(.white.opacity(0.85))
                    .frame(width: w * 0.36, height: w * 0.075)
                    .position(x: w * 0.02 + (drift ? -6 : 6), y: h * 0.415)

                // Hills: a darker one on the left, a big light one in front
                Ellipse()
                    .fill(Color(hex: 0x8DC85F))
                    .frame(width: w * 1.5, height: h * 0.5)
                    .position(x: w * 0.12, y: h * hillTop + h * 0.25)
                Ellipse()
                    .fill(Color.sprout)
                    .frame(width: w * 1.7, height: h * 0.5)
                    .position(x: w * 0.92, y: h * (hillTop + 0.035) + h * 0.25)

                PaperTexture(opacity: 0.03)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) { drift = true }
        }
    }
}

/// A flat-bottomed puffy cloud.
private struct SceneCloud: Shape {
    nonisolated func path(in r: CGRect) -> Path {
        var p = Path()
        let base = r.maxY
        p.addRoundedRect(in: CGRect(x: r.minX, y: r.minY + r.height * 0.45, width: r.width, height: r.height * 0.55),
                         cornerSize: CGSize(width: r.height * 0.27, height: r.height * 0.27))
        p.addEllipse(in: CGRect(x: r.minX + r.width * 0.42, y: r.minY, width: r.width * 0.4, height: base - r.minY))
        return p
    }
}

/// A small cream pill with bold dark text, like "For kids in physical therapy".
struct ScenePill: View {
    let text: String
    var size: CGFloat = 15

    var body: some View {
        Text(text)
            .font(.buddy(size, .heavy))
            .foregroundStyle(Color.deepTeal)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(Capsule().fill(Color.cream))
            .shadow(color: .deepTeal.opacity(0.08), radius: 4, y: 2)
    }
}
