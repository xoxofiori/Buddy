import AudioToolbox
import UIKit

/// The little "tock" and tap you feel on every button. Grown-ups can turn the sound off in the
/// hidden settings; haptics always play.
enum Feedback {
    static let soundKey = "soundEffectsOn"
    static let voiceKey = "buddyVoiceOn"

    static var soundOn: Bool { UserDefaults.standard.object(forKey: soundKey) as? Bool ?? true }
    static var voiceOn: Bool { UserDefaults.standard.object(forKey: voiceKey) as? Bool ?? true }

    /// A soft click and a light tap.
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if soundOn { AudioServicesPlaySystemSound(1104) }   // keyboard "tock" (respects silent mode)
    }

    /// A happier sound for good news (bought something, checked in, finished).
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        if soundOn { AudioServicesPlaySystemSound(1407) }
    }
}
