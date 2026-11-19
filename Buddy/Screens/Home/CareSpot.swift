import SwiftUI

/// Things in the backyard a kid can tap to look after Buddy.
enum CareSpot: String, CaseIterable, Identifiable {
    case bowl, pool, doghouse, toyBox, trail

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bowl: "Snack time"
        case .pool: "Bath time"
        case .doghouse: "Nap time"
        case .toyBox: "Toy box"
        case .trail: "Recovery Trail"
        }
    }

    /// The little icon floating above it in the yard, so kids know it does something.
    var icon: String {
        switch self {
        case .bowl: "fork.knife"
        case .pool: "shower.fill"
        case .doghouse: "moon.zzz.fill"
        case .toyBox: "bag.fill"
        case .trail: "map.fill"
        }
    }

    var color: Color {
        switch self {
        case .bowl: .coral
        case .pool: .sky
        case .doghouse: Color(hex: 0x9C8FD6)
        case .toyBox: Color.sunny.shade(-0.1)
        case .trail: Color.sprout.shade(-0.25)
        }
    }

    /// The full-screen room this spot opens.
    var room: CareRoom {
        switch self {
        case .bowl: .kitchen
        case .pool: .bath
        case .doghouse: .bed
        case .toyBox: .shop
        case .trail: .progress
        }
    }

    /// The need this spot looks after (it wiggles when that need runs low).
    func need(in needs: Needs) -> Double? {
        switch self {
        case .bowl: needs.hunger
        case .pool: needs.clean
        case .doghouse: needs.energy
        case .toyBox: needs.fun
        case .trail: nil
        }
    }
}

/// The full-screen care rooms.
enum CareRoom: String, Identifiable {
    case kitchen, bath, bed, shop, progress
    var id: String { rawValue }
}

/// Every sheet the home screen can open.
enum HomeSheet: Identifiable {
    case checkIn
    case heart
    case settings

    var id: String {
        switch self {
        case .checkIn: "checkIn"
        case .heart: "heart"
        case .settings: "settings"
        }
    }
}
