import SwiftUI

/// Two friendly steps: what's your name, then the code from your PT.
struct OnboardingView: View {
    enum Step { case name, code }

    @Environment(GameStore.self) private var store
    @State private var step: Step = .name

    var body: some View {
        ZStack {
            LinearGradient(colors: [.cream, .lavender.opacity(0.6)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                StepDots(current: step == .name ? 0 : 1)
                    .padding(.top, 12)

                Group {
                    switch step {
                    case .name:
                        NameStepView {
                            withAnimation(Theme.bouncy) { step = .code }
                        }
                        .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity),
                                                removal: .move(edge: .leading).combined(with: .opacity)))
                    case .code:
                        CodeStepView {
                            withAnimation(Theme.bouncy) { step = .name }
                        }
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                removal: .move(edge: .trailing).combined(with: .opacity)))
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
}

/// Two little dots showing which step you're on.
private struct StepDots: View {
    let current: Int

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<2) { index in
                Capsule()
                    .fill(index == current ? Color.coral : Color.deepTeal.opacity(0.15))
                    .frame(width: index == current ? 32 : 12, height: 12)
            }
        }
        .animation(Theme.bouncy, value: current)
    }
}
