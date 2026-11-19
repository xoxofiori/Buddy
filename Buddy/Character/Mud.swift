import SwiftUI

/// Muddy spots on Buddy's fur when he needs a bath. The home screen and the bath
/// use the same spots, so the ones a kid sees in the yard are the ones they scrub off.
enum MudLayout {
    /// Spot centers and sizes on the 600 × 800 art canvas: head first, then body, then legs.
    static let spots: [(x: CGFloat, y: CGFloat, size: CGFloat)] = [
        (215, 300, 50), (385, 135, 46), (300, 470, 70), (250, 560, 58),
        (352, 600, 64), (266, 700, 50), (338, 706, 52), (404, 300, 48),
    ]

    /// How many spots for a "clean" level (0–1): none when he's clean, up to 8 when filthy.
    static func count(clean: Double, threshold: Double = 0.95) -> Int {
        guard clean < threshold else { return 0 }
        return min(spots.count, max(2, Int(((1 - clean) * 8).rounded(.up))))
    }
}

extension EnvironmentValues {
    /// How many muddy spots BuddyView draws on him (0 = clean). Set by screens that show him dirty.
    @Entry var buddyMud: Int = 0
}

/// The muddy spots for one part of Buddy, drawn on the 600 × 800 canvas.
struct MudArt: View {
    enum Part { case head, body, legs }

    let count: Int
    let part: Part

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(MudLayout.spots.prefix(count).enumerated()), id: \.offset) { _, spot in
                if belongs(spot.y) {
                    Ellipse()
                        .fill(Color(hex: 0x8C5A2E).opacity(0.55))
                        .frame(width: spot.size, height: spot.size * 0.75)
                        .blur(radius: 2)
                        .position(x: spot.x, y: spot.y)
                }
            }
        }
        .frame(width: 600, height: 800, alignment: .topLeading)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func belongs(_ y: CGFloat) -> Bool {
        switch part {
        case .head: y < 372          // above the neck pivot
        case .body: y >= 372 && y < 648
        case .legs: y >= 648
        }
    }
}
