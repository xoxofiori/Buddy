import SwiftUI

/// Bath time (opened from the kiddie pool). Drag a soap over Buddy to scrub away the muddy
/// spots, which fills him with bubbles, then tap the shower to rinse. The "clean" part fills.
/// Plain soap is free; rainbow soap costs bones and makes him extra happy.
struct BathView: View {
    var onClose: () -> Void

    @Environment(GameStore.self) private var store

    @State private var mud: [MudSpot] = []
    @State private var bubbles: [Bubble] = []
    @State private var soapInHand: Soap?
    @State private var soapPoint: CGPoint = .zero
    @State private var lastBubble: CGPoint?
    @State private var paidForRainbow = false
    @State private var usedRainbow = false
    @State private var rinseStart: Date?
    @State private var actionPose: BuddyPose?
    @State private var speech: String?
    @State private var sparkle = false
    @State private var saidBubbly = false
    @State private var haptic = 0
    @State private var cleanDone = 0
    @State private var speechTask: Task<Void, Never>?

    private static let rinseTime = 2.4

    private var pose: BuddyPose {
        if let actionPose { return actionPose }
        if speech != nil { return .talking }
        return store.state.needs.clean < 0.3 ? .needsCare : .idle
    }

    /// How much of the scrubbing is done, 0–1.
    private var scrubbed: Double {
        if mud.isEmpty { return min(1, Double(bubbles.count) / 60) }
        return Double(mud.filter(\.scrubbed).count) / Double(mud.count)
    }

    var body: some View {
        ZStack {
            // Fills the areas behind the status bar and home indicator
            VStack(spacing: 0) {
                Color.sky.shade(0.2)
                Color.sprout.shade(-0.12)
            }
            .ignoresSafeArea()

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let buddy = BuddyFrame(feetAt: CGPoint(x: w / 2, y: h * 0.72), height: min(h * 0.42, 360))
                let showerAt = CGPoint(x: w / 2, y: buddy.rect.minY - 6)

                TimelineView(.animation(paused: rinseStart == nil)) { context in
                    let rinse = rinseProgress(at: context.date)

                    ZStack(alignment: .topLeading) {
                        PoolBackground(feet: CGPoint(x: w / 2, y: h * 0.72), front: false)

                        BuddyView(pose: pose, height: buddy.rect.height)
                            .position(buddy.center)

                        // Muddy spots on his fur
                        ForEach(mud) { spot in
                            Ellipse()
                                .fill(Color(hex: 0x8C5A2E).opacity(0.55))
                                .frame(width: buddy.rect.width * spot.size / 600, height: buddy.rect.width * spot.size * 0.75 / 600)
                                .blur(radius: 1.5)
                                .position(buddy.point(spot.x, spot.y))
                                .opacity(spot.scrubbed ? 1 - rinse : 1)
                        }

                        // Bubbles
                        ForEach(bubbles) { bubble in
                            BubbleView(bubble: bubble)
                                .position(bubble.point)
                                .opacity(1 - rinse)
                        }

                        PoolBackground(feet: CGPoint(x: w / 2, y: h * 0.72), front: true)
                            .allowsHitTesting(false)

                        ShowerHead()
                            .frame(width: 110, height: 44)
                            .position(showerAt)
                        if rinseStart != nil {
                            WaterDrops(time: context.date.timeIntervalSinceReferenceDate)
                                .frame(width: buddy.rect.width * 0.8, height: buddy.rect.height * 0.95)
                                .position(x: w / 2, y: showerAt.y + buddy.rect.height * 0.5)
                        }

                        if sparkle {
                            Sparkles(around: buddy)
                        }

                        if let speech {
                            SpeechBubble(text: speech)
                                .position(x: w / 2, y: showerAt.y - 64)
                        }

                        tools(width: w, height: h, buddy: buddy)

                        if let soap = soapInHand {
                            SoapBar(soap: soap)
                                .scaleEffect(1.15)
                                .rotationEffect(.degrees(-12))
                                .position(soapPoint)
                                .allowsHitTesting(false)
                        }
                    }
                    .coordinateSpace(.named("bath"))
                }
                .onAppear { makeMud() }
            }

            VStack {
                CareRoomHeader(title: "Bath time", need: .clean, value: store.state.needs.clean,
                               bones: store.state.bones, onClose: onClose)
                Spacer()
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: haptic)
        .sensoryFeedback(.success, trigger: cleanDone)
        .task {
            try? await Task.sleep(for: .seconds(0.4))
            say(mud.isEmpty ? "Splash time!" : "I got muddy! Can you scrub me?")
        }
    }

    // MARK: Tools

    private func tools(width w: CGFloat, height h: CGFloat, buddy: BuddyFrame) -> some View {
        let trayY = h * 0.9
        return ZStack(alignment: .topLeading) {
            ForEach(Array(Soap.allCases.enumerated()), id: \.element) { index, soap in
                let home = CGPoint(x: 70 + CGFloat(index) * 104, y: trayY)
                VStack(spacing: 4) {
                    SoapBar(soap: soap)
                    Text(soap.price == 0 ? "Free" : "\(soap.price) bones")
                        .font(.buddy(13, .heavy))
                        .foregroundStyle(store.state.bones >= soap.price ? Color.deepTeal.opacity(0.7) : Color.coral)
                }
                .frame(width: 96, height: 96)
                .background(StoryCard(shape: RoundedRectangle(cornerRadius: 24)))
                .opacity(soapInHand == soap ? 0.4 : 1)
                .position(home)
                .gesture(soapDrag(soap, buddy: buddy))
                .accessibilityLabel("\(soap.name). Drag over Buddy to scrub")
            }

            Button(action: rinse) {
                VStack(spacing: 2) {
                    Image(systemName: "shower.fill")
                        .font(.system(size: 30, weight: .bold))
                    Text("Rinse").font(.buddy(15, .heavy))
                }
                .foregroundStyle(Color.paper)
                .frame(width: 96, height: 96)
                .background(Circle().fill(Color.sky).shadow(color: .black.opacity(0.15), radius: 0, x: 0, y: 4))
            }
            .buttonStyle(SquishStyle())
            .disabled(rinseStart != nil)
            .position(x: w - 70, y: trayY)
            .accessibilityLabel("Rinse with the shower")
        }
    }

    private func soapDrag(_ soap: Soap, buddy: BuddyFrame) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("bath"))
            .onChanged { value in
                guard rinseStart == nil else { return }
                if soapInHand == nil {
                    soapInHand = soap
                    haptic += 1
                }
                soapPoint = CGPoint(x: value.location.x, y: value.location.y - 30)
                scrub(at: soapPoint, buddy: buddy)
            }
            .onEnded { _ in
                withAnimation(BuddyView<EmptyView>.spring) {
                    soapInHand = nil
                    actionPose = nil
                }
                lastBubble = nil
            }
    }

    private func scrub(at point: CGPoint, buddy: BuddyFrame) {
        guard let soap = soapInHand, buddy.body.contains(point) else { return }
        if let last = lastBubble, hypot(point.x - last.x, point.y - last.y) < 12 { return }

        // Rainbow soap is paid for once per bath, the first time it touches Buddy.
        if soap == .rainbow && !paidForRainbow {
            guard store.spendBones(soap.price) else {
                soapInHand = nil
                say("Let's do exercises to earn more bones!")
                return
            }
            paidForRainbow = true
        }
        if soap == .rainbow { usedRainbow = true }

        lastBubble = point
        // A little cluster of foam each time the soap moves
        for _ in 0..<3 {
            let jitter = CGPoint(x: point.x + .random(in: -14...14), y: point.y + .random(in: -12...12))
            bubbles.append(Bubble(point: jitter, rainbow: soap == .rainbow))
        }
        if bubbles.count > 120 { bubbles.removeFirst(bubbles.count - 120) }

        // Bubbles cover any muddy spot they land on.
        for i in mud.indices where !mud[i].scrubbed {
            let spot = buddy.point(mud[i].x, mud[i].y)
            if hypot(spot.x - point.x, spot.y - point.y) < buddy.rect.width * 0.09 {
                mud[i].scrubbed = true
                haptic += 1
            }
        }

        if actionPose != .happy {
            withAnimation(BuddyView<EmptyView>.spring) { actionPose = .happy }
        }
        if !saidBubbly {
            saidBubbly = true
            say("Hehe, bubbly!")
        }
    }

    // MARK: Rinse

    private func rinseProgress(at date: Date) -> Double {
        guard let rinseStart else { return 0 }
        return min(1, date.timeIntervalSince(rinseStart) / Self.rinseTime)
    }

    private func rinse() {
        guard rinseStart == nil else { return }
        guard !bubbles.isEmpty else {
            say("Scrub-a-dub with the soap first!")
            return
        }
        haptic += 1
        rinseStart = Date()
        say("Wheee! Splashy!")
        let scrubbedNow = scrubbed
        Task {
            try? await Task.sleep(for: .seconds(Self.rinseTime))
            let clean = store.state.needs.clean
            let gain = scrubbedNow >= 0.999 ? 1 - clean : max(0.05, scrubbedNow * (1 - clean))
            store.care(\.clean, by: gain)
            if usedRainbow { store.care(\.fun, by: Soap.rainbow.joy) }

            mud.removeAll(where: \.scrubbed)
            bubbles.removeAll()
            rinseStart = nil
            usedRainbow = false
            paidForRainbow = false
            saidBubbly = false
            cleanDone += 1

            withAnimation(BuddyView<EmptyView>.spring) {
                actionPose = .happy
                sparkle = mud.isEmpty
            }
            say(mud.isEmpty ? "Squeaky clean! Thank you!" : "Better! Let's scrub the muddy spots too.", for: 2.4)
            try? await Task.sleep(for: .seconds(2.4))
            withAnimation(BuddyView<EmptyView>.spring) {
                actionPose = nil
                sparkle = false
            }
        }
    }

    // MARK: Setup

    /// The dirtier Buddy is, the more muddy spots he has (none when he's already clean).
    private func makeMud() {
        guard mud.isEmpty else { return }
        let count = MudLayout.count(clean: store.state.needs.clean)
        mud = MudLayout.spots.prefix(count).map { MudSpot(x: $0.x, y: $0.y, size: $0.size) }
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

private struct MudSpot: Identifiable {
    let id = UUID()
    /// Position and size on the 600 × 800 art canvas.
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    var scrubbed = false
}

private struct Bubble: Identifiable {
    let id = UUID()
    let point: CGPoint
    let size = CGFloat.random(in: 16...38)
    let hue: Double
    let rainbow: Bool

    init(point: CGPoint, rainbow: Bool) {
        self.point = point
        self.rainbow = rainbow
        hue = Double.random(in: 0...1)
    }
}

private struct BubbleView: View {
    let bubble: Bubble
    @State private var popIn = false

    var body: some View {
        let tint = bubble.rainbow ? Color(hue: bubble.hue, saturation: 0.45, brightness: 1) : Color.sky
        Circle()
            .fill(RadialGradient(colors: [.white.opacity(0.25), .white.opacity(0.9)],
                                 center: UnitPoint(x: 0.35, y: 0.35), startRadius: 1, endRadius: bubble.size / 2))
            .overlay(Circle().stroke(tint.opacity(0.6), lineWidth: 1.5))
            .overlay(alignment: .topLeading) {
                Circle().fill(.white).frame(width: bubble.size * 0.22).offset(x: bubble.size * 0.2, y: bubble.size * 0.18)
            }
            .frame(width: bubble.size, height: bubble.size)
            .scaleEffect(popIn ? 1 : 0.2)
            .allowsHitTesting(false)
            .onAppear { withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { popIn = true } }
    }
}

private struct SoapBar: View {
    let soap: Soap

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(soap == .plain
                  ? AnyShapeStyle(LinearGradient(colors: [Color(hex: 0xFFF3F6), Color(hex: 0xF7C9D6)], startPoint: .top, endPoint: .bottom))
                  : AnyShapeStyle(LinearGradient(colors: [.coral, .sunny, .sprout, .sky, Color(hex: 0x9C8FD6)],
                                                 startPoint: .leading, endPoint: .trailing)))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.7), lineWidth: 2).padding(6))
            .frame(width: 58, height: 38)
            .shadow(color: .black.opacity(0.15), radius: 0, x: 0, y: 3)
    }
}

private struct ShowerHead: View {
    var body: some View {
        ZStack(alignment: .top) {
            Capsule().fill(Color(hex: 0xB9C4CC)).frame(width: 10, height: 30).offset(y: -22)
            Capsule()
                .fill(LinearGradient(colors: [Color(hex: 0xE7EEF2), Color(hex: 0xB9C4CC)], startPoint: .top, endPoint: .bottom))
                .frame(width: 110, height: 26)
            HStack(spacing: 10) {
                ForEach(0..<6) { _ in Circle().fill(Color.deepTeal.opacity(0.3)).frame(width: 5, height: 5) }
            }
            .offset(y: 15)
        }
        .shadow(color: .black.opacity(0.12), radius: 0, x: 0, y: 3)
        .accessibilityHidden(true)
    }
}

/// Falling shower water.
private struct WaterDrops: View {
    let time: Double

    var body: some View {
        Canvas { ctx, size in
            for i in 0..<36 {
                let lane = CGFloat(i % 12) / 11
                let speed = 1.4 + Double(i % 5) * 0.15
                let phase = (time * speed + Double(i) * 0.37).truncatingRemainder(dividingBy: 1)
                let x = size.width * lane + CGFloat(sin(Double(i))) * 6
                let y = size.height * CGFloat(phase)
                var p = Path()
                p.move(to: CGPoint(x: x, y: y))
                p.addLine(to: CGPoint(x: x, y: y + 16))
                ctx.stroke(p, with: .color(Color.sky.opacity(0.7)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
        }
        .allowsHitTesting(false)
    }
}

/// Twinkles around a squeaky-clean Buddy.
private struct Sparkles: View {
    let around: BuddyFrame
    @State private var on = false

    var body: some View {
        ZStack {
            ForEach(0..<6) { i in
                let angle = Double(i) / 6 * 2 * .pi
                Image(systemName: "sparkle")
                    .font(.system(size: i.isMultiple(of: 2) ? 26 : 18, weight: .bold))
                    .foregroundStyle(Color.sunny)
                    .position(x: around.center.x + cos(angle) * around.rect.width * 0.55,
                              y: around.center.y + sin(angle) * around.rect.height * 0.45)
                    .scaleEffect(on ? 1 : 0.3)
                    .opacity(on ? 1 : 0)
            }
        }
        .allowsHitTesting(false)
        .onAppear { withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { on = true } }
    }
}

/// The backyard kiddie pool. Drawn in two halves so Buddy stands *in* the water:
/// the back (sky, lawn, back rim) goes behind him, the front rim and water in front of his feet.
private struct PoolBackground: View {
    let feet: CGPoint
    let front: Bool

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let pool = CGRect(x: w * 0.04, y: feet.y - h * 0.085, width: w * 0.92, height: h * 0.15)

            if front {
                // Front half of the water and rim, over his paws
                Ellipse()
                    .fill(LinearGradient(colors: [Color.sky.opacity(0.55), Color.sky.opacity(0.75)], startPoint: .top, endPoint: .bottom))
                    .overlay(Ellipse().strokeBorder(Color.sky.shade(0.5), lineWidth: 12))
                    .mask(Rectangle().frame(height: pool.height / 2).offset(y: pool.height / 4))
                    .frame(width: pool.width, height: pool.height)
                    .position(x: pool.midX, y: pool.midY)
                    .offset(y: 0)
            } else {
                ZStack(alignment: .topLeading) {
                    LinearGradient(colors: [Color.sky.shade(0.2), Color(hex: 0xE6F5FC)], startPoint: .top, endPoint: .bottom)
                    LinearGradient(colors: [Color.sprout.shade(0.1), Color.sprout.shade(-0.12)], startPoint: .top, endPoint: .bottom)
                        .frame(height: h * 0.55)
                        .offset(y: h * 0.48)
                    Ellipse()
                        .fill(Color.sprout.shade(-0.2))
                        .frame(width: w * 1.3, height: h * 0.14)
                        .position(x: w * 0.75, y: h * 0.48)
                    Ellipse()
                        .fill(Color.sky.shade(0.45))
                        .frame(width: pool.width, height: pool.height)
                        .position(x: pool.midX, y: pool.midY)
                        .shadow(color: .black.opacity(0.12), radius: 0, x: 0, y: 4)
                    Ellipse()
                        .fill(LinearGradient(colors: [Color.sky.shade(0.15), Color.sky], startPoint: .top, endPoint: .bottom))
                        .frame(width: pool.width - 24, height: pool.height - 20)
                        .position(x: pool.midX, y: pool.midY)
                    Text("🐥").font(.system(size: 26)).position(x: pool.maxX - 50, y: pool.midY - 4)
                    PaperTexture()
                }
            }
        }
    }
}
