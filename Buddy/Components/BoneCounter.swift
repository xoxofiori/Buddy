import SwiftUI

/// The kid's bones (earned by doing reps). Pops when the number changes.
struct BoneCounter: View {
    var bones: Int

    var body: some View {
        HStack(spacing: 8) {
            BoneShape()
                .fill(LinearGradient(colors: [Color(hex: 0xFFF6E3), Color(hex: 0xEBD3A6)],
                                     startPoint: .top, endPoint: .bottom))
                .overlay(BoneShape().stroke(Color(hex: 0xC9A46A), lineWidth: 1.5))
                .frame(width: 34, height: 18)
                .rotationEffect(.degrees(-20))
            Text("\(bones)")
                .font(.buddy(24, .heavy))
                .foregroundStyle(Color.deepTeal)
                .contentTransition(.numericText(value: Double(bones)))
        }
        .padding(.leading, 12)
        .padding(.trailing, 16)
        .frame(minHeight: 48)
        .background(StoryCard(shape: Capsule()))
        .animation(Theme.bouncy, value: bones)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(bones) bones")
    }
}
