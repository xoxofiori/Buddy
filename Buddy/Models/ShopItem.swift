import Foundation

/// The four shelves in the Shop.
enum ShopCategory: String, CaseIterable, Identifiable {
    case hats, bandanas, glasses, toys

    var id: String { rawValue }

    var title: String { rawValue.capitalized }

    var icon: String {
        switch self {
        case .hats: "crown.fill"
        case .bandanas: "triangle.fill"
        case .glasses: "eyeglasses"
        case .toys: "tennisball.fill"
        }
    }
}

/// Everything Buddy can wear or play with. Bought with bones; Buddy wears one of each kind.
enum ShopItem: String, CaseIterable, Identifiable, Codable {
    case partyHat, cap, beanie, crown
    case redBandana, skyBandana, starBandana
    case roundGlasses, heartGlasses, starSunglasses
    case tennisBall, squeakyBone, frisbee, rubberDuck, teddy

    var id: String { rawValue }

    var category: ShopCategory {
        switch self {
        case .partyHat, .cap, .beanie, .crown: .hats
        case .redBandana, .skyBandana, .starBandana: .bandanas
        case .roundGlasses, .heartGlasses, .starSunglasses: .glasses
        case .tennisBall, .squeakyBone, .frisbee, .rubberDuck, .teddy: .toys
        }
    }

    var name: String {
        switch self {
        case .partyHat: "Party hat"
        case .cap: "Sky cap"
        case .beanie: "Cozy beanie"
        case .crown: "Gold crown"
        case .redBandana: "Polka-dot bandana"
        case .skyBandana: "Stripy bandana"
        case .starBandana: "Star bandana"
        case .roundGlasses: "Round glasses"
        case .heartGlasses: "Heart glasses"
        case .starSunglasses: "Star shades"
        case .tennisBall: "Tennis ball"
        case .squeakyBone: "Squeaky bone"
        case .frisbee: "Frisbee"
        case .rubberDuck: "Rubber duck"
        case .teddy: "Teddy bear"
        }
    }

    /// Price in bones.
    var price: Int {
        switch self {
        case .tennisBall: 5
        case .redBandana, .skyBandana: 6
        case .squeakyBone: 7
        case .partyHat, .frisbee: 8
        case .starBandana, .rubberDuck: 9
        case .beanie, .roundGlasses: 10
        case .cap, .heartGlasses: 12
        case .starSunglasses, .teddy: 15
        case .crown: 25
        }
    }

    static func items(in category: ShopCategory) -> [ShopItem] {
        allCases.filter { $0.category == category }
    }
}

/// What Buddy is wearing right now: at most one item of each kind.
struct Outfit: Equatable {
    var hat: ShopItem?
    var bandana: ShopItem?
    var glasses: ShopItem?
    var toy: ShopItem?

    static let none = Outfit()

    init(hat: ShopItem? = nil, bandana: ShopItem? = nil, glasses: ShopItem? = nil, toy: ShopItem? = nil) {
        self.hat = hat
        self.bandana = bandana
        self.glasses = glasses
        self.toy = toy
    }

    init(ids: [String]) {
        self.init()
        for item in ids.compactMap(ShopItem.init(rawValue:)) { self = wearing(item) }
    }

    /// This outfit with `item` put on (replacing anything of the same kind).
    func wearing(_ item: ShopItem) -> Outfit {
        var o = self
        switch item.category {
        case .hats: o.hat = item
        case .bandanas: o.bandana = item
        case .glasses: o.glasses = item
        case .toys: o.toy = item
        }
        return o
    }

    var items: [ShopItem] { [hat, bandana, glasses, toy].compactMap { $0 } }
}

enum BuyResult: Equatable {
    case bought
    case needsBones
    case alreadyOwned
}
