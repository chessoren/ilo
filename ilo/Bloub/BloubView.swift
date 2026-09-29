import SwiftUI

/// What bloub is doing, on top of its facial expression.
enum BloubMode: Equatable, Sendable {
    /// Regular face with the current expression.
    case face
    /// Body splits into three pulsing dots — used while the AI is working.
    case thinking
    /// Eyes shut, floating "z"s.
    case sleeping
}

/// Resolved, drawable bloub pose (no idle motion applied yet).
private struct BloubPose {
    var radii: [Double]
    var cx: Double = 0
    var cy: Double = 0
    var gaze: BloubGaze
    var split: Double
    var eyes: (BloubEye, BloubEye)
    var eyeAlpha: Double = 1
    /// Side dots used by the thinking state: (x, radius, opacity).
    var dots: [(x: Double, r: Double, o: Double)] = [(-0.557, 0.001, 0), (0.532, 0.001, 0)]
    var zAlpha: Double = 0

    static func lerp(_ a: BloubPose, _ b: BloubPose, _ t: Double) -> BloubPose {
        func l(_ x: Double, _ y: Double) -> Double { x + (y - x) * t }
        var out = b
        out.radii = zip(a.radii, b.radii).map { l($0, $1) }
        out.cx = l(a.cx, b.cx)
        out.cy = l(a.cy, b.cy)
        out.gaze = .lerp(a.gaze, b.gaze, t)
        out.split = l(a.split, b.split)
        out.eyes = (.lerp(a.eyes.0, b.eyes.0, t), .lerp(a.eyes.1, b.eyes.1, t))
        out.eyeAlpha = l(a.eyeAlpha, b.eyeAlpha)
        out.dots = zip(a.dots, b.dots).map { (l($0.x, $1.x), l($0.r, $1.r), l($0.o, $1.o)) }
        out.zAlpha = l(a.zAlpha, b.zAlpha)
        return out
    }
}

/// Holds the transition state between poses. Reference type so the Canvas can read it every frame.
private final class BloubEngine {
    let epoch = Date.timeIntervalSinceReferenceDate - Double.random(in: 0...40)
    var target: (shape: BloubShape, expression: BloubExpression, mode: BloubMode) = (.circle, .neutral, .face)
    var from: BloubPose?
    var transitionStart: Double = 0
    var morphDuration: Double = 0.45
    var configured = false

    func now() -> Double { Date.timeIntervalSinceReferenceDate - epoch }

    func configure(shape: BloubShape, expression: BloubExpression, mode: BloubMode) {
        guard !configured else { return }
        configured = true
        target = (shape, expression, mode)
    }

    func transition(shape: BloubShape, expression: BloubExpression, mode: BloubMode) {
        let t = now()
        from = resolved(at: t)
        target = (shape, expression, mode)
        transitionStart = t
        morphDuration = mode == .thinking || target.mode == .thinking ? 0.4 : 0.45
    }

    /// Target pose for the current target at time t (thinking pulses over time).
    func targetPose(at t: Double) -> BloubPose {
        let face = target.expression.face
        var pose = BloubPose(radii: target.shape.radii, gaze: face.gaze, split: face.split, eyes: face.eyes)
        switch target.mode {
        case .face:
            break
        case .thinking:
            let dotR = 0.165, grow = 1.25
            func pulse(_ i: Double) -> Double {
                let n = (((t - i * 0.5) / 1.5).truncatingRemainder(dividingBy: 1) + 1).truncatingRemainder(dividingBy: 1)
                return BloubMotion.clamp((n < 0.5 ? 0.5 - 0.5 * cos(n * .pi * 2) : 0) * 2)
            }
            pose.radii = Array(repeating: dotR * (1 + (grow - 1) * pulse(1)), count: 64)
            pose.cx = -0.013
            pose.eyeAlpha = 0
            pose.dots = [(-0.557, dotR * (1 + (grow - 1) * pulse(0)), 0.55 + 0.45 * pulse(0)),
                         (0.532, dotR * (1 + (grow - 1) * pulse(2)), 0.55 + 0.45 * pulse(2))]
        case .sleeping:
            let sleepy = BloubExpression.sleepy.face
            pose.gaze = sleepy.gaze
            pose.split = sleepy.split
            pose.eyes = (BloubEye(w: 0.26, h: 0.06, tilt: 0, open: 1), BloubEye(w: 0.26, h: 0.06, tilt: 0, open: 1))
            pose.cy = 0.03
            pose.zAlpha = 1
        }
        return pose
    }

    func resolved(at t: Double) -> BloubPose {
        let goal = targetPose(at: t)
        guard let from else { return goal }
        let p = BloubMotion.clamp((t - transitionStart) / morphDuration)
        if p >= 1 { self.from = nil; return goal }
        return .lerp(from, goal, BloubMotion.easeOutQuint(p))
    }
}

/// The animated bloub avatar — ilo's mascot and every player's avatar.
struct BloubView: View {
    var shape: BloubShape = .circle
    var color: BloubColor = .ink
    var expression: BloubExpression = .neutral
    var mode: BloubMode = .face
    /// Optional point to look at, in unit coordinates (-1...1, y down).
    var lookAt: CGPoint? = nil
    /// Idle life (wander, blink, breathing). Turn off for tiny static avatars.
    var alive: Bool = true
    /// Override body colour (e.g. white bloub on dark surfaces).
    var tint: Color? = nil

    @State private var engine = BloubEngine()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 60, paused: !alive || reduceMotion)) { timeline in
            Canvas { gc, size in
                draw(&gc, size: size, date: timeline.date)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear { engine.configure(shape: shape, expression: expression, mode: mode) }
        .onChange(of: shape) { engine.transition(shape: shape, expression: expression, mode: mode) }
        .onChange(of: expression) { engine.transition(shape: shape, expression: expression, mode: mode) }
        .onChange(of: mode) { engine.transition(shape: shape, expression: expression, mode: mode) }
        .accessibilityHidden(true)
    }

    private func draw(_ gc: inout GraphicsContext, size: CGSize, date: Date) {
        let t = date.timeIntervalSinceReferenceDate - engine.epoch
        var pose = engine.resolved(at: t)
        let unit = min(size.width, size.height) * 100 / 316
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let live = alive && !reduceMotion

        // Idle motion (same frequencies as the original).
        let eyesVisible = pose.eyeAlpha > 0.01
        let wander = live && eyesVisible ? 1.0 : 0
        let dYaw = (BloubMotion.noise(t, 11.3, 0.4) * 5.5 + BloubMotion.noise(t, 3.7, 2.1) * 1.6) * wander
        let dPitch = (BloubMotion.noise(t, 9.1, 1.3) * 4.2 + BloubMotion.noise(t, 4.3, 0.7) * 1.3) * wander
        let dRoll = BloubMotion.noise(t, 13.7, 3.2) * 2.2 * wander
        let lid = live && eyesVisible && engine.target.mode == .face ? BloubMotion.lid(at: t) : 1
        let driftX = live ? BloubMotion.noise(t, 7.9, 1.9) * 0.006 : 0
        let driftY = live ? BloubMotion.noise(t, 5.3, 0.3) * 0.007 : 0
        let breath = live ? 1 + sin(t / 3.4 * .pi * 2) * 0.005 : 1

        if let lookAt, engine.target.mode == .face {
            let mix = 0.75
            pose.gaze.yaw += (Double(lookAt.x) * 34 - pose.gaze.yaw) * mix
            pose.gaze.pitch += (-Double(lookAt.y) * 28 - pose.gaze.pitch) * mix
        }
        let gaze = BloubGaze(yaw: pose.gaze.yaw + dYaw, pitch: pose.gaze.pitch + dPitch, roll: pose.gaze.roll + dRoll)

        let bodyColor = tint ?? color.color
        let offX = pose.cx + driftX, offY = pose.cy + driftY

        // Silhouette: 64 polar samples smoothed with Catmull-Rom (tension 1/6).
        var points: [CGPoint] = []
        points.reserveCapacity(64)
        for i in 0..<64 {
            let a = Double(i) / 64 * .pi * 2
            let r = pose.radii[i]
            points.append(CGPoint(x: center.x + (r * cos(a) + offX) * unit,
                                  y: center.y + (r * sin(a) * breath + offY) * unit))
        }
        gc.fill(Self.smoothPath(points), with: .color(bodyColor))

        // Thinking dots.
        for dot in pose.dots where dot.o > 0.01 && dot.r > 0.0005 {
            let r = dot.r * unit
            let c = CGPoint(x: center.x + (dot.x + driftX) * unit, y: center.y + (pose.cy + driftY) * unit)
            gc.opacity = dot.o
            gc.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)), with: .color(bodyColor))
            gc.opacity = 1
        }

        // Eyes projected on a virtual sphere.
        if pose.eyeAlpha > 0.01 {
            let eyeColor = tint == nil ? color.eyeColor : Color.white
            let projections = Self.project(gaze: gaze, radius: unit, split: pose.split)
            let eyes = [pose.eyes.0, pose.eyes.1]
            for (index, proj) in projections.enumerated() where proj.depth > 0.02 {
                let eye = eyes[index]
                let s = Self.radius(at: atan2(proj.y, proj.x), radii: pose.radii)
                let tilt = eye.tilt * .pi / 180
                let l = cos(tilt), u = sin(tilt)
                let d = proj.a * l + proj.c * u
                let f = proj.b * l + proj.d * u
                let p = -proj.a * u + proj.c * l
                let m = -proj.b * u + proj.d * l
                let v = 0.06 + 0.94 * BloubMotion.clamp(min(lid, eye.open))
                let w = max(eye.w * unit, 0.01), h = max(eye.h * unit, 0.01)
                let rect = CGRect(x: -w / 2, y: -h / 2, width: w, height: h)
                let pill = Path(roundedRect: rect, cornerRadius: min(w, h) / 2)
                let transform = CGAffineTransform(a: d, b: f * v, c: p, d: m * v,
                                                  tx: center.x + proj.x * s + offX * unit,
                                                  ty: center.y + proj.y * s + offY * unit)
                gc.opacity = pose.eyeAlpha * BloubMotion.clamp(proj.depth / 0.12)
                gc.fill(pill.applying(transform), with: .color(eyeColor))
                gc.opacity = 1
            }
        }

        // Sleeping z's.
        if pose.zAlpha > 0.01 {
            for i in 0..<3 {
                let phase = ((t * 0.45) + Double(i) / 3).truncatingRemainder(dividingBy: 1)
                let x = center.x + unit * (0.7 + phase * 0.35 + sin(phase * 6) * 0.05)
                let y = center.y - unit * (0.55 + phase * 0.7)
                let fade = sin(phase * .pi)
                gc.opacity = pose.zAlpha * fade
                let text = Text("z").font(.system(size: unit * (0.22 + phase * 0.18), weight: .heavy, design: .rounded))
                    .foregroundStyle(bodyColor)
                gc.draw(text, at: CGPoint(x: x, y: y))
                gc.opacity = 1
            }
        }
    }

    // MARK: - Geometry

    private struct EyeProjection {
        var x: Double, y: Double, a: Double, b: Double, c: Double, d: Double, depth: Double
    }

    private static func rotate(_ e: [Double], _ t: [Double], _ angle: Double) -> ([Double], [Double]) {
        let r = cos(angle), i = sin(angle)
        return ([e[0] * r + t[0] * i, e[1] * r + t[1] * i, e[2] * r + t[2] * i],
                [t[0] * r - e[0] * i, t[1] * r - e[1] * i, t[2] * r - e[2] * i])
    }

    private static func project(gaze: BloubGaze, radius: Double, split: Double) -> [EyeProjection] {
        let rad = { (deg: Double) in deg * .pi / 180 }
        var r: [Double] = [0, 0, 1], i: [Double] = [1, 0, 0], a: [Double] = [0, 1, 0]
        (r, i) = rotate(r, i, rad(gaze.yaw))
        (a, r) = rotate(a, r, rad(gaze.pitch))
        (i, a) = rotate(i, a, rad(gaze.roll))
        return [-1.0, 1.0].map { side in
            let (o, s) = rotate(r, i, rad(split * side))
            return EyeProjection(x: o[0] * radius, y: o[1] * radius, a: s[0], b: s[1], c: a[0], d: a[1], depth: o[2])
        }
    }

    private static func radius(at angle: Double, radii: [Double]) -> Double {
        let n = Double(radii.count)
        let turn = angle / (.pi * 2)
        let pos = ((turn.truncatingRemainder(dividingBy: 1)) + 1).truncatingRemainder(dividingBy: 1) * n
        let i = Int(pos)
        let a = radii[i % radii.count], b = radii[(i + 1) % radii.count]
        return a + (b - a) * (pos - Double(i))
    }

    private static func smoothPath(_ pts: [CGPoint], tension: Double = 1.0 / 6) -> Path {
        var path = Path()
        let n = pts.count
        guard n > 2 else { return path }
        path.move(to: pts[0])
        for i in 0..<n {
            let p0 = pts[(i - 1 + n) % n], p1 = pts[i], p2 = pts[(i + 1) % n], p3 = pts[(i + 2) % n]
            let c1 = CGPoint(x: p1.x + (p2.x - p0.x) * tension, y: p1.y + (p2.y - p0.y) * tension)
            let c2 = CGPoint(x: p2.x - (p3.x - p1.x) * tension, y: p2.y - (p3.y - p1.y) * tension)
            path.addCurve(to: p2, control1: c1, control2: c2)
        }
        path.closeSubpath()
        return path
    }
}

#Preview {
    VStack {
        BloubView(expression: .happy).frame(width: 200)
        HStack {
            BloubView(shape: .cloud, color: .blue, expression: .proud)
            BloubView(shape: .squircle, color: .violet, mode: .thinking)
            BloubView(shape: .droplet, color: .orange, mode: .sleeping)
        }
    }
    .padding()
}
