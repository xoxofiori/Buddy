import Foundation

/// Counts reps and picks form cues from a stream of joint angles, exactly as CLAUDE.md says:
///
/// - **Arm raises** (shoulder angle): a rep counts when it goes from <40° up to >150° and back.
///   If an arm comes back down without passing 150°, Buddy says "Reach higher!".
/// - **Mini squats** (knee angle): a rep counts when it goes from >160° down to <120° and back up.
///   "Bend a little more!" if a squat comes back up without passing 120°; "Not too low!" if it went below 70°.
/// - Angles are smoothed over the last 5 frames.
/// - Accuracy = share of tries that hit the target range. A try that stops short gets a cue and
///   doesn't count as a rep; a squat below 70° counts but isn't in the target range.
nonisolated struct RepCounter {
    enum Event: Equatable {
        /// A rep was counted. `inTarget` is false for a squat that went too low.
        case rep(number: Int, inTarget: Bool, cue: String?)
        /// A try that didn't go far enough to count.
        case tooShort(cue: String)
    }

    let kind: ExerciseKind

    private(set) var reps = 0
    private(set) var inTargetReps = 0
    private(set) var tries = 0
    /// The smoothed angle, for showing on screen.
    private(set) var angle: Double?

    private var recent: [Double] = []
    private var phase = Phase.waitingForRest
    private var extreme = 0.0     // highest shoulder angle / lowest knee angle this try

    private enum Phase { case waitingForRest, ready, moving }

    static let smoothing = 5

    // Thresholds from CLAUDE.md
    static let armRest = 40.0, armTarget = 150.0
    static let squatRest = 160.0, squatTarget = 120.0, squatTooLow = 70.0
    // When a try has clearly started (so small wobbles don't count as tries)
    static let armStarted = 70.0, squatStarted = 145.0

    init(kind: ExerciseKind) {
        self.kind = kind
    }

    /// 0–100, share of tries that hit the target range.
    var accuracy: Int {
        tries == 0 ? 100 : Int((Double(inTargetReps) / Double(tries) * 100).rounded())
    }

    /// Feed one raw angle (degrees) from the camera. Returns something to celebrate or a cue.
    mutating func add(_ raw: Double) -> Event? {
        recent.append(raw)
        if recent.count > Self.smoothing { recent.removeFirst() }
        let a = recent.reduce(0, +) / Double(recent.count)
        angle = a

        switch kind {
        case .armRaises: return armRaise(a)
        case .miniSquats: return squat(a)
        }
    }

    /// Forget the smoothing (e.g. the kid stepped out of view).
    mutating func lostSight() {
        recent.removeAll()
        angle = nil
    }

    private mutating func armRaise(_ a: Double) -> Event? {
        switch phase {
        case .waitingForRest:
            if a < Self.armRest { phase = .ready }
        case .ready:
            if a > Self.armStarted {
                phase = .moving
                extreme = a
            }
        case .moving:
            extreme = max(extreme, a)
            if a < Self.armRest {
                phase = .ready
                tries += 1
                if extreme > Self.armTarget {
                    reps += 1
                    inTargetReps += 1
                    return .rep(number: reps, inTarget: true, cue: nil)
                }
                return .tooShort(cue: "Reach higher!")
            }
        }
        return nil
    }

    private mutating func squat(_ k: Double) -> Event? {
        switch phase {
        case .waitingForRest:
            if k > Self.squatRest { phase = .ready }
        case .ready:
            if k < Self.squatStarted {
                phase = .moving
                extreme = k
            }
        case .moving:
            extreme = min(extreme, k)
            if k > Self.squatRest {
                phase = .ready
                tries += 1
                guard extreme < Self.squatTarget else {
                    return .tooShort(cue: "Bend a little more!")
                }
                reps += 1
                if extreme < Self.squatTooLow {
                    return .rep(number: reps, inTarget: false, cue: "Not too low!")
                }
                inTargetReps += 1
                return .rep(number: reps, inTarget: true, cue: nil)
            }
        }
        return nil
    }
}
