import PhotosUI
import SwiftUI

/// Real-world mission: a checklist to do offline, an optional timer, and a photo proof that ilo "checks".
struct MissionModule: View {
    let session: ModuleSession

    enum Stage: Equatable { case doing, checking, accepted }

    @State private var done: Set<Int> = []
    @State private var stage: Stage = .doing
    @State private var photo: UIImage?
    @State private var showCamera = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var showLibrary = false
    @State private var visible = false
    @State private var confetti = 0
    @State private var polaroidIn = false
    @State private var stamp = false
    // Timer
    @State private var timerLeft: Int = 0
    @State private var timerRunning = false
    @State private var timerTask: Task<Void, Never>?

    private var module: LessonModule { session.module }
    private var steps: [String] { module.instructions ?? [] }
    private var progress: Double { steps.isEmpty ? 0 : Double(done.count) / Double(steps.count) }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    RealHeader(type: module.type, title: nil, tint: session.tint)

                    missionCard.appear(visible, delay: 0.05)

                    if let seconds = module.seconds, seconds > 0 {
                        timerCard(total: seconds).appear(visible, delay: 0.12)
                    }

                    proofSection
                        .appear(visible, delay: 0.18)
                        .id("proof")
                }
                .padding(.horizontal, Metrics.gutter)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .onChange(of: photo) {
                if photo != nil { withAnimation(.smooth(duration: 0.6)) { proxy.scrollTo("proof", anchor: .top) } }
            }
        }
        .overlay { ConfettiView(trigger: confetti).ignoresSafeArea() }
        .onAppear {
            visible = true
            session.hidesCheckBar = true
            session.mood = .excited
            if timerLeft == 0 { timerLeft = module.seconds ?? 0 }
        }
        .onDisappear { timerTask?.cancel() }
        .fullScreenCover(isPresented: $showCamera) {
            RealCameraPicker { image in
                showCamera = false
                if let image { receive(image) }
            }
            .ignoresSafeArea()
        }
        .photosPicker(isPresented: $showLibrary, selection: $pickerItem, matching: .images)
        .onChange(of: pickerItem) {
            guard let item = pickerItem else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    receive(image)
                }
                pickerItem = nil
            }
        }
        .realDemoAuto {
            await realPause(1.2)
            for i in steps.indices.dropLast() {
                toggle(i)
                await realPause(0.45)
            }
            await realPause(0.6)
            receive(RealMissionDemoPhoto.render())
        }
    }

    // MARK: Mission card

    private var missionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("REAL-WORLD MISSION", systemImage: "flag.checkered")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(Palette.ink.opacity(0.6))
                    Text(module.title ?? "Your mission")
                        .font(.display(26, weight: .heavy))
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if let prompt = module.prompt {
                        Text(prompt)
                            .font(.body(15, weight: .medium))
                            .foregroundStyle(Palette.ink2.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 8)
                ZStack {
                    Circle().stroke(Palette.ink.opacity(0.1), lineWidth: 5)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Palette.ink, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(done.count)/\(steps.count)")
                        .font(.display(14, weight: .heavy))
                        .foregroundStyle(Palette.ink)
                        .contentTransition(.numericText(value: Double(done.count)))
                }
                .frame(width: 54, height: 54)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: done.count)
            }

            VStack(spacing: 10) {
                ForEach(Array(steps.enumerated()), id: \.offset) { i, step in
                    checkRow(i, step)
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(colors: [Palette.peach, Palette.butter.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: .rect(cornerRadius: 32, style: .continuous)
        )
        .overlay(alignment: .topTrailing) {
            Image(systemName: "sparkle")
                .font(.system(size: 60, weight: .black))
                .foregroundStyle(.white.opacity(0.35))
                .offset(x: -70, y: -14)
                .allowsHitTesting(false)
        }
        .shadow(color: Palette.orange.opacity(0.18), radius: 20, y: 10)
    }

    private func checkRow(_ i: Int, _ step: String) -> some View {
        let on = done.contains(i)
        return Button { toggle(i) } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(on ? Palette.ink : .white)
                        .frame(width: 30, height: 30)
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(.white)
                        .scaleEffect(on ? 1 : 0.2)
                        .opacity(on ? 1 : 0)
                }
                Text(step)
                    .font(.body(16, weight: .semibold))
                    .foregroundStyle(on ? Palette.ink.opacity(0.45) : Palette.ink)
                    .strikethrough(on, color: Palette.ink.opacity(0.4))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(.white.opacity(on ? 0.4 : 0.75), in: .rect(cornerRadius: 18, style: .continuous))
            .contentShape(.rect)
        }
        .buttonStyle(.squish(0.97))
        .disabled(stage != .doing)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: on)
    }

    private func toggle(_ i: Int) {
        if done.contains(i) {
            done.remove(i)
            Haptics.shared.softTap()
        } else {
            done.insert(i)
            Haptics.shared.correct()
            SoundFX.shared.play(done.count == steps.count ? .coin : .pop)
            if done.count == steps.count { session.mood = .proud }
        }
    }

    // MARK: Timer

    private func timerCard(total: Int) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().stroke(session.tint.soft, lineWidth: 6)
                Circle()
                    .trim(from: 0, to: Double(timerLeft) / Double(max(1, total)))
                    .stroke(session.tint.deep, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timerLeft)
                Image(systemName: timerLeft == 0 ? "checkmark" : "timer")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(session.tint.deep)
                    .contentTransition(.symbolEffect(.replace))
            }
            .frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 2) {
                Text(String(format: "%d:%02d", timerLeft / 60, timerLeft % 60))
                    .font(.display(26, weight: .heavy))
                    .monospacedDigit()
                    .foregroundStyle(Palette.ink)
                    .contentTransition(.numericText(countsDown: true))
                Text(timerLeft == 0 ? "Time's up — nice focus!" : "Optional focus timer")
                    .font(.body(13, weight: .medium))
                    .foregroundStyle(Palette.muted)
            }
            Spacer()
            Button {
                timerRunning ? pauseTimer() : startTimer(total: total)
            } label: {
                Image(systemName: timerLeft == 0 ? "arrow.counterclockwise" : (timerRunning ? "pause.fill" : "play.fill"))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(Palette.ink, in: .circle)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.squish)
        }
        .card(radius: 26, padding: 14)
    }

    private func startTimer(total: Int) {
        if timerLeft == 0 { timerLeft = total }
        timerRunning = true
        Haptics.shared.press()
        timerTask?.cancel()
        timerTask = Task {
            while timerLeft > 0 && !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                withAnimation { timerLeft -= 1 }
                if timerLeft <= 3 && timerLeft > 0 { Haptics.shared.tick(); SoundFX.shared.play(.tick) }
            }
            if timerLeft == 0 {
                timerRunning = false
                Haptics.shared.levelUp()
                SoundFX.shared.play(.streak)
            }
        }
    }

    private func pauseTimer() {
        timerTask?.cancel()
        timerRunning = false
        Haptics.shared.softTap()
    }

    // MARK: Proof

    @ViewBuilder
    private var proofSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "camera.viewfinder")
                    .foregroundStyle(session.tint.deep)
                Text(module.proof.map { "Proof: \($0)" } ?? "Proof: a photo of what you did")
                    .font(.body(15, weight: .bold))
                    .foregroundStyle(Palette.ink2)
            }

            if let photo {
                polaroid(photo)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                switch stage {
                case .checking:
                    RealThinkingRow(text: "ilo is checking your proof…")
                        .transition(.opacity)
                case .accepted:
                    VStack(spacing: 12) {
                        RealIloSays(text: "Proof accepted! That's how real habits start. +15 bonus XP", expression: .proud, size: 50)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                case .doing:
                    EmptyView()
                }
            } else {
                VStack(spacing: 12) {
                    Button {
                        Haptics.shared.press()
                        if RealCameraPicker.isAvailable { showCamera = true } else { showLibrary = true }
                    } label: {
                        Label(RealCameraPicker.isAvailable ? "Take a photo" : "Choose a photo", systemImage: "camera.fill")
                    }
                    .buttonStyle(.pill(.ink))

                    HStack(spacing: 12) {
                        if RealCameraPicker.isAvailable {
                            Button {
                                showLibrary = true
                            } label: {
                                Label("From library", systemImage: "photo.on.rectangle")
                            }
                            .buttonStyle(.pill(.white, height: 50))
                        }
                        Button {
                            Haptics.shared.tap()
                            timerTask?.cancel()
                            session.finish()
                        } label: {
                            Text("Skip for now")
                        }
                        .buttonStyle(.pill(.white, height: 50))
                    }
                }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: stage)
    }

    private func polaroid(_ image: UIImage) -> some View {
        VStack(spacing: 10) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 236, height: 236)
                .clipped()
            Text(stage == .accepted ? "Mission done ✓" : "My proof")
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .italic()
                .foregroundStyle(Palette.ink2)
                .contentTransition(.opacity)
                .padding(.bottom, 6)
        }
        .padding([.top, .horizontal], 12)
        .padding(.bottom, 8)
        .background(.white, in: .rect(cornerRadius: 6))
        .shadow(color: .black.opacity(0.18), radius: 18, y: 12)
        .overlay(alignment: .topTrailing) {
            Text("APPROVED")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .tracking(2)
                .foregroundStyle(Palette.success)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Palette.success, lineWidth: 3))
                .rotationEffect(.degrees(-14))
                .scaleEffect(stamp ? 1 : 2.4)
                .opacity(stamp ? 0.92 : 0)
                .offset(x: 18, y: 150)
        }
        .rotationEffect(.degrees(polaroidIn ? -4 : 14))
        .offset(y: polaroidIn ? 0 : -340)
        .scaleEffect(polaroidIn ? 1 : 1.25)
        .opacity(polaroidIn ? 1 : 0)
    }

    private func receive(_ image: UIImage) {
        let thumb = image.realThumbnail()
        polaroidIn = false
        stamp = false
        photo = thumb
        stage = .checking
        session.mood = .curious
        SoundFX.shared.play(.whoosh)
        withAnimation(.spring(response: 0.6, dampingFraction: 0.62).delay(0.1)) { polaroidIn = true }
        Task {
            try? await Task.sleep(for: .seconds(0.55))
            Haptics.shared.thud()
            try? await Task.sleep(for: .seconds(1.6))
            accept()
        }
    }

    private func accept() {
        guard stage == .checking else { return }
        timerTask?.cancel()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) { stamp = true }
        withAnimation(.spring) {
            stage = .accepted
            done = Set(steps.indices)
        }
        Haptics.shared.celebrate()
        confetti += 1
        session.bonusXP = 15
        session.resolve(correct: true, feedback: "Mission complete! You did it in the real world — that's what makes it stick.")
    }
}

/// DEBUG/demo: a rendered "photo" so the proof flow can be shown on the simulator without a camera.
enum RealMissionDemoPhoto {
    @MainActor
    static func render() -> UIImage {
        let view = ZStack {
            LinearGradient(colors: [Color(hex: 0xF6E7D8), Color(hex: 0xE9D3BF)], startPoint: .top, endPoint: .bottom)
            RoundedRectangle(cornerRadius: 30).fill(.white).frame(width: 260, height: 150).offset(y: 70)
                .shadow(color: .black.opacity(0.08), radius: 10, y: 6)
            Image(systemName: "book.closed.fill")
                .font(.system(size: 120))
                .foregroundStyle(Palette.periwinkleDeep)
                .rotationEffect(.degrees(-12))
                .offset(y: 20)
            Image(systemName: "note.text")
                .font(.system(size: 44))
                .foregroundStyle(Palette.gold)
                .rotationEffect(.degrees(10))
                .offset(x: 80, y: -50)
        }
        .frame(width: 400, height: 400)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        return renderer.uiImage ?? UIImage()
    }
}
