import SwiftUI

/// Home: Buddy's Backyard. The scene and Buddy are the interface: tap things in the yard
/// to look after him, tap or pet Buddy, and start today's exercises from the card on top.
struct HomeView: View {
    /// Pin the time of day (previews and screenshots); nil follows the real clock.
    var forcedTime: TimeOfDay? = nil

    @Environment(GameStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase

    @State private var now = Date()
    @State private var timeOverride: TimeOfDay?
    @State private var sheet: HomeSheet?
    @State private var room: CareRoom?
    @State private var exercise: PlannedExercise?
    @State private var planExpanded = true
    @State private var confirmStartOver = false

    private var time: TimeOfDay { forcedTime ?? timeOverride ?? TimeOfDay(date: now) }

    var body: some View {
        ZStack {
            BackyardScene(time: time, needs: store.state.needs, layer: .scenery) { _ in }
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Time-of-day light over the sky, grass and fence only: the things you can tap
            // (and their icons) and Buddy stay bright and clear all day.
            Rectangle()
                .fill(time.light)
                .opacity(time.lightOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            BackyardScene(time: time, needs: store.state.needs, layer: .objects) { spot in
                room = spot.room
            }
            .ignoresSafeArea()

            BuddyStage(
                kidName: store.state.kidName,
                needs: store.state.needs,
                time: time,
                onFun: { store.addFun($0) },
                onTapHeart: { sheet = .heart },
                onOpen: { room = $0 }
            )

            if time == .night {
                Fireflies().ignoresSafeArea()
            }

            VStack(spacing: 10) {
                topBar
                if let plan = store.state.plan {
                    TodayCard(plan: plan, done: store.doneToday(now: now), expanded: $planExpanded) { item in
                        switch item {
                        case .exercise(let e): exercise = e
                        case .checkIn: sheet = .checkIn
                        }
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .fullScreenCover(item: $exercise) { planned in
                ExerciseSessionView(exercise: planned, kidName: store.state.kidName) {
                    exercise = nil
                    now = Date()
                }
                .environment(\.buddyOutfit, store.state.outfit)
            }
        }
        .sheet(item: $sheet) { sheet in
            sheetView(sheet)
        }
        .fullScreenCover(item: $room) { room in
            Group {
                switch room {
                case .kitchen: KitchenView { self.room = nil }
                case .bath: BathView { self.room = nil }
                case .bed: BedView { self.room = nil }
                case .shop: ShopView { self.room = nil }
                case .progress: ProgressScreen { self.room = nil }
                }
            }
            .environment(\.buddyOutfit, store.state.outfit)
        }
        .task {
            // Needs drain slowly in real time (including while the app was closed),
            // and the sky follows the clock.
            store.tickNeeds()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                store.tickNeeds()
                now = Date()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                store.tickNeeds()
                now = Date()
            }
        }
    }

    private var topBar: some View {
        HStack {
            Text("Hi \(store.state.kidName)!")
                .font(.buddy(26, .heavy))
                .foregroundStyle(time == .night ? Color.paper : Color.deepTeal)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .shadow(color: .black.opacity(time == .night ? 0.3 : 0), radius: 3)
                // Hidden grown-up settings: hold the greeting for 1.5 seconds.
                .onLongPressGesture(minimumDuration: 1.5) {
                    Feedback.tap()
                    sheet = .settings
                }
            Spacer()
            demoMenu
        }
        .padding(.horizontal, 6)
    }

    /// Hidden demo controls: tap the bone counter.
    private var demoMenu: some View {
        Menu {
            Button {
                store.resetToday()
                now = Date()
                Feedback.success()
            } label: {
                Label("Reset today", systemImage: "arrow.counterclockwise")
            }
            Button(role: .destructive) {
                confirmStartOver = true
            } label: {
                Label("Start over", systemImage: "trash")
            }
        } label: {
            BoneCounter(bones: store.state.bones)
        }
        .menuOrder(.fixed)
        .simultaneousGesture(TapGesture().onEnded { Feedback.tap() })
        .confirmationDialog("Start the demo over?", isPresented: $confirmStartOver, titleVisibility: .visible) {
            Button("Start over", role: .destructive) {
                timeOverride = nil
                store.reset()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears the saved game and goes back to the start.")
        }
    }

    @ViewBuilder
    private func sheetView(_ sheet: HomeSheet) -> some View {
        switch sheet {
        case .checkIn:
            CheckInView {
                self.sheet = nil
                now = Date()
            }
            .environment(\.buddyOutfit, store.state.outfit)
            .presentationDetents([.large])
            .presentationCornerRadius(36)
        case .heart:
            HeartDetailSheet(needs: store.state.needs)
        case .settings:
            GrownUpSettingsView(timeOverride: $timeOverride) { self.sheet = nil }
        }
    }
}

/// Buddy standing in the yard: picks his pose, wears his collar, and reacts to touch.
private struct BuddyStage: View {
    let kidName: String
    let needs: Needs
    let time: TimeOfDay
    var onFun: (Double) -> Void
    var onTapHeart: () -> Void
    /// Open a care room (from the "Hungry" / "Muddy" bubble).
    var onOpen: (CareRoom) -> Void

    @State private var speech: String?
    @State private var gesturePose: BuddyPose?
    @State private var awakeUntil = Date.distantPast
    @State private var hearts: [FloatingHeart] = []
    @State private var petDistance: CGFloat = 0
    @State private var haptic = 0
    @State private var speechTask: Task<Void, Never>?

    private var needsCare: Bool {
        min(needs.hunger, needs.energy, needs.clean, needs.fun) < 0.3
    }

    /// Hungry enough to hold his tummy.
    private var isHungry: Bool { needs.hunger < Self.hungryBelow }
    /// Muddy enough to show spots.
    private var isMuddy: Bool { needs.clean < Self.muddyBelow }

    static let hungryBelow = 0.3
    static let muddyBelow = 0.5

    private var isAsleep: Bool { time == .night && Date() > awakeUntil }

    private var pose: BuddyPose {
        if let gesturePose { return gesturePose }
        if speech != nil { return .talking }
        if isAsleep { return .sleeping }
        if isHungry { return .hungry }
        if needsCare { return .needsCare }
        return .idle
    }

    /// What Buddy most wants right now, shown as a tappable bubble over his head.
    private var want: (label: String, icon: String, color: Color, room: CareRoom)? {
        if isHungry { return ("Hungry", "fork.knife", .coral, .kitchen) }
        if isMuddy { return ("Muddy", "bubbles.and.sparkles.fill", .sky, .bath) }
        return nil
    }

    var body: some View {
        GeometryReader { geo in
            // Feet near the bottom of the yard, head below the plan card.
            let height = min(geo.size.height * 0.5, 400)
            let feetY = geo.size.height * 0.95

            BuddyView(pose: pose, height: height, interactive: true, onInteraction: handle) {
                BuddyCollar(needs: needs)
            }
            .environment(\.buddyMud, isMuddy ? MudLayout.count(clean: needs.clean) : 0)
            .accessibilityAction(named: "Show Buddy's heart", onTapHeart)
            .overlay(alignment: .topTrailing) {
                if speech == nil, !isAsleep, let want {
                    WantBubble(label: want.label, icon: want.icon, color: want.color) { onOpen(want.room) }
                        .offset(x: 24, y: -height * 0.02)
                        .transition(.scale(scale: 0.4, anchor: .bottomLeading).combined(with: .opacity))
                }
            }
            .overlay(alignment: .top) { bubble.offset(y: height * 0.02) }
            .animation(BuddyView<EmptyView>.spring, value: want?.label)
            .overlay { heartLayer }
            .position(x: geo.size.width / 2, y: feetY - height * (752.0 / 800) + height / 2)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: haptic)
        .task {
            // Say hi with a wave when the yard opens (unless he's asleep).
            guard time != .night else { return }
            try? await Task.sleep(for: .seconds(0.6))
            gesturePose = .waving
            say("Hi \(kidName)!", for: 2.4)
            try? await Task.sleep(for: .seconds(2.4))
            gesturePose = nil
        }
        .task(id: want?.label) {
            // Every so often, Buddy says what he needs so the kid knows what to do.
            guard let want else { return }
            try? await Task.sleep(for: .seconds(4))
            while !Task.isCancelled {
                if !isAsleep, speech == nil, gesturePose == nil {
                    say(want.room == .kitchen
                        ? ["My tummy is rumbling… Can I have a snack?", "I'm so hungry! Tap my bowl?"].randomElement()!
                        : ["I'm all muddy! Bath time?", "Eww, mud! Can you give me a bath?"].randomElement()!,
                        for: 2.8)
                }
                try? await Task.sleep(for: .seconds(Double.random(in: 18...28)))
            }
        }
    }

    // MARK: Touch

    private func handle(_ event: BuddyInteraction) {
        switch event {
        case .tapCollar:
            haptic += 1
            onTapHeart()
        case .tapHead:
            haptic += 1
            onFun(0.01)
            if pose == .sleeping {
                awakeUntil = Date().addingTimeInterval(8)
                say("*yawn* Hi \(kidName)!", for: 2.2)
                Task {
                    // Drift back to sleep after a little while.
                    try? await Task.sleep(for: .seconds(8))
                    withAnimation(BuddyView<EmptyView>.spring) { awakeUntil = .distantPast }
                }
            } else {
                showBubble("Hehe!", for: 1.4)
            }
        case .tapBelly:
            haptic += 1
            onFun(0.01)
            say("That tickles!", for: 1.6)
        case .petting(let point, let distance):
            petDistance += distance
            if petDistance > 80 {
                petDistance = 0
                addHeart(at: point)
                haptic += 1
                onFun(0.02)
            }
        case .petEnded:
            petDistance = 0
            say("I love pets!", for: 1.8)
        }
    }

    // MARK: Speech bubble

    /// Show words and say them out loud; Buddy's mouth moves while he talks.
    private func say(_ text: String, for seconds: Double) {
        BuddyVoice.shared.say(text)
        showBubble(text, for: seconds)
    }

    private func showBubble(_ text: String, for seconds: Double) {
        withAnimation(BuddyView<EmptyView>.spring) { speech = text }
        speechTask?.cancel()
        speechTask = Task {
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            withAnimation(BuddyView<EmptyView>.spring) { speech = nil }
        }
    }

    @ViewBuilder
    private var bubble: some View {
        if let speech {
            Text(speech)
                .font(.buddy(20, .heavy))
                .foregroundStyle(Color.deepTeal)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(StoryCard(shape: RoundedRectangle(cornerRadius: 22)))
                .frame(width: 260)
                .transition(.scale(scale: 0.5, anchor: .bottom).combined(with: .opacity))
                .id(speech)
        }
    }

    // MARK: Hearts

    private func addHeart(at point: CGPoint) {
        let heart = FloatingHeart(start: point)
        hearts.append(heart)
        Task {
            try? await Task.sleep(for: .seconds(1.1))
            hearts.removeAll { $0.id == heart.id }
        }
    }

    private var heartLayer: some View {
        ZStack(alignment: .topLeading) {
            ForEach(hearts) { FloatingHeartView(heart: $0) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .allowsHitTesting(false)
    }
}

private struct FloatingHeart: Identifiable {
    let id = UUID()
    let start: CGPoint
    let drift = CGFloat.random(in: -20...20)
}

private struct FloatingHeartView: View {
    let heart: FloatingHeart
    @State private var rise = false

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 30))
            .foregroundStyle(Color.coral)
            .scaleEffect(rise ? 1.2 : 0.4)
            .opacity(rise ? 0 : 1)
            .position(x: heart.start.x + (rise ? heart.drift : 0),
                      y: heart.start.y - (rise ? 90 : 0))
            .onAppear {
                withAnimation(.easeOut(duration: 1)) { rise = true }
            }
    }
}

/// "Hungry" / "Muddy": a little thought bubble over Buddy. Tapping it opens the room that helps.
private struct WantBubble: View {
    let label: String
    let icon: String
    let color: Color
    let action: () -> Void

    @State private var bob = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.paper)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(color))
                    Text(label)
                        .font(.buddy(18, .heavy))
                        .foregroundStyle(Color.deepTeal)
                }
                .padding(.leading, 6)
                .padding(.trailing, 14)
                .frame(minHeight: 44)
                .background(StoryCard(shape: Capsule()))
                // Thought-bubble dots trailing down toward Buddy
                HStack(spacing: 4) {
                    Circle().fill(Color.paper).frame(width: 11, height: 11)
                    Circle().fill(Color.paper).frame(width: 7, height: 7).offset(x: -4, y: 7)
                }
                .padding(.leading, 12)
                .shadow(color: .deepTeal.opacity(0.1), radius: 2, y: 1)
            }
            .frame(minWidth: Theme.minTap, minHeight: Theme.minTap)
            .contentShape(Rectangle())
            .offset(y: bob ? -4 : 2)
        }
        .buttonStyle(SquishStyle())
        .accessibilityLabel("Buddy is \(label.lowercased()). Tap to help him.")
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { bob = true }
        }
    }
}
