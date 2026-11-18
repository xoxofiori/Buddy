import AVFoundation
import Observation
import SwiftUI

/// Runs one exercise from start to finish: Buddy's demo, "step back until Buddy can see all of
/// you" (for a propped-up phone), a "3, 2, 1, Go!" countdown, each set of reps with the camera
/// (or practice mode), a short rest between sets, then the result.
/// Speaks counts, praise and form cues out loud.
@Observable
final class ExerciseSession {
    enum Phase: Equatable {
        case demo
        /// Waiting until the whole body is in view.
        case framing
        case countdown(Int)
        case active
        case rest(Int)
        case finished
    }

    let exercise: PlannedExercise
    let kidName: String

    private(set) var phase: Phase = .demo
    private(set) var set = 1
    private(set) var counter: RepCounter
    private(set) var frame: PoseFrame?
    /// The cue or praise on screen right now.
    private(set) var bubble: String?
    /// True when Buddy can't see the joints he needs.
    private(set) var cantSee = false
    /// Using the pretend kid instead of the camera.
    private(set) var practice: Bool
    /// The camera isn't allowed (show the grown-up help card).
    private(set) var cameraBlocked = false
    /// Counting is on hold.
    private(set) var paused = false

    // Totals from finished sets
    private var doneReps = 0
    private var doneInTarget = 0
    private var doneTries = 0

    let camera = CameraPoseSource()
    private let pretend: PracticePoseSource
    private var lastSeen = Date()
    private var lastStepBackCue = Date.distantPast
    private var inViewSince: Date?
    private var bubbleTask: Task<Void, Never>?
    private var flowTask: Task<Void, Never>?
    var onFinished: ((ExerciseResult) -> Void)?

    init(exercise: PlannedExercise, kidName: String, practice: Bool = !CameraPoseSource.isAvailable) {
        self.exercise = exercise
        self.kidName = kidName
        self.practice = practice
        counter = RepCounter(kind: exercise.kind)
        pretend = PracticePoseSource(kind: exercise.kind)
        pretend.onFrame = { [weak self] in self?.handle($0) }
        camera.onFrame = { [weak self] in self?.handle($0) }
    }

    var kind: ExerciseKind { exercise.kind }

    /// The Buddy pose for this exercise.
    var pose: BuddyPose { kind == .armRaises ? .armRaise : .squat }

    /// How far the kid is into the move right now (Buddy copies it).
    var kidProgress: Double { counter.angle.map(kind.progress(for:)) ?? 0 }

    var result: ExerciseResult {
        ExerciseResult(reps: doneReps + counter.reps,
                       inTargetReps: doneInTarget + counter.inTargetReps,
                       tries: doneTries + counter.tries)
    }

    // MARK: Flow

    /// "I'm ready!" — check the camera, then count down into the first set.
    func begin() async {
        if !practice {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                break
            case .notDetermined:
                guard await AVCaptureDevice.requestAccess(for: .video) else {
                    cameraBlocked = true
                    return
                }
            default:
                cameraBlocked = true
                return
            }
            guard camera.configure() else {
                usePractice()
                return
            }
            camera.start()
        } else {
            pretend.start()
        }
        getInFrame()
    }

    /// Ask the kid to prop the phone up and step back; counting starts once Buddy sees them head to toe.
    private func getInFrame() {
        phase = .framing
        inViewSince = nil
        say("Prop up your phone, then step back so I can see all of you!")
    }

    /// Skip waiting to be seen and start the countdown.
    func startNow() {
        guard phase == .framing else { return }
        startSet()
    }

    func togglePause() {
        guard phase == .active else { return }
        paused.toggle()
        counter.lostSight()
        say(paused ? "Take your time!" : "Let's keep going!")
    }

    /// Carry on without the camera (pretend kid).
    func usePractice() {
        cameraBlocked = false
        practice = true
        camera.stop()
        pretend.start()
        getInFrame()
    }

    private func startSet() {
        counter = RepCounter(kind: kind)
        flowTask?.cancel()
        flowTask = Task {
            for n in [3, 2, 1] {
                phase = .countdown(n)
                BuddyVoice.shared.say(["One", "Two", "Three"][n - 1])
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
            }
            phase = .active
            lastSeen = Date()
            say(set == 1 ? "Go! Do it with me!" : "Go!")
        }
    }

    /// Leave the session early (nothing is saved).
    func stop() {
        flowTask?.cancel()
        bubbleTask?.cancel()
        camera.stop()
        pretend.stop()
    }

    // MARK: Frames

    private func handle(_ frame: PoseFrame?) {
        self.frame = frame

        if phase == .framing {
            if let frame, frame.showsWholeBody {
                let since = inViewSince ?? Date()
                inViewSince = since
                if Date().timeIntervalSince(since) > 0.8 {
                    say("I can see you!")
                    startSet()
                }
            } else {
                inViewSince = nil
            }
            return
        }
        guard phase == .active, !paused else { return }

        guard let frame, let angle = kind.angle(in: frame) else {
            counter.lostSight()
            if Date().timeIntervalSince(lastSeen) > 1.5 {
                cantSee = true
                if Date().timeIntervalSince(lastStepBackCue) > 6 {
                    lastStepBackCue = Date()
                    say(kind.stepBackCue)
                }
            }
            return
        }
        lastSeen = Date()
        cantSee = false

        guard let event = counter.add(angle) else { return }
        switch event {
        case .rep(let number, _, let cue):
            if let cue {
                say("\(number)! \(cue)")
            } else if number % 3 == 0 {
                say("\(number)! Nice one, \(kidName)!")
            } else if number == 1 {
                say(kind == .armRaises ? "One! Great reach!" : "One! Great bend! Keep going!")
            } else {
                say("\(number)!")
            }
            if number >= exercise.reps { finishSet() }
        case .tooShort(let cue):
            say("Almost! \(cue)")
        }
    }

    private func finishSet() {
        doneReps += counter.reps
        doneInTarget += counter.inTargetReps
        doneTries += counter.tries
        counter = RepCounter(kind: kind)

        guard set < exercise.sets else {
            finish()
            return
        }
        flowTask?.cancel()
        flowTask = Task {
            try? await Task.sleep(for: .seconds(1.2))
            say("Great set! Take a little rest.")
            for n in stride(from: 5, through: 1, by: -1) {
                phase = .rest(n)
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
            }
            set += 1
            startSet()
        }
    }

    private func finish() {
        flowTask?.cancel()
        camera.stop()
        pretend.stop()
        let result = ExerciseResult(reps: doneReps, inTargetReps: doneInTarget, tries: doneTries)
        flowTask = Task {
            try? await Task.sleep(for: .seconds(1))
            phase = .finished
            onFinished?(result)
        }
    }

    // MARK: Talking

    private func say(_ text: String) {
        BuddyVoice.shared.say(text)
        withAnimation(BuddyView<EmptyView>.spring) { bubble = text }
        bubbleTask?.cancel()
        bubbleTask = Task {
            try? await Task.sleep(for: .seconds(1.8))
            guard !Task.isCancelled else { return }
            withAnimation(BuddyView<EmptyView>.spring) { bubble = nil }
        }
    }

    // MARK: Previews

    /// Puts the session in a given state without running it (previews and screenshots).
    func preview(phase: Phase, frame: PoseFrame?, reps: [Double] = []) {
        self.phase = phase
        self.frame = frame
        for a in reps { _ = counter.add(a) }
    }
}
