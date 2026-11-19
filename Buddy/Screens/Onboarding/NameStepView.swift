import SwiftUI

/// Step 1: "Hi! I'm Buddy! What's your name?"
struct NameStepView: View {
    let onBack: () -> Void
    let onNext: () -> Void

    @Environment(GameStore.self) private var store
    @State private var name = ""
    @FocusState private var focused: Bool

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        VStack(spacing: 0) {
            OnboardingTopBar(current: 0, onBack: onBack)

            Text("Hi! I'm Buddy!")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundStyle(Color.deepTeal)
                .padding(.top, 8)

            BuddyView(pose: .waving)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.top, 8)

            OnboardingCard {
                Text("What's your name?")
                    .font(.buddyHeader)
                    .foregroundStyle(Color.deepTeal)
                BigTextField(placeholder: "Your name", text: $name)
                    .focused($focused)
                    .submitLabel(.next)
                    .onSubmit(next)
                BigButton(title: "Next", color: .coral, textColor: .paper, action: next)
                    .disabled(trimmed.isEmpty)
            }
        }
        .onAppear { name = store.state.kidName }
    }

    private func next() {
        guard !trimmed.isEmpty else { return }
        store.state.kidName = trimmed
        focused = false
        onNext()
    }
}
