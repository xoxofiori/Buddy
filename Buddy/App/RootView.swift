import SwiftUI

/// Shows onboarding until the kid has entered a working PT code, then Buddy's house.
struct RootView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        ZStack {
            if store.state.hasFinishedOnboarding {
                HomeView()
                    .transition(.asymmetric(insertion: .scale(scale: 0.8).combined(with: .opacity),
                                            removal: .opacity))
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(Theme.bouncy, value: store.state.hasFinishedOnboarding)
        .environment(\.buddyOutfit, store.state.outfit)
    }
}
