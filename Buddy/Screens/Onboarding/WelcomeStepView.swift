import SwiftUI

/// The first screen: "Get better with Buddy".
struct WelcomeStepView: View {
    let onStart: () -> Void

    @State private var shown = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                ScenePill(text: "For kids in physical therapy")

                Text("Get better\nwith Buddy")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(Color.deepTeal)
                    .lineSpacing(-6)
                    .minimumScaleFactor(0.7)
                    .accessibilityAddTraits(.isHeader)

                Text("Do your PT moves, earn bones, and take care of your new best friend.")
                    .font(.buddy(19, .bold))
                    .foregroundStyle(Color.deepTeal.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 300, alignment: .leading)
            }
            .padding(.horizontal, 28)
            .offset(y: shown ? 0 : -20)
            .opacity(shown ? 1 : 0)

            // Buddy waving, standing on the hill
            BuddyView(pose: .waving, interactive: true)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.top, 8)
                .scaleEffect(shown ? 1 : 0.85, anchor: .bottom)
                .opacity(shown ? 1 : 0)

            VStack(spacing: 14) {
                HStack(spacing: 8) {
                    ScenePill(text: "Daily exercises", size: 14)
                    ScenePill(text: "Rep counting", size: 14)
                    ScenePill(text: "Care for Buddy", size: 14)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)

                BigButton(title: "Let's go!", color: .coral, textColor: .paper, action: onStart)
                    .padding(.horizontal, 24)
            }
            .padding(.top, 12)
            .padding(.bottom, 8)
            .opacity(shown ? 1 : 0)
        }
        .padding(.top, 20)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.1)) { shown = true }
        }
    }
}
