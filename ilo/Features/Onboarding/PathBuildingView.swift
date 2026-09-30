import SwiftUI

/// "ilo is building your path" — runs the research agent live and reveals the path. Reused by Create.
struct PathBuildingView: View {
    let request: CourseRequest
    /// Called with the finished course (already added to the model).
    var onDone: (Course) -> Void
    /// Label of the final button.
    var ctaTitle: String = "Let's go"

    @Environment(AppModel.self) private var model

    private enum Stage: Equatable { case working, revealing, ready, failed(String) }

    private struct Row: Identifiable, Equatable {
        var id = UUID()
        var phase: PlanStep.Phase
        var text: String
        var detail: String?
        var done = false
    }

    @State private var stage: Stage = .working
    @State private var rows: [Row] = []
    @State private var course: Course?
    @State private var revealed = 0
    @State private var attempt = 0
    @State private var addedCourseID: UUID?
    @State private var celebrate = 0

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, 12)
            switch stage {
            case .working:
                checklist
                    .padding(.horizontal, Metrics.gutter)
                    .padding(.top, 22)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                Spacer(minLength: 0)
            case .failed(let message):
                failure(message)
                    .padding(.horizontal, Metrics.gutter)
                    .padding(.top, 22)
                    .transition(.opacity)
                Spacer(minLength: 0)
            case .revealing, .ready:
                if let course { reveal(course).transition(.opacity) }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar.padding(.top, 6).obBottomFade() }
        .overlay { ConfettiView(trigger: celebrate).ignoresSafeArea().allowsHitTesting(false) }
        .animation(.spring(response: 0.55, dampingFraction: 0.85), value: stage)
        .task(id: attempt) { await build() }
    }

    // MARK: Header

    private var bloubExpression: BloubExpression {
        switch stage {
        case .working: .attentive
        case .revealing: .excited
        case .ready: .proud
        case .failed: .sad
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            ZStack {
                if stage == .working { orbit.transition(.scale.combined(with: .opacity)) }
                Circle()
                    .fill(RadialGradient(colors: [glowColor.opacity(0.45), .clear], center: .center, startRadius: 5, endRadius: 90))
                    .frame(width: 180, height: 180)
                    .phaseAnimator([0.9, 1.1]) { view, s in view.scaleEffect(s) } animation: { _ in .easeInOut(duration: 1.2) }
                OBBounce(trigger: celebrate + rows.count) {
                    BloubView(shape: .circle, color: .ink, expression: bloubExpression,
                              mode: stage == .working ? .thinking : .face)
                        .frame(width: isCompact ? 84 : 116, height: isCompact ? 84 : 116)
                }
            }
            .frame(height: isCompact ? 110 : 170)

            VStack(spacing: 6) {
                Text(title)
                    .font(.display(isCompact ? 26 : 30, weight: .heavy))
                    .foregroundStyle(Palette.ink)
                    .multilineTextAlignment(.center)
                    .contentTransition(.opacity)
                Text(subtitle)
                    .font(.body(15, weight: .medium))
                    .foregroundStyle(Palette.muted)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.horizontal, Metrics.gutter)
        }
    }

    private var isCompact: Bool { stage == .revealing || stage == .ready }

    private var glowColor: Color {
        switch stage {
        case .failed: Palette.danger
        case .ready, .revealing: course?.tint.base ?? Palette.periwinkle
        case .working: Palette.periwinkle
        }
    }

    private var title: String {
        switch stage {
        case .working: "Building your path"
        case .failed: "Hmm, that didn't work"
        case .revealing, .ready: course.map { "\($0.title)" } ?? "Your path is ready"
        }
    }

    private var subtitle: String {
        switch stage {
        case .working: "“\(request.goal)”"
        case .failed: "ilo tripped over its own feet. Let's try again."
        case .revealing, .ready: course?.tagline ?? "Made just for you."
        }
    }

    private var orbit: some View {
        TimelineView(.animation(minimumInterval: 1 / 60)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            ZStack {
                Circle().stroke(Palette.periwinkle.opacity(0.25), style: StrokeStyle(lineWidth: 1.5, dash: [4, 6]))
                    .frame(width: 164, height: 164)
                    .rotationEffect(.degrees(t * 20))
                ForEach(0..<3, id: \.self) { i in
                    let speed = [1.4, -1.0, 0.8][i]
                    let radius = [82.0, 70.0, 94.0][i]
                    let angle = t * speed + Double(i) * 2.1
                    Image(systemName: ["doc.text.fill", "sparkles", "book.fill"][i])
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle([Palette.periwinkleDeep, Palette.orchid, Palette.orange][i])
                        .frame(width: 30, height: 30)
                        .background(.white, in: .circle)
                        .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
                        .offset(x: cos(angle) * radius, y: sin(angle) * radius * 0.55)
                }
            }
        }
        .frame(width: 200, height: 170)
    }

    // MARK: Checklist

    private var checklist: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { i, row in
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        if row.done {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundStyle(.white)
                                .frame(width: 26, height: 26)
                                .background(Palette.success, in: .circle)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            ProgressView()
                                .controlSize(.small)
                                .frame(width: 26, height: 26)
                                .background(Palette.periwinkleMist, in: .circle)
                        }
                    }
                    .frame(width: 26, height: 26)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.text)
                            .font(.display(16, weight: .bold))
                            .foregroundStyle(row.done ? Palette.ink : Palette.ink2)
                        if let detail = row.detail {
                            Text(detail)
                                .font(.body(13))
                                .foregroundStyle(Palette.muted)
                                .lineLimit(2)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 10)
                .transition(.asymmetric(insertion: .offset(y: 14).combined(with: .opacity), removal: .opacity))
                if i < rows.count - 1 { Divider().opacity(0.5).padding(.leading, 38) }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: .rect(cornerRadius: Metrics.cardRadius, style: .continuous))
        .shadow(color: Color(hex: 0x3A4470, alpha: 0.07), radius: 18, y: 8)
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: rows)
    }

    private func failure(_ message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Palette.danger)
            Text(message)
                .font(.body(15))
                .foregroundStyle(Palette.ink2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .card(Palette.dangerSoft, radius: Metrics.cardRadius, padding: 20)
    }

    // MARK: Reveal

    private func reveal(_ course: Course) -> some View {
        let nodes = course.allNodes
        return ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 14) {
                    stats(course)
                        .padding(.top, 14)
                    ForEach(Array(course.units.enumerated()), id: \.element.id) { u, unit in
                        let offset = course.units[..<u].reduce(0) { $0 + $1.nodes.count }
                        unitCard(unit, index: u, offset: offset)
                            .id(unit.id)
                            .opacity(revealed > offset || (unit.nodes.isEmpty && revealed >= offset) ? 1 : 0)
                            .offset(y: revealed > offset ? 0 : 24)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: revealed > offset)
                    }
                    if nodes.isEmpty {
                        Text("Your first lessons are on their way.")
                            .font(.body(15)).foregroundStyle(Palette.muted)
                    }
                }
                .padding(.horizontal, Metrics.gutter)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .onChange(of: revealed) {
                guard let unit = unitIndex(forNode: revealed - 1, in: course) else { return }
                withAnimation(.smooth) { proxy.scrollTo(course.units[unit].id, anchor: .center) }
            }
        }
    }

    private func unitIndex(forNode index: Int, in course: Course) -> Int? {
        var seen = 0
        for (u, unit) in course.units.enumerated() {
            seen += unit.nodes.count
            if index < seen { return u }
        }
        return nil
    }

    private func stats(_ course: Course) -> some View {
        HStack(spacing: 8) {
            stat("\(course.units.count)", course.units.count == 1 ? "unit" : "units", "square.stack.3d.up.fill")
            stat("\(course.lessonCount)", course.lessonCount == 1 ? "lesson" : "lessons", "star.fill")
            stat(durationValue(course), durationUnit(course), "calendar")
        }
    }

    private func stat(_ value: String, _ label: String, _ symbol: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: symbol).font(.system(size: 13, weight: .bold)).foregroundStyle(Palette.periwinkleDeep)
            Text(value).font(.display(24, weight: .heavy)).foregroundStyle(Palette.ink)
                .contentTransition(.numericText())
            Text(label).font(.body(12, weight: .semibold)).foregroundStyle(Palette.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.white, in: .rect(cornerRadius: 20, style: .continuous))
        .shadow(color: Color(hex: 0x3A4470, alpha: 0.05), radius: 10, y: 4)
    }

    private func estimatedDays(_ course: Course) -> Int {
        let minutes = max(course.dailyMinutes, 5)
        return max(1, Int((Double(course.lessonCount * 5) / Double(minutes)).rounded(.up)))
    }

    private func durationValue(_ course: Course) -> String {
        let days = estimatedDays(course)
        return days < 14 ? "~\(days)" : "~\(Int((Double(days) / 7).rounded()))"
    }

    private func durationUnit(_ course: Course) -> String {
        let days = estimatedDays(course)
        return days < 14 ? (days == 1 ? "day" : "days") : "weeks"
    }

    private func unitCard(_ unit: CourseUnit, index: Int, offset: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text("UNIT \(index + 1)")
                    .font(.display(12, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .frame(height: 24)
                    .background(unit.tint.deep, in: .capsule)
                Text(unit.title)
                    .font(.display(17, weight: .bold))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
            }
            if !unit.outcome.isEmpty {
                Text(unit.outcome)
                    .font(.body(13.5))
                    .foregroundStyle(Palette.ink2.opacity(0.75))
                    .lineLimit(2)
            }
            OBFlowLayout(spacing: 8, lineSpacing: 8) {
                ForEach(Array(unit.nodes.enumerated()), id: \.element.id) { i, node in
                    let global = offset + i
                    let isFirst = global == 0
                    Image(systemName: node.symbol.isEmpty ? node.kind.defaultSymbol : node.symbol)
                        .font(.system(size: node.kind == .boss ? 18 : 15, weight: .bold))
                        .foregroundStyle(isFirst ? .white : unit.tint.deep)
                        .frame(width: node.kind == .boss ? 50 : 44, height: node.kind == .boss ? 50 : 44)
                        .background(isFirst ? unit.tint.deep : .white, in: .circle)
                        .overlay { Circle().strokeBorder(unit.tint.base.opacity(0.35), lineWidth: isFirst ? 0 : 2) }
                        .scaleEffect(revealed > global ? 1 : 0.2)
                        .opacity(revealed > global ? 1 : 0)
                        .animation(.spring(response: 0.35, dampingFraction: 0.55), value: revealed > global)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(unit.tint.soft, radius: 26, padding: 16)
    }

    // MARK: Bottom

    @ViewBuilder private var bottomBar: some View {
        switch stage {
        case .ready:
            if let course {
                Button {
                    Haptics.shared.thud()
                    onDone(course)
                } label: {
                    HStack(spacing: 8) {
                        Text(ctaTitle)
                        Image(systemName: "arrow.right").font(.system(size: 16, weight: .bold))
                    }
                }
                .buttonStyle(.pill(.ink))
                .padding(.horizontal, Metrics.gutter)
                .padding(.vertical, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        case .failed:
            Button {
                attempt += 1
            } label: {
                Label("Try again", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.pill(.ink))
            .padding(.horizontal, Metrics.gutter)
            .padding(.vertical, 8)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        default:
            EmptyView()
        }
    }

    // MARK: Running the agent

    private func push(_ phase: PlanStep.Phase, _ text: String, _ detail: String? = nil) {
        for i in rows.indices { rows[i].done = true }
        rows.append(Row(phase: phase, text: text, detail: detail))
        Haptics.shared.tick()
        SoundFX.shared.play(.tick)
    }

    private func build() async {
        stage = .working
        rows = []
        course = nil
        revealed = 0

        let ai = model.ai
        let request = request
        let (stream, continuation) = AsyncStream.makeStream(of: PlanStep.self)
        let planning = Task { () -> Result<Course, Error> in
            defer { continuation.finish() }
            do {
                return .success(try await ai.planCourse(request) { continuation.yield($0) })
            } catch {
                return .failure(error)
            }
        }

        let topic = request.goal.count > 40 ? String(request.goal.prefix(38)) + "…" : request.goal
        push(.understanding, "Understanding your goal", "\(request.level.title) · \(request.dailyMinutes) min a day")
        var lastPush = Date()

        func pace(_ seconds: Double) async {
            let wait = seconds - Date().timeIntervalSince(lastPush)
            if wait > 0 { try? await Task.sleep(for: .seconds(wait)) }
            lastPush = Date()
        }

        for await step in stream {
            guard step.phase != .done else { continue }
            if rows.contains(where: { $0.text == step.text }) {
                if let i = rows.firstIndex(where: { $0.text == step.text }), step.detail != nil { rows[i].detail = step.detail }
                continue
            }
            await pace(0.55)
            push(step.phase, step.text, step.detail)
        }

        let result = await planning.value
        if Task.isCancelled { return }

        switch result {
        case .failure(let error):
            await pace(0.4)
            for i in rows.indices { rows[i].done = true }
            Haptics.shared.wrong()
            SoundFX.shared.play(.wrong)
            stage = .failed(error.localizedDescription)

        case .success(let built):
            let seen = Set(rows.map(\.phase))
            if !seen.contains(.researching) {
                await pace(0.75)
                push(.researching, "Researching \(topic.lowercased())…", "Reading guides, tutorials and expert tips")
                await pace(0.9)
                if built.sources.isEmpty {
                    push(.researching, "Picked the best techniques", "Distilled into bite-sized lessons")
                } else {
                    push(.researching, "Found \(built.sources.count) sources",
                         built.sources.prefix(2).map(\.title).joined(separator: " · "))
                }
            }
            if !seen.contains(.designing) {
                await pace(0.8)
                push(.designing, "Designing \(built.units.count) \(built.units.count == 1 ? "unit" : "units")",
                     built.units.prefix(3).map(\.title).joined(separator: " · "))
            }
            if !seen.contains(.writing) {
                await pace(0.8)
                push(.writing, "Writing \(built.lessonCount) lesson briefs", "Stories, quizzes, missions and boss battles")
            }
            await pace(0.7)
            for i in rows.indices { rows[i].done = true }
            Haptics.shared.correct()
            SoundFX.shared.play(.correct)
            try? await Task.sleep(for: .milliseconds(500))
            if Task.isCancelled { return }

            course = built
            stage = .revealing
            try? await Task.sleep(for: .milliseconds(350))
            let total = built.allNodes.count
            let step = min(0.09, max(0.025, 2.2 / Double(max(total, 1))))
            for i in 0..<total {
                if Task.isCancelled { return }
                revealed = i + 1
                Haptics.shared.tick()
                if i % 2 == 0 { SoundFX.shared.play(.tick) }
                try? await Task.sleep(for: .seconds(step))
            }
            if addedCourseID != built.id {
                model.add(built)
                addedCourseID = built.id
            }
            celebrate += 1
            Haptics.shared.celebrate()
            SoundFX.shared.play(.complete)
            stage = .ready
        }
    }
}
