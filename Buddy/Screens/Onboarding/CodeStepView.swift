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
        VStack(spacing: 24) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.buddy(22, .heavy))
                        .foregroundStyle(Color.deepTeal)
                        .frame(width: Theme.minTap, height: Theme.minTap)
                        .background(Circle().fill(Color.paper))
                }
                .buttonStyle(SquishStyle())
                .accessibilityLabel("Back")
                Spacer()
            }

            Spacer(minLength: 0)

            BuddyPlaceholder(size: 120)

            VStack(spacing: 8) {
                Text("Nice to meet you, \(store.state.kidName)!")
                    .font(.buddyHeader)
                Text("Type the code from your PT.")
                    .font(.buddyBody)
                    .foregroundStyle(Color.deepTeal.opacity(0.7))
            }
            .foregroundStyle(Color.deepTeal)
            .multilineTextAlignment(.center)

            BigTextField(placeholder: "PT code", text: $code, capitalization: .characters)
                .focused($focused)
                .submitLabel(.go)
                .onSubmit(tryCode)
                .modifier(Shake(amount: CGFloat(shakes)))
                .onChange(of: code) { if showError { withAnimation(Theme.bouncy) { showError = false } } }

            if showError {
                Text("Hmm, Buddy doesn't know that code yet. Ask your PT and try again!")
                    .font(.buddyBody)
                    .foregroundStyle(Color.coral)
                    .multilineTextAlignment(.center)
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color.coral.opacity(0.12)))
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }

            Spacer(minLength: 0)

            BigButton(title: "Let's go!", color: .sky, textColor: .paper, action: tryCode)
                .disabled(code.trimmingCharacters(in: .whitespaces).isEmpty)
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
