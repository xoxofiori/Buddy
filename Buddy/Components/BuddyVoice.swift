import AVFoundation

/// Buddy's squeaky cartoon voice, using the built-in speech synthesizer.
final class BuddyVoice {
    static let shared = BuddyVoice()

    private let synthesizer = AVSpeechSynthesizer()

    private init() {
        // "Ambient" plays alongside music and respects the silent switch.
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
    }

    func say(_ text: String, pitch: Float = 1.7, rate: Float = 0.52) {
        guard Feedback.voiceOn else { return }
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.pitchMultiplier = pitch
        utterance.rate = rate
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }
}
