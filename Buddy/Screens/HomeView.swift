import SwiftUI

/// Placeholder for Buddy's house (built for real in Phase 2).
struct HomeView: View {
    @Environment(GameStore.self) private var store
    @State private var wave = false

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                BuddyPlaceholder(size: 180)

                Text("Hi \(store.state.kidName)!")
                    .font(.buddy(52, .heavy))
                    .foregroundStyle(Color.deepTeal)
                    .scaleEffect(wave ? 1 : 0.6)
                    .opacity(wave ? 1 : 0)

                if let plan = store.state.plan {
                    Text("Buddy can't wait to do \(plan.exercises.count) exercises with you today!")
                        .font(.buddyBody)
                        .foregroundStyle(Color.deepTeal.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                // Temporary while building; a hidden reset menu replaces this in Phase 6.
                Button("Start over") { store.reset() }
                    .font(.buddy(16, .semibold))
                    .foregroundStyle(Color.deepTeal.opacity(0.4))
                    .frame(minHeight: Theme.minTap)
            }
        }
        .onAppear {
            withAnimation(Theme.bouncy.delay(0.15)) { wave = true }
        }
    }
}
