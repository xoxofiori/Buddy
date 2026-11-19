import SwiftUI

/// The backyard follows the real clock: morning light, bright day, sunset glow, starry night.
enum TimeOfDay: String, CaseIterable, Identifiable {
    case morning, day, sunset, night

    var id: String { rawValue }

    init(date: Date, calendar: Calendar = .current) {
        switch calendar.component(.hour, from: date) {
        case 6..<11: self = .morning
        case 11..<17: self = .day
        case 17..<20: self = .sunset
        default: self = .night
        }
    }

    var title: String { rawValue.capitalized }

    var skyTop: Color {
        switch self {
        case .morning: Color(hex: 0x9FD4F2)
        case .day: .sky
        case .sunset: Color(hex: 0xEE9C7E)
        case .night: Color(hex: 0x18264A)
        }
    }

    var skyBottom: Color {
        switch self {
        case .morning: Color(hex: 0xFFE4C4)
        case .day: Color(hex: 0xCFEBFA)
        case .sunset: Color(hex: 0xFFD49C)
        case .night: Color(hex: 0x3A4C78)
        }
    }

    /// A wash of color laid over the sky, grass and fence (not Buddy or the tappable objects) to set the mood.
    var light: Color {
        switch self {
        case .morning: .sunny
        case .day: .clear
        case .sunset: .coral
        case .night: Color(hex: 0x16244A)
        }
    }

    var lightOpacity: Double {
        switch self {
        case .morning: 0.07
        case .day: 0
        case .sunset: 0.16
        case .night: 0.42
        }
    }
}
