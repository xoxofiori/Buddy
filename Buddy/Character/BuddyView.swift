import SwiftUI

/// Buddy, built from the PDF art parts in Assets.xcassets (see BuddyCharacter/CHARACTER.md).
/// Every part sits on the same 600 × 800 canvas, so the parts are simply stacked and only
/// rotated, scaled or swapped. Nothing here redraws Buddy.
///
///     BuddyView(pose: .sleeping)
///     BuddyView(pose: .idle, height: 300, interactive: true) { event in ... }
struct BuddyView<Collar: View>: View {
    var pose: BuddyPose = .idle
    var height: CGFloat? = nil
    /// Let kids tap and pet him.
    var interactive = false
    var onInteraction: ((BuddyInteraction) -> Void)? = nil
    /// For armRaise / squat: how far into the move, 0 (resting) to 1 (all the way).
    /// Lets Buddy move in sync with the kid. nil = arm raises loop on their own and squats hold.
    var motion: Double? = nil
    /// Something worn at the neck (drawn in 600 × 800 art coordinates, between body and head).
    @ViewBuilder var collar: () -> Collar

    /// Hats, glasses, bandanas and toys from the Shop.
    @Environment(\.buddyOutfit) private var outfit

    // Always-on life
    @State private var poseStart = Date()
    @State private var blinking = false
    @State private var fidgetHead = 0.0
    @State private var fidgetEarLeft = 0.0
    @State private var fidgetEarRight = 0.0

    // Reactions to touch
    @State private var reactionEyes: BuddyEyes?
    @State private var reactionMouth: BuddyMouth?
    @State private var earFlop = 0.0
    @State private var squash: CGFloat = 1
    @State private var petting = false
    @State private var lastDrag: CGPoint?
    @State private var reactionTask: Task<Void, Never>?

    /// CHARACTER.md: all transitions use springs (response ~0.35, damping ~0.6).
    static var spring: Animation { .spring(response: 0.35, dampingFraction: 0.6) }

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { context in
                figure(size: geo.size, now: context.date)
            }
            .contentShape(BuddyTouchShape())   // only Buddy himself, not the empty corners
            .gesture(SpatialTapGesture().onEnded { tapped(at: $0.location, size: geo.size) },
                     including: interactive ? .all : .none)
            .simultaneousGesture(petGesture, including: interactive ? .all : .none)
        }
        .aspectRatio(600.0 / 800.0, contentMode: .fit)
        .frame(height: height)
        .onChange(of: pose) { poseStart = Date() }
        .task { await blinkLoop() }
        .task { await fidgetLoop() }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Buddy the puppy")
    }

    // MARK: Drawing

    @ViewBuilder
    private func figure(size: CGSize, now: Date) -> some View {
        let spec = pose.spec
        let t = now.timeIntervalSince(poseStart)
        let clock = now.timeIntervalSinceReferenceDate
        let unit = size.height / 800            // points per art pixel

        // Face
        let baseEyes = reactionEyes ?? (petting ? .happy : spec.eyes)
        let eyes: BuddyEyes = (blinking && baseEyes == .open) ? .closed : baseEyes
        let talkingMouth: BuddyMouth = Int(t / 0.12) % 2 == 0 ? .open : .smile
        let chompMouth: BuddyMouth = Int(t / 0.15) % 2 == 0 ? .open : .o
        let mouth = reactionMouth ?? (pose == .talking ? talkingMouth : pose == .eating ? chompMouth : spec.mouth)

        // Breathing: body + head scale 1.0 → 1.015 vertically, 2.4 s (slower asleep)
        let breathPeriod = pose == .sleeping ? 4.0 : 2.4
        let breath = 1 + 0.0075 * (1 - cos(clock * 2 * .pi / breathPeriod))

        // Tail: gentle ±6° sway over 1.2 s, fast ±15° wag at 0.25 s when happy
        let happy = pose.isHappy || petting || reactionEyes == .happy
        let tailMotion = happy ? sin(clock * 2 * .pi / 0.25) * 15 : sin(clock * 2 * .pi / 1.2) * 6

        // Arm motions that belong to a pose
        let raise = pose == .armRaise
            ? 112 * (motion ?? (1 - cos(t * 2 * .pi / 3)) / 2)   // 6° → 118° and back
            : 0
        let wave = pose == .waving ? sin(t * 2 * .pi / 0.6) * 12 : 0
        let chewBob = pose == .eating ? sin(t * 2 * .pi / 0.3) * 3 : 0

        // Squat: everything above the legs drops 40, legs squash to 0.75 from the feet
        let squat = pose == .squat ? (motion ?? 1) : 0
        let drop = 40 * unit * squat
        let legSquash: CGFloat = 1 - 0.25 * squat
        // Arms reach forward as he goes down (the spec's 40 / −40 at the bottom)
        let squatArmLeft = pose == .squat ? (spec.armLeft - 6) * (squat - 1) : 0
        let squatArmRight = pose == .squat ? (spec.armRight + 6) * (squat - 1) : 0

        ZStack {
            part("buddy_shadow")

            if let toy = outfit.toy { onCanvas(AccessoryArt(item: toy), size: size) }

            part("buddy_tail")
                .rotationEffect(.degrees(spec.tail), anchor: BuddyPivot.tailBase)
                .animation(Self.spring, value: pose)
                .rotationEffect(.degrees(tailMotion), anchor: BuddyPivot.tailBase)
                .offset(y: drop)

            ZStack {
                part("buddy_leg_left")
                part("buddy_leg_right")
            }
            .scaleEffect(x: 1, y: legSquash, anchor: BuddyPivot.feet)
            .animation(Self.spring, value: pose)

            ZStack {
                part("buddy_body")
                if let bandana = outfit.bandana { onCanvas(AccessoryArt(item: bandana), size: size) }
                collar()
                    .allowsHitTesting(false)
                    .frame(width: 600, height: 800)
                    .scaleEffect(unit, anchor: .topLeading)
                    .frame(width: size.width, height: size.height, alignment: .topLeading)
            }
            .scaleEffect(x: 1, y: breath, anchor: BuddyPivot.bodyBase)
            .offset(y: drop)

            headGroup(spec: spec, eyes: eyes, mouth: mouth, size: size)
                .rotationEffect(.degrees(spec.head), anchor: BuddyPivot.neck)
                .animation(Self.spring, value: pose)
                .rotationEffect(.degrees(fidgetHead + chewBob), anchor: BuddyPivot.neck)
                .scaleEffect(x: 1, y: breath, anchor: BuddyPivot.bodyBase)
                .offset(y: drop)

            // Arms: the art is drawn at rest (+6° / −6°), so rotate by the difference.
            part("buddy_arm_left")
                .rotationEffect(.degrees(spec.armLeft - 6), anchor: BuddyPivot.shoulderLeft)
                .animation(Self.spring, value: pose)
                .rotationEffect(.degrees(raise + squatArmLeft), anchor: BuddyPivot.shoulderLeft)
                .offset(y: drop)

            part("buddy_arm_right")
                .rotationEffect(.degrees(spec.armRight + 6), anchor: BuddyPivot.shoulderRight)
                .animation(Self.spring, value: pose)
                .rotationEffect(.degrees(-raise + wave + squatArmRight), anchor: BuddyPivot.shoulderRight)
                .offset(y: drop)
        }
        .scaleEffect(x: 2 - squash, y: squash, anchor: BuddyPivot.feet)
    }

    private func headGroup(spec: BuddyPoseSpec, eyes: BuddyEyes, mouth: BuddyMouth, size: CGSize) -> some View {
        ZStack {
            part("buddy_head")
            part("buddy_ear_left")
                .rotationEffect(.degrees(spec.earLeft), anchor: BuddyPivot.earLeft)
                .animation(Self.spring, value: pose)
                .rotationEffect(.degrees(fidgetEarLeft + earFlop), anchor: BuddyPivot.earLeft)
            part("buddy_ear_right")
                .rotationEffect(.degrees(spec.earRight), anchor: BuddyPivot.earRight)
                .animation(Self.spring, value: pose)
                .rotationEffect(.degrees(fidgetEarRight - earFlop), anchor: BuddyPivot.earRight)
            part(eyes.rawValue)
            part(spec.brows.rawValue)
            part(mouth.rawValue)
            if let glasses = outfit.glasses { onCanvas(AccessoryArt(item: glasses), size: size) }
            if let hat = outfit.hat { onCanvas(AccessoryArt(item: hat), size: size) }
        }
    }

    /// Something drawn on the 600 × 800 art canvas, scaled to Buddy's size.
    private func onCanvas<V: View>(_ view: V, size: CGSize) -> some View {
        view
            .frame(width: 600, height: 800)
            .scaleEffect(size.height / 800, anchor: .topLeading)
            .frame(width: size.width, height: size.height, alignment: .topLeading)
            .allowsHitTesting(false)
    }

    private func part(_ name: String) -> some View {
        Image(name)
            .resizable()
            .accessibilityHidden(true)
    }

    // MARK: Always-on life

    /// Every 3–6 s, close the eyes for 0.12 s.
    private func blinkLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(Double.random(in: 3...6)))
            blinking = true
            try? await Task.sleep(for: .seconds(0.12))
            blinking = false
        }
    }

    /// Every 8–15 s, a small head tilt (±5°) or an ear flick (±8°).
    private func fidgetLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(Double.random(in: 8...15)))
            guard pose != .sleeping else { continue }
            let sign: Double = Bool.random() ? 1 : -1
            switch Int.random(in: 0...2) {
            case 0: withAnimation(Self.spring) { fidgetHead = 5 * sign }
            case 1: withAnimation(Self.spring) { fidgetEarLeft = 8 * sign }
            default: withAnimation(Self.spring) { fidgetEarRight = 8 * sign }
            }
            try? await Task.sleep(for: .seconds(0.9))
            withAnimation(Self.spring) {
                fidgetHead = 0
                fidgetEarLeft = 0
                fidgetEarRight = 0
            }
        }
    }

    // MARK: Touch

    private func tapped(at location: CGPoint, size: CGSize) {
        let art = CGPoint(x: location.x / size.width * 600, y: location.y / size.height * 800)
        if Collar.self != EmptyView.self, BuddyPivot.collarTag.contains(art) {
            onInteraction?(.tapCollar)
        } else if location.y / size.height < BuddyPivot.neck.y {
            tapHead()
        } else {
            tapBelly()
        }
    }

    /// Ears flop ±12° with a spring, happy eyes, a giggle.
    private func tapHead() {
        onInteraction?(.tapHead)
        BuddyVoice.shared.say("hee hee!")
        react {
            withAnimation(Self.spring) {
                earFlop = 12
                reactionEyes = .happy
            }
            try? await Task.sleep(for: .seconds(0.3))
            withAnimation(Self.spring) { earFlop = 0 }
            try? await Task.sleep(for: .seconds(0.7))
            withAnimation(Self.spring) { reactionEyes = nil }
        }
    }

    /// Squash-and-stretch bounce (0.95 → 1.05 → 1) with an open mouth.
    private func tapBelly() {
        onInteraction?(.tapBelly)
        react {
            reactionMouth = .open
            withAnimation(.spring(response: 0.15, dampingFraction: 0.7)) { squash = 0.95 }
            try? await Task.sleep(for: .seconds(0.12))
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) { squash = 1.05 }
            try? await Task.sleep(for: .seconds(0.16))
            withAnimation(Self.spring) { squash = 1 }
            try? await Task.sleep(for: .seconds(0.5))
            reactionMouth = nil
        }
    }

    /// Run one reaction at a time; a new tap replaces the old one cleanly.
    private func react(_ steps: @escaping @MainActor () async -> Void) {
        reactionTask?.cancel()
        reactionTask = Task {
            await steps()
        }
    }

    /// Petting: happy eyes and a fast tail wag while dragging.
    private var petGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                if !petting { petting = true }
                let moved = lastDrag.map { hypot(value.location.x - $0.x, value.location.y - $0.y) } ?? 0
                lastDrag = value.location
                onInteraction?(.petting(at: value.location, distance: moved))
            }
            .onEnded { _ in
                petting = false
                lastDrag = nil
                onInteraction?(.petEnded)
            }
    }
}

extension BuddyView where Collar == EmptyView {
    init(pose: BuddyPose = .idle, height: CGFloat? = nil, interactive: Bool = false,
         onInteraction: ((BuddyInteraction) -> Void)? = nil, motion: Double? = nil) {
        self.init(pose: pose, height: height, interactive: interactive,
                  onInteraction: onInteraction, motion: motion, collar: { EmptyView() })
    }
}

#Preview("Pose sheet") {
    LazyVGrid(columns: [GridItem(), GridItem(), GridItem()], spacing: 16) {
        ForEach(BuddyPose.allCases, id: \.self) { pose in
            VStack {
                BuddyView(pose: pose, height: 220)
                Text(pose.rawValue).font(.buddyBody)
            }
        }
    }
    .padding()
    .background(Color.cream)
}
