import SwiftUI

@main
struct BuddyApp: App {
    @State private var store = GameStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .fontDesign(.rounded)
                .tint(.deepTeal)
        }
    }
}
