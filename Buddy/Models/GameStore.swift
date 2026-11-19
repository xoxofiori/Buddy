import Foundation
import Observation

/// Holds the live `GameState` and saves it to Documents/gamestate.json on every change.
@Observable
final class GameStore {
    var state: GameState {
        didSet {
            guard state != oldValue else { return }
            save()
        }
    }

    private let fileURL: URL

    init(fileURL: URL = GameStore.defaultURL) {
        self.fileURL = fileURL
        self.state = GameStore.load(from: fileURL) ?? GameState()
    }

    static var defaultURL: URL {
        URL.documentsDirectory.appending(path: "gamestate.json")
    }

    // MARK: Onboarding

    /// The only code that works in the demo build.
    static let demoCode = "BUDDY123"

    /// Returns true and loads the sample plan if the code matches.
    func redeem(code: String) -> Bool {
        let cleaned = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard cleaned == GameStore.demoCode else { return false }

        var newState = SampleData.makeState()
        newState.kidName = state.kidName
        newState.hasFinishedOnboarding = true
        newState.needsUpdatedAt = Date()
        state = newState
        return true
    }

    /// "Start over": wipes the saved game and goes back to onboarding.
    func reset() {
        state = GameState()
    }

    /// "Reset today": keeps the kid, plan, bones and outfit, but clears today's to-dos
    /// and check-in (and today's line in the history) so the day can be demoed again.
    func resetToday(now: Date = Date()) {
        let calendar = Calendar.current
        var s = state
        s.today = nil
        s.history.removeAll { calendar.isDate($0.date, inSameDayAs: now) }
        state = s
    }

    /// Launch argument that starts the demo over when the app opens.
    static let resetDemoArgument = "-resetDemo"

    /// The store the app starts with. `-resetDemo` on launch does the same as "Start over".
    static func launching(arguments: [String] = ProcessInfo.processInfo.arguments,
                          fileURL: URL = GameStore.defaultURL) -> GameStore {
        let store = GameStore(fileURL: fileURL)
        if arguments.contains(resetDemoArgument) { store.reset() }
        return store
    }

    // MARK: Buddy's needs

    /// Lowers the need bars for the real time that passed since the last tick.
    func tickNeeds(now: Date = Date()) {
        var newState = state
        if let last = newState.needsUpdatedAt {
            newState.needs.decay(hours: now.timeIntervalSince(last) / 3600)
        }
        newState.needsUpdatedAt = now
        state = newState
    }

    /// Petting and playing cheer Buddy up a little.
    func addFun(_ amount: Double) {
        state.needs.fun = min(1, state.needs.fun + amount)
    }

    // MARK: Care rooms

    /// Feed Buddy a snack: costs its bones and fills the "fed" part of his heart.
    @discardableResult
    func feed(_ food: FoodItem) -> FeedResult {
        guard state.needs.hunger < 0.97 else { return .full }
        guard state.bones >= food.price else { return .needsBones }
        var s = state
        s.bones -= food.price
        s.needs.hunger = min(1, s.needs.hunger + food.filling)
        s.needs.fun = min(1, s.needs.fun + food.joy)
        state = s
        return .ate
    }

    /// Pay for something (e.g. rainbow soap). Returns false if there aren't enough bones.
    func spendBones(_ amount: Int) -> Bool {
        guard amount > 0 else { return true }
        guard state.bones >= amount else { return false }
        state.bones -= amount
        return true
    }

    /// Raise one of Buddy's needs, never above full.
    func care(_ need: WritableKeyPath<Needs, Double>, by amount: Double) {
        state.needs[keyPath: need] = min(1, max(0, state.needs[keyPath: need] + amount))
    }

    // MARK: Shop

    func owns(_ item: ShopItem) -> Bool { state.ownedItemIDs.contains(item.rawValue) }
    func isWearing(_ item: ShopItem) -> Bool { state.outfit.items.contains(item) }

    /// Buy an item with bones. Buddy puts it on straight away.
    @discardableResult
    func buy(_ item: ShopItem) -> BuyResult {
        guard !owns(item) else { return .alreadyOwned }
        guard state.bones >= item.price else { return .needsBones }
        var s = state
        s.bones -= item.price
        s.ownedItemIDs.append(item.rawValue)
        s.equippedItemIDs = s.outfit.wearing(item).items.map(\.rawValue)
        s.needs.fun = min(1, s.needs.fun + 0.1)
        state = s
        return .bought
    }

    /// Put an owned item on (swapping out anything of the same kind), or take it off if worn.
    func toggleWearing(_ item: ShopItem) {
        guard owns(item) else { return }
        if isWearing(item) {
            state.equippedItemIDs.removeAll { $0 == item.rawValue }
        } else {
            state.equippedItemIDs = state.outfit.wearing(item).items.map(\.rawValue)
        }
    }

    // MARK: Exercises

    /// Item ids finished today ("armRaises", "miniSquats", "checkIn").
    func doneToday(now: Date = Date()) -> Set<String> {
        guard let today = state.today, Calendar.current.isDate(today.date, inSameDayAs: now) else { return [] }
        return Set(today.doneIDs)
    }

    /// Record a finished exercise: award bones, mark it done on today's plan,
    /// and update today's line in the history (for the progress screen).
    @discardableResult
    func finishExercise(_ kind: ExerciseKind, result: ExerciseResult, now: Date = Date()) -> ExerciseReward {
        let reward = ExerciseReward(bones: result.reps + result.inTargetReps, goldenBones: result.inTargetReps)
        let calendar = Calendar.current
        var s = state

        s.bones += reward.bones
        s.needs.fun = min(1, s.needs.fun + 0.15)   // Buddy loves exercising with you

        var today = s.today.flatMap { calendar.isDate($0.date, inSameDayAs: now) ? $0 : nil }
            ?? TodayProgress(date: now)
        if !today.doneIDs.contains(kind.rawValue) { today.doneIDs.append(kind.rawValue) }
        today.reps += result.reps
        today.inTargetReps += result.inTargetReps
        today.tries += result.tries
        s.today = today

        let day = calendar.startOfDay(for: now)
        let planned = s.plan?.exercises.count ?? 0
        let done = s.plan?.exercises.filter { today.doneIDs.contains($0.kind.rawValue) }.count ?? today.doneIDs.count
        let accuracy = today.tries == 0 ? 1 : Double(today.inTargetReps) / Double(today.tries)
        var record = s.history.first { calendar.isDate($0.date, inSameDayAs: day) }
            ?? DayRecord(date: day, exercisesPlanned: planned, exercisesDone: 0, reps: 0, accuracy: 0, pain: nil)
        record.exercisesPlanned = planned
        record.exercisesDone = done
        record.reps = today.reps
        record.accuracy = accuracy
        s.history.removeAll { calendar.isDate($0.date, inSameDayAs: day) }
        s.history.append(record)
        s.history.sort { $0.date < $1.date }

        state = s
        return reward
    }

    // MARK: Check-in

    static let checkInID = "checkIn"
    static let checkInBones = 2

    /// "How's your knee?" — save today's pain (1–10), tick it off today's plan,
    /// and give a couple of bones for being brave enough to check in.
    @discardableResult
    func checkIn(pain: Int, now: Date = Date()) -> Int {
        let pain = min(10, max(1, pain))
        let calendar = Calendar.current
        let firstTime = !doneToday(now: now).contains(Self.checkInID)
        var s = state

        var today = s.today.flatMap { calendar.isDate($0.date, inSameDayAs: now) ? $0 : nil }
            ?? TodayProgress(date: now)
        if firstTime { today.doneIDs.append(Self.checkInID) }
        today.pain = pain
        s.today = today

        let day = calendar.startOfDay(for: now)
        var record = s.history.first { calendar.isDate($0.date, inSameDayAs: day) }
            ?? DayRecord(date: day, exercisesPlanned: s.plan?.exercises.count ?? 0, exercisesDone: 0,
                         reps: 0, accuracy: 0, pain: nil)
        record.pain = pain
        s.history.removeAll { calendar.isDate($0.date, inSameDayAs: day) }
        s.history.append(record)
        s.history.sort { $0.date < $1.date }

        let bones = firstTime ? Self.checkInBones : 0
        s.bones += bones
        state = s
        return bones
    }

    // MARK: Progress

    /// Days in a row with at least one exercise done, ending today (or yesterday,
    /// so the streak isn't "broken" before today's exercises are done).
    func streak(now: Date = Date()) -> Int {
        let calendar = Calendar.current
        let doneDays = Set(state.history.filter { $0.exercisesDone > 0 }.map { calendar.startOfDay(for: $0.date) })
        var day = calendar.startOfDay(for: now)
        if !doneDays.contains(day) {
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        }
        var count = 0
        while doneDays.contains(day) {
            count += 1
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        }
        return count
    }

    /// The last `count` days ending today, with an empty record for days without one.
    func recentDays(_ count: Int = 14, now: Date = Date()) -> [DayRecord] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        return (0..<count).reversed().compactMap { back in
            guard let day = calendar.date(byAdding: .day, value: -back, to: today) else { return nil }
            return state.history.first { calendar.isDate($0.date, inSameDayAs: day) }
                ?? DayRecord(date: day, exercisesPlanned: state.plan?.exercises.count ?? 0,
                             exercisesDone: 0, reps: 0, accuracy: 0, pain: nil)
        }
    }

    /// Adherence over the last `count` days that had a plan, 0–1.
    func adherence(lastDays count: Int = 14, now: Date = Date()) -> Double {
        let days = recentDays(count, now: now).filter { $0.exercisesPlanned > 0 }
        let planned = days.reduce(0) { $0 + $1.exercisesPlanned }
        guard planned > 0 else { return 0 }
        return Double(days.reduce(0) { $0 + $1.exercisesDone }) / Double(planned)
    }

    // MARK: Saving & loading

    private func save() {
        // Stamp the time on a copy. Changing `state` itself here would trigger
        // another save, and another, until the app crashed.
        var snapshot = state
        snapshot.lastUpdated = Date()
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(snapshot).write(to: fileURL, options: .atomic)
        } catch {
            print("Couldn't save game state: \(error)")
        }
    }

    private static func load(from url: URL) -> GameState? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(GameState.self, from: data)
    }
}
