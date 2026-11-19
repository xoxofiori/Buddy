import SwiftUI
import Testing
@testable import Buddy

/// Saves PNGs of Buddy and the home screen for a quick visual check.
/// Only runs when RENDER_DIR is set, e.g.
/// `TEST_RUNNER_RENDER_DIR=/some/folder xcodebuild test ...`
@MainActor
struct RenderSnapshots {
    private var renderDir: URL? {
        ProcessInfo.processInfo.environment["RENDER_DIR"].map { URL(filePath: $0) }
    }

    @Test func buddyPoses() throws {
        guard let dir = renderDir else { return }
        let grid = LazyVGrid(columns: [GridItem(), GridItem(), GridItem(), GridItem()], spacing: 16) {
            ForEach(BuddyPose.allCases, id: \.self) { pose in
                VStack {
                    BuddyView(pose: pose, height: 300)
                    Text(pose.rawValue).font(.buddyBody)
                }
            }
        }
        .padding(30)
        .frame(width: 1000)
        .background(Color.cream)
        try save(grid, to: dir.appending(path: "buddy-poses.png"))
    }

    @Test func homeAtEveryTimeOfDay() throws {
        guard let dir = renderDir else { return }
        let store = GameStore(fileURL: FileManager.default.temporaryDirectory.appending(path: "render-\(UUID()).json"))
        store.state.kidName = "Maya"
        _ = store.redeem(code: "BUDDY123")
        for time in TimeOfDay.allCases {
            let home = HomeView(forcedTime: time)
                .environment(store)
                .fontDesign(.rounded)
                .frame(width: 402, height: 874)
            try save(home, to: dir.appending(path: "home-\(time.rawValue).png"))
        }
    }

    @Test func careRooms() throws {
        guard let dir = renderDir else { return }
        let store = GameStore(fileURL: FileManager.default.temporaryDirectory.appending(path: "rooms-\(UUID()).json"))
        store.state.kidName = "Maya"
        _ = store.redeem(code: "BUDDY123")
        store.state.needs = Needs(hunger: 0.4, energy: 0.3, clean: 0.35, fun: 0.6)
        let rooms: [(String, AnyView)] = [
            ("kitchen", AnyView(KitchenView {})),
            ("bath", AnyView(BathView {})),
            ("bed", AnyView(BedView {})),
        ]
        for (name, view) in rooms {
            let screen = view
                .environment(store)
                .fontDesign(.rounded)
                .frame(width: 402, height: 874)
            try save(screen, to: dir.appending(path: "room-\(name).png"))
        }
    }

    @Test func exerciseScreens() throws {
        guard let dir = renderDir else { return }
        let store = GameStore(fileURL: FileManager.default.temporaryDirectory.appending(path: "exr-\(UUID()).json"))
        store.state.kidName = "Maya"
        _ = store.redeem(code: "BUDDY123")
        for planned in store.state.plan?.exercises ?? [] {
            let demo = ExerciseSessionView(exercise: planned, kidName: "Maya", practice: true) {}
            try save(demo.environment(store).fontDesign(.rounded).frame(width: 402, height: 874),
                     to: dir.appending(path: "exercise-\(planned.kind.rawValue)-demo.png"))

            let session = ExerciseSession(exercise: planned, kidName: "Maya", practice: true)
            let pretend = PracticePoseSource(kind: planned.kind)
            let angles = stride(from: 0.0, to: 3 * PracticePoseSource.repTime + 1.6, by: 1.0 / 30).map { pretend.angle(at: $0) }
            session.preview(phase: .active, frame: pretend.frame(at: 3 * PracticePoseSource.repTime + 1.6), reps: angles)
            let framing = ExerciseSession(exercise: planned, kidName: "Maya", practice: true)
            framing.preview(phase: .framing, frame: nil)
            try save(ExerciseActiveView(session: framing) {}.background(Color.cream)
                        .environment(store).fontDesign(.rounded).frame(width: 402, height: 874),
                     to: dir.appending(path: "exercise-\(planned.kind.rawValue)-framing.png"))
            let active = ExerciseActiveView(session: session) {}
                .background(Color.cream)
            try save(active.environment(store).fontDesign(.rounded).frame(width: 402, height: 874),
                     to: dir.appending(path: "exercise-\(planned.kind.rawValue)-active.png"))
        }
        let celebration = CelebrationView(kind: .armRaises, kidName: "Maya",
                                          result: ExerciseResult(reps: 20, inTargetReps: 18, tries: 21),
                                          reward: ExerciseReward(bones: 38, goldenBones: 18)) {}
            .background(Color.cream)
        try save(celebration.environment(store).fontDesign(.rounded).frame(width: 402, height: 874),
                 to: dir.appending(path: "exercise-celebration.png"))
    }

    @Test func shopAndOutfits() throws {
        guard let dir = renderDir else { return }
        let store = GameStore(fileURL: FileManager.default.temporaryDirectory.appending(path: "shopr-\(UUID()).json"))
        store.state.kidName = "Maya"
        _ = store.redeem(code: "BUDDY123")
        _ = store.buy(.partyHat)
        _ = store.buy(.redBandana)
        try save(ShopView {}.environment(store).fontDesign(.rounded).frame(width: 402, height: 874),
                 to: dir.appending(path: "shop.png"))

        // Every item on Buddy
        let looks: [Outfit] = [
            Outfit(hat: .partyHat, bandana: .redBandana, glasses: .roundGlasses, toy: .tennisBall),
            Outfit(hat: .cap, bandana: .skyBandana, glasses: .heartGlasses, toy: .squeakyBone),
            Outfit(hat: .beanie, bandana: .starBandana, glasses: .starSunglasses, toy: .frisbee),
            Outfit(hat: .crown, toy: .rubberDuck),
            Outfit(toy: .teddy),
        ]
        let grid = HStack(spacing: 10) {
            ForEach(looks.indices, id: \.self) { i in
                BuddyView(pose: .idle, height: 300).environment(\.buddyOutfit, looks[i])
            }
        }
        .padding(20)
        .background(Color.cream)
        try save(grid, to: dir.appending(path: "outfits.png"))
    }

    @Test func checkInProgressAndSettings() throws {
        guard let dir = renderDir else { return }
        let store = GameStore(fileURL: FileManager.default.temporaryDirectory.appending(path: "cps-\(UUID()).json"))
        store.state.kidName = "Maya"
        _ = store.redeem(code: "BUDDY123")
        store.finishExercise(.armRaises, result: ExerciseResult(reps: 20, inTargetReps: 18, tries: 21))
        func shot(_ view: some View, _ name: String) throws {
            try save(view.environment(store).fontDesign(.rounded).frame(width: 402, height: 874),
                     to: dir.appending(path: name))
        }
        try shot(CheckInView {}, "checkin.png")
        try shot(GrownUpSettingsView(timeOverride: .constant(nil)) {}, "settings.png")
        store.checkIn(pain: 2)
        // Progress is in a scroll view (which snapshots can't draw), so render its content tall.
        try shot(ProgressScreen {}.frame(height: 1300), "progress.png")
    }

    @Test func onboardingScreens() throws {
        guard let dir = renderDir else { return }
        let store = GameStore(fileURL: FileManager.default.temporaryDirectory.appending(path: "ob-\(UUID()).json"))
        store.state.kidName = "Maya"
        let screens: [(String, AnyView)] = [
            ("welcome", AnyView(ZStack { OnboardingScene(); WelcomeStepView {} })),
            ("name", AnyView(ZStack { OnboardingScene(hillTop: 0.6); NameStepView(onBack: {}, onNext: {}) })),
            ("code", AnyView(ZStack { OnboardingScene(hillTop: 0.6); CodeStepView(onBack: {}) })),
        ]
        for (name, view) in screens {
            try save(view.environment(store).fontDesign(.rounded).frame(width: 402, height: 874),
                     to: dir.appending(path: "onboarding-\(name).png"))
        }
    }

    @Test func hungryAndMuddy() throws {
        guard let dir = renderDir else { return }
        let looks = HStack(spacing: 12) {
            BuddyView(pose: .hungry, height: 320)
            BuddyView(pose: .idle, height: 320).environment(\.buddyMud, 4)
            BuddyView(pose: .hungry, height: 320).environment(\.buddyMud, 8)
        }
        .padding(20)
        .background(Color.cream)
        try save(looks, to: dir.appending(path: "hungry-muddy.png"))

        let store = GameStore(fileURL: FileManager.default.temporaryDirectory.appending(path: "hm-\(UUID()).json"))
        store.state.kidName = "Maya"
        _ = store.redeem(code: "BUDDY123")
        store.state.needs.hunger = 0.15
        store.state.needs.clean = 0.2
        try save(HomeView(forcedTime: .day).environment(store).fontDesign(.rounded).frame(width: 402, height: 874),
                 to: dir.appending(path: "home-hungry-muddy.png"))
    }

    private func save(_ view: some View, to url: URL) throws {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        guard let image = renderer.uiImage, let data = image.pngData() else {
            Issue.record("Render failed")
            return
        }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
    }
}
