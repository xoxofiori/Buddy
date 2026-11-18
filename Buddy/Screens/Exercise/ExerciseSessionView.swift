import SwiftUI

/// The whole exercise: Buddy demos the move, then kid and Buddy do it side by side with the
/// camera counting reps, then a celebration. Opened from "Let's go" on Today with Buddy.
struct ExerciseSessionView: View {
    var onClose: () -> Void

    @Environment(GameStore.self) private var store
    @State private var session: ExerciseSession
    @State private var reward: ExerciseReward?
    @State private var result: ExerciseResult?
    @State private var confirmLeave = false

    init(exercise: PlannedExercise, kidName: String, practice: Bool? = nil, onClose: @escaping () -> Void) {
        self.onClose = onClose
        _session = State(initialValue: practice.map { ExerciseSession(exercise: exercise, kidName: kidName, practice: $0) }
                         ?? ExerciseSession(exercise: exercise, kidName: kidName))
    }

    var body: some View {
        ZStack {
            Color.cream.overlay(PaperTexture()).ignoresSafeArea()

            switch session.phase {
            case .demo:
                ExerciseDemoView(session: session, onBack: leave, onReady: {
                    Task { await session.begin() }
                })
            case .finished:
                if let result, let reward {
                    CelebrationView(kind: session.kind, kidName: session.kidName,
                                    result: result, reward: reward, onDone: onClose)
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
            default:
                ExerciseActiveView(session: session, onClose: { confirmLeave = true })
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: session.phase)
        .onAppear {
            // The phone is propped up across the room, so don't let the screen dim or lock.
            UIApplication.shared.isIdleTimerDisabled = true
            session.onFinished = { result in
                self.result = result
                self.reward = store.finishExercise(session.kind, result: result)
            }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            session.stop()
        }
        .confirmationDialog("Stop exercising?", isPresented: $confirmLeave, titleVisibility: .visible) {
            Button("Stop for now", role: .destructive, action: leave)
            Button("Keep going", role: .cancel) {}
        } message: {
            Text("That's okay! Buddy will be here when you're ready.")
        }
    }

    private func leave() {
        session.stop()
        onClose()
    }
}

// MARK: Demo

/// "Watch Buddy!" Buddy shows the move while the steps are read out.
struct ExerciseDemoView: View {
    let session: ExerciseSession
    var onBack: () -> Void
    var onReady: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                CloseButton(icon: "chevron.left", label: "Back to the yard", action: onBack)
                Spacer()
            }
            .padding(.horizontal, 14)

            Text(session.kind.title)
                .font(.buddyTitle)
                .foregroundStyle(Color.deepTeal)
            Text("Watch Buddy!")
                .font(.buddyHeader)
                .foregroundStyle(Color.coral)

            // Buddy loops the move: arm raises on their own, squats down and up.
            TimelineView(.animation) { ctx in
                let t = ctx.date.timeIntervalSinceReferenceDate
                BuddyView(pose: session.pose, height: 300,
                          motion: session.kind == .miniSquats ? (1 - cos(t * 2 * .pi / 3)) / 2 : nil)
            }

            VStack(spacing: 10) {
                Text(session.kind.howTo)
                    .font(.buddyBody)
                    .foregroundStyle(Color.deepTeal)
                    .multilineTextAlignment(.center)
                HStack(spacing: 10) {
                    Chip(text: "\(session.exercise.sets) sets")
                    Chip(text: "\(session.exercise.reps) reps each")
                }
                if session.practice {
                    Text("No camera here, so Buddy will pretend to be you (practice mode).")
                        .font(.buddy(14, .semibold))
                        .foregroundStyle(Color.deepTeal.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(18)
            .background(StoryCard(shape: RoundedRectangle(cornerRadius: 26)))
            .padding(.horizontal, 20)

            Spacer(minLength: 0)

            BigButton(title: "I'm ready!", color: .coral, textColor: .paper, action: onReady)
                .padding(.horizontal, 24)
                .padding(.bottom, 10)
        }
        .task {
            try? await Task.sleep(for: .seconds(0.5))
            BuddyVoice.shared.say("Watch me! \(session.kind.howTo)")
        }
    }
}

// MARK: Doing it together

/// Made for a phone propped up across the room:
/// - **Top:** Buddy and a guide stick figure doing the move together at a steady pace.
/// - **Bottom:** the front camera, full width, with the kid's own skeleton in the same colors,
///   so they can compare their form against the guide.
/// Big rep ring, big captions and a pause button so it all reads from a distance.
struct ExerciseActiveView: View {
    let session: ExerciseSession
    var onClose: () -> Void

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 8) {
                FollowAlong(kind: session.kind, pose: session.pose)
                    .frame(height: geo.size.height * 0.37)   // leaves the camera close to 3:4, head to toe
                    .overlay(alignment: .top) { topBar }

                cameraPanel
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
        }
        .sensoryFeedback(.success, trigger: session.counter.reps)
    }

    private var topBar: some View {
        HStack(alignment: .top) {
            CloseButton(icon: "xmark", label: "Stop exercising", action: onClose)
            Spacer()
            Text("Set \(session.set) of \(session.exercise.sets)")
                .font(.buddy(17, .heavy))
                .foregroundStyle(Color.deepTeal)
                .padding(.horizontal, 14)
                .frame(minHeight: 40)
                .background(StoryCard(shape: Capsule()))
                .padding(.top, 10)
            Spacer()
            AccuracyPill(accuracy: session.result.accuracy)
                .padding(.top, 8)
        }
        .padding(8)
    }

    private var isResting: Bool {
        if case .rest = session.phase { return true }
        return false
    }

    private var cameraPanel: some View {
        ZStack {
            if session.practice {
                LinearGradient(colors: [Color.lavender.opacity(0.7), Color.cream], startPoint: .top, endPoint: .bottom)
            } else {
                CameraPreview(session: session.camera.session)
            }

            SkeletonOverlay(frame: session.frame, kind: session.kind, fill: true, lineWidth: 6)

            // Big caption: what Buddy is saying (cues, counts, praise)
            VStack {
                if let bubble = session.bubble {
                    Text(bubble)
                        .font(.buddy(28, .heavy))
                        .foregroundStyle(Color.deepTeal)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(StoryCard(shape: RoundedRectangle(cornerRadius: 24)))
                        .padding(.top, 14)
                        .padding(.horizontal, 12)
                        .transition(.scale(scale: 0.6, anchor: .top).combined(with: .opacity))
                        .id(bubble)
                }
                Spacer()
            }

            // Bottom corners: rep ring and pause
            VStack {
                Spacer()
                if session.cantSee && session.phase == .active && !session.paused {
                    Label(session.kind.stepBackCue, systemImage: "figure.walk")
                        .font(.buddy(18, .heavy))
                        .foregroundStyle(Color.paper)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.deepTeal.opacity(0.85)))
                }
                HStack(alignment: .bottom) {
                    RepRing(done: isResting ? session.exercise.reps : session.counter.reps,
                            goal: session.exercise.reps)
                    Spacer()
                    if session.practice {
                        Text("Practice mode")
                            .font(.buddy(13, .heavy))
                            .foregroundStyle(Color.deepTeal.opacity(0.6))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.paper.opacity(0.85)))
                            .padding(.bottom, 8)
                    }
                    Spacer()
                    if session.phase == .active {
                        Button { session.togglePause() } label: {
                            Image(systemName: session.paused ? "play.fill" : "pause.fill")
                                .font(.system(size: 26, weight: .heavy))
                                .foregroundStyle(Color.deepTeal)
                                .frame(width: 72, height: 72)
                                .background(StoryCard(shape: Circle()))
                        }
                        .buttonStyle(SquishStyle())
                        .accessibilityLabel(session.paused ? "Keep going" : "Pause")
                    } else {
                        Color.clear.frame(width: 72, height: 72)
                    }
                }
            }
            .padding(14)

            switch session.phase {
            case .framing:
                FramingCard(kind: session.kind, onStart: session.startNow)
            case .countdown(let n):
                BigNumber(text: "\(n)")
            case .rest(let n):
                RestCard(seconds: n)
            default:
                if session.paused { PausedCard { session.togglePause() } }
            }

            if session.cameraBlocked {
                CameraHelpCard { session.usePractice() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .overlay(RoundedRectangle(cornerRadius: 30).strokeBorder(Color.paper, lineWidth: 4))
        .shadow(color: .deepTeal.opacity(0.12), radius: 10, y: 5)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: session.bubble)
    }
}

/// Top half: Buddy and a guide stick figure doing perfect reps side by side, at a calm pace.
/// The stick figure uses the same colors as the kid's skeleton below, so it's easy to compare.
struct FollowAlong: View {
    let kind: ExerciseKind
    let pose: BuddyPose

    var body: some View {
        TimelineView(.animation) { ctx in
            let angle = PracticePoseSource.guideAngle(kind, at: ctx.date.timeIntervalSinceReferenceDate)
            HStack(spacing: 0) {
                BuddyView(pose: pose, motion: kind.progress(for: angle))
                    .padding(.top, 54)
                    .padding(.bottom, 6)
                    .frame(maxWidth: .infinity)
                SkeletonOverlay(frame: PracticePoseSource.figure(kind, angle: angle), kind: kind,
                                fill: false, crop: PracticePoseSource.guideCrop(kind), lineWidth: 7)
                    .padding(.top, 64)
                    .padding(.bottom, 18)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity)
            }
        }
        .overlay(alignment: .bottom) {
            Text("Follow Buddy!")
                .font(.buddy(15, .heavy))
                .foregroundStyle(Color.deepTeal.opacity(0.55))
                .padding(.bottom, 6)
        }
        .background(
            StoryCard(shape: RoundedRectangle(cornerRadius: 30), fill: Color.sky.opacity(0.18))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Buddy and a stick figure showing \(kind.title.lowercased())")
    }
}

/// Reps done as a big ring with "2/10" inside, readable from across the room.
private struct RepRing: View {
    let done: Int
    let goal: Int

    var body: some View {
        ZStack {
            Circle().fill(Color.paper)
            Circle()
                .stroke(Color.deepTeal.opacity(0.1), lineWidth: 10)
                .padding(8)
            Circle()
                .trim(from: 0, to: CGFloat(done) / CGFloat(max(goal, 1)))
                .stroke(Color.coral, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(8)
            Text("\(done)/\(goal)")
                .font(.buddy(30, .heavy))
                .foregroundStyle(Color.deepTeal)
                .contentTransition(.numericText(value: Double(done)))
                .minimumScaleFactor(0.6)
                .padding(18)
        }
        .frame(width: 104, height: 104)
        .shadow(color: .deepTeal.opacity(0.15), radius: 8, y: 4)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: done)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(done) of \(goal) reps")
    }
}

/// Before counting: prop the phone up and step back until Buddy sees you head to toe.
private struct FramingCard: View {
    let kind: ExerciseKind
    var onStart: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "figure.stand")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(Color.coral)
            Text("Prop up your phone and step back")
                .font(.buddy(22, .heavy))
                .multilineTextAlignment(.center)
            Text("Buddy starts counting when he can see you from head to toe.")
                .font(.buddy(16, .semibold))
                .foregroundStyle(Color.deepTeal.opacity(0.65))
                .multilineTextAlignment(.center)
            Button("Start now", action: onStart)
                .font(.buddy(17, .heavy))
                .foregroundStyle(Color.coral)
                .frame(minWidth: 120, minHeight: 48)
        }
        .foregroundStyle(Color.deepTeal)
        .padding(20)
        .background(StoryCard(shape: RoundedRectangle(cornerRadius: 26)))
        .padding(24)
    }
}

private struct PausedCard: View {
    var onResume: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text("Paused")
                .font(.buddy(30, .heavy))
                .foregroundStyle(Color.deepTeal)
            BigButton(title: "Keep going", color: .coral, textColor: .paper, action: onResume)
                .frame(width: 220)
        }
        .padding(22)
        .background(StoryCard(shape: RoundedRectangle(cornerRadius: 26)))
    }
}

private struct AccuracyPill: View {
    let accuracy: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "scope").font(.system(size: 15, weight: .bold))
            Text("\(accuracy)%").font(.buddy(18, .heavy))
                .contentTransition(.numericText(value: Double(accuracy)))
        }
        .foregroundStyle(Color.deepTeal)
        .padding(.horizontal, 12)
        .frame(minHeight: 44)
        .background(StoryCard(shape: Capsule()))
        .animation(.spring, value: accuracy)
        .accessibilityLabel("Accuracy \(accuracy) percent")
    }
}

private struct BigNumber: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.buddy(110, .heavy))
            .foregroundStyle(Color.paper)
            .shadow(color: .deepTeal.opacity(0.4), radius: 0, x: 0, y: 5)
            .id(text)
            .transition(.scale(scale: 1.6).combined(with: .opacity))
    }
}

private struct RestCard: View {
    let seconds: Int

    var body: some View {
        VStack(spacing: 6) {
            Text("Great set!")
                .font(.buddy(26, .heavy))
            Text("Little rest…")
                .font(.buddy(18, .bold))
                .foregroundStyle(Color.deepTeal.opacity(0.6))
            Text("\(seconds)")
                .font(.buddy(54, .heavy))
                .foregroundStyle(Color.coral)
                .contentTransition(.numericText(value: Double(seconds)))
        }
        .foregroundStyle(Color.deepTeal)
        .padding(22)
        .background(StoryCard(shape: RoundedRectangle(cornerRadius: 26)))
        .animation(.spring, value: seconds)
    }
}

/// Shown if the camera isn't allowed.
private struct CameraHelpCard: View {
    var onPractice: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.fill")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(Color.coral)
            Text("Buddy needs the camera to count your reps.")
                .font(.buddy(18, .heavy))
                .multilineTextAlignment(.center)
            Text("Ask a grown-up to turn on the camera for Buddy in Settings.")
                .font(.buddy(15, .semibold))
                .foregroundStyle(Color.deepTeal.opacity(0.65))
                .multilineTextAlignment(.center)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
            }
            .font(.buddy(17, .heavy))
            .frame(minHeight: 44)
            Button("Practice without camera", action: onPractice)
                .font(.buddy(15, .bold))
                .foregroundStyle(Color.deepTeal.opacity(0.6))
                .frame(minHeight: 44)
        }
        .foregroundStyle(Color.deepTeal)
        .padding(18)
        .background(StoryCard(shape: RoundedRectangle(cornerRadius: 24)))
        .padding(10)
    }
}

struct CloseButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(Color.deepTeal)
                .frame(width: Theme.minTap, height: Theme.minTap)
                .background(StoryCard(shape: Circle()))
        }
        .buttonStyle(SquishStyle())
        .accessibilityLabel(label)
    }
}

private struct Chip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.buddy(15, .heavy))
            .foregroundStyle(Color.deepTeal)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.sunny.opacity(0.3)))
    }
}
