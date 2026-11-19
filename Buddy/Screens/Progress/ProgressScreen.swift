import Charts
import SwiftUI

/// "Your Recovery Trail": how the last two weeks went, for kids (and the grown-ups and PT
/// looking over their shoulder). Opened from the arch on the garden path.
/// Shows the streak, adherence %, reps per day and the knee-pain trend from check-ins.
struct ProgressScreen: View {
    var onClose: () -> Void

    @Environment(GameStore.self) private var store

    var body: some View {
        let days = store.recentDays(14)
        let streak = store.streak()
        let adherence = Int((store.adherence() * 100).rounded())
        let totalReps = days.reduce(0) { $0 + $1.reps }

        ScrollView {
            VStack(spacing: 16) {
                HStack(alignment: .center) {
                    CloseButton(icon: "chevron.left", label: "Back to the yard", action: onClose)
                    Spacer()
                    BoneCounter(bones: store.state.bones)
                }

                HStack(alignment: .bottom, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Recovery Trail")
                            .font(.buddy(30, .heavy))
                            .foregroundStyle(Color.deepTeal)
                        Text(cheer(streak: streak, adherence: adherence))
                            .font(.buddy(17, .semibold))
                            .foregroundStyle(Color.deepTeal.opacity(0.65))
                    }
                    Spacer(minLength: 0)
                    BuddyView(pose: .waving, height: 120)
                }

                HStack(spacing: 12) {
                    StatTile(icon: "flame.fill", color: .coral, value: "\(streak)",
                             label: streak == 1 ? "day in a row" : "days in a row")
                    StatTile(icon: "checkmark.seal.fill", color: Color.sprout.shade(-0.2), value: "\(adherence)%",
                             label: "exercises done")
                }
                StatTile(icon: "figure.arms.open", color: .sky, value: "\(totalReps)",
                         label: "reps in the last 2 weeks", wide: true)

                ChartCard(title: "Reps each day", note: "Today is the coral bar") {
                    Chart(days) { day in
                        BarMark(
                            x: .value("Day", day.date, unit: .day),
                            y: .value("Reps", day.reps)
                        )
                        .foregroundStyle(Calendar.current.isDateInToday(day.date) ? Color.coral : Color.sprout.shade(-0.1))
                        .cornerRadius(5)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                            AxisValueLabel(format: .dateTime.day().month(.abbreviated), centered: true)
                        }
                    }
                    .chartYAxis { AxisMarks(position: .leading) }
                    .frame(height: 170)
                }

                ChartCard(title: "How your knee felt", note: "Lower is better 💚 (1 = hardly hurts, 10 = hurts the most)") {
                    let checkIns = days.filter { $0.pain != nil }
                    if checkIns.isEmpty {
                        Text("Check in each day to see this fill up!")
                            .font(.buddyBody)
                            .foregroundStyle(Color.deepTeal.opacity(0.6))
                            .frame(maxWidth: .infinity, minHeight: 120)
                    } else {
                        Chart(checkIns) { day in
                            LineMark(x: .value("Day", day.date, unit: .day), y: .value("Pain", day.pain ?? 0))
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(Color.coral)
                                .lineStyle(StrokeStyle(lineWidth: 4, lineCap: .round))
                            PointMark(x: .value("Day", day.date, unit: .day), y: .value("Pain", day.pain ?? 0))
                                .foregroundStyle(PainScale.color(day.pain ?? 0))
                                .symbolSize(140)
                                .annotation(position: .top) {
                                    Text(PainScale.face(day.pain ?? 1)).font(.system(size: 14))
                                }
                        }
                        .chartYScale(domain: 0...10)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                                AxisValueLabel(format: .dateTime.day().month(.abbreviated), centered: true)
                            }
                        }
                        .chartYAxis { AxisMarks(position: .leading, values: [0, 5, 10]) }
                        .frame(height: 170)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
        .background(Color.cream.overlay(PaperTexture()).ignoresSafeArea())
        .task {
            try? await Task.sleep(for: .seconds(0.4))
            BuddyVoice.shared.say(cheer(streak: store.streak(), adherence: Int(store.adherence() * 100)))
        }
    }

    private func cheer(streak: Int, adherence: Int) -> String {
        if streak >= 5 { return "\(streak) days in a row. You're on fire!" }
        if adherence >= 75 { return "You're doing great. Keep it up!" }
        return "Every day you exercise, your knee gets stronger!"
    }
}

/// One big number with an icon.
private struct StatTile: View {
    let icon: String
    let color: Color
    let value: String
    let label: String
    var wide = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.paper)
                .frame(width: 48, height: 48)
                .background(Circle().fill(color))
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.buddy(30, .heavy))
                    .foregroundStyle(Color.deepTeal)
                Text(label)
                    .font(.buddy(14, .bold))
                    .foregroundStyle(Color.deepTeal.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(StoryCard(shape: RoundedRectangle(cornerRadius: 24)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(label)")
    }
}

private struct ChartCard<Content: View>: View {
    let title: String
    let note: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.buddy(20, .heavy))
                .foregroundStyle(Color.deepTeal)
            content
            Text(note)
                .font(.buddy(13, .semibold))
                .foregroundStyle(Color.deepTeal.opacity(0.55))
        }
        .padding(16)
        .background(StoryCard(shape: RoundedRectangle(cornerRadius: 24)))
    }
}
