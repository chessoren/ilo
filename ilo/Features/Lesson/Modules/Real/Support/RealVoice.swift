import AVFoundation
import Speech
import SwiftUI

// MARK: - Audio session

/// Switches the shared audio session between ilo's ambient sound effects and voice (record + speak).
@MainActor
enum RealAudioSession {
    private static var voiceUsers = 0

    static func beginVoice() {
        voiceUsers += 1
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers, .allowBluetoothHFP])
        try? session.setActive(true, options: [])
    }

    static func endVoice() {
        voiceUsers = max(0, voiceUsers - 1)
        guard voiceUsers == 0 else { return }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, options: [.mixWithOthers])
        try? session.setActive(true, options: [])
    }
}

// MARK: - Voice input (speech recognition)

/// Live dictation: SFSpeechRecognizer + AVAudioEngine, with a mic level and a rolling waveform.
@Observable
@MainActor
final class RealVoiceInput {
    private(set) var isListening = false
    private(set) var transcript = ""
    /// Smoothed mic level 0...1.
    private(set) var level: CGFloat = 0
    /// Rolling levels for the waveform.
    private(set) var levels: [CGFloat] = Array(repeating: 0.08, count: 22)
    /// Human-readable reason voice isn't available (permission denied, no mic, …).
    private(set) var problem: String?
    /// When the transcript last changed (for silence detection).
    private(set) var lastSpeech = Date()

    private var engine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) ?? SFSpeechRecognizer()
    private var generation = 0

    /// Text that existed before this dictation started (dictation appends to it).
    var prefix = ""

    var permissionDenied: Bool {
        SFSpeechRecognizer.authorizationStatus() == .denied || AVAudioApplication.shared.recordPermission == .denied
    }

    @discardableResult
    func start(prefix: String = "") async -> Bool {
        guard !isListening else { return true }
        problem = nil
        self.prefix = prefix

        guard await Self.requestSpeechAuth() else {
            problem = "Speech recognition is off. Enable it in Settings, or just type."
            return false
        }
        guard await AVAudioApplication.requestRecordPermission() else {
            problem = "Microphone access is off. Enable it in Settings, or just type."
            return false
        }
        guard let recognizer, recognizer.isAvailable else {
            problem = "Voice isn't available right now — typing works too."
            return false
        }

        RealAudioSession.beginVoice()
        let engine = AVAudioEngine()
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.channelCount > 0, format.sampleRate > 0 else {
            RealAudioSession.endVoice()
            problem = "No microphone found — typing works too."
            return false
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition { request.requiresOnDeviceRecognition = false }
        request.addsPunctuation = true

        generation += 1
        let gen = generation
        Self.installTap(on: input, format: format, request: request) { [weak self] rms in
            Task { @MainActor in self?.push(level: rms, gen: gen) }
        }

        engine.prepare()
        do {
            try engine.start()
        } catch {
            input.removeTap(onBus: 0)
            RealAudioSession.endVoice()
            problem = "Couldn't start the microphone — typing works too."
            return false
        }

        self.engine = engine
        self.request = request
        transcript = ""
        lastSpeech = Date()
        isListening = true
        task = Self.recognize(with: recognizer, request: request) { [weak self] text, isFinal, failed in
            Task { @MainActor in self?.receive(text: text, isFinal: isFinal, failed: failed, gen: gen) }
        }
        return true
    }

    func stop() {
        guard isListening || engine != nil else { return }
        generation += 1
        engine?.inputNode.removeTap(onBus: 0)
        engine?.stop()
        request?.endAudio()
        task?.finish()
        engine = nil
        request = nil
        task = nil
        isListening = false
        level = 0
        levels = Array(repeating: 0.08, count: levels.count)
        RealAudioSession.endVoice()
    }

    /// Full text = prefix + live transcript.
    var fullText: String {
        let p = prefix.realTrimmed
        if p.isEmpty { return transcript }
        if transcript.isEmpty { return prefix }
        return p + " " + transcript
    }

    private func push(level rms: Float, gen: Int) {
        guard gen == generation, isListening else { return }
        let db = 20 * log10(max(rms, 0.000_01))
        let norm = CGFloat(max(0, min(1, (db + 50) / 42)))
        level = level * 0.55 + norm * 0.45
        levels.removeFirst()
        levels.append(max(0.08, level))
    }

    private func receive(text: String?, isFinal: Bool, failed: Bool, gen: Int) {
        guard gen == generation else { return }
        if let text, text != transcript {
            transcript = text
            lastSpeech = Date()
        }
        if failed && transcript.isEmpty {
            stop()
            problem = "I couldn't hear that — try again or type."
        } else if isFinal || failed {
            stop()
        }
    }

    // MARK: Nonisolated helpers (callbacks run on audio / recognition queues)

    nonisolated private static func requestSpeechAuth() async -> Bool {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized: return true
        case .denied, .restricted: return false
        default:
            return await withCheckedContinuation { cont in
                SFSpeechRecognizer.requestAuthorization { status in cont.resume(returning: status == .authorized) }
            }
        }
    }

    nonisolated private static func installTap(on input: AVAudioInputNode, format: AVAudioFormat,
                                               request: SFSpeechAudioBufferRecognitionRequest,
                                               onLevel: @escaping @Sendable (Float) -> Void) {
        nonisolated(unsafe) let request = request
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
            guard let data = buffer.floatChannelData?[0] else { return }
            let n = Int(buffer.frameLength)
            guard n > 0 else { return }
            var sum: Float = 0
            for i in stride(from: 0, to: n, by: 2) { sum += data[i] * data[i] }
            onLevel(sqrt(sum / Float(max(1, n / 2))))
        }
    }

    nonisolated private static func recognize(with recognizer: SFSpeechRecognizer,
                                              request: SFSpeechAudioBufferRecognitionRequest,
                                              onResult: @escaping @Sendable (String?, Bool, Bool) -> Void) -> SFSpeechRecognitionTask {
        recognizer.recognitionTask(with: request) { result, error in
            onResult(result?.bestTranscription.formattedString, result?.isFinal ?? false, error != nil)
        }
    }
}

// MARK: - Voice output (text to speech)

/// ilo's voice. Publishes a lively `pulse` on every word so orbs can react to speech.
@Observable
@MainActor
final class RealVoiceOutput: NSObject, AVSpeechSynthesizerDelegate {
    private(set) var isSpeaking = false
    /// Spikes to 1 on each spoken word, decays in the view.
    private(set) var wordTick = 0
    private(set) var spokenRange: NSRange?
    private(set) var currentText = ""

    private let synth = AVSpeechSynthesizer()
    private var continuation: CheckedContinuation<Void, Never>?
    private var currentID: ObjectIdentifier?
    @ObservationIgnored private var cachedVoice: AVSpeechSynthesisVoice?

    override init() {
        super.init()
        synth.delegate = self
    }

    /// Speaks and returns when done (or stopped).
    func speak(_ text: String) async {
        stop()
        currentText = text
        let utterance = AVSpeechUtterance(string: text)
        if cachedVoice == nil { cachedVoice = RealVoiceOutput.bestVoice() }
        utterance.voice = cachedVoice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 1.02
        utterance.pitchMultiplier = 1.12
        utterance.postUtteranceDelay = 0.1
        isSpeaking = true
        let id = ObjectIdentifier(utterance)
        currentID = id
        // Safety net: some devices/simulators never deliver didFinish — don't let a call hang.
        let words = Double(text.split(separator: " ").count)
        let timeout = 2.5 + words * 0.5
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(timeout))
            guard let self, self.currentID == id else { return }
            self.stop()
        }
        await withCheckedContinuation { cont in
            continuation = cont
            synth.speak(utterance)
        }
    }

    func stop() {
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
        finish()
    }

    private func finish(_ id: ObjectIdentifier? = nil) {
        if let id, id != currentID { return }
        currentID = nil
        isSpeaking = false
        spokenRange = nil
        let c = continuation
        continuation = nil
        c?.resume()
    }

    private static func bestVoice() -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("en") }
        let preferred = ["Samantha", "Ava", "Zoe", "Nicky", "Allison"]
        let ranked = voices.sorted { a, b in
            if a.quality != b.quality { return a.quality.rawValue > b.quality.rawValue }
            let ai = preferred.firstIndex(of: a.name) ?? 99, bi = preferred.firstIndex(of: b.name) ?? 99
            if ai != bi { return ai < bi }
            return a.language == "en-US" && b.language != "en-US"
        }
        return ranked.first ?? AVSpeechSynthesisVoice(language: "en-US")
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in
            guard id == self.currentID else { return }
            self.spokenRange = characterRange
            self.wordTick += 1
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.finish(id) }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.finish(id) }
    }
}
