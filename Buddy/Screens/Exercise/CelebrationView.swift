import SwiftUI

/// "You did it!" Buddy does a happy dance, confetti falls, stars light up,
/// and the bones you earned fly into the bone jar.
struct CelebrationView: View {
    let kind: ExerciseKind
    let kidName: String
    let result: ExerciseResult
    let reward: ExerciseReward
    var onDone: () -> Void

    @State private var shownStars = 0
    @State private var bonesIn = false

    var body: some View {
        ZStack {
            Confetti().ignoresSafeArea()

            VStack(spacing: 14) {
                Text("You did it, \(kidName)!")
                    .font(.buddyTitle)
                    .foregroundStyle(Color.deepTeal)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                    .padding(.top, 20)

                // Happy dance: he switches between cheerful poses.
                TimelineView(.animation(minimumInterval: 0.65)) { ctx in
                    let dance: [BuddyPose] = [.happy, .waving, .armRaise, .happy]
                    let step = Int(ctx.date.timeIntervalSinceReferenceDate / 0.65) % dance.count
                    BuddyView(pose: dance[step], height: 250)
                }

                HStack(spacing: 10) {
                    ForEach(0..<3) { i in
                        Image(systemName: "star.fill")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundStyle(i < shownStars ? Color.sunny : Color.deepTeal.opacity(0.12))
                            .scaleEffect(i < shownStars ? 1 : 0.7)
                            .rotationEffect(.degrees(i == 1 ? 0 : (i == 0 ? -12 : 12)))
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.45), value: shownStars)
                .accessibilityLabel("\(result.stars) stars")

                HStack(spacing: 12) {
                    Stat(value: "\(result.reps)", label: "reps")
                    Stat(value: "\(result.accuracy)%", label: "accuracy")
                }

                BoneJar(bones: reward.bones, golden: reward.goldenBones, filled: bonesIn)

                Spacer(minLength: 0)

                BigButton(title: "Back to Buddy", color: .coral, textColor: .paper, action: onDone)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 10)
            }
            .padding(.horizontal, 20)
        }
        .sensoryFeedback(.success, trigger: shownStars)
        .task {
            BuddyVoice.shared.say("You did it, \(kidName)! I'm so proud of you!")
            for i in 1...result.stars {
                try? await Task.sleep(for: .seconds(0.45))
                shownStars = i
            }
            try? await Task.sleep(for: .seconds(0.3))
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) { bonesIn = true }
        }
    }
}

private struct Stat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 0) {
            Text(value).font(.buddy(28, .heavy)).foregroundStyle(Color.deepTeal)
            Text(label).font(.buddy(15, .bold)).foregroundStyle(Color.deepTeal.opacity(0.6))
        }
        .frame(maxWidth: .infinity, minHeight: 74)
        .background(StoryCard(shape: RoundedRectangle(cornerRadius: 22)))
    }
}

/// A glass jar that bones fly into. Golden bones are the perfect-form reps.
private struct BoneJar: View {
    let bones: Int
    let golden: Int
    let filled: Bool

    var body: some View {
        HStack(spacing: 16) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.sky.opacity(0.15))
                    .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.sky.opacity(0.6), lineWidth: 3))
                    .frame(width: 92, height: 96)
                Capsule().fill(Color.coral).frame(width: 70, height: 12).offset(y: -96)
                // Bones dropping in (golden ones in the same share as earned)
                let shown = min(bones, 9)
                let goldShown = bones == 0 ? 0 : Int((Double(shown) * Double(golden) / Double(bones)).rounded())
                ForEach(0..<shown, id: \.self) { i in
                    let isGold = i < goldShown
                    BoneShape()
                        .fill(isGold ? Color.sunny : Color(hex: 0xF3E2C2))
                        .overlay(BoneShape().stroke(isGold ? Color.sunny.shade(-0.3) : Color(hex: 0xC9A46A), lineWidth: 1))
                        .frame(width: 34, height: 16)
                        .rotationEffect(.degrees(Double(i * 37 % 60) - 30))
                        .offset(x: CGFloat(i % 3 - 1) * 22, y: filled ? -CGFloat(10 + (i / 3) * 18) : -260)
                        .opacity(filled ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(Double(i) * 0.08), value: filled)
                }
            }
            .frame(width: 92, height: 110, alignment: .bottom)

            VStack(alignment: .leading, spacing: 2) {
                Text("+\(bones) bones")
                    .font(.buddy(28, .heavy))
                    .foregroundStyle(Color.deepTeal)
                if golden > 0 {
                    Label("\(golden) golden for perfect form", systemImage: "sparkles")
                        .font(.buddy(15, .bold))
                        .foregroundStyle(Color.sunny.shade(-0.35))
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(StoryCard(shape: RoundedRectangle(cornerRadius: 26)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("You earned \(bones) bones, \(golden) of them golden")
    }
}

/// Paper confetti falling across the screen.
private struct Confetti: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { ctx in
            Canvas { gc, size in
                let t = ctx.date.timeIntervalSinceReferenceDate
                let colors: [Color] = [.coral, .sunny, .sky, .sprout, .lavender.shade(-0.15)]
                for i in 0..<46 {
                    let d = Double(i)
                    let speed = 0.12 + Double(i % 5) * 0.03
                    let y = ((t * speed + d * 0.137).truncatingRemainder(dividingBy: 1)) * (size.height + 40) - 20
                    let x = (d * 0.618).truncatingRemainder(dividingBy: 1) * size.width + CGFloat(sin(t * 1.5 + d)) * 14
                    var piece = gc
                    piece.translateBy(x: x, y: y)
                    piece.rotate(by: .radians(t * 2 + d))
                    piece.fill(Path(roundedRect: CGRect(x: -5, y: -3, width: 10, height: 6), cornerRadius: 1.5),
                               with: .color(colors[i % colors.count]))
                }
            }
        }
        .allowsHitTesting(false)
        .opacity(0.85)
    }
}
