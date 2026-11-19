import SwiftUI

/// Step 2: type the code your PT gave you. BUDDY123 loads the demo plan.
struct CodeStepView: View {
    let onBack: () -> Void

    @Environment(GameStore.self) private var store
    @State private var code = ""
    @State private var showError = false
    @State private var shakes = 0
    @State private var successCount = 0
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            OnboardingTopBar(current: 1, onBack: onBack)

            Text("Nice to meet you,\n\(store.state.kidName)!")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(Color.deepTeal)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
                .padding(.top, 8)
                .padding(.horizontal, 20)

            BuddyView(pose: showError ? .needsCare : .idle)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.top, 8)

            OnboardingCard {
                Text("Type the code from your PT")
                    .font(.buddyHeader)
                    .foregroundStyle(Color.deepTeal)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)

                BigTextField(placeholder: "PT code", text: $code, capitalization: .characters)
                    .focused($focused)
                    .submitLabel(.go)
                    .onSubmit(tryCode)
                    .modifier(Shake(amount: CGFloat(shakes)))
                    .onChange(of: code) { if showError { withAnimation(Theme.bouncy) { showError = false } } }

                if showError {
                    Text("Hmm, Buddy doesn't know that code yet. Ask your PT and try again!")
                        .font(.buddy(17, .bold))
                        .foregroundStyle(Color.coral.shade(-0.15))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                }

                BigButton(title: "Let's go!", color: .coral, textColor: .paper, action: tryCode)
                    .disabled(code.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .sensoryFeedback(.error, trigger: shakes)
        .sensoryFeedback(.success, trigger: successCount)
    }

    private func tryCode() {
        guard !code.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        if store.redeem(code: code) {
            focused = false
            successCount += 1
        } else {
            withAnimation(.linear(duration: 0.4)) { shakes += 1 }
            withAnimation(Theme.bouncy) { showError = true }
        }
    }
}

/// Wiggles side to side; animate `amount` up by 1 to play one shake.
struct Shake: GeometryEffect {
    var amount: CGFloat
    var animatableData: CGFloat {
        get { amount }
        set { amount = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 10 * sin(amount * .pi * 4), y: 0))
    }
}
