import SwiftUI

/// "How's your knee?" Tap how much it hurts, 1 (hardly at all) to 10 (the most).
/// The face and words change with the answer, and Buddy's face mirrors it.
/// Never a wrong answer: Buddy thanks the kid, and for big numbers reminds them to tell a grown-up.
struct CheckInView: View {
    var onClose: () -> Void

    @Environment(GameStore.self) private var store

    @State private var pain: Int?
    @State private var saved = false
    @State private var reply: String?
    @State private var earned = 0

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                CloseButton(icon: "xmark", label: "Close", action: onClose)
                Spacer()
            }

            Text(saved ? "Thanks, \(store.state.kidName)!" : "How's your knee?")
                .font(.buddyTitle)
                .foregroundStyle(Color.deepTeal)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .contentTransition(.opacity)

            ZStack(alignment: .top) {
                BuddyView(pose: buddyPose, height: 210)
                    .padding(.top, reply == nil ? 0 : 54)
                if let reply {
                    SpeechBubble(text: reply)
                }
            }
            .frame(height: 270)

            if let pain {
                VStack(spacing: 2) {
                    Text(PainScale.face(pain)).font(.system(size: 54))
                    Text(PainScale.words(pain))
                        .font(.buddy(22, .heavy))
                        .foregroundStyle(PainScale.color(pain).shade(-0.35))
                }
                .transition(.scale(scale: 0.6).combined(with: .opacity))
                .id(pain)
            } else {
                Text("Tap how much it hurts today")
                    .font(.buddyBody)
                    .foregroundStyle(Color.deepTeal.opacity(0.65))
                    .frame(height: 90)
            }

            // Once saved, the scale steps aside so the thank-you fits
            if !saved {
                scale
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            Spacer(minLength: 0)

            if saved {
                if earned > 0 {
                    Label("+\(earned) bones for checking in", systemImage: "sparkles")
                        .font(.buddy(17, .heavy))
                        .foregroundStyle(Color.sunny.shade(-0.35))
                        .transition(.scale.combined(with: .opacity))
                }
                BigButton(title: "Back to Buddy", color: .coral, textColor: .paper, action: onClose)
            } else {
                BigButton(title: "That's how it feels", color: .coral, textColor: .paper, action: save)
                    .disabled(pain == nil)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
        .background(Color.cream.overlay(PaperTexture()).ignoresSafeArea())
        .animation(.spring(response: 0.4, dampingFraction: 0.65), value: pain)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: saved)
        .task {
            pain = store.state.today.flatMap { Calendar.current.isDateInToday($0.date) ? $0.pain : nil }
            try? await Task.sleep(for: .seconds(0.4))
            BuddyVoice.shared.say("How's your knee today? Tap how much it hurts.")
        }
    }

    /// Buddy's face follows the answer.
    private var buddyPose: BuddyPose {
        guard let pain else { return .talking }
        switch pain {
        case 1...3: return .happy
        case 4...6: return .idle
        default: return .needsCare
        }
    }

    /// Two rows of five big buttons, green (hardly) to coral (the most).
    private var scale: some View {
        VStack(spacing: 10) {
            ForEach(0..<2) { row in
                HStack(spacing: 10) {
                    ForEach(1...5, id: \.self) { col in
                        let n = row * 5 + col
                        Button {
                            pain = n
                        } label: {
                            VStack(spacing: 0) {
                                Text(PainScale.face(n)).font(.system(size: 22))
                                Text("\(n)").font(.buddy(20, .heavy))
                            }
                            .foregroundStyle(Color.deepTeal)
                            .frame(maxWidth: .infinity, minHeight: 64)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(PainScale.color(n).opacity(pain == n ? 1 : 0.35))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .strokeBorder(Color.deepTeal, lineWidth: pain == n ? 3 : 0)
                            )
                            .scaleEffect(pain == n ? 1.08 : 1)
                        }
                        .buttonStyle(SquishStyle())
                        .accessibilityLabel("\(n), \(PainScale.words(n))")
                        .accessibilityAddTraits(pain == n ? .isSelected : [])
                    }
                }
            }
            HStack {
                Text("Hardly at all")
                Spacer()
                Text("The most")
            }
            .font(.buddy(14, .bold))
            .foregroundStyle(Color.deepTeal.opacity(0.55))
        }
    }

    private func save() {
        guard let pain else { return }
        earned = store.checkIn(pain: pain)
        Feedback.success()
        saved = true
        let text: String
        switch pain {
        case 1...3: text = "Yay! Your knee is getting stronger!"
        case 4...6: text = "Thanks for telling me. Let's go gently today."
        default: text = "Thanks for being brave. Please tell a grown-up or Dr. Lee too."
        }
        reply = text
        BuddyVoice.shared.say(text)
    }
}

/// Faces, words and colors for the 1–10 pain scale.
enum PainScale {
    static func face(_ n: Int) -> String {
        ["😄", "😊", "🙂", "🙂", "😐", "😕", "🙁", "😣", "😖", "😭"][min(max(n, 1), 10) - 1]
    }

    static func words(_ n: Int) -> String {
        switch n {
        case ...2: "Hardly at all"
        case 3...4: "A little"
        case 5...6: "Some"
        case 7...8: "A lot"
        default: "The most"
        }
    }

    static func color(_ n: Int) -> Color {
        switch n {
        case ...3: .sprout
        case 4...6: .sunny
        default: .coral
        }
    }
}
