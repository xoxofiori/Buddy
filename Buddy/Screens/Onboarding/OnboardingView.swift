import SwiftUI

/// Welcome ("Get better with Buddy"), then two friendly steps: your name, then the code from your PT.
/// All three share the same sunny sky and hills.
struct OnboardingView: View {
    enum Step: Int { case welcome, name, code }

    @Environment(GameStore.self) private var store
    @State private var step: Step = .welcome
    @State private var forward = true

    var body: some View {
        ZStack {
            OnboardingScene(hillTop: step == .welcome ? 0.72 : 0.6)
                .animation(.spring(response: 0.7, dampingFraction: 0.85), value: step)

            Group {
                switch step {
                case .welcome:
                    WelcomeStepView { go(.name) }
                case .name:
                    NameStepView(onBack: { go(.welcome) }, onNext: { go(.code) })
                case .code:
                    CodeStepView(onBack: { go(.name) })
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
                removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity)))
        }
    }

    private func go(_ next: Step) {
        forward = next.rawValue > step.rawValue
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { step = next }
    }
}

/// Top of the name and code steps: a back button and two dots showing which step you're on.
struct OnboardingTopBar: View {
    let current: Int
    var onBack: () -> Void

    var body: some View {
        HStack {
            CloseButton(icon: "chevron.left", label: "Back", action: onBack)
            Spacer()
            HStack(spacing: 10) {
                ForEach(0..<2) { index in
                    Capsule()
                        .fill(index == current ? Color.paper : Color.paper.opacity(0.45))
                        .frame(width: index == current ? 32 : 12, height: 12)
                }
            }
            .animation(Theme.bouncy, value: current)
            Spacer()
            Color.clear.frame(width: Theme.minTap, height: Theme.minTap)
        }
        .padding(.horizontal, 20)
    }
}

/// The paper card the name and code steps put their question in, sitting on the hills.
struct OnboardingCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 18) { content }
            .padding(22)
            .background(StoryCard(shape: RoundedRectangle(cornerRadius: 32), fill: .cream))
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
    }
}
