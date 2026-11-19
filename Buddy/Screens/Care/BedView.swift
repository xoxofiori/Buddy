import SwiftUI

/// Nap time (opened from the doghouse). Tap the lamp: the lights go off, Buddy curls up under
/// his blanket and sleeps, and the "rested" part of his heart refills while he snoozes.
/// Tap the lamp again to wake him; he wakes up on his own when he's fully rested.
struct BedView: View {
    var onClose: () -> Void

    @Environment(GameStore.self) private var store

    @State private var lightsOn = true
    @State private var actionPose: BuddyPose?
    @State private var speech: String?
    @State private var haptic = 0
    @State private var rested = 0
    @State private var speechTask: Task<Void, Never>?

    /// Energy gained per second of napping (0 → full in about 25 seconds, so kids see it work).
    private static let restPerSecond = 0.04

    private var pose: BuddyPose {
        if !lightsOn { return .sleeping }
        if let actionPose { return actionPose }
        if speech != nil { return .talking }
        return store.state.needs.energy < 0.3 ? .needsCare : .idle
    }

    var body: some View {
        ZStack {
            // Wall above, wooden floor below (fills behind the status bar and home indicator)
            VStack(spacing: 0) {
                Color(hex: 0xFBEFD9)
                Color(hex: 0xD29E62)
            }
            .ignoresSafeArea()

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let feet = CGPoint(x: w * 0.44, y: h * 0.76)
                let buddy = BuddyFrame(feetAt: feet, height: min(h * 0.42, 360))

                ZStack(alignment: .topLeading) {
                    BedroomBackground(lightsOn: lightsOn, feet: feet, front: false)

                    BuddyView(pose: pose, height: buddy.rect.height)
                        .position(buddy.center)

                    Blanket()
                        .frame(width: buddy.rect.width * 0.62, height: buddy.rect.height * 0.3)
                        .position(buddy.point(300, 655))
                        .offset(y: lightsOn ? buddy.rect.height * 0.5 : 0)
                        .opacity(lightsOn ? 0 : 1)
                        .animation(.spring(response: 0.6, dampingFraction: 0.75), value: lightsOn)
                        .allowsHitTesting(false)

                    BedroomBackground(lightsOn: lightsOn, feet: feet, front: true)
                        .allowsHitTesting(false)

                    // Lights-off darkness (the lamp and moon stay on top)
                    Color(hex: 0x16244A)
                        .opacity(lightsOn ? 0 : 0.5)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .animation(.easeInOut(duration: 0.6), value: lightsOn)

                    if !lightsOn {
                        Snores(from: buddy.point(380, 120))
                    }

                    Button(action: toggleLamp) {
                        Lamp(on: lightsOn)
                            .frame(width: 92, height: 190)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(SquishStyle())
                    .position(x: w * 0.86, y: feet.y - 95)
                    .accessibilityLabel(lightsOn ? "Turn off the lamp so Buddy can nap" : "Turn on the lamp to wake Buddy")

                    Text(lightsOn ? "Tap the lamp to turn off the lights" : "Shh… Buddy is napping")
                        .font(.buddy(17, .bold))
                        .foregroundStyle(lightsOn ? Color.deepTeal.opacity(0.75) : Color.paper)
                        .position(x: w / 2, y: h * 0.93)

                    if let speech {
                        SpeechBubble(text: speech)
                            .position(x: buddy.rect.midX, y: buddy.rect.minY + 20)
                    }
                }
            }

            VStack {
                CareRoomHeader(title: "Nap time", need: .rested, value: store.state.needs.energy,
                               bones: store.state.bones, onClose: onClose)
                Spacer()
            }
        }
        .sensoryFeedback(.success, trigger: rested)
        .task(id: lightsOn) {
            guard !lightsOn else { return }
            // Refill energy while he sleeps.
            while !Task.isCancelled && !lightsOn {
                try? await Task.sleep(for: .seconds(0.25))
                guard !lightsOn else { return }
                store.care(\.energy, by: Self.restPerSecond * 0.25)
                if store.state.needs.energy >= 1 {
                    wake(full: true)
                    return
                }
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(0.4))
            say(store.state.needs.energy < 0.5 ? "*yawn* I'm sleepy…" : "Nap time? Okay!")
        }
    }

    private func toggleLamp() {
        haptic += 1
        if lightsOn {
            guard store.state.needs.energy < 0.97 else {
                say("I'm not sleepy! Let's play!")
                return
            }
            speechTask?.cancel()
            withAnimation(BuddyView<EmptyView>.spring) { speech = nil }
            BuddyVoice.shared.say("Good night!")
            withAnimation(.easeInOut(duration: 0.6)) { lightsOn = false }
        } else {
            wake(full: false)
        }
    }

    private func wake(full: Bool) {
        withAnimation(.easeInOut(duration: 0.6)) { lightsOn = true }
        if full { rested += 1 }
        withAnimation(BuddyView<EmptyView>.spring) { actionPose = full ? .waving : .happy }
        say(full ? "I feel great! Thanks for the nap!" : "*yawn* Good morning!", for: 2.4)
        Task {
            try? await Task.sleep(for: .seconds(2.4))
            withAnimation(BuddyView<EmptyView>.spring) { actionPose = nil }
        }
    }

    private func say(_ text: String, for seconds: Double = 2) {
        BuddyVoice.shared.say(text)
        withAnimation(BuddyView<EmptyView>.spring) { speech = text }
        speechTask?.cancel()
        speechTask = Task {
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            withAnimation(BuddyView<EmptyView>.spring) { speech = nil }
        }
    }
}

// MARK: Pieces

/// Inside the doghouse: warm wall, a round window, and a cushy dog bed.
/// Drawn in two halves so Buddy stands *in* his bed (front rim goes over his paws).
private struct BedroomBackground: View {
    let lightsOn: Bool
    let feet: CGPoint
    let front: Bool

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let bed = CGRect(x: feet.x - w * 0.38, y: feet.y - h * 0.06, width: w * 0.76, height: h * 0.13)

            if front {
                Ellipse()
                    .fill(LinearGradient(colors: [Color.lavender.shade(-0.05), Color.lavender.shade(-0.2)],
                                         startPoint: .top, endPoint: .bottom))
                    .mask(Rectangle().frame(height: bed.height * 0.5).offset(y: bed.height * 0.25))
                    .frame(width: bed.width, height: bed.height)
                    .position(x: bed.midX, y: bed.midY + 4)
            } else {
                ZStack(alignment: .topLeading) {
                    LinearGradient(colors: [Color(hex: 0xFBEFD9), Color(hex: 0xF1DDBB)], startPoint: .top, endPoint: .bottom)
                    // Wooden floor
                    LinearGradient(colors: [Color(hex: 0xE2B67F), Color(hex: 0xD29E62)], startPoint: .top, endPoint: .bottom)
                        .frame(height: h * 0.32)
                        .offset(y: h * 0.68)
                    // Round window
                    ZStack {
                        Circle().fill(lightsOn
                                      ? LinearGradient(colors: [Color.sky, Color.sky.shade(0.5)], startPoint: .top, endPoint: .bottom)
                                      : LinearGradient(colors: [Color(hex: 0x18264A), Color(hex: 0x3A4C78)], startPoint: .top, endPoint: .bottom))
                        if lightsOn {
                            Circle().fill(Color.sunny).frame(width: 26).offset(x: 18, y: -16)
                        } else {
                            Circle().fill(Color(hex: 0xFFF3C4)).frame(width: 24).offset(x: 16, y: -14)
                            ForEach(0..<5) { i in
                                Circle().fill(.white).frame(width: 3).offset(x: CGFloat(i * 13 - 30), y: CGFloat((i * 17) % 30 - 6))
                            }
                        }
                        Rectangle().fill(Color.paper).frame(width: 5)
                        Rectangle().fill(Color.paper).frame(height: 5)
                        Circle().strokeBorder(Color(hex: 0xC98D55), lineWidth: 9)
                    }
                    .frame(width: 110, height: 110)
                    .shadow(color: .black.opacity(0.12), radius: 0, x: 0, y: 3)
                    .position(x: w * 0.17, y: h * 0.3)
                    // Bed: back rim and cushion
                    Ellipse()
                        .fill(Color.lavender.shade(-0.2))
                        .frame(width: bed.width, height: bed.height)
                        .position(x: bed.midX, y: bed.midY - 6)
                        .shadow(color: .black.opacity(0.12), radius: 0, x: 0, y: 4)
                    Ellipse()
                        .fill(Color.paper)
                        .frame(width: bed.width - 34, height: bed.height - 26)
                        .position(x: bed.midX, y: bed.midY)
                    PaperTexture()
                }
            }
        }
    }
}

/// A cozy patchwork blanket tucked over Buddy's legs.
private struct Blanket: View {
    var body: some View {
        let colors: [Color] = [.coral, .sunny, .sky, .sprout, .lavender.shade(-0.1), .paper]
        RoundedRectangle(cornerRadius: 22)
            .fill(Color.coral.shade(0.3))
            .overlay(
                Grid(horizontalSpacing: 3, verticalSpacing: 3) {
                    ForEach(0..<3) { row in
                        GridRow {
                            ForEach(0..<4) { col in
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(colors[(row * 4 + col) % colors.count].opacity(0.85))
                            }
                        }
                    }
                }
                .padding(8)
            )
            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(.white.opacity(0.6), style: StrokeStyle(lineWidth: 2, dash: [5, 4])).padding(4))
            .shadow(color: .black.opacity(0.15), radius: 0, x: 0, y: 4)
    }
}

/// A bedside lamp on a little table. Glows when on.
private struct Lamp: View {
    let on: Bool

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack(alignment: .bottom) {
                if on {
                    Circle()
                        .fill(RadialGradient(colors: [Color.sunny.opacity(0.55), .clear], center: .center, startRadius: 4, endRadius: 90))
                        .frame(width: 200, height: 200)
                        .offset(y: -(h * 0.79 - 100))   // centered on the shade
                        .allowsHitTesting(false)
                }
                // Table
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: 0xC98D55))
                    .frame(width: w, height: h * 0.4)
                // Pole and base
                Capsule().fill(Color.deepTeal.shade(0.2)).frame(width: 8, height: h * 0.3).offset(y: -h * 0.4)
                Capsule().fill(Color.deepTeal.shade(0.2)).frame(width: w * 0.5, height: 10).offset(y: -h * 0.4)
                // Shade
                LampShade()
                    .fill(on ? Color.sunny.shade(0.3) : Color.sunny.shade(-0.25))
                    .frame(width: w * 0.9, height: h * 0.26)
                    .offset(y: -h * 0.66)
            }
            .frame(width: w, height: h, alignment: .bottom)
            .shadow(color: .black.opacity(0.13), radius: 0, x: 0, y: 3)
        }
    }
}

private struct LampShade: Shape {
    nonisolated func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX + r.width * 0.22, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - r.width * 0.22, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// Floating "z"s while Buddy sleeps.
private struct Snores: View {
    let from: CGPoint

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(0..<3) { i in
                    let phase = (t * 0.4 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
                    Text("z")
                        .font(.buddy(22 + CGFloat(i) * 7, .heavy))
                        .foregroundStyle(Color.paper)
                        .opacity(1 - phase)
                        .position(x: from.x + CGFloat(phase) * 40, y: from.y - CGFloat(phase) * 70)
                }
            }
        }
        .allowsHitTesting(false)
    }
}
