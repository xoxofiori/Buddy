import Foundation

/// Everything the app remembers, saved as one JSON file.
struct GameState: Codable, Equatable {
    var kidName: String = ""
    var hasFinishedOnboarding = false

    var patient: Patient?
    var plan: RecoveryPlan?

    /// Earned by doing reps; spent in the Shop. (Saved under the old key "coins".)
    var bones = 0
    var needs = Needs()
    /// When the need bars last decayed. Optional so older saves still load.
    var needsUpdatedAt: Date?
    var history: [DayRecord] = []

    var ownedItemIDs: [String] = []
    var equippedItemIDs: [String] = []

    /// What's been done today (exercises finished). Optional so older saves still load.
    var today: TodayProgress?

    var lastUpdated = Date()

    enum CodingKeys: String, CodingKey {
        case kidName, hasFinishedOnboarding, patient, plan
        case bones = "coins"
        case needs, needsUpdatedAt, history, ownedItemIDs, equippedItemIDs, today, lastUpdated
    }
}

/// Today's finished items and totals. Starts fresh each day.
struct TodayProgress: Codable, Equatable {
    var date: Date
    var doneIDs: [String] = []
    var reps = 0
    var inTargetReps = 0
    var tries = 0
}

/// How an exercise session went.
struct ExerciseResult: Equatable {
    var reps: Int
    var inTargetReps: Int
    var tries: Int

    /// 0–100: share of tries in the target range.
    var accuracy: Int {
        tries == 0 ? 100 : Int((Double(inTargetReps) / Double(tries) * 100).rounded())
    }

    /// 1–3 stars for the celebration screen.
    var stars: Int {
        accuracy >= 90 ? 3 : accuracy >= 60 ? 2 : 1
    }
}

/// What finishing an exercise earned.
struct ExerciseReward: Equatable {
    /// Total bones added (every rep earns a bone; perfect-form reps are golden bones worth 2).
    var bones: Int
    var goldenBones: Int
}

struct Patient: Codable, Equatable {
    var name: String
    var age: Int
    var condition: String
    var therapistName: String
}

enum ExerciseKind: String, Codable, CaseIterable, Identifiable {
    case armRaises
    case miniSquats

    var id: String { rawValue }

    var title: String {
        switch self {
        case .armRaises: "Arm Raises"
        case .miniSquats: "Mini Squats"
        }
    }
}

struct PlannedExercise: Codable, Hashable, Identifiable {
    var kind: ExerciseKind
    var sets: Int
    var reps: Int

    var id: String { kind.rawValue }
}

struct RecoveryPlan: Codable, Equatable {
    var exercises: [PlannedExercise]
    var dailyCheckIn: Bool
    /// Reminder time, stored as hour + minute (24h clock).
    var reminderHour: Int
    var reminderMinute: Int
}

/// Buddy's care bars, each from 0 (empty) to 1 (full).
struct Needs: Codable, Equatable {
    var hunger = 0.8
    var energy = 0.8
    var clean = 0.8
    var fun = 0.8

    /// How much each bar drops per hour of real time (slowly: a full bar lasts 16–33 hours).
    static let hungerPerHour = 0.05
    static let energyPerHour = 0.04
    static let cleanPerHour = 0.03
    static let funPerHour = 0.06

    mutating func decay(hours: Double) {
        guard hours > 0 else { return }
        hunger = max(0, hunger - Self.hungerPerHour * hours)
        energy = max(0, energy - Self.energyPerHour * hours)
        clean = max(0, clean - Self.cleanPerHour * hours)
        fun = max(0, fun - Self.funPerHour * hours)
    }
}

/// One day of exercise history, used by the progress view.
struct DayRecord: Codable, Equatable, Identifiable {
    var date: Date
    var exercisesPlanned: Int
    var exercisesDone: Int
    var reps: Int
    /// 0–1: share of reps that hit the target range.
    var accuracy: Double
    /// 1–5 answer to "How's your knee?", if the kid checked in.
    var kneeFeeling: Int?

    var id: Date { date }
}

extension GameState {
    /// Share of planned exercises actually done across the history, 0–1.
    var adherence: Double {
        let planned = history.reduce(0) { $0 + $1.exercisesPlanned }
        guard planned > 0 else { return 0 }
        let done = history.reduce(0) { $0 + $1.exercisesDone }
        return Double(done) / Double(planned)
    }
}
