import SwiftUI

/// Gem shop (streak freezes).
struct ShopView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var bought = 0
    @State private var denied = 0
    @State private var shown = false

    var body: some View {
        let p = model.player
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 6) {
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(Palette.gem.gradient)
                        .symbolEffect(.bounce, value: bought)
                    Text("\(p.gems)")
                        .font(.display(46, weight: .heavy))
                        .contentTransition(.numericText(value: Double(p.gems)))
                    Text("gems").font(.body(15, weight: .semibold)).foregroundStyle(Palette.muted)
                }
                .padding(.top, 10)
                .appear(shown)

                ForEach(ShopItem.allCases) { item in
                    let owned = item == .streakFreeze ? p.streakFreezes : 0
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 14) {
                            Image(systemName: item.symbol)
                                .font(.system(size: 26, weight: .bold))
                                .foregroundStyle(Palette.victory)
                                .frame(width: 62, height: 62)
                                .background(Palette.sky, in: .rect(cornerRadius: 20, style: .continuous))
                                .symbolEffect(.bounce, value: bought)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.title).font(.display(19, weight: .bold))
                                Text(item.detail).font(.body(13)).foregroundStyle(Palette.muted)
                                Text("Equipped: \(owned)").font(.body(12, weight: .bold)).foregroundStyle(Palette.victoryDeep)
                                    .contentTransition(.numericText())
                            }
                        }
                        Button {
                            if model.buy(item) {
                                withAnimation(.spring) { bought += 1 }
                                Haptics.shared.celebrate()
                                SoundFX.shared.play(.coin)
                            } else {
                                denied += 1
                                Haptics.shared.warning()
                                SoundFX.shared.play(.wrong)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text("Buy for")
                                Image(systemName: "diamond.fill")
                                Text("\(item.price)")
                            }
                        }
                        .buttonStyle(.pill(p.gems >= item.price ? .ink : .white, height: 50))
                        .keyframeAnimator(initialValue: CGFloat(0), trigger: denied) { v, x in v.offset(x: x) } keyframes: { _ in
                            LinearKeyframe(-9, duration: 0.06); LinearKeyframe(9, duration: 0.08); LinearKeyframe(0, duration: 0.06)
                        }
                        if p.gems < item.price {
                            Text("You need \(item.price - p.gems) more gems. Open chests and claim quests to earn them.")
                                .font(.body(12)).foregroundStyle(Palette.muted)
                        }
                    }
                    .card(radius: 30, padding: 18)
                    .appear(shown, delay: 0.1)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("How to earn gems").font(.display(17, weight: .bold))
                    earn("checkmark.seal.fill", "Finish a lesson", "+5 (perfect: +10)")
                    earn("gift.fill", "Open a chest on your path", "+15 to 40")
                    earn("checklist", "Claim a daily quest", "+10 to 20")
                }
                .card(Palette.periwinkleMist, radius: 26, padding: 18)
                .appear(shown, delay: 0.16)
            }
            .padding(Metrics.gutter)
        }
        .background(Palette.canvas)
        .navigationTitle("Shop")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { shown = true }
    }

    private func earn(_ symbol: String, _ title: String, _ value: String) -> some View {
        HStack {
            Image(systemName: symbol).foregroundStyle(Palette.periwinkleDeep).frame(width: 24)
            Text(title).font(.body(14, weight: .medium))
            Spacer()
            Text(value).font(.body(13, weight: .bold)).foregroundStyle(Palette.gem)
        }
    }
}
