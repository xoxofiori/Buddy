import SwiftUI

/// The four parts of Buddy's heart.
enum NeedKind: CaseIterable {
    case fed, clean, rested, played

    var title: String {
        switch self {
        case .fed: "Fed"
        case .clean: "Clean"
        case .rested: "Rested"
        case .played: "Played"
        }
    }

    var icon: String {
        switch self {
        case .fed: "fork.knife"
        case .clean: "drop.fill"
        case .rested: "moon.zzz.fill"
        case .played: "tennisball.fill"
        }
    }

    var color: Color {
        switch self {
        case .fed: .coral
        case .clean: .sky
        case .rested: Color(hex: 0x9C8FD6)
        case .played: Color.sprout.shade(-0.15)
        }
    }

    var keyPath: WritableKeyPath<Needs, Double> {
        switch self {
        case .fed: \.hunger
        case .clean: \.clean
        case .rested: \.energy
        case .played: \.fun
        }
    }
}

/// One need as an icon, a name and a bar that fills with a spring.
struct NeedMeter: View {
    let kind: NeedKind
    let value: Double

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: kind.icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.paper)
                .frame(width: 40, height: 40)
                .background(Circle().fill(kind.color))
            Text(kind.title)
                .font(.buddy(20, .bold))
                .foregroundStyle(Color.deepTeal)
                .frame(width: 76, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.deepTeal.opacity(0.08))
                    Capsule().fill(kind.color).frame(width: max(14, geo.size.width * value))
                }
            }
            .frame(height: 14)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: value)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(kind.title): \(Int(value * 100)) percent")
    }
}

/// What Buddy is saying, in a paper speech bubble.
struct SpeechBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.buddy(20, .heavy))
            .foregroundStyle(Color.deepTeal)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(StoryCard(shape: RoundedRectangle(cornerRadius: 22)))
            .frame(maxWidth: 270)
            .transition(.scale(scale: 0.5, anchor: .bottom).combined(with: .opacity))
            .id(text)
    }
}

/// Shared frame for the care rooms: back button, bones, and the need being cared for.
struct CareRoomHeader: View {
    let title: String
    let need: NeedKind
    let value: Double
    let bones: Int
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Button(action: onClose) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(Color.deepTeal)
                        .frame(width: Theme.minTap, height: Theme.minTap)
                        .background(StoryCard(shape: Circle()))
                }
                .buttonStyle(SquishStyle())
                .accessibilityLabel("Back to the yard")
                Spacer()
                Text(title)
                    .font(.buddy(26, .heavy))
                    .foregroundStyle(Color.deepTeal)
                Spacer()
                BoneCounter(bones: bones)
            }
            NeedMeter(kind: need, value: value)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(StoryCard(shape: RoundedRectangle(cornerRadius: 22)))
        }
        .padding(.horizontal, 14)
    }
}
