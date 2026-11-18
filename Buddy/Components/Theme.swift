import SwiftUI

/// Buddy's palette: "soft, sunny, never neon".
extension Color {
    static let sky      = Color(hex: 0x5DB6E8)
    static let sprout   = Color(hex: 0xB5DD7A)
    static let coral    = Color(hex: 0xE8765A)
    static let sunny    = Color(hex: 0xFFB547)
    static let lavender = Color(hex: 0xD9D2F2)
    static let cream    = Color(hex: 0xFFF6E5)
    static let paper    = Color(hex: 0xFFFDF8)
    static let deepTeal = Color(hex: 0x24403E)

    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// Chunky SF Rounded type sizes used across the app.
extension Font {
    static func buddy(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static let buddyTitle  = buddy(40, .heavy)
    static let buddyHeader = buddy(28, .bold)
    static let buddyBody   = buddy(20, .semibold)
    static let buddyButton = buddy(24, .heavy)
}

enum Theme {
    /// Smallest tap target for small hands.
    static let minTap: CGFloat = 60
    static let corner: CGFloat = 28
    static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
}
