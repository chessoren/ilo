import AVFoundation
import SwiftUI

/// ilo reads the script aloud (on-device TTS) with karaoke word highlighting, play/pause, speed and a live waveform.
struct AudioLessonModule: View {
    let session: ModuleSession

    @State private var reader = LessonSpeechReader()
    @State private var appeared = false

    private var lines: [String] { session.module.script ?? [] }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ModulePrompt(title: "Listen", prompt: session.module.title ?? "Listen to ilo")
                            .appear(appeared)
                        ForEach(Array(lines.enumerated()), id: \.offset) { i, line in
                            Text(attributed(line, index: i))
                                .font(.display(22, weight: .semibold))
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background {
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .fill(i == reader.lineIndex && reader.hasStarted ? Color.white : Color.clear)
                                        .shadow(color: Color(hex: 0x3A4470, alpha: i == reader.lineIndex && reader.hasStarted ? 0.08 : 0), radius: 14, y: 6)
                                }
                                .scaleEffect(i == reader.lineIndex && reader.hasStarted ? 1 : 0.98, anchor: .leading)
                                .id(i)
                                .onTapGesture {
                                    Haptics.shared.tick()
                                    reader.play(lines: lines, from: i)
                                }
                                .appear(appeared, delay: 0.05 + Double(i) * 0.05)
                        }
                    }
                    .padding(.horizontal, Metrics.gutter)
                    .padding(.vertical, 16)
                }
                .scrollBounceBehavior(.basedOnSize)
                .onChange(of: reader.lineIndex) { _, i in
                    withAnimation(.smooth) { proxy.scrollTo(i, anchor: .center) }
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: reader.lineIndex)

            controls
                .padding(.horizontal, 12)
                .padding(.bottom, 4)
        }
        .onAppear {
            appeared = true
            session.hidesCheckBar = true
            session.mood = .happy
        }
        .task {
            // `.task` is cancelled on disappear, so skipping within 700 ms can't start speech on the next module.
            try? await Task.sleep(for: .milliseconds(700))
            if !Task.isCancelled, !reader.hasStarted, !session.isDetached { reader.play(lines: lines, from: 0) }
        }
        .onDisappear { reader.stop() }
        .onChange(of: reader.isPlaying) { _, playing in
            session.mood = playing ? .happy : (reader.finished ? .proud : .attentive)
        }
    }

    private func attributed(_ line: String, index i: Int) -> AttributedString {
        var attr = AttributedString(line)
        let current = reader.hasStarted && !reader.finished && i == reader.lineIndex
        let past = reader.hasStarted && (i < reader.lineIndex || reader.finished)
        attr.foregroundColor = current ? Palette.ink.opacity(0.35) : (past ? Palette.ink : Palette.ink.opacity(0.3))
        if current, let r = reader.wordRange, let swiftRange = Range(r, in: line),
           let lower = AttributedString.Index(swiftRange.lowerBound, within: attr),
           let upper = AttributedString.Index(swiftRange.upperBound, within: attr) {
            // Everything spoken so far on this line is ink; the current word gets the highlighter.
            attr[attr.startIndex..<upper].foregroundColor = Palette.ink
            attr[lower..<upper].backgroundColor = session.tint.soft
            attr[lower..<upper].foregroundColor = session.tint.deep
        } else if current && reader.wordRange == nil {
            attr.foregroundColor = Palette.ink.opacity(0.45)
        }
        return attr
    }

    private var controls: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                Button {
                    Haptics.shared.press()
                    reader.toggle(lines: lines)
                } label: {
                    Image(systemName: reader.isPlaying ? "pause.fill" : (reader.finished ? "arrow.counterclockwise" : "play.fill"))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .contentTransition(.symbolEffect(.replace))
                        .frame(width: 64, height: 64)
                        .background(Palette.ink, in: .circle)
                }
                .buttonStyle(.squish(0.9))

                LessonWaveform(active: reader.isPlaying, tint: session.tint.deep)
                    .frame(height: 44)

                Menu {
                    ForEach([0.75, 1.0, 1.25, 1.5], id: \.self) { s in
                        Button("\(s.formatted())×") { reader.setSpeed(s, lines: lines) }
                    }
                } label: {
                    Text("\(reader.speed.formatted())×")
                        .font(.display(16, weight: .bold))
                        .foregroundStyle(Palette.ink)
                        .frame(width: 58, height: 40)
                        .background(Palette.canvas, in: .capsule)
                }
            }
            Button {
                reader.stop()
                session.finish()
            } label: {
                Text(reader.finished ? "Continue" : "I've got it")
            }
            .buttonStyle(.pill(reader.finished ? .ink : .white))
        }
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 34, style: .continuous))
    }
}

/// Animated bars — bounce while ilo is speaking.
struct LessonWaveform: View {
    var active: Bool
    var tint: Color

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: !active)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { gc, size in
                let bars = 22
                let w = size.width / CGFloat(bars)
                for i in 0..<bars {
                    let phase = Double(i) * 0.55
                    let amp = active ? (0.35 + 0.65 * abs(sin(t * 5.2 + phase) * cos(t * 2.1 + phase * 0.7))) : 0.18
                    let h = max(4, size.height * amp)
                    let rect = CGRect(x: CGFloat(i) * w + w * 0.2, y: (size.height - h) / 2, width: w * 0.6, height: h)
                    gc.fill(Path(roundedRect: rect, cornerRadius: w * 0.3), with: .color(tint.opacity(active ? 0.9 : 0.35)))
                }
            }
        }
    }
}

/// Wraps AVSpeechSynthesizer: speaks lines in sequence and publishes the word being spoken.
@Observable
@MainActor
final class LessonSpeechReader: NSObject, AVSpeechSynthesizerDelegate {
    private(set) var lineIndex = 0
    private(set) var wordRange: NSRange?
    private(set) var isPlaying = false
    private(set) var hasStarted = false
    private(set) var finished = false
    private(set) var speed: Double = 1

    @ObservationIgnored private let synth = AVSpeechSynthesizer()
    @ObservationIgnored private var utteranceLines: [ObjectIdentifier: Int] = [:]
    @ObservationIgnored private var lastLine = 0

    override init() {
        super.init()
        synth.delegate = self
    }

    func play(lines: [String], from start: Int) {
        guard !lines.isEmpty else { return }
        synth.stopSpeaking(at: .immediate)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        utteranceLines = [:]
        lastLine = lines.count - 1
        hasStarted = true
        finished = false
        lineIndex = start
        wordRange = nil
        let voice = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode().hasPrefix("en") ? AVSpeechSynthesisVoice.currentLanguageCode() : "en-US")
        for i in start..<lines.count {
            let u = AVSpeechUtterance(string: lines[i])
            u.voice = voice
            u.rate = Float(Double(AVSpeechUtteranceDefaultSpeechRate) * (0.92 * speed))
            u.pitchMultiplier = 1.05
            u.postUtteranceDelay = 0.35
            utteranceLines[ObjectIdentifier(u)] = i
            synth.speak(u)
        }
        isPlaying = true
    }

    func toggle(lines: [String]) {
        if isPlaying {
            synth.pauseSpeaking(at: .word)
            isPlaying = false
        } else if synth.isPaused {
            synth.continueSpeaking()
            isPlaying = true
        } else {
            play(lines: lines, from: finished ? 0 : lineIndex)
        }
    }

    func setSpeed(_ s: Double, lines: [String]) {
        speed = s
        Haptics.shared.tick()
        if isPlaying || synth.isPaused { play(lines: lines, from: lineIndex) }
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
        isPlaying = false
        // Hand the session back to the sound effects (ambient, mixes with other audio).
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
    }

    // MARK: Delegate (delivered on the main thread)

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in
            guard let line = self.utteranceLines[id] else { return }
            self.lineIndex = line
            self.wordRange = characterRange
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in
            guard let line = self.utteranceLines[id] else { return }
            self.lineIndex = line
            self.wordRange = nil
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in
            guard let line = self.utteranceLines[id] else { return }
            self.wordRange = nil
            if line >= self.lastLine {
                self.isPlaying = false
                self.finished = true
                Haptics.shared.softTap()
            }
        }
    }
}
