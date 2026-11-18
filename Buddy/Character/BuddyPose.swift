import Foundation

/// The poses Buddy can be drawn in. All of Buddy's drawing lives in this folder (built in Phase 2).
enum BuddyPose: String, Codable, CaseIterable {
    case idle, happy, eating, sleeping, bathing, demoArmRaise, demoSquat
}
