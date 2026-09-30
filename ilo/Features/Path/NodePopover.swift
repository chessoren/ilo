import SwiftUI

/// Glass card that drops under a tapped node: title, what you'll learn, XP and the Start pill.
struct NodePopover: View {
    enum Action { case start, openChest, dismiss }

    @Environment(AppModel.self) private var model
    let course: Course
    let node: PathNode
    let state: NodeState
    let arrowX: CGFloat
    var perform: (Action) -> Void

    @State private var shake = 0
    @State private var lockedHint = false

    var body: some View {
        let unit = course.unit(containing: node.id)
        let tint = unit?.tint ?? course.tint
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Label(node.kind.label, systemImage: node.kind.defaultSymbol)
                    .font(.body(12, weight: .bold))
                    .foregroundStyle(tint.deep)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(tint.soft, in: .capsule)
                if node.kind != .chest {
                    Label("\(node.xp) XP", systemImage: "bolt.fill")
                        .font(.body(12, weight: .bold))
                        .foregroundStyle(Palette.ink2)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Palette.butter, in: .capsule)
                }
                Spacer()
                statusBadge(tint)
            }
            Text(node.title)
                .font(.display(22, weight: .heavy))
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(description)
                .font(.body(14))
                .foregroundStyle(Palette.ink2.opacity(0.8))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            if lockedHint {
                Label("Complete previous lessons first", systemImage: "lock.fill")
                    .font(.body(13, weight: .semibold))
                    .foregroundStyle(Palette.danger)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            button(tint)
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.white.opacity(0.55))
                .glassEffect(.regular, in: .rect(cornerRadius: 28, style: .continuous))
        }
        .overlay(alignment: .topLeading) {
            Triangle()
                .fill(.white.opacity(0.9))
                .frame(width: 22, height: 11)
                .rotationEffect(.degrees(180))
                .offset(x: arrowX - Metrics.gutter - 11, y: -10)
        }
        .shadow(color: Color(hex: 0x3A4470, alpha: 0.14), radius: 24, y: 12)
        .padding(.horizontal, Metrics.gutter)
        .keyframeAnimator(initialValue: CGFloat(0), trigger: shake) { v, x in v.offset(x: x) } keyframes: { _ in
            LinearKeyframe(-12, duration: 0.06)
            LinearKeyframe(10, duration: 0.07)
            LinearKeyframe(-7, duration: 0.07)
            LinearKeyframe(4, duration: 0.07)
            LinearKeyframe(0, duration: 0.06)
        }
    }

    private var description: String {
        if node.kind == .chest {
            return state == .completed ? "You already opened this chest." : "A treasure chest full of gems. Reach it to crack it open!"
        }
        let brief = node.brief.trimmingCharacters(in: .whitespacesAndNewlines)
        if let end = brief.firstIndex(where: { ".!?".contains($0) }) {
            return String(brief[...end])
        }
        return brief
    }

    @ViewBuilder private func statusBadge(_ tint: CourseTint) -> some View {
        if state == .completed {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 20))
                .foregroundStyle(Palette.success)
        } else if model.generating.contains(node.id) {
            BloubView(shape: .circle, color: .ink, mode: .thinking).frame(width: 28)
        } else if model.lessons[node.id] != nil {
            Image(systemName: "sparkles")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(tint.deep)
                .symbolEffect(.pulse)
        }
    }

    @ViewBuilder private func button(_ tint: CourseTint) -> some View {
        switch state {
        case .locked:
            Button {
                shake += 1
                Haptics.shared.warning()
                SoundFX.shared.play(.wrong)
                withAnimation(.spring) { lockedHint = true }
            } label: {
                Label("Locked", systemImage: "lock.fill")
            }
            .buttonStyle(.pill(.white, height: 50))
        case .current:
            if node.kind == .chest {
                Button { perform(.openChest) } label: { Label("Open chest", systemImage: "gift.fill") }
                    .buttonStyle(.pill(.ink, height: 50))
            } else {
                Button { perform(.start) } label: {
                    HStack(spacing: 6) {
                        Text("Start")
                        Text("+\(node.xp) XP").foregroundStyle(.white.opacity(0.7))
                    }
                }
                .buttonStyle(.pill(.ink, height: 50))
            }
        case .completed:
            if node.kind == .chest {
                Button { perform(.dismiss) } label: { Text("Nice!") }
                    .buttonStyle(.pill(.white, height: 50))
            } else {
                Button { perform(.start) } label: { Label("Practice again", systemImage: "arrow.counterclockwise") }
                    .buttonStyle(.pill(.ink, height: 50))
            }
        }
    }
}

/// Full-screen chest opening: shake, pop, gems burst and count-up.
struct ChestOpenOverlay: View {
    let gems: Int
    let tint: CourseTint
    var onDone: () -> Void

    @State private var phase = 0 // 0 shaking, 1 open
    @State private var confetti = 0

    var body: some View {
        ZStack {
            Rectangle().fill(.black.opacity(0.35)).ignoresSafeArea()
                .onTapGesture { if phase == 1 { onDone() } }
            ConfettiView(trigger: confetti).ignoresSafeArea()
            VStack(spacing: 22) {
                ZStack {
                    if phase == 1 {
                        ForEach(0..<10, id: \.self) { i in
                            GemParticle(index: i)
                        }
                    }
                    Image(systemName: phase == 1 ? "gift.fill" : "gift.fill")
                        .font(.system(size: 96, weight: .bold))
                        .foregroundStyle(Palette.gold.gradient)
                        .shadow(color: Palette.gold.opacity(0.6), radius: phase == 1 ? 30 : 0)
                        .symbolEffect(.bounce, value: phase)
                        .keyframeAnimator(initialValue: Double(0), repeating: phase == 0) { v, a in
                            v.rotationEffect(.degrees(a))
                        } keyframes: { _ in
                            LinearKeyframe(-10, duration: 0.08)
                            LinearKeyframe(10, duration: 0.1)
                            LinearKeyframe(-6, duration: 0.1)
                            LinearKeyframe(0, duration: 0.08)
                            LinearKeyframe(0, duration: 0.2)
                        }
                        .scaleEffect(phase == 1 ? 1.15 : 1)
                }
                .frame(height: 160)
                if phase == 1 {
                    VStack(spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "diamond.fill").foregroundStyle(Palette.gem)
                            CountUpText(value: gems, font: .display(48, weight: .heavy), prefix: "+")
                        }
                        Text("gems found in the chest!").font(.body(16, weight: .semibold)).foregroundStyle(Palette.muted)
                    }
                    .transition(.scale.combined(with: .opacity))
                    Button("Collect", action: onDone)
                        .buttonStyle(.pill(.victory))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(28)
            .frame(maxWidth: 340)
            .glassEffect(.regular.tint(.white.opacity(0.55)), in: .rect(cornerRadius: 40, style: .continuous))
            .padding(24)
        }
        .onAppear {
            SoundFX.shared.play(.whoosh)
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.1))
                withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) { phase = 1 }
                confetti += 1
                SoundFX.shared.play(.coin)
                Haptics.shared.levelUp()
            }
        }
    }
}

private struct GemParticle: View {
    let index: Int
    @State private var fly = false

    var body: some View {
        let angle = Double(index) / 10 * .pi * 2
        Image(systemName: "diamond.fill")
            .font(.system(size: CGFloat(14 + index % 3 * 5), weight: .bold))
            .foregroundStyle(Palette.gem)
            .offset(x: fly ? cos(angle) * 120 : 0, y: fly ? sin(angle) * 100 - 20 : 0)
            .opacity(fly ? 0 : 1)
            .scaleEffect(fly ? 1.2 : 0.3)
            .onAppear { withAnimation(.easeOut(duration: 1.1)) { fly = true } }
    }
}
