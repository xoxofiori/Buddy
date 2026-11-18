import SwiftUI

/// A big, bouncy, pill-shaped button. Squishes when pressed and gives a haptic tap.
struct BigButton: View {
    let title: String
    var color: Color = .sunny
    var textColor: Color = .deepTeal
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled
    @State private var tapCount = 0

    var body: some View {
        Button {
            tapCount += 1
            action()
        } label: {
            Text(title)
                .font(.buddyButton)
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity, minHeight: Theme.minTap + 8)
                .background(
                    Capsule()
                        .fill(color)
                        .shadow(color: color.opacity(0.5), radius: 0, x: 0, y: 6)
                )
                .opacity(isEnabled ? 1 : 0.45)
        }
        .buttonStyle(SquishStyle())
        .sensoryFeedback(.impact(weight: .medium), trigger: tapCount)
    }
}

/// Shrinks a little on press and springs back.
struct SquishStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(Theme.bouncy, value: configuration.isPressed)
    }
}

/// A rounded, roomy text field that matches the palette.
struct BigTextField: View {
    let placeholder: String
    @Binding var text: String
    var capitalization: TextInputAutocapitalization = .words

    var body: some View {
        TextField(placeholder, text: $text)
            .font(.buddy(28, .bold))
            .foregroundStyle(Color.deepTeal)
            .multilineTextAlignment(.center)
            .textInputAutocapitalization(capitalization)
            .autocorrectionDisabled()
            .padding(.horizontal, 20)
            .frame(minHeight: Theme.minTap + 12)
            .background(
                RoundedRectangle(cornerRadius: Theme.corner)
                    .fill(Color.paper)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.corner)
                            .stroke(Color.sky.opacity(0.5), lineWidth: 3)
                    )
            )
    }
}
