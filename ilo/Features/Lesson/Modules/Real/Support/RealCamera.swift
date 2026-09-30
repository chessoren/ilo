import AVFoundation
import SwiftUI
import UIKit
import Vision

// MARK: - Camera feed

/// Front-camera capture session. Frames are delivered on a private queue.
final class RealCameraFeed: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "app.ilo.camera", qos: .userInitiated)
    private var configured = false
    private var wantsFrames = false
    /// Called on the camera queue for every frame (portrait, mirrored).
    var onFrame: (@Sendable (CVPixelBuffer) -> Void)?

    static var hasFrontCamera: Bool {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) != nil
    }

    static func requestAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return true
        case .notDetermined: return await AVCaptureDevice.requestAccess(for: .video)
        default: return false
        }
    }

    /// Starts the session. `frames` adds a video data output for Vision.
    func start(frames: Bool) {
        queue.async { [self] in
            if !configured { configure(frames: frames) }
            if !session.isRunning { session.startRunning() }
        }
    }

    func stop() {
        queue.async { [self] in
            if session.isRunning { session.stopRunning() }
        }
    }

    private func configure(frames: Bool) {
        configured = true
        wantsFrames = frames
        session.beginConfiguration()
        session.sessionPreset = frames ? .hd1280x720 : .high
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)
        if frames {
            let output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
            output.setSampleBufferDelegate(self, queue: queue)
            if session.canAddOutput(output) {
                session.addOutput(output)
                if let connection = output.connection(with: .video) {
                    if connection.isVideoRotationAngleSupported(90) { connection.videoRotationAngle = 90 }
                    if connection.isVideoMirroringSupported {
                        connection.automaticallyAdjustsVideoMirroring = false
                        connection.isVideoMirrored = true
                    }
                }
            }
        }
        session.commitConfiguration()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixels = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        onFrame?(pixels)
    }
}

/// Live camera preview layer.
struct RealCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.backgroundColor = .black
        if let connection = view.previewLayer.connection, connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
        return view
    }

    func updateUIView(_ view: PreviewView, context: Context) {
        if let connection = view.previewLayer.connection, connection.isVideoRotationAngleSupported(90), connection.videoRotationAngle != 90 {
            connection.videoRotationAngle = 90
        }
    }
}

// MARK: - Pose

/// Joint names we use, as raw strings (Sendable) — top-left normalized coordinates.
enum RealJoint {
    static let names: [VNHumanBodyPoseObservation.JointName] = [
        .nose, .neck, .leftShoulder, .rightShoulder, .leftElbow, .rightElbow, .leftWrist, .rightWrist,
        .root, .leftHip, .rightHip, .leftKnee, .rightKnee, .leftAnkle, .rightAnkle,
    ]

    static func key(_ j: VNHumanBodyPoseObservation.JointName) -> String { j.rawValue.rawValue }

    static let bones: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        (.nose, .neck), (.neck, .leftShoulder), (.neck, .rightShoulder),
        (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist), (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
        (.neck, .root), (.root, .leftHip), (.root, .rightHip),
        (.leftHip, .leftKnee), (.leftKnee, .leftAnkle), (.rightHip, .rightKnee), (.rightKnee, .rightAnkle),
    ]

    /// Runs body-pose detection on a frame (call off the main thread).
    static func detect(in pixels: CVPixelBuffer) -> [String: CGPoint] {
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixels, orientation: .up, options: [:])
        guard (try? handler.perform([request])) != nil,
              let observation = request.results?.first,
              let points = try? observation.recognizedPoints(.all) else { return [:] }
        var out: [String: CGPoint] = [:]
        for name in names {
            if let p = points[name], p.confidence > 0.3 {
                out[key(name)] = CGPoint(x: p.location.x, y: 1 - p.location.y)
            }
        }
        return out
    }
}

/// What kind of movement a move name describes.
enum RealMoveKind {
    case squat, arms, steps

    init(move: String) {
        let m = move.lowercased()
        if ["arm", "raise", "press", "curl", "wave", "jack", "punch", "stretch", "shoulder", "clap", "reach"].contains(where: m.contains) {
            self = .arms
        } else if ["step", "dance", "salsa", "march", "walk", "shuffle", "basic", "cha", "bachata", "tap", "sway"].contains(where: m.contains) {
            self = .steps
        } else {
            self = .squat
        }
    }
}

/// Counts reps from a 1-D signal with an adaptive envelope and hysteresis.
struct RealRepCounter {
    private var smoothed: Double?
    private var lo = 1.0
    private var hi = 0.0
    private var armed = false
    private var lastRep = Date.distantPast

    mutating func feed(_ value: Double) -> Bool {
        let s = smoothed.map { $0 * 0.55 + value * 0.45 } ?? value
        smoothed = s
        hi = max(s, hi - 0.0025)
        lo = min(s, lo + 0.0025)
        let amp = hi - lo
        guard amp > 0.05 else { return false }
        let p = (s - lo) / amp
        if !armed && p > 0.72 { armed = true }
        if armed && p < 0.28 {
            armed = false
            if Date().timeIntervalSince(lastRep) > 0.45 {
                lastRep = Date()
                return true
            }
        }
        return false
    }

    static func signal(_ joints: [String: CGPoint], kind: RealMoveKind) -> Double? {
        func y(_ j: VNHumanBodyPoseObservation.JointName) -> Double? { joints[RealJoint.key(j)].map { Double($0.y) } }
        func avg(_ a: Double?, _ b: Double?) -> Double? {
            switch (a, b) {
            case let (a?, b?): (a + b) / 2
            case let (a?, nil): a
            case let (nil, b?): b
            default: nil
            }
        }
        switch kind {
        case .squat: return avg(y(.leftHip), y(.rightHip)) ?? y(.root)
        case .arms: return avg(y(.leftWrist), y(.rightWrist)).map { 1 - $0 }
        case .steps:
            guard let l = y(.leftAnkle) ?? y(.leftKnee), let r = y(.rightAnkle) ?? y(.rightKnee) else { return nil }
            return 0.5 + (l - r) * 2
        }
    }
}

/// Main-actor pose state fed by the camera queue.
@Observable
@MainActor
final class RealPoseTracker {
    private(set) var joints: [String: CGPoint] = [:]
    private(set) var lastSeen = Date.distantPast
    var kind: RealMoveKind = .squat
    var onRep: (() -> Void)?
    private var counter = RealRepCounter()

    var bodyVisible: Bool { Date().timeIntervalSince(lastSeen) < 0.8 && joints.count >= 6 }

    func ingest(_ points: [String: CGPoint]) {
        guard !points.isEmpty else {
            if Date().timeIntervalSince(lastSeen) > 0.8 { joints = [:] }
            return
        }
        joints = points
        lastSeen = Date()
        if let s = RealRepCounter.signal(points, kind: kind), counter.feed(s) { onRep?() }
    }
}

/// Skeleton overlay drawn with aspect-fill mapping of a 720×1280 portrait buffer.
struct RealSkeletonOverlay: View {
    var joints: [String: CGPoint]
    var color: Color = Palette.periwinkle
    var bufferAspect: CGFloat = 720.0 / 1280.0

    var body: some View {
        Canvas { gc, size in
            let viewAspect = size.width / size.height
            var drawW = size.width, drawH = size.height
            if viewAspect > bufferAspect { drawH = size.width / bufferAspect } else { drawW = size.height * bufferAspect }
            let ox = (size.width - drawW) / 2, oy = (size.height - drawH) / 2
            func map(_ p: CGPoint) -> CGPoint { CGPoint(x: ox + p.x * drawW, y: oy + p.y * drawH) }

            for (a, b) in RealJoint.bones {
                guard let pa = joints[RealJoint.key(a)], let pb = joints[RealJoint.key(b)] else { continue }
                var path = Path()
                path.move(to: map(pa))
                path.addLine(to: map(pb))
                gc.stroke(path, with: .color(.white.opacity(0.9)), style: StrokeStyle(lineWidth: 7, lineCap: .round))
                gc.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 4, lineCap: .round))
            }
            for (_, p) in joints {
                let c = map(p)
                gc.fill(Path(ellipseIn: CGRect(x: c.x - 6, y: c.y - 6, width: 12, height: 12)), with: .color(.white))
                gc.fill(Path(ellipseIn: CGRect(x: c.x - 3.5, y: c.y - 3.5, width: 7, height: 7)), with: .color(color))
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Demo figure (practice mode)

/// An animated stick figure demonstrating the move, used when there's no camera.
struct RealDemoFigure: View {
    var kind: RealMoveKind
    var period: Double = 1.6
    var color: Color = .white
    var paused = false

    var body: some View {
        TimelineView(.animation(paused: paused)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            let phase = (t.truncatingRemainder(dividingBy: period)) / period
            Canvas { gc, size in
                let pose = Self.pose(kind: kind, phase: phase)
                let s = min(size.width, size.height)
                let ox = size.width / 2, oy = size.height * 0.08
                func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: ox + x * s, y: oy + y * s) }
                let style = StrokeStyle(lineWidth: s * 0.045, lineCap: .round, lineJoin: .round)
                var body = Path()
                for (a, b) in pose.bones {
                    body.move(to: p(a.0, a.1))
                    body.addLine(to: p(b.0, b.1))
                }
                gc.stroke(body, with: .color(color), style: style)
                let head = p(pose.head.0, pose.head.1)
                let r = s * 0.065
                gc.fill(Path(ellipseIn: CGRect(x: head.x - r, y: head.y - r, width: r * 2, height: r * 2)), with: .color(color))
                // floor
                var floor = Path()
                floor.move(to: p(-0.35, 0.86))
                floor.addLine(to: p(0.35, 0.86))
                gc.stroke(floor, with: .color(color.opacity(0.25)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
        }
    }

    private typealias P = (Double, Double)

    private static func pose(kind: RealMoveKind, phase: Double) -> (head: P, bones: [(P, P)]) {
        let w = 0.5 - 0.5 * cos(phase * 2 * .pi) // 0 → 1 → 0
        switch kind {
        case .squat:
            let drop = 0.2 * w
            let hip: P = (0, 0.5 + drop)
            let neck: P = (0.02 * w, 0.2 + drop * 0.9)
            let kneeL: P = (-0.1 - 0.1 * w, 0.68 + drop * 0.25), kneeR: P = (0.1 + 0.1 * w, 0.68 + drop * 0.25)
            let footL: P = (-0.12, 0.86), footR: P = (0.12, 0.86)
            let handL: P = (-0.05, 0.28 + drop), handR: P = (0.05, 0.28 + drop)
            let elbowL: P = (-0.17, 0.3 + drop * 0.9), elbowR: P = (0.17, 0.3 + drop * 0.9)
            return (head: (neck.0, neck.1 - 0.1), bones: [(neck, hip), (hip, kneeL), (kneeL, footL), (hip, kneeR), (kneeR, footR),
                                                         (neck, elbowL), (elbowL, handL), (neck, elbowR), (elbowR, handR)])
        case .arms:
            let a = w * .pi * 0.85
            let neck: P = (0, 0.22), hip: P = (0, 0.52)
            func arm(_ side: Double) -> [(P, P)] {
                let elbow: P = (side * (0.1 + 0.08 * sin(a + 0.4)), 0.24 + 0.1 * cos(a))
                let hand: P = (side * (0.12 + 0.14 * sin(a)), 0.24 + 0.22 * cos(a))
                return [(neck, elbow), (elbow, hand)]
            }
            let spread = 0.06 * w
            return (head: (0, 0.12), bones: [(neck, hip), (hip, (-0.08 - spread, 0.69)), ((-0.08 - spread, 0.69), (-0.1 - spread * 1.6, 0.86)),
                                            (hip, (0.08 + spread, 0.69)), ((0.08 + spread, 0.69), (0.1 + spread * 1.6, 0.86))] + arm(-1) + arm(1))
        case .steps:
            let sway = sin(phase * 2 * .pi)
            let hip: P = (0.03 * sway, 0.52)
            let neck: P = (0.02 * sway, 0.22)
            let liftL = max(0, sway) * 0.08, liftR = max(0, -sway) * 0.08
            let kneeL: P = (-0.07 + 0.03 * sway, 0.69 - liftL), kneeR: P = (0.07 + 0.03 * sway, 0.69 - liftR)
            let footL: P = (-0.1 + 0.08 * sway, 0.86 - liftL * 0.8), footR: P = (0.1 + 0.08 * sway, 0.86 - liftR * 0.8)
            let handL: P = (-0.16, 0.44 - 0.04 * sway), handR: P = (0.16, 0.44 + 0.04 * sway)
            let elbowL: P = (-0.14, 0.34), elbowR: P = (0.14, 0.34)
            return (head: (neck.0, 0.12), bones: [(neck, hip), (hip, kneeL), (kneeL, footL), (hip, kneeR), (kneeR, footR),
                                                  (neck, elbowL), (elbowL, handL), (neck, elbowR), (elbowR, handR)])
        }
    }
}
