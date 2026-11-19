import SwiftUI

@main
struct BuddyApp: App {
    /// Pass `-resetDemo` as a launch argument to start the demo over on startup.
    @State private var store = GameStore.launching()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .fontDesign(.rounded)
                .tint(.deepTeal)
        }
    }
}
