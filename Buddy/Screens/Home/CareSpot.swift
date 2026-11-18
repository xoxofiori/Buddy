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

    var comingSoon: String {
        switch self {
        case .bowl: "Soon you can fill Buddy's bowl with yummy snacks!"
        case .pool: "Soon Buddy can splash in the pool and get squeaky clean!"
        case .doghouse: "Soon you can tuck Buddy into his doghouse for a nap."
        case .toyBox: "Soon you can spend your bones on hats, bandanas and toys for Buddy!"
        case .trail: "Every day of exercises will move Buddy one step along this path, all the way to the park, the beach and the mountain!"
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

    /// Full-screen care room this spot opens, if it has one yet.
    var room: CareRoom? {
        switch self {
        case .bowl: .kitchen
        case .pool: .bath
        case .doghouse: .bed
        default: nil
        }
    }

    var pose: BuddyPose {
        switch self {
        case .doghouse: .sleeping
        case .toyBox, .trail: .waving
        default: .talking
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
    case kitchen, bath, bed
    var id: String { rawValue }
}

/// Every sheet the home screen can open.
enum HomeSheet: Identifiable {
    case spot(CareSpot)
    case checkIn
    case heart

    var id: String {
        switch self {
        case .spot(let s): "spot-\(s.rawValue)"
        case .checkIn: "checkIn"
        case .heart: "heart"
        }
    }
}

/// Placeholder for screens built in later phases, with Buddy explaining.
struct ComingSoonSheet: View {
    let title: String
    let message: String
    let pose: BuddyPose
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            Text(title)
                .font(.buddyTitle)
                .foregroundStyle(Color.deepTeal)
                .multilineTextAlignment(.center)
                .padding(.top, 28)

            BuddyView(pose: pose, height: 240)

            Text(message)
                .font(.buddyBody)
                .foregroundStyle(Color.deepTeal.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer(minLength: 0)

            BigButton(title: "Okay!", color: .coral, textColor: .paper) { dismiss() }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .background(Color.cream.overlay(PaperTexture()).ignoresSafeArea())
        .presentationDetents([.large])
        .presentationCornerRadius(36)
    }
}
