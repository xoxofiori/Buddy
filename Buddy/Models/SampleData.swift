import Foundation

/// Demo data loaded by the code BUDDY123: Maya, 8, recovering from a knee injury.
enum SampleData {
    static let patient = Patient(
        name: "Maya",
        age: 8,
        condition: "Knee recovery",
        therapistName: "Dr. Lee"
    )

    static let plan = RecoveryPlan(
        exercises: [
            PlannedExercise(kind: .armRaises, sets: 2, reps: 10),
            PlannedExercise(kind: .miniSquats, sets: 2, reps: 8),
        ],
        dailyCheckIn: true,
        reminderHour: 16,   // 4:00 PM
        reminderMinute: 0
    )

    static let starterBones = 50

    static func makeState(today: Date = Date()) -> GameState {
        var state = GameState()
        state.kidName = patient.name
        state.patient = patient
        state.plan = plan
        state.bones = starterBones
        state.needs = Needs(hunger: 0.7, energy: 0.85, clean: 0.55, fun: 0.6)
        state.history = twoWeekHistory(endingBefore: today)
        return state
    }

    /// 14 days of made-up history so the progress view has something to show.
    /// Hand-written so it looks the same every time: mostly good days, a couple of misses.
    static func twoWeekHistory(endingBefore today: Date) -> [DayRecord] {
        // (exercises done out of 2, average accuracy, knee pain 1–10 or nil if no check-in)
        // Pain eases over the two weeks, like a recovering knee.
        let days: [(done: Int, accuracy: Double, pain: Int?)] = [
            (1, 0.60, 7), (2, 0.65, 7), (2, 0.70, 6), (0, 0.00, nil),
            (2, 0.72, 6), (2, 0.75, 5), (1, 0.78, 5), (2, 0.80, 4),
            (2, 0.82, 4), (0, 0.00, 5), (2, 0.85, 3), (2, 0.86, 3),
            (2, 0.88, 2), (2, 0.90, 2),
        ]
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: today)
        let planned = plan.exercises.count
        let repsPerExercise = plan.exercises.map { $0.sets * $0.reps }

        return days.enumerated().compactMap { index, day in
            let daysAgo = days.count - index
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: start) else { return nil }
            let reps = repsPerExercise.prefix(day.done).reduce(0, +)
            return DayRecord(
                date: date,
                exercisesPlanned: planned,
                exercisesDone: day.done,
                reps: reps,
                accuracy: day.accuracy,
                pain: day.pain
            )
        }
    }
}
