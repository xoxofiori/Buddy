import SwiftUI

/// Snack time (opened from the food bowl), inside Buddy's house. Swipe the carousel to pick a snack, then drag it
/// up to Buddy's mouth. He chomps it, crumbs fall, and the "fed" part of his heart fills.
struct KitchenView: View {
    var onClose: () -> Void

    @Environment(GameStore.self) private var store

    @State private var selected = 0
    @State private var swipe: CGFloat = 0
    @State private var mode: DragMode?
    @State private var held: FoodItem?
    @State private var heldPoint: CGPoint = .zero
    @State private var heldScale: CGFloat = 1
    @State private var actionPose: BuddyPose?
    @State private var speech: String?
    @State private var crumbs: [Crumb] = []
    @State private var haptic = 0
    @State private var yum = 0
    @State private var speechTask: Task<Void, Never>?
    @State private var poseTask: Task<Void, Never>?

    private enum DragMode { case swipe, food }
    private let foods = FoodItem.allCases
    private let spacing: CGFloat = 128

    private var pose: BuddyPose {
        if let actionPose { return actionPose }
        if speech != nil { return .talking }
        return store.state.needs.hunger < 0.3 ? .hungry : .idle
    }

    var body: some View {
        ZStack {
            // Inside Buddy's house: wall, window, wooden floor, and a rug under his paws
            HouseInterior(floorTop: 0.52, rugAt: 0.7).ignoresSafeArea()

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let buddy = BuddyFrame(feetAt: CGPoint(x: w / 2, y: h * 0.7), height: min(h * 0.42, 360))
                let carousel = CGPoint(x: w / 2, y: h * 0.88)

                ZStack(alignment: .topLeading) {
                    BuddyView(pose: pose, height: buddy.rect.height)
                        .position(buddy.center)

                    ForEach(crumbs) { CrumbView(crumb: $0) }

                    if let speech {
                        SpeechBubble(text: speech)
                            .position(x: w / 2, y: buddy.rect.minY + 20)
                    }

                    Text(held == nil ? "Drag a snack to Buddy's mouth!" : "Over here! Yum!")
                        .font(.buddy(16, .bold))
                        .foregroundStyle(Color.deepTeal.opacity(0.8))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(StoryCard(shape: Capsule()))
                        .position(x: w / 2, y: carousel.y - 104)

                    carouselView(width: w)
                        .frame(width: w, height: 170)
                        .contentShape(Rectangle())
                        .position(carousel)
                        .gesture(dragGesture(buddy: buddy, home: carousel, width: w))
                        .simultaneousGesture(SpatialTapGesture(coordinateSpace: .named("kitchen")).onEnded { tap in
                            tapped(x: tap.location.x, width: w)
                        })

                    if let held {
                        Text(held.emoji)
                            .font(.system(size: 64))
                            .scaleEffect(heldScale)
                            .shadow(color: .black.opacity(0.2), radius: 4, y: 4)
                            .position(heldPoint)
                            .allowsHitTesting(false)
                    }
                }
                .coordinateSpace(.named("kitchen"))
            }

            VStack {
                CareRoomHeader(title: "Snack time", need: .fed, value: store.state.needs.hunger,
                               bones: store.state.bones, onClose: onClose)
                Spacer()
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: haptic)
        .sensoryFeedback(.success, trigger: yum)
        .task {
            try? await Task.sleep(for: .seconds(0.4))
            say(store.state.needs.hunger < 0.5 ? "I'm hungry!" : "Snack time!")
        }
    }

    // MARK: Carousel

    private func carouselView(width: CGFloat) -> some View {
        ZStack {
            ForEach(foods.indices, id: \.self) { i in
                let rel = CGFloat(i - selected) + swipe / spacing
                let distance = min(abs(rel), 2)
                FoodCard(food: foods[i], affordable: store.state.bones >= foods[i].price)
                    .opacity(i == selected && held != nil ? 0.35 : 1)
                    .scaleEffect(1 - min(abs(rel), 1) * 0.28)
                    .opacity(abs(rel) > 2.4 ? 0 : 1 - distance * 0.25)
                    .offset(x: rel * spacing)
                    .zIndex(-Double(abs(rel)))
            }
        }
        .frame(width: width)
    }

    private func tapped(x: CGFloat, width: CGFloat) {
        guard mode == nil else { return }
        Feedback.tap()
        if x < width / 2 - 70, selected > 0 {
            withAnimation(Theme.bouncy) { selected -= 1 }
        } else if x > width / 2 + 70, selected < foods.count - 1 {
            withAnimation(Theme.bouncy) { selected += 1 }
        } else {
            say("Drag it up to my mouth!")
        }
    }

    private func dragGesture(buddy: BuddyFrame, home: CGPoint, width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .named("kitchen"))
            .onChanged { value in
                if mode == nil {
                    let dx = value.translation.width
                    let dy = value.translation.height
                    let onCenterCard = abs(value.startLocation.x - width / 2) < 72
                    if dy < 0, abs(dy) > abs(dx), onCenterCard {
                        mode = .food
                        held = foods[selected]
                        heldScale = 1
                        haptic += 1
                    } else {
                        mode = .swipe
                    }
                }
                switch mode {
                case .food:
                    heldPoint = value.location
                    let near = buddy.head.contains(value.location)
                    if actionPose != .eating {
                        withAnimation(BuddyView<EmptyView>.spring) { actionPose = near ? .happy : nil }
                    }
                case .swipe:
                    swipe = value.translation.width
                case nil:
                    break
                }
            }
            .onEnded { value in
                if mode == .food {
                    drop(at: value.location, buddy: buddy, home: home)
                } else {
                    let flick = value.predictedEndTranslation.width
                    var next = selected
                    if flick < -spacing / 2 { next += 1 } else if flick > spacing / 2 { next -= 1 }
                    next = min(max(next, 0), foods.count - 1)
                    if next != selected { haptic += 1 }
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        selected = next
                        swipe = 0
                    }
                }
                mode = nil
            }
    }

    // MARK: Feeding

    private func drop(at point: CGPoint, buddy: BuddyFrame, home: CGPoint) {
        let food = foods[selected]
        guard buddy.head.contains(point) else {
            flyBack(to: home)
            return
        }
        switch store.feed(food) {
        case .ate:
            yum += 1
            withAnimation(.easeIn(duration: 0.22)) {
                heldPoint = buddy.mouth
                heldScale = 0.15
            }
            Task {
                try? await Task.sleep(for: .seconds(0.22))
                held = nil
                heldScale = 1
                spawnCrumbs(at: buddy.mouth)
                showPose(.eating, for: 1.6)
                try? await Task.sleep(for: .seconds(0.4))
                say(food == .pupcake ? "Best treat ever!" : ["Yum!", "Mmm, tasty!", "Crunch crunch!"].randomElement()!)
            }
        case .full:
            flyBack(to: home)
            say("I'm so full! Maybe later.")
        case .needsBones:
            flyBack(to: home)
            say("Let's do exercises to earn more bones!")
        }
    }

    private func flyBack(to home: CGPoint) {
        withAnimation(BuddyView<EmptyView>.spring) {
            heldPoint = home
            actionPose = nil
        }
        Task {
            try? await Task.sleep(for: .seconds(0.3))
            held = nil
        }
    }

    private func spawnCrumbs(at mouth: CGPoint) {
        let new = (0..<7).map { _ in Crumb(start: mouth) }
        crumbs.append(contentsOf: new)
        Task {
            try? await Task.sleep(for: .seconds(0.9))
            crumbs.removeAll { c in new.contains { $0.id == c.id } }
        }
    }

    private func showPose(_ pose: BuddyPose, for seconds: Double) {
        actionPose = pose
        poseTask?.cancel()
        poseTask = Task {
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
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

/// One snack in the carousel, with its price in bones.
private struct FoodCard: View {
    let food: FoodItem
    let affordable: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text(food.emoji).font(.system(size: 54))
            Text(food.name)
                .font(.buddy(16, .heavy))
                .foregroundStyle(Color.deepTeal)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            HStack(spacing: 4) {
                if food.price == 0 {
                    Text("Free").font(.buddy(14, .heavy))
                } else {
                    BoneShape().fill(Color(hex: 0xE9CF9F)).frame(width: 20, height: 10)
                    Text("\(food.price)").font(.buddy(15, .heavy))
                }
            }
            .foregroundStyle(affordable ? Color.deepTeal.opacity(0.7) : Color.coral)
        }
        .frame(width: 118, height: 150)
        .background(StoryCard(shape: RoundedRectangle(cornerRadius: 26)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(food.name), \(food.price == 0 ? "free" : "\(food.price) bones")")
    }
}

private struct Crumb: Identifiable {
    let id = UUID()
    let start: CGPoint
    let dx = CGFloat.random(in: -40...40)
    let size = CGFloat.random(in: 5...10)
}

private struct CrumbView: View {
    let crumb: Crumb
    @State private var fallen = false

    var body: some View {
        Circle()
            .fill(Color(hex: 0xC48A4A))
            .frame(width: crumb.size, height: crumb.size)
            .position(x: crumb.start.x + (fallen ? crumb.dx : 0), y: crumb.start.y + (fallen ? 80 : 0))
            .opacity(fallen ? 0 : 1)
            .allowsHitTesting(false)
            .onAppear { withAnimation(.easeIn(duration: 0.8)) { fallen = true } }
    }
}
