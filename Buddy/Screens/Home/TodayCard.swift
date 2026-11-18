import SwiftUI

/// Something on today's plan: an exercise from the PT, or the knee check-in.
enum TodayItem: Identifiable, Hashable {
    case exercise(PlannedExercise)
    case checkIn

    var id: String {
        switch self {
        case .exercise(let e): e.id
        case .checkIn: "checkIn"
        }
    }
}

/// "Today with Buddy": slides down from the top with big tiles for each exercise and
/// the check-in. Each tile shows a mini Buddy doing the move. Done tiles flip to a sticker.
struct TodayCard: View {
    let plan: RecoveryPlan
    /// Item ids finished today.
    var done: Set<String> = []
    @Binding var expanded: Bool
    var onStart: (TodayItem) -> Void

    @State private var shown = false
    @State private var taps = 0

    private var items: [TodayItem] {
        plan.exercises.map(TodayItem.exercise) + (plan.dailyCheckIn ? [.checkIn] : [])
    }

    var body: some View {
        VStack(spacing: 12) {
            Button {
                taps += 1
                withAnimation(Theme.bouncy) { expanded.toggle() }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Today with Buddy")
                            .font(.buddy(22, .heavy))
                        Text("\(done.count) of \(items.count) done")
                            .font(.buddy(15, .bold))
                            .foregroundStyle(Color.deepTeal.opacity(0.55))
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 18, weight: .heavy))
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.cream))
                }
                .foregroundStyle(Color.deepTeal)
                .frame(minHeight: Theme.minTap)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(expanded ? "Hide today's plan" : "Show today's plan")

            if expanded {
                HStack(spacing: 10) {
                    ForEach(items) { item in
                        TodayTile(item: item, isDone: done.contains(item.id)) {
                            taps += 1
                            onStart(item)
                        }
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 4)
        .padding(.bottom, expanded ? 14 : 4)
        .background(StoryCard(shape: RoundedRectangle(cornerRadius: 30)))
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .offset(y: shown ? 0 : -420)
        .sensoryFeedback(.impact(weight: .light), trigger: taps)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.15)) { shown = true }
        }
    }
}

/// One big tile. Flips over to a sticker when done.
private struct TodayTile: View {
    let item: TodayItem
    let isDone: Bool
    let action: () -> Void

    private var title: String {
        switch item {
        case .exercise(let e): e.kind.title
        case .checkIn: "Knee check"
        }
    }

    private var detail: String {
        switch item {
        case .exercise(let e): "\(e.sets) × \(e.reps) reps"
        case .checkIn: "How's it feel?"
        }
    }

    private var pose: BuddyPose {
        switch item {
        case .exercise(let e): e.kind == .armRaises ? .armRaise : .squat
        case .checkIn: .talking
        }
    }

    private var tint: Color {
        switch item {
        case .exercise(let e): e.kind == .armRaises ? .sky : .sprout
        case .checkIn: .sunny
        }
    }

    var body: some View {
        Button(action: action) {
            // The back is laid over the front so it takes the front's size.
            front
                .opacity(isDone ? 0 : 1)
                .overlay {
                    back
                        .opacity(isDone ? 1 : 0)
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                }
            .rotation3DEffect(.degrees(isDone ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: isDone)
        }
        .buttonStyle(SquishStyle())
        .disabled(isDone)
        .accessibilityLabel(isDone ? "\(title), done" : "\(title), \(detail). Let's go")
    }

    private var front: some View {
        VStack(spacing: 4) {
            BuddyView(pose: pose, height: 78)
                .allowsHitTesting(false)
            Text(title)
                .font(.buddy(15, .heavy))
                .foregroundStyle(Color.deepTeal)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(detail)
                .font(.buddy(13, .semibold))
                .foregroundStyle(Color.deepTeal.opacity(0.6))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text("Let's go")
                .font(.buddy(15, .heavy))
                .foregroundStyle(Color.paper)
                .frame(maxWidth: .infinity, minHeight: 36)
                .background(Capsule().fill(Color.coral))
                .padding(.top, 2)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 22).fill(tint.opacity(0.2)))
    }

    private var back: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().fill(Color.sunny).frame(width: 70, height: 70)
                Image(systemName: "star.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Color.paper)
            }
            .rotationEffect(.degrees(-8))
            .shadow(color: .black.opacity(0.12), radius: 0, x: 0, y: 3)
            Text("Done!")
                .font(.buddy(18, .heavy))
                .foregroundStyle(Color.deepTeal)
            Text(title)
                .font(.buddy(13, .semibold))
                .foregroundStyle(Color.deepTeal.opacity(0.6))
                .lineLimit(1)
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 22).fill(Color.sunny.opacity(0.18)))
    }
}
