import SwiftUI

/// The Shop (opened from the toy box): hats, bandanas, glasses and toys bought with bones.
/// It's also Buddy's closet: owned things can be put on or taken off right here.
/// Tapping any item tries it on Buddy first, so kids can see how it looks before buying.
struct ShopView: View {
    var onClose: () -> Void

    @Environment(GameStore.self) private var store

    @State private var category: ShopCategory = .hats
    @State private var selected: ShopItem = .partyHat
    @State private var actionPose: BuddyPose?
    @State private var speech: String?
    @State private var haptic = 0
    @State private var bought = 0
    @State private var sparkle = false
    @State private var speechTask: Task<Void, Never>?

    /// What Buddy shows: his real outfit, with the selected item tried on.
    private var preview: Outfit {
        store.isWearing(selected) || (store.owns(selected) && !trying) ? store.state.outfit
            : store.state.outfit.wearing(selected)
    }

    /// Showing an item on Buddy that he isn't really wearing yet.
    private var trying: Bool { !store.isWearing(selected) }

    private var pose: BuddyPose {
        actionPose ?? (speech != nil ? .talking : .idle)
    }

    var body: some View {
        ZStack {
            Color.cream.overlay(PaperTexture()).ignoresSafeArea()

            VStack(spacing: 12) {
                header

                // Buddy under a little striped awning, showing off the outfit
                ZStack(alignment: .top) {
                    Awning().frame(height: 34)
                    BuddyView(pose: pose, height: 260)
                        .environment(\.buddyOutfit, preview)
                        .padding(.top, 30)
                    // Buddy's words go below his head so they never hide what he's trying on
                    if let speech {
                        SpeechBubble(text: speech)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                            .padding(.bottom, 14)
                    }
                    if sparkle {
                        ShopSparkles().allowsHitTesting(false)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .background(StoryCard(shape: RoundedRectangle(cornerRadius: 28), fill: Color.sky.opacity(0.14)))
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .overlay(alignment: .bottomLeading) {
                    if trying {
                        Text("Trying on")
                            .font(.buddy(14, .heavy))
                            .foregroundStyle(Color.deepTeal.opacity(0.7))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.paper))
                            .padding(12)
                    }
                }
                .padding(.horizontal, 14)

                tabs

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(ShopItem.items(in: category)) { item in
                            ItemCard(item: item,
                                     owned: store.owns(item),
                                     wearing: store.isWearing(item),
                                     affordable: store.state.bones >= item.price,
                                     selected: item == selected) {
                                haptic += 1
                                withAnimation(BuddyView<EmptyView>.spring) { selected = item }
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                }

                Spacer(minLength: 0)

                actionButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
            }
        }
        .sensoryFeedback(.success, trigger: bought)
        .task {
            selected = store.state.outfit.hat ?? .partyHat
            try? await Task.sleep(for: .seconds(0.4))
            say("Welcome to the shop! What should I wear?")
        }
    }

    // MARK: Pieces

    private var header: some View {
        HStack {
            CloseButton(icon: "chevron.left", label: "Back to the yard", action: onClose)
            Spacer()
            Text("Shop")
                .font(.buddy(28, .heavy))
                .foregroundStyle(Color.deepTeal)
            Spacer()
            BoneCounter(bones: store.state.bones)
        }
        .padding(.horizontal, 14)
    }

    private var tabs: some View {
        HStack(spacing: 8) {
            ForEach(ShopCategory.allCases) { tab in
                Button {
                    haptic += 1
                    withAnimation(BuddyView<EmptyView>.spring) {
                        category = tab
                        selected = currentOrFirst(in: tab)
                    }
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: .bold))
                            .rotationEffect(.degrees(tab == .bandanas ? 180 : 0))
                        Text(tab.title).font(.buddy(13, .heavy))
                    }
                    .foregroundStyle(category == tab ? Color.paper : Color.deepTeal)
                    .frame(maxWidth: .infinity, minHeight: Theme.minTap)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(category == tab ? Color.coral : Color.paper)
                            .shadow(color: .deepTeal.opacity(0.1), radius: 4, y: 2)
                    )
                }
                .buttonStyle(SquishStyle())
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(category == tab ? .isSelected : [])
            }
        }
        .padding(.horizontal, 14)
    }

    @ViewBuilder
    private var actionButton: some View {
        if store.isWearing(selected) {
            BigButton(title: "Take it off", color: .lavender, textColor: .deepTeal) {
                store.toggleWearing(selected)
                say("Okay!")
            }
        } else if store.owns(selected) {
            BigButton(title: "Wear it!", color: .sprout, textColor: .deepTeal) {
                store.toggleWearing(selected)
                celebrate("How do I look?")
            }
        } else {
            BigButton(title: "Buy for \(selected.price) bones", color: .coral, textColor: .paper) { buy() }
                .opacity(store.state.bones >= selected.price ? 1 : 0.6)
        }
    }

    // MARK: Actions

    private func buy() {
        switch store.buy(selected) {
        case .bought:
            bought += 1
            Feedback.success()
            celebrate(["I love it! Thank you!", "So cool!", "Look at me!"].randomElement()!)
        case .needsBones:
            say("Let's do exercises to earn more bones!")
        case .alreadyOwned:
            break
        }
    }

    private func celebrate(_ text: String) {
        withAnimation(BuddyView<EmptyView>.spring) {
            actionPose = .happy
            sparkle = true
        }
        say(text)
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            withAnimation(BuddyView<EmptyView>.spring) {
                actionPose = nil
                sparkle = false
            }
        }
    }

    private func currentOrFirst(in category: ShopCategory) -> ShopItem {
        store.state.outfit.items.first { $0.category == category } ?? ShopItem.items(in: category)[0]
    }

    private func say(_ text: String) {
        BuddyVoice.shared.say(text)
        withAnimation(BuddyView<EmptyView>.spring) { speech = text }
        speechTask?.cancel()
        speechTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            withAnimation(BuddyView<EmptyView>.spring) { speech = nil }
        }
    }
}

/// One item on the shelf: picture, name, and its price or "Owned" / "Wearing".
private struct ItemCard: View {
    let item: ShopItem
    let owned: Bool
    let wearing: Bool
    let affordable: Bool
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                AccessoryThumbnail(item: item)
                    .frame(width: 96, height: 70)
                Text(item.name)
                    .font(.buddy(14, .heavy))
                    .foregroundStyle(Color.deepTeal)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                    .frame(height: 36)
                badge
            }
            .padding(10)
            .frame(width: 122, height: 172)
            .background(StoryCard(shape: RoundedRectangle(cornerRadius: 22)))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(selected ? Color.coral : .clear, lineWidth: 4)
            )
        }
        .buttonStyle(SquishStyle())
        .accessibilityLabel("\(item.name), \(wearing ? "wearing" : owned ? "owned" : "\(item.price) bones")")
    }

    @ViewBuilder
    private var badge: some View {
        if wearing {
            Label("Wearing", systemImage: "checkmark")
                .font(.buddy(13, .heavy))
                .foregroundStyle(Color.paper)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.sprout.shade(-0.2)))
        } else if owned {
            Text("Owned")
                .font(.buddy(13, .heavy))
                .foregroundStyle(Color.deepTeal.opacity(0.6))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.deepTeal.opacity(0.08)))
        } else {
            HStack(spacing: 4) {
                BoneShape().fill(Color(hex: 0xE9CF9F)).frame(width: 22, height: 11)
                Text("\(item.price)").font(.buddy(16, .heavy))
            }
            .foregroundStyle(affordable ? Color.deepTeal : Color.coral)
        }
    }
}

/// Coral and paper stripes with a scalloped edge, like a little shop front.
private struct Awning: View {
    var body: some View {
        GeometryReader { geo in
            let stripes = 10
            let w = geo.size.width / CGFloat(stripes)
            HStack(spacing: 0) {
                ForEach(0..<stripes, id: \.self) { i in
                    VStack(spacing: 0) {
                        Rectangle().fill(i.isMultiple(of: 2) ? Color.coral : Color.paper)
                        Circle().fill(i.isMultiple(of: 2) ? Color.coral : Color.paper)
                            .frame(width: w, height: w)
                            .offset(y: -w / 2)
                    }
                    .frame(width: w)
                }
            }
            .shadow(color: .black.opacity(0.1), radius: 0, x: 0, y: 3)
        }
    }
}

private struct ShopSparkles: View {
    @State private var on = false

    var body: some View {
        ZStack {
            ForEach(0..<7) { i in
                Image(systemName: "sparkle")
                    .font(.system(size: i.isMultiple(of: 2) ? 26 : 18, weight: .bold))
                    .foregroundStyle(Color.sunny)
                    .offset(x: CGFloat([-120, 110, -90, 95, -40, 50, 0][i]), y: CGFloat([60, 80, 170, 190, 40, 30, 230][i]))
                    .scaleEffect(on ? 1 : 0.2)
                    .opacity(on ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear { withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { on = true } }
    }
}
