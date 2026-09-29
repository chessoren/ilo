import CoreHaptics
import UIKit

/// Custom Core Haptics patterns — every meaningful moment in ilo has its own feel.
@MainActor
final class Haptics {
    static let shared = Haptics()

    private var engine: CHHapticEngine?
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let soft = UIImpactFeedbackGenerator(style: .soft)
    private let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private let selection = UISelectionFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()

    var enabled: Bool {
        get { UserDefaults.standard.object(forKey: "haptics.enabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "haptics.enabled") }
    }

    private init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            let engine = try CHHapticEngine()
            engine.isAutoShutdownEnabled = true
            engine.resetHandler = { [weak engine] in try? engine?.start() }
            try engine.start()
            self.engine = engine
        } catch {
            engine = nil
        }
    }

    // MARK: Simple taps

    func tap() { guard enabled else { return }; light.impactOccurred(intensity: 0.7) }
    func softTap() { guard enabled else { return }; soft.impactOccurred() }
    func press() { guard enabled else { return }; rigid.impactOccurred(intensity: 0.8) }
    func thud() { guard enabled else { return }; heavy.impactOccurred() }
    func tick() { guard enabled else { return }; selection.selectionChanged() }
    func warning() { guard enabled else { return }; notification.notificationOccurred(.warning) }

    // MARK: Signature patterns

    /// Correct answer: two quick rising taps.
    func correct() {
        play([event(0, 0.55, 0.5), event(0.09, 1, 0.8)]) { self.notification.notificationOccurred(.success) }
    }

    /// Wrong answer: a low buzzy double knock.
    func wrong() {
        play([event(0, 0.9, 0.1), event(0.12, 0.7, 0.05), continuous(0.02, 0.2, 0.4, 0.05)]) {
            self.notification.notificationOccurred(.error)
        }
    }

    /// Lesson complete: rolling crescendo ending on a big hit.
    func celebrate() {
        var events: [CHHapticEvent] = (0..<8).map { i in
            let t = Double(i) * 0.07
            return event(t, 0.3 + Double(i) * 0.08, 0.3 + Double(i) * 0.08)
        }
        events.append(event(0.62, 1, 1))
        events.append(continuous(0.62, 0.35, 0.6, 0.5))
        play(events) { self.notification.notificationOccurred(.success) }
    }

    /// Streak flame ignition: crackle then warm rumble.
    func ignite() {
        var events: [CHHapticEvent] = (0..<6).map { i in event(Double(i) * 0.045, Double.random(in: 0.3...0.7), Double.random(in: 0.6...1)) }
        events.append(continuous(0.28, 0.7, 0.25, 0.7))
        events.append(event(1.0, 1, 0.5))
        play(events) { self.heavy.impactOccurred() }
    }

    /// Heartbeat — used on the paywall and commitment screen.
    func heartbeat() {
        play([event(0, 0.8, 0.2), event(0.14, 0.5, 0.15)]) { self.soft.impactOccurred() }
    }

    /// A long press building up, intensity 0...1 (commitment hold).
    func charge(_ progress: Double) {
        guard enabled else { return }
        rigid.impactOccurred(intensity: 0.25 + 0.75 * progress)
    }

    /// Metronome beat (accent on the first beat of the bar).
    func beat(accent: Bool) {
        play([event(0, accent ? 1 : 0.55, accent ? 0.9 : 0.5)]) { accent ? self.rigid.impactOccurred() : self.light.impactOccurred() }
    }

    /// League promotion / level up.
    func levelUp() {
        let events = [event(0, 0.5, 0.4), event(0.12, 0.7, 0.6), event(0.24, 1, 0.9), continuous(0.24, 0.6, 0.5, 0.6)]
        play(events) { self.notification.notificationOccurred(.success) }
    }

    // MARK: Engine helpers

    private func event(_ time: TimeInterval, _ intensity: Double, _ sharpness: Double) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticTransient,
                      parameters: [.init(parameterID: .hapticIntensity, value: Float(intensity)),
                                   .init(parameterID: .hapticSharpness, value: Float(sharpness))],
                      relativeTime: time)
    }

    private func continuous(_ time: TimeInterval, _ intensity: Double, _ sharpness: Double, _ duration: TimeInterval) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticContinuous,
                      parameters: [.init(parameterID: .hapticIntensity, value: Float(intensity)),
                                   .init(parameterID: .hapticSharpness, value: Float(sharpness))],
                      relativeTime: time, duration: duration)
    }

    private func play(_ events: [CHHapticEvent], fallback: () -> Void) {
        guard enabled else { return }
        guard let engine else { fallback(); return }
        do {
            try engine.start()
            let player = try engine.makePlayer(with: CHHapticPattern(events: events, parameters: []))
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            fallback()
        }
    }
}
