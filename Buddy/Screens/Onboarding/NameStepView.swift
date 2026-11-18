import SwiftUI

/// Step 1: "Hi! I'm Buddy. What's your name?"
struct NameStepView: View {
    let onNext: () -> Void

    @Environment(GameStore.self) private var store
    @State private var name = ""
    @FocusState private var focused: Bool

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 0)

            BuddyView(pose: .waving, height: 230)

            VStack(spacing: 8) {
                Text("Hi! I'm Buddy!")
                    .font(.buddyTitle)
                Text("What's your name?")
                    .font(.buddyHeader)
                    .foregroundStyle(Color.deepTeal.opacity(0.7))
            }
            .foregroundStyle(Color.deepTeal)
            .multilineTextAlignment(.center)

            BigTextField(placeholder: "Your name", text: $name)
                .focused($focused)
                .submitLabel(.next)
                .onSubmit(next)

            Spacer(minLength: 0)

            BigButton(title: "Next", action: next)
                .disabled(trimmed.isEmpty)
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
