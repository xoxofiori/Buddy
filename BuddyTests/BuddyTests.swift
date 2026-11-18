import Foundation
import Testing
@testable import Buddy

@MainActor
struct OnboardingTests {
    private func tempStore() -> (GameStore, URL) {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "gamestate-\(UUID().uuidString).json")
        return (GameStore(fileURL: url), url)
    }

    @Test func demoCodeLoadsMayasPlan() {
        let (store, _) = tempStore()
        store.state.kidName = "Maya"
        #expect(store.redeem(code: " buddy123 "))
        #expect(store.state.hasFinishedOnboarding)
        #expect(store.state.kidName == "Maya")
        #expect(store.state.patient?.therapistName == "Dr. Lee")
        #expect(store.state.plan?.exercises.count == 2)
        #expect(store.state.history.count == 14)
        #expect(store.state.adherence > 0.5 && store.state.adherence < 1)
    }

    @Test func otherCodesDoNothing() {
        let (store, _) = tempStore()
        #expect(!store.redeem(code: "HELLO"))
        #expect(!store.state.hasFinishedOnboarding)
    }

    @Test func stateIsSavedAndReloaded() {
        let (store, url) = tempStore()
        store.state.kidName = "Sam"
        _ = store.redeem(code: "BUDDY123")
        let reloaded = GameStore(fileURL: url)
        #expect(reloaded.state.kidName == "Sam")
        #expect(reloaded.state.coins == 50)
        #expect(reloaded.state.hasFinishedOnboarding)
    }
}
