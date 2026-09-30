import SwiftUI

// MARK: - Splash

/// bloub morphs through every silhouette, then settles into the "ilo" wordmark.
struct OBSplashStep: View {
    var onDone: () -> Void

    @State private var index = 0
    @State private var entered = false
    @State private var showWord = false
    @State private var finished = false

    private let frames: [(BloubShape, BloubColor)] = [
        (.circle, .ink), (.squircle, .blue), (.cloud, .violet), (.droplet, .orange),
        (.hexagon, .green), (.capsule, .pink), (.pebble, .turquoise), (.circle, .ink),
    ]

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            OBBounce(trigger: index) {
                BloubView(shape: frames[index].0, color: frames[index].1,
                          expression: showWord ? .happy : .excited)
                    .frame(width: showWord ? 120 : 170, height: showWord ? 120 : 170)
            }
            .scaleEffect(entered ? 1 : 0.1)
            .opacity(entered ? 1 : 0)

            HStack(spacing: 2) {
                ForEach(Array("ilo".enumerated()), id: \.offset) { i, letter in
                    Text(String(letter))
                        .font(.display(92, weight: .heavy))
                        .foregroundStyle(Palette.ink)
                        .appear(showWord, delay: Double(i) * 0.08, y: 40)
                }
            }
            .frame(height: showWord ? 100 : 0)
            .clipped()

            Text("learn anything")
                .font(.display(18, weight: .semibold))
                .foregroundStyle(Palette.muted)
                .appear(showWord, delay: 0.35)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .contentShape(.rect)
        .onTapGesture { done() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("ilo")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("splash")
        .task {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.6)) { entered = true }
            Haptics.shared.softTap()
            try? await Task.sleep(for: .milliseconds(420))
            for i in 1..<frames.count {
                guard !finished else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { index = i }
                Haptics.shared.tick()
                SoundFX.shared.play(.pop)
                try? await Task.sleep(for: .milliseconds(260))
            }
            guard !finished else { return }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.72)) { showWord = true }
            Haptics.shared.levelUp()
            SoundFX.shared.play(.levelUp)
            try? await Task.sleep(for: .milliseconds(1500))
            done()
        }
    }

    private func done() {
        guard !finished else { return }
        finished = true
        onDone()
    }
}

// MARK: - Welcome

/// "Learn anything. Like it's a game." — big bold type with a highlighted word block.
struct OBWelcomeStep: View {
    var onStart: () -> Void
    @State private var visible = false
    @State private var focus = 0

    private struct Topic: Identifiable {
        var id: String { title }
        var title: String
        var symbol: String
        var tint: CourseTint
        var at: CGPoint
    }

    private let topics: [Topic] = [
        .init(title: "Salsa", symbol: "figure.dance", tint: .orchid, at: CGPoint(x: -120, y: -125)),
        .init(title: "Python", symbol: "chevron.left.forwardslash.chevron.right", tint: .sky, at: CGPoint(x: 112, y: -140)),
        .init(title: "Atomic Habits", symbol: "books.vertical.fill", tint: .butter, at: CGPoint(x: 104, y: 92)),
        .init(title: "Chess", symbol: "crown.fill", tint: .mint, at: CGPoint(x: -132, y: 8)),
        .init(title: "Japanese", symbol: "character.book.closed.fill", tint: .peach, at: CGPoint(x: -104, y: 112)),
        .init(title: "Public speaking", symbol: "music.mic", tint: .lavender, at: CGPoint(x: 24, y: 166)),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            cluster
                .frame(height: 380)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)

            Spacer(minLength: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text("Learn")
                    .font(.display(56, weight: .heavy))
                    .appear(visible, delay: 0.05)
                OBHighlightWord(text: "anything.", fill: Palette.periwinkle, size: 56)
                    .appear(visible, delay: 0.15)
                Text("Like it's a \(Text("game.").foregroundStyle(Palette.periwinkleDeep))")
                    .font(.display(40, weight: .heavy))
                    .padding(.top, 6)
                    .appear(visible, delay: 0.25)
            }
            .foregroundStyle(Palette.ink)

            Text("Tell ilo what you want to learn. It researches, builds your path, and turns it into bite-sized play.")
                .font(.body(17))
                .foregroundStyle(Palette.muted)
                .padding(.top, 14)
                .fixedSize(horizontal: false, vertical: true)
                .appear(visible, delay: 0.35)

            Spacer(minLength: 16)

            Button(action: onStart) {
                HStack(spacing: 8) {
                    Text("Get started")
                    Image(systemName: "arrow.right").font(.system(size: 16, weight: .bold))
                }
            }
            .buttonStyle(.pill(.ink))
            .accessibilityIdentifier("welcome-start")
            .appear(visible, delay: 0.45)

            Text("Takes 2 minutes. No account needed.")
                .font(.body(13, weight: .medium))
                .foregroundStyle(Palette.faint)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
                .appear(visible, delay: 0.5)
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.bottom, 8)
        .onAppear { visible = true }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1.4))
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { focus = (focus + 1) % topics.count }
            }
        }
    }

    private var cluster: some View {
        GeometryReader { geo in
            let k = min(geo.size.width / 400, 1.1)
            TimelineView(.animation(minimumInterval: 1 / 30)) { context in
                let t = context.date.timeIntervalSinceReferenceDate
                ZStack {
                    Circle()
                        .fill(RadialGradient(colors: [Palette.periwinkle.opacity(0.45), .clear], center: .center, startRadius: 10, endRadius: 150))
                        .frame(width: 300, height: 300)
                    ForEach(Array(topics.enumerated()), id: \.offset) { i, topic in
                        let bob = sin(t * 1.3 + Double(i) * 1.1) * 6
                        HStack(spacing: 6) {
                            Image(systemName: topic.symbol).font(.system(size: 13, weight: .bold)).foregroundStyle(topic.tint.deep)
                            Text(topic.title).font(.display(14, weight: .bold)).foregroundStyle(Palette.ink)
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 36)
                        .background(i == focus ? topic.tint.soft : .white, in: .capsule)
                        .shadow(color: Color(hex: 0x3A4470, alpha: 0.1), radius: 10, y: 5)
                        .scaleEffect(i == focus ? 1.12 : 1)
                        .rotationEffect(.degrees(sin(t * 0.9 + Double(i)) * 3))
                        .offset(x: topic.at.x * k, y: topic.at.y + bob)
                        .appear(visible, delay: 0.1 + Double(i) * 0.07)
                    }
                    OBBounce(trigger: focus) {
                        BloubView(shape: .circle, color: .ilo, expression: .excited,
                                  lookAt: CGPoint(x: topics[focus].at.x / 130, y: topics[focus].at.y / 150))
                            .frame(width: 140, height: 140)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }
}

// MARK: - How it works

struct OBHowItWorksStep: View {
    @State private var shown = 0
    @State private var typed = ""
    private let sample = "Salsa for my grandma's wedding"

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                card(index: 1, tint: .peach, title: "You name a goal", subtitle: "Anything: a dance, a book, a language, a skill.") {
                    HStack {
                        Text(typed.isEmpty ? " " : typed)
                            .font(.display(16, weight: .bold))
                            .foregroundStyle(Palette.ink)
                        Rectangle().fill(Palette.ink).frame(width: 2, height: 18)
                            .opacity(shown >= 1 ? 1 : 0)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(.white.opacity(0.8), in: .capsule)
                }
                card(index: 2, tint: .lavender, title: "ilo researches it", subtitle: "Real sources, turned into a path made for you.") {
                    HStack(spacing: 12) {
                        BloubView(shape: .circle, color: .ilo, mode: .thinking).frame(width: 40, height: 40)
                        Chip(text: "12 sources", systemImage: "doc.text.magnifyingglass", fill: .white)
                        Chip(text: "6 units", systemImage: "square.stack.3d.up.fill", fill: .white)
                        Spacer(minLength: 0)
                    }
                }
                card(index: 3, tint: .mint, title: "You play, every day", subtitle: "5-minute lessons, streaks, leagues and real missions.") {
                    HStack(spacing: 10) {
                        ForEach(0..<4, id: \.self) { i in
                            Circle()
                                .fill(i < 2 ? CourseTint.mint.deep : .white)
                                .frame(width: 40, height: 40)
                                .overlay {
                                    Image(systemName: i < 2 ? "checkmark" : (i == 3 ? "crown.fill" : "star.fill"))
                                        .font(.system(size: 15, weight: .heavy))
                                        .foregroundStyle(i < 2 ? .white : Palette.faint)
                                }
                                .offset(y: i % 2 == 0 ? 0 : 8)
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill").foregroundStyle(Palette.flame)
                                .symbolEffect(.bounce, value: shown)
                            Text("7").font(.display(18, weight: .heavy))
                        }
                    }
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.top, 18)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .task {
            for i in 1...3 {
                try? await Task.sleep(for: .milliseconds(i == 1 ? 250 : 420))
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { shown = i }
                Haptics.shared.tick()
                SoundFX.shared.play(.pop)
                if i == 1 {
                    Task {
                        for ch in sample {
                            try? await Task.sleep(for: .milliseconds(35))
                            typed.append(ch)
                        }
                    }
                }
            }
        }
    }

    private func card<Content: View>(index: Int, tint: CourseTint, title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Text("\(index)")
                    .font(.display(16, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(Palette.ink, in: .circle)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.display(19, weight: .bold)).foregroundStyle(Palette.ink)
                    Text(subtitle).font(.body(14)).foregroundStyle(Palette.ink2.opacity(0.75))
                }
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(tint.soft, radius: 28, padding: 16)
        .opacity(shown >= index ? 1 : 0)
        .offset(y: shown >= index ? 0 : 30)
        .scaleEffect(shown >= index ? 1 : 0.94)
    }
}
