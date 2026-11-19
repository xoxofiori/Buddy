import SwiftUI

/// Hidden settings for grown-ups and demos (hold "Hi Maya!" on the home screen for 1.5 s).
/// Shows the PT plan, sound/voice switches, a time-of-day preview, and "Reset demo".
struct GrownUpSettingsView: View {
    @Binding var timeOverride: TimeOfDay?
    var onClose: () -> Void

    @Environment(GameStore.self) private var store
    @AppStorage(Feedback.soundKey) private var soundOn = true
    @AppStorage(Feedback.voiceKey) private var voiceOn = true
    @State private var confirmReset = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Grown-ups")
                        .font(.buddy(30, .heavy))
                        .foregroundStyle(Color.deepTeal)
                    Spacer()
                    CloseButton(icon: "xmark", label: "Close", action: onClose)
                }

                section("Patient") {
                    if let patient = store.state.patient {
                        row("Name", store.state.kidName.isEmpty ? patient.name : store.state.kidName)
                        row("Age", "\(patient.age)")
                        row("Recovery", patient.condition)
                        row("Physical therapist", patient.therapistName)
                    }
                    if let plan = store.state.plan {
                        ForEach(plan.exercises) { e in
                            row(e.kind.title, "\(e.sets) × \(e.reps)")
                        }
                        row("Reminder", reminder(plan))
                    }
                }

                section("Sound") {
                    Toggle("Sound effects", isOn: $soundOn)
                    Toggle("Buddy's voice", isOn: $voiceOn)
                }
                .tint(.coral)

                section("Preview time of day") {
                    Picker("Time of day", selection: $timeOverride) {
                        Text("Clock").tag(TimeOfDay?.none)
                        ForEach(TimeOfDay.allCases) { t in
                            Text(t.title).tag(TimeOfDay?.some(t))
                        }
                    }
                    .pickerStyle(.segmented)
                }

                section("Demo") {
                    Text("Clears the name, bones, Buddy's outfit and today's progress, and goes back to the start.")
                        .font(.buddy(15, .semibold))
                        .foregroundStyle(Color.deepTeal.opacity(0.6))
                    BigButton(title: "Reset demo", color: .coral, textColor: .paper) { confirmReset = true }
                }
            }
            .padding(20)
        }
        .font(.buddy(17, .semibold))
        .foregroundStyle(Color.deepTeal)
        .background(Color.cream.overlay(PaperTexture()).ignoresSafeArea())
        .confirmationDialog("Reset the demo?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset everything", role: .destructive) {
                timeOverride = nil
                onClose()
                store.reset()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
        }
        .presentationDetents([.large])
        .presentationCornerRadius(36)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.buddy(15, .heavy))
                .foregroundStyle(Color.deepTeal.opacity(0.55))
                .textCase(.uppercase)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(StoryCard(shape: RoundedRectangle(cornerRadius: 22)))
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(Color.deepTeal.opacity(0.65))
            Spacer()
            Text(value).font(.buddy(17, .heavy))
        }
    }

    private func reminder(_ plan: RecoveryPlan) -> String {
        var c = DateComponents()
        c.hour = plan.reminderHour
        c.minute = plan.reminderMinute
        guard let date = Calendar.current.date(from: c) else { return "" }
        return date.formatted(date: .omitted, time: .shortened)
    }
}
