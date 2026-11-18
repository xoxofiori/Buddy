import Foundation

/// Snacks in the food carousel. Kibble is always free so Buddy can always eat;
/// treats cost bones (earned by doing exercises).
enum FoodItem: String, CaseIterable, Identifiable, Codable {
    case kibble, apple, carrot, blueberries, bone, pupcake

    var id: String { rawValue }

    var name: String {
        switch self {
        case .kibble: "Kibble"
        case .apple: "Apple"
        case .carrot: "Carrot"
        case .blueberries: "Blueberries"
        case .bone: "Chew bone"
        case .pupcake: "Pupcake"
        }
    }

    var emoji: String {
        switch self {
        case .kibble: "🥣"
        case .apple: "🍎"
        case .carrot: "🥕"
        case .blueberries: "🫐"
        case .bone: "🦴"
        case .pupcake: "🧁"
        }
    }

    /// Cost in bones.
    var price: Int {
        switch self {
        case .kibble: 0
        case .apple, .carrot: 1
        case .blueberries: 2
        case .bone: 3
        case .pupcake: 5
        }
    }

    /// How much it fills the "fed" part of Buddy's heart (0–1).
    var filling: Double {
        switch self {
        case .kibble, .apple, .carrot: 0.15
        case .blueberries: 0.18
        case .bone: 0.2
        case .pupcake: 0.3
        }
    }

    /// Treats also make him happy (the "played" part).
    var joy: Double {
        switch self {
        case .kibble, .carrot: 0
        case .apple: 0.02
        case .blueberries: 0.04
        case .bone: 0.08
        case .pupcake: 0.15
        }
    }
}

/// Soaps in the bath. Plain soap is free; rainbow soap costs bones and makes Buddy extra happy.
enum Soap: String, CaseIterable, Identifiable {
    case plain, rainbow

    var id: String { rawValue }
    var name: String { self == .plain ? "Soap" : "Rainbow soap" }
    var price: Int { self == .plain ? 0 : 3 }
    var joy: Double { self == .plain ? 0 : 0.1 }
}

enum FeedResult: Equatable {
    case ate
    case full
    case needsBones
}
