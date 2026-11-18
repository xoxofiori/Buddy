import Foundation
import Observation

/// Holds the live `GameState` and saves it to Documents/gamestate.json on every change.
@Observable
final class GameStore {
    var state: GameState {
        didSet {
            guard state != oldValue else { return }
            save()
        }
    }

    private let fileURL: URL

    init(fileURL: URL = GameStore.defaultURL) {
        self.fileURL = fileURL
        self.state = GameStore.load(from: fileURL) ?? GameState()
    }

    static var defaultURL: URL {
        URL.documentsDirectory.appending(path: "gamestate.json")
    }

    // MARK: Onboarding

    /// The only code that works in the demo build.
    static let demoCode = "BUDDY123"

    /// Returns true and loads the sample plan if the code matches.
    func redeem(code: String) -> Bool {
        let cleaned = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard cleaned == GameStore.demoCode else { return false }

        var newState = SampleData.makeState()
        newState.kidName = state.kidName
        newState.hasFinishedOnboarding = true
        state = newState
        return true
    }

    /// Wipes everything and goes back to onboarding.
    func reset() {
        state = GameState()
    }

    // MARK: Saving & loading

    private func save() {
        state.lastUpdated = Date()
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(state).write(to: fileURL, options: .atomic)
        } catch {
            print("Couldn't save game state: \(error)")
        }
    }

    private static func load(from url: URL) -> GameState? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(GameState.self, from: data)
    }
}
