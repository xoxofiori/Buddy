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

    /// Wipes everything and goes back to onboarding.
    func reset() {
        state = GameState()
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
            ?? DayRecord(date: day, exercisesPlanned: planned, exercisesDone: 0, reps: 0, accuracy: 0, kneeFeeling: nil)
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
