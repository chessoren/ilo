import SwiftUI

/// Customize your bloub: shapes & colours unlock with levels; the preview morphs live.
struct BloubStudioView: View {
    @Environment(AppModel.self) private var model
    @State private var expression: BloubExpression = .happy
    @State private var hop = 0
    @State private var lockedShake = 0
    @State private var message: String?

    var body: some View {
        let p = model.player
        ScrollView {
            VStack(spacing: 24) {
                ZStack(alignment: .bottom) {
                    Ellipse().fill(p.bloubColor.color.opacity(0.18)).frame(width: 190, height: 30).blur(radius: 4)
                    BloubView(shape: p.bloubShape, color: p.bloubColor, expression: expression)
                        .frame(width: 190, height: 190)
                        .padding(.bottom, 12)
                        .keyframeAnimator(initialValue: CGFloat(0), trigger: hop) { v, y in v.offset(y: y) } keyframes: { _ in
                            SpringKeyframe(-40, duration: 0.22)
                            SpringKeyframe(0, duration: 0.4, spring: .bouncy)
                        }
                }
                .frame(height: 222)
                .keyframeAnimator(initialValue: CGFloat(0), trigger: lockedShake) { v, x in v.offset(x: x) } keyframes: { _ in
                    LinearKeyframe(-10, duration: 0.06); LinearKeyframe(10, duration: 0.08); LinearKeyframe(0, duration: 0.06)
                }

                Text(message ?? "\(p.bloubColor.rawValue.capitalized) \(p.bloubShape.title)")
                    .font(.display(20, weight: .bold))
                    .contentTransition(.interpolate)
                    .animation(.snappy, value: message)

                section("Shape") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                        ForEach(BloubShape.allCases.sorted { $0.unlockLevel < $1.unlockLevel }) { shape in
                            let locked = shape.unlockLevel > p.level
                            Button { pick(shape: shape, locked: locked) } label: {
                                VStack(spacing: 4) {
                                    BloubView(shape: shape, color: locked ? .grey : p.bloubColor, expression: .neutral, alive: false)
                                        .frame(width: 46, height: 46)
                                        .opacity(locked ? 0.45 : 1)
                                    Text(locked ? "Lv \(shape.unlockLevel)" : shape.title)
                                        .font(.body(11, weight: .semibold))
                                        .foregroundStyle(locked ? Palette.faint : Palette.ink2)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(.white, in: .rect(cornerRadius: 20, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(p.bloubShape == shape ? Palette.ink : .clear, lineWidth: 2.5))
                                .overlay(alignment: .topTrailing) {
                                    if locked { Image(systemName: "lock.fill").font(.system(size: 10)).foregroundStyle(Palette.faint).padding(8) }
                                }
                            }
                            .buttonStyle(.squish)
                        }
                    }
                }

                section("Colour") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 14) {
                        ForEach(BloubColor.playerColors.sorted { $0.unlockLevel < $1.unlockLevel }) { color in
                            let locked = color.unlockLevel > p.level
                            Button { pick(color: color, locked: locked) } label: {
                                ZStack {
                                    Circle().fill(color.color).opacity(locked ? 0.3 : 1)
                                        .overlay(Circle().stroke(Palette.hairline, lineWidth: 1))
                                    if locked {
                                        Image(systemName: "lock.fill").font(.system(size: 12, weight: .bold)).foregroundStyle(Palette.ink.opacity(0.5))
                                    } else if p.bloubColor == color {
                                        Image(systemName: "checkmark").font(.system(size: 14, weight: .heavy)).foregroundStyle(color.eyeColor)
                                    }
                                }
                                .frame(width: 44, height: 44)
                                .padding(3)
                                .overlay(Circle().stroke(p.bloubColor == color ? Palette.ink : .clear, lineWidth: 2.5))
                            }
                            .buttonStyle(.squish(0.9))
                        }
                    }
                }
                Text("New shapes and colours unlock as you level up. You're level \(p.level).")
                    .font(.body(13)).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
            }
            .padding(Metrics.gutter)
            .padding(.bottom, 90) // clear the floating tab bar
        }
        .background(IloBackground(tint: p.bloubColor.color.opacity(0.6), lines: false))
        .navigationTitle("My bloub")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            let cycle: [BloubExpression] = [.happy, .curious, .excited, .proud, .attentive]
            var i = 0
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2.4))
                i += 1
                expression = cycle[i % cycle.count]
            }
        }
    }

    private func section<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.display(18, weight: .bold))
            content()
        }
    }

    private func pick(shape: BloubShape, locked: Bool) {
        guard !locked else { return deny("Reach level \(shape.unlockLevel) to unlock \(shape.title)") }
        guard shape != model.player.bloubShape else { return }
        model.player.bloubShape = shape
        model.save()
        celebrate()
    }

    private func pick(color: BloubColor, locked: Bool) {
        guard !locked else { return deny("Reach level \(color.unlockLevel) for \(color.rawValue)") }
        guard color != model.player.bloubColor else { return }
        model.player.bloubColor = color
        model.save()
        celebrate()
    }

    private func celebrate() {
        hop += 1
        message = nil
        expression = .excited
        Haptics.shared.correct()
        SoundFX.shared.play(.pop)
    }

    private func deny(_ text: String) {
        lockedShake += 1
        expression = .sad
        message = text
        Haptics.shared.warning()
        Task {
            try? await Task.sleep(for: .seconds(2))
            message = nil
            expression = .happy
        }
    }
}
