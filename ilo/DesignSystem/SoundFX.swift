import AVFoundation

/// Tiny synthesised sound kit — no audio assets, every sound is generated at launch.
@MainActor
final class SoundFX {
    static let shared = SoundFX()

    enum Effect: CaseIterable {
        case tap, pop, correct, wrong, complete, coin, streak, whoosh, tick, levelUp, bubble
    }

    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private var buffers: [Effect: AVAudioPCMBuffer] = [:]
    private var nextPlayer = 0
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!

    var enabled: Bool {
        get { UserDefaults.standard.object(forKey: "sound.enabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "sound.enabled") }
    }

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        for _ in 0..<6 {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            players.append(node)
        }
        engine.mainMixerNode.outputVolume = 0.55
        for effect in Effect.allCases { buffers[effect] = render(effect) }
        try? engine.start()
    }

    func play(_ effect: Effect) {
        guard enabled, let buffer = buffers[effect] else { return }
        if !engine.isRunning { try? engine.start() }
        let node = players[nextPlayer]
        nextPlayer = (nextPlayer + 1) % players.count
        node.stop()
        node.scheduleBuffer(buffer, at: nil)
        node.play()
    }

    // MARK: Synthesis

    private struct Note {
        var freq: Double
        var start: Double
        var duration: Double
        var gain: Double = 0.5
        var wave: Wave = .sine
        var glide: Double = 0 // Hz per second
    }

    private enum Wave { case sine, triangle, square, noise }

    private func render(_ effect: Effect) -> AVAudioPCMBuffer {
        let notes: [Note]
        switch effect {
        case .tap:
            notes = [Note(freq: 1400, start: 0, duration: 0.03, gain: 0.25, wave: .triangle)]
        case .pop:
            notes = [Note(freq: 520, start: 0, duration: 0.09, gain: 0.45, wave: .sine, glide: 3800)]
        case .bubble:
            notes = [Note(freq: 380, start: 0, duration: 0.12, gain: 0.4, wave: .sine, glide: 2600)]
        case .correct:
            notes = [Note(freq: 1046.5, start: 0, duration: 0.14, gain: 0.45, wave: .triangle),
                     Note(freq: 1568, start: 0.085, duration: 0.3, gain: 0.45, wave: .triangle)]
        case .wrong:
            notes = [Note(freq: 196, start: 0, duration: 0.16, gain: 0.35, wave: .square),
                     Note(freq: 164.8, start: 0.13, duration: 0.26, gain: 0.35, wave: .square)]
        case .complete:
            let chord = [523.25, 659.25, 783.99, 1046.5, 1318.5]
            notes = chord.enumerated().map { Note(freq: $1, start: Double($0) * 0.075, duration: 0.55, gain: 0.32, wave: .triangle) }
                + [Note(freq: 2093, start: 0.4, duration: 0.6, gain: 0.18, wave: .sine)]
        case .coin:
            notes = [Note(freq: 1318.5, start: 0, duration: 0.07, gain: 0.35, wave: .square),
                     Note(freq: 1975.5, start: 0.06, duration: 0.25, gain: 0.3, wave: .square)]
        case .streak:
            notes = [Note(freq: 220, start: 0, duration: 0.5, gain: 0.3, wave: .noise),
                     Note(freq: 440, start: 0.15, duration: 0.5, gain: 0.3, wave: .triangle, glide: 400),
                     Note(freq: 880, start: 0.35, duration: 0.6, gain: 0.3, wave: .triangle)]
        case .whoosh:
            notes = [Note(freq: 0, start: 0, duration: 0.35, gain: 0.25, wave: .noise)]
        case .tick:
            notes = [Note(freq: 2400, start: 0, duration: 0.015, gain: 0.2, wave: .square)]
        case .levelUp:
            let run = [392.0, 523.25, 659.25, 783.99, 1046.5]
            notes = run.enumerated().map { Note(freq: $1, start: Double($0) * 0.06, duration: 0.2, gain: 0.3, wave: .square) }
                + [Note(freq: 1046.5, start: 0.32, duration: 0.7, gain: 0.3, wave: .triangle),
                   Note(freq: 1318.5, start: 0.32, duration: 0.7, gain: 0.25, wave: .triangle)]
        }

        let sampleRate = format.sampleRate
        let total = (notes.map { $0.start + $0.duration }.max() ?? 0.1) + 0.05
        let frames = AVAudioFrameCount(total * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
        buffer.frameLength = frames
        let data = buffer.floatChannelData![0]
        for i in 0..<Int(frames) { data[i] = 0 }

        for note in notes {
            let startFrame = Int(note.start * sampleRate)
            let count = Int(note.duration * sampleRate)
            var phase = 0.0
            var lowpass = 0.0
            for n in 0..<count {
                let idx = startFrame + n
                guard idx < Int(frames) else { break }
                let t = Double(n) / sampleRate
                let freq = note.freq + note.glide * t
                phase += freq / sampleRate
                let x = phase.truncatingRemainder(dividingBy: 1)
                var sample: Double
                switch note.wave {
                case .sine: sample = sin(2 * .pi * x)
                case .triangle: sample = 4 * abs(x - 0.5) - 1
                case .square: sample = (x < 0.5 ? 1 : -1) * 0.5
                case .noise:
                    lowpass += (Double.random(in: -1...1) - lowpass) * (effect == .whoosh ? 0.08 + 0.3 * t / note.duration : 0.2)
                    sample = lowpass * 2
                }
                // Fast attack, exponential decay envelope.
                let attack = min(1, t / 0.004)
                let release = exp(-4.5 * t / note.duration)
                let tail = min(1, (note.duration - t) / 0.01)
                data[idx] += Float(sample * note.gain * attack * release * tail)
            }
        }
        return buffer
    }
}
