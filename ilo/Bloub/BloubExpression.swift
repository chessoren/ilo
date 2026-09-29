import Foundation

/// A single eye: pill of width/height (relative to body radius), tilt in degrees, lid openness.
struct BloubEye: Equatable, Sendable {
    var w: Double
    var h: Double
    var tilt: Double = 0
    var open: Double = 1

    static func lerp(_ a: BloubEye, _ b: BloubEye, _ t: Double) -> BloubEye {
        BloubEye(w: a.w + (b.w - a.w) * t,
                 h: a.h + (b.h - a.h) * t,
                 tilt: a.tilt + (b.tilt - a.tilt) * t,
                 open: a.open + (b.open - a.open) * t)
    }
}

struct BloubGaze: Equatable, Sendable {
    var yaw: Double
    var pitch: Double
    var roll: Double

    static func lerp(_ a: BloubGaze, _ b: BloubGaze, _ t: Double) -> BloubGaze {
        BloubGaze(yaw: a.yaw + (b.yaw - a.yaw) * t,
                  pitch: a.pitch + (b.pitch - a.pitch) * t,
                  roll: a.roll + (b.roll - a.roll) * t)
    }
}

/// The 16 bloub expressions, with the exact face parameters of bloub.vercel.app.
enum BloubExpression: String, CaseIterable, Codable, Sendable, Identifiable {
    case neutral, attentive, surprised, excited, happy, laughing, angry, sad
    case scared, suspicious, confused, curious, proud, shy, unimpressed, sleepy

    var id: String { rawValue }

    struct Face: Sendable {
        var gaze: BloubGaze
        var split: Double
        var eyes: (BloubEye, BloubEye)
    }

    private static func pair(_ w: Double, _ h: Double, _ tilt: Double = 0, _ open: Double = 1) -> (BloubEye, BloubEye) {
        (BloubEye(w: w, h: h, tilt: tilt, open: open), BloubEye(w: w, h: h, tilt: -tilt, open: open))
    }

    var face: Face {
        switch self {
        case .neutral: Face(gaze: .init(yaw: 28.49, pitch: 28.62, roll: -13), split: 15.46, eyes: Self.pair(0.186, 0.412))
        case .attentive: Face(gaze: .init(yaw: 4, pitch: 5, roll: -4), split: 16, eyes: Self.pair(0.21, 0.44))
        case .surprised: Face(gaze: .init(yaw: 3, pitch: -3, roll: 0), split: 19, eyes: Self.pair(0.45, 0.47))
        case .excited: Face(gaze: .init(yaw: 6, pitch: -14, roll: 0), split: 19.5, eyes: Self.pair(0.4, 0.56, -10))
        case .happy: Face(gaze: .init(yaw: 5, pitch: 9, roll: 0), split: 17, eyes: Self.pair(0.27, 0.17, 14))
        case .laughing: Face(gaze: .init(yaw: 4, pitch: 14, roll: 0), split: 18, eyes: Self.pair(0.34, 0.13, 20))
        case .angry: Face(gaze: .init(yaw: 3, pitch: 7, roll: 0), split: 17, eyes: Self.pair(0.34, 0.15, 30))
        case .sad: Face(gaze: .init(yaw: 3, pitch: -13, roll: 0), split: 16, eyes: Self.pair(0.22, 0.4, -28))
        case .scared: Face(gaze: .init(yaw: 2, pitch: -20, roll: 0), split: 20.5, eyes: Self.pair(0.4, 0.6))
        case .suspicious: Face(gaze: .init(yaw: 12, pitch: 6, roll: -6), split: 16,
                               eyes: (BloubEye(w: 0.21, h: 0.4), BloubEye(w: 0.22, h: 0.15)))
        case .confused: Face(gaze: .init(yaw: -14, pitch: 3, roll: 8), split: 16.5,
                             eyes: (BloubEye(w: 0.2, h: 0.44, tilt: -18), BloubEye(w: 0.28, h: 0.17, tilt: 14)))
        case .curious: Face(gaze: .init(yaw: 16, pitch: -9, roll: -15), split: 16.5,
                            eyes: (BloubEye(w: 0.24, h: 0.46, tilt: -8), BloubEye(w: 0.2, h: 0.38, tilt: -8)))
        case .proud: Face(gaze: .init(yaw: 5, pitch: 17, roll: 0), split: 17, eyes: Self.pair(0.3, 0.15, 18))
        case .shy: Face(gaze: .init(yaw: -19, pitch: -14, roll: -7), split: 14, eyes: Self.pair(0.17, 0.3))
        case .unimpressed: Face(gaze: .init(yaw: -22, pitch: 2, roll: 0), split: 16, eyes: Self.pair(0.3, 0.12))
        case .sleepy: Face(gaze: .init(yaw: 6, pitch: -9, roll: -3), split: 16, eyes: Self.pair(0.2, 0.42, 0, 0.42))
        }
    }
}

/// Deterministic PRNG identical to bloub's (mulberry32) so blinks feel the same.
struct Mulberry32 {
    private var state: UInt32
    init(seed: UInt32) { state = seed }
    mutating func next() -> Double {
        state = state &+ 0x6D2B79F5
        var e = (state ^ (state >> 15)) &* (state | 1)
        e = (e &+ ((e ^ (e >> 7)) &* (e | 61))) ^ e
        return Double(e ^ (e >> 14)) / 4_294_967_296
    }
}

enum BloubMotion {
    /// Smooth pseudo-noise used for the idle "wander" of the gaze.
    static func noise(_ t: Double, _ period: Double, _ phase: Double = 0) -> Double {
        let r = t / period * .pi * 2
        return 0.55 * sin(r + phase) + 0.3 * sin(2 * r + phase * 1.7 + 1.1) + 0.15 * sin(3 * r + phase * 2.3 + 2.4)
    }

    /// Blink timeline (seconds), same generator as the original.
    static let blinkTimes: [Double] = {
        var rng = Mulberry32(seed: 24301)
        var times: [Double] = []
        var t = 1.4
        while t < 900 {
            times.append(t)
            t += 1.9 + rng.next() * 2.7
            if rng.next() < 0.18 {
                times.append(t)
                t += 0.24
            }
        }
        return times
    }()

    /// Lid openness 0...1 at time t (1 = open).
    static func lid(at time: Double) -> Double {
        let t = time.truncatingRemainder(dividingBy: 900)
        for start in blinkTimes {
            if t < start { break }
            let r = (t - start) / 0.18
            if r >= 0 && r <= 1 { return r < 0.45 ? 1 - r / 0.45 : (r - 0.45) / 0.55 }
        }
        return 1
    }

    static func clamp(_ v: Double, _ lo: Double = 0, _ hi: Double = 1) -> Double { min(max(v, lo), hi) }
    static func easeOutQuint(_ t: Double) -> Double { 1 - pow(1 - t, 5) }
    static func easeOutCubic(_ t: Double) -> Double { 1 - pow(1 - t, 3) }
}
