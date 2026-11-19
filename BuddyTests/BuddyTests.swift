import Foundation
import Testing
@testable import Buddy

@MainActor
struct OnboardingTests {
    private func tempStore() -> (GameStore, URL) {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "gamestate-\(UUID().uuidString).json")
        return (GameStore(fileURL: url), url)
    }

    @Test func demoCodeLoadsMayasPlan() {
        let (store, _) = tempStore()
        store.state.kidName = "Maya"
        #expect(store.redeem(code: " buddy123 "))
        #expect(store.state.hasFinishedOnboarding)
        #expect(store.state.kidName == "Maya")
        #expect(store.state.patient?.therapistName == "Dr. Lee")
        #expect(store.state.plan?.exercises.count == 2)
        #expect(store.state.history.count == 14)
        #expect(store.state.adherence > 0.5 && store.state.adherence < 1)
    }

    @Test func otherCodesDoNothing() {
        let (store, _) = tempStore()
        #expect(!store.redeem(code: "HELLO"))
        #expect(!store.state.hasFinishedOnboarding)
    }

    /// Saving must never change `state` itself, or each save triggers another save
    /// and the app crashes (this happened in the first Phase 1 build).
    @Test func savingDoesNotChangeState() {
        let (store, _) = tempStore()
        let before = store.state.lastUpdated
        store.state.kidName = "Maya"      // saves
        store.state.bones += 5            // saves again
        store.tickNeeds()                 // and again
        #expect(store.state.lastUpdated == before)
    }

    @Test func stateIsSavedAndReloaded() {
        let (store, url) = tempStore()
        store.state.kidName = "Sam"
        _ = store.redeem(code: "BUDDY123")
        let reloaded = GameStore(fileURL: url)
        #expect(reloaded.state.kidName == "Sam")
        #expect(reloaded.state.bones == 50)
        #expect(reloaded.state.hasFinishedOnboarding)
    }
}

@MainActor
struct NeedsTests {
    @Test func barsDrainOverRealTime() {
        let url = FileManager.default.temporaryDirectory.appending(path: "needs-\(UUID()).json")
        let store = GameStore(fileURL: url)
        _ = store.redeem(code: "BUDDY123")
        let start = store.state.needsUpdatedAt ?? Date()
        let before = store.state.needs

        store.tickNeeds(now: start.addingTimeInterval(10 * 3600))   // 10 hours later
        let after = store.state.needs
        #expect(abs(after.hunger - (before.hunger - 0.5)) < 0.001)
        #expect(after.fun == 0)                                       // never below empty
        #expect(after.clean < before.clean && after.energy < before.energy)

        // Saved, so a reopened app keeps the drained bars.
        #expect(GameStore(fileURL: url).state.needs == after)
    }

    @Test func pettingAddsFunButCapsAtFull() {
        let store = GameStore(fileURL: FileManager.default.temporaryDirectory.appending(path: "fun-\(UUID()).json"))
        store.state.needs.fun = 0.99
        store.addFun(0.05)
        #expect(store.state.needs.fun == 1)
    }
}

@MainActor
struct CareTests {
    private func store(bones: Int = 50, hunger: Double = 0.4) -> GameStore {
        let s = GameStore(fileURL: FileManager.default.temporaryDirectory.appending(path: "care-\(UUID()).json"))
        s.state.bones = bones
        s.state.needs.hunger = hunger
        return s
    }

    @Test func feedingCostsBonesAndFillsHunger() {
        let s = store()
        #expect(s.feed(.pupcake) == .ate)
        #expect(s.state.bones == 45)
        #expect(abs(s.state.needs.hunger - 0.7) < 0.001)
    }

    @Test func kibbleIsAlwaysFree() {
        let s = store(bones: 0)
        #expect(s.feed(.kibble) == .ate)
        #expect(s.state.bones == 0)
    }

    @Test func treatsNeedEnoughBones() {
        let s = store(bones: 2)
        #expect(s.feed(.bone) == .needsBones)
        #expect(s.state.bones == 2)
        #expect(s.state.needs.hunger == 0.4)
    }

    @Test func aFullBuddySaysNoThanks() {
        let s = store(hunger: 1)
        #expect(s.feed(.apple) == .full)
        #expect(s.state.bones == 50)
    }

    @Test func careNeverGoesOverFull() {
        let s = store()
        s.state.needs.clean = 0.9
        s.care(\.clean, by: 0.5)
        #expect(s.state.needs.clean == 1)
        #expect(s.spendBones(60) == false)
        #expect(s.spendBones(3) == true)
        #expect(s.state.bones == 47)
    }
}

struct RepCounterTests {
    /// Feed each angle several frames in a row, like a real camera would.
    private func feed(_ counter: inout RepCounter, _ angles: [Double], frames: Int = 8) -> [RepCounter.Event] {
        var events: [RepCounter.Event] = []
        for a in angles {
            for _ in 0..<frames {
                if let e = counter.add(a) { events.append(e) }
            }
        }
        return events
    }

    @Test func fullArmRaiseCounts() {
        var c = RepCounter(kind: .armRaises)
        let events = feed(&c, [20, 90, 165, 90, 20])
        #expect(events == [.rep(number: 1, inTarget: true, cue: nil)])
        #expect(c.accuracy == 100)
    }

    @Test func shortArmRaiseSaysReachHigher() {
        var c = RepCounter(kind: .armRaises)
        let events = feed(&c, [20, 90, 130, 90, 20])
        #expect(events == [.tooShort(cue: "Reach higher!")])
        #expect(c.reps == 0)
        #expect(c.accuracy == 0)
    }

    @Test func goodSquatCounts() {
        var c = RepCounter(kind: .miniSquats)
        let events = feed(&c, [175, 140, 100, 140, 175])
        #expect(events == [.rep(number: 1, inTarget: true, cue: nil)])
    }

    @Test func tooDeepSquatCountsButIsOffTarget() {
        var c = RepCounter(kind: .miniSquats)
        let events = feed(&c, [175, 120, 60, 120, 175])
        #expect(events == [.rep(number: 1, inTarget: false, cue: "Not too low!")])
        #expect(c.accuracy == 0)
    }

    @Test func shallowSquatSaysBendMore() {
        var c = RepCounter(kind: .miniSquats)
        let events = feed(&c, [175, 138, 130, 138, 175])
        #expect(events == [.tooShort(cue: "Bend a little more!")])
        #expect(c.reps == 0)
    }

    @Test func accuracyIsShareOfTriesOnTarget() {
        var c = RepCounter(kind: .armRaises)
        _ = feed(&c, [20, 165, 20, 165, 20, 165, 20, 120, 20])
        #expect(c.reps == 3)
        #expect(c.tries == 4)
        #expect(c.accuracy == 75)
    }

    @Test func oneJitteryFrameIsSmoothedAway() {
        var c = RepCounter(kind: .armRaises)
        _ = feed(&c, [20])
        // A single wild reading doesn't start a rep on its own.
        #expect(c.add(170) == nil)
        _ = feed(&c, [20])
        #expect(c.tries == 0)
    }

    @Test func anglesUseTrueProportions() {
        // A right angle in pixels on a tall 9:16 image.
        let frame = PoseFrame(joints: [
            .leftHip: TrackedJoint(point: CGPoint(x: 0.5, y: 0.6), confidence: 0.9),
            .leftKnee: TrackedJoint(point: CGPoint(x: 0.5, y: 0.7), confidence: 0.9),
            .leftAnkle: TrackedJoint(point: CGPoint(x: 0.5 + 0.1 * 1920 / 1080, y: 0.7), confidence: 0.9),
        ], imageSize: CGSize(width: 1080, height: 1920))
        let angle = ExerciseKind.miniSquats.angle(in: frame) ?? 0
        #expect(abs(angle - 90) < 0.5)
    }

    @Test func lowConfidenceJointsAreIgnored() {
        let frame = PoseFrame(joints: [
            .leftHip: TrackedJoint(point: CGPoint(x: 0.5, y: 0.6), confidence: 0.2),
            .leftShoulder: TrackedJoint(point: CGPoint(x: 0.5, y: 0.3), confidence: 0.9),
            .leftWrist: TrackedJoint(point: CGPoint(x: 0.5, y: 0.1), confidence: 0.9),
        ], imageSize: CGSize(width: 1080, height: 1920))
        #expect(ExerciseKind.armRaises.angle(in: frame) == nil)
    }
}

@MainActor
struct PracticeModeTests {
    /// The pretend kid's skeleton must measure the same angle it was told to make,
    /// so practice mode exercises the real counting code.
    @Test func pretendSkeletonMatchesItsAngles() {
        for kind in ExerciseKind.allCases {
            let source = PracticePoseSource(kind: kind)
            for t in stride(from: 0.0, through: 26.0, by: 0.7) {
                let measured = kind.angle(in: source.frame(at: t)) ?? -1
                #expect(abs(measured - source.angle(at: t)) < 4, "\(kind) at \(t)s")
            }
        }
    }

    @Test func pretendSessionCountsAndCues() {
        for kind in ExerciseKind.allCases {
            let source = PracticePoseSource(kind: kind)
            var counter = RepCounter(kind: kind)
            var cues: [String] = []
            for t in stride(from: 0.0, to: PracticePoseSource.repTime * 10, by: 1.0 / 30) {
                if let angle = kind.angle(in: source.frame(at: t)), let event = counter.add(angle) {
                    switch event {
                    case .rep(_, _, let cue): if let cue { cues.append(cue) }
                    case .tooShort(let cue): cues.append(cue)
                    }
                }
            }
            #expect(counter.tries == 10, "\(kind)")
            #expect(counter.reps == 9, "\(kind)")
            #expect(!cues.isEmpty, "\(kind)")
        }
    }
}

@MainActor
struct ExerciseRewardTests {
    private func store() -> GameStore {
        let s = GameStore(fileURL: FileManager.default.temporaryDirectory.appending(path: "ex-\(UUID()).json"))
        s.state.kidName = "Maya"
        _ = s.redeem(code: "BUDDY123")
        return s
    }

    @Test func finishingAwardsBonesAndMarksDone() {
        let s = store()
        let before = s.state.bones
        let reward = s.finishExercise(.armRaises, result: ExerciseResult(reps: 20, inTargetReps: 18, tries: 22))
        #expect(reward.bones == 38)
        #expect(reward.goldenBones == 18)
        #expect(s.state.bones == before + 38)
        #expect(s.doneToday() == ["armRaises"])
    }

    @Test func todayShowsUpInHistory() {
        let s = store()
        s.finishExercise(.armRaises, result: ExerciseResult(reps: 20, inTargetReps: 20, tries: 20))
        s.finishExercise(.miniSquats, result: ExerciseResult(reps: 16, inTargetReps: 12, tries: 16))
        let today = s.state.history.last
        #expect(today.map { Calendar.current.isDateInToday($0.date) } == true)
        #expect(today?.exercisesDone == 2)
        #expect(today?.reps == 36)
        #expect(s.state.history.count == 15)   // 14 sample days + today
    }

    @Test func yesterdaysWorkDoesNotCountToday() {
        let s = store()
        let yesterday = Date().addingTimeInterval(-86_400)
        s.finishExercise(.armRaises, result: ExerciseResult(reps: 10, inTargetReps: 10, tries: 10), now: yesterday)
        #expect(s.doneToday().isEmpty)
    }

    @Test func starsFollowAccuracy() {
        #expect(ExerciseResult(reps: 10, inTargetReps: 10, tries: 10).stars == 3)
        #expect(ExerciseResult(reps: 8, inTargetReps: 7, tries: 10).stars == 2)
        #expect(ExerciseResult(reps: 4, inTargetReps: 3, tries: 10).stars == 1)
    }
}

@MainActor
struct ShopTests {
    private func store() -> GameStore {
        let s = GameStore(fileURL: FileManager.default.temporaryDirectory.appending(path: "shop-\(UUID()).json"))
        s.state.kidName = "Maya"
        _ = s.redeem(code: "BUDDY123")
        return s
    }

    @Test func mayaStartsWith50Bones() {
        #expect(store().state.bones == 50)
    }

    @Test func buyingCostsBonesAndPutsItOn() {
        let s = store()
        #expect(s.buy(.partyHat) == .bought)
        #expect(s.state.bones == 42)
        #expect(s.owns(.partyHat))
        #expect(s.state.outfit.hat == .partyHat)
    }

    @Test func cantBuyTwiceOrWithoutEnoughBones() {
        let s = store()
        _ = s.buy(.crown)
        #expect(s.buy(.crown) == .alreadyOwned)
        #expect(s.state.bones == 25)
        s.state.bones = 3
        #expect(s.buy(.teddy) == .needsBones)
        #expect(!s.owns(.teddy))
    }

    @Test func oneOfEachKindAtATime() {
        let s = store()
        _ = s.buy(.partyHat)
        _ = s.buy(.cap)
        _ = s.buy(.roundGlasses)
        #expect(s.state.outfit == Outfit(hat: .cap, glasses: .roundGlasses))
        s.toggleWearing(.partyHat)
        #expect(s.state.outfit.hat == .partyHat)
        s.toggleWearing(.partyHat)
        #expect(s.state.outfit.hat == nil)
        #expect(s.state.outfit.glasses == .roundGlasses)
    }

    @Test func cantWearWhatYouDontOwn() {
        let s = store()
        s.toggleWearing(.teddy)
        #expect(s.state.outfit.toy == nil)
    }
}

@MainActor
struct CheckInAndProgressTests {
    private func store() -> GameStore {
        let s = GameStore(fileURL: FileManager.default.temporaryDirectory.appending(path: "cp-\(UUID()).json"))
        s.state.kidName = "Maya"
        _ = s.redeem(code: "BUDDY123")
        return s
    }

    @Test func checkInSavesPainAndTicksTheCard() {
        let s = store()
        #expect(s.checkIn(pain: 3) == 2)
        #expect(s.doneToday().contains("checkIn"))
        #expect(s.state.history.last?.pain == 3)
        #expect(s.state.bones == 52)
        // Checking in again updates the answer but doesn't pay twice
        #expect(s.checkIn(pain: 5) == 0)
        #expect(s.state.history.last?.pain == 5)
        #expect(s.state.bones == 52)
    }

    @Test func painStaysBetweenOneAndTen() {
        let s = store()
        s.checkIn(pain: 14)
        #expect(s.state.today?.pain == 10)
    }

    @Test func streakCountsDaysInARow() {
        let s = store()
        // Sample history: the last 4 days were all exercise days (the one before was a miss).
        #expect(s.streak() == 4)
        s.finishExercise(.armRaises, result: ExerciseResult(reps: 10, inTargetReps: 10, tries: 10))
        #expect(s.streak() == 5)
    }

    @Test func recentDaysCoversTwoWeeksIncludingToday() {
        let s = store()
        let days = s.recentDays()
        #expect(days.count == 14)
        #expect(Calendar.current.isDateInToday(days.last!.date))
        #expect(days.contains { $0.pain != nil })
        #expect(s.adherence() > 0.6 && s.adherence() < 0.9)
    }
}

@MainActor
struct ResetTests {
    private func playedStore(url: URL) -> GameStore {
        let s = GameStore(fileURL: url)
        s.state.kidName = "Maya"
        _ = s.redeem(code: "BUDDY123")
        _ = s.buy(.partyHat)
        s.finishExercise(.armRaises, result: ExerciseResult(reps: 20, inTargetReps: 20, tries: 20))
        s.checkIn(pain: 3)
        return s
    }

    @Test func resetTodayKeepsTheKidButClearsTheDay() {
        let s = playedStore(url: FileManager.default.temporaryDirectory.appending(path: "rt-\(UUID()).json"))
        let bones = s.state.bones
        s.resetToday()
        #expect(s.doneToday().isEmpty)
        #expect(s.state.today == nil)
        #expect(!s.state.history.contains { Calendar.current.isDateInToday($0.date) })
        #expect(s.state.hasFinishedOnboarding)
        #expect(s.state.kidName == "Maya")
        #expect(s.state.bones == bones)
        #expect(s.state.outfit.hat == .partyHat)
    }

    @Test func startOverReturnsToOnboarding() {
        let s = playedStore(url: FileManager.default.temporaryDirectory.appending(path: "so-\(UUID()).json"))
        s.reset()
        #expect(!s.state.hasFinishedOnboarding)
        #expect(s.state.kidName.isEmpty)
        #expect(s.state.ownedItemIDs.isEmpty)
    }

    @Test func resetDemoLaunchArgumentStartsOver() {
        let url = FileManager.default.temporaryDirectory.appending(path: "la-\(UUID()).json")
        _ = playedStore(url: url)
        // Without the argument the saved game loads as usual…
        #expect(GameStore.launching(arguments: ["Buddy"], fileURL: url).state.hasFinishedOnboarding)
        // …with it, the demo starts over (and stays that way on the next normal launch).
        #expect(!GameStore.launching(arguments: ["Buddy", "-resetDemo"], fileURL: url).state.hasFinishedOnboarding)
        #expect(!GameStore.launching(arguments: ["Buddy"], fileURL: url).state.hasFinishedOnboarding)
    }
}
