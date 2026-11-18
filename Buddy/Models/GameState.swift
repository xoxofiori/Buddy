import Foundation

/// Everything the app remembers, saved as one JSON file.
struct GameState: Codable, Equatable {
    var kidName: String = ""
    var hasFinishedOnboarding = false

    var patient: Patient?
    var plan: RecoveryPlan?

    var coins = 0
    var needs = Needs()
    var history: [DayRecord] = []

    var ownedItemIDs: [String] = []
    var equippedItemIDs: [String] = []

    var lastUpdated = Date()
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

struct PlannedExercise: Codable, Equatable, Identifiable {
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
