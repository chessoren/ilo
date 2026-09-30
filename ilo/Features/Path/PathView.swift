import SwiftUI

/// The heart of ilo: a Duolingo-style winding path of nodes, grouped by unit with sticky banners.
struct PathView: View {
    @Environment(AppModel.self) private var model
    @Environment(AppRouter.self) private var router
    let course: Course

    @State private var selected: UUID?
    @State private var guidebook: CourseUnit?
    @State private var showSources = false
    @State private var confirmDelete = false
    @State private var chest: ChestState?
    @State private var toast: String?
    @State private var didScroll = false

    struct ChestState: Identifiable { var id: UUID; var gems: Int }

    private var live: Course { model.courses.first { $0.id == course.id } ?? course }

    var body: some View {
        let course = live
        let current = model.currentNode(in: course)
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    PathIntro(course: course).padding(.bottom, 18)
                    ForEach(Array(course.units.enumerated()), id: \.element.id) { unitIndex, unit in
                        Section {
                            unitNodes(unit, unitIndex: unitIndex, course: course, current: current)
                        } header: {
                            UnitBanner(unit: unit, index: unitIndex) {
                                Haptics.shared.tap()
                                guidebook = unit
                            }
                            .padding(.horizontal, Metrics.gutter)
                            .padding(.vertical, 8)
                        }
                    }
                    CourseFinishFlag(done: current == nil, tint: course.tint)
                        .padding(.bottom, 80)
                }
                .overlayPreferenceValue(SelectedNodeAnchor.self) { anchor in
                    GeometryReader { geo in
                        if let anchor, let id = selected, let node = course.node(id) {
                            let rect = geo[anchor]
                            NodePopover(course: course, node: node, state: model.state(of: node, in: course),
                                        arrowX: rect.midX) { action in handle(action, node: node, course: course) }
                                .frame(width: geo.size.width)
                                .offset(y: rect.maxY + 14)
                                .transition(.scale(scale: 0.85, anchor: .top).combined(with: .opacity))
                                .id(id)
                        }
                    }
                }
                .background {
                    Color.clear.contentShape(.rect)
                        .onTapGesture { withAnimation(.snappy) { selected = nil } }
                }
            }
            .scrollIndicators(.hidden)
            // The course header scrolls under the glass toolbar: a hard edge keeps the title from colliding with it.
            .scrollEdgeEffectStyle(.hard, for: .top)
            .onChange(of: selected) { _, id in
                guard let id else { return }
                Task {
                    try? await Task.sleep(for: .milliseconds(80))
                    withAnimation(.smooth(duration: 0.5)) { proxy.scrollTo(id, anchor: UnitPoint(x: 0.5, y: 0.28)) }
                }
            }
            .onAppear {
                model.open(course)
                guard !didScroll, let current else { return }
                didScroll = true
                Task {
                    try? await Task.sleep(for: .milliseconds(350))
                    withAnimation(.smooth(duration: 0.8)) { proxy.scrollTo(current.id, anchor: .center) }
                }
            }
        }
        .background(PathBackground(tint: course.tint))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { StatsCluster() }
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
            ToolbarItem(placement: .topBarTrailing) { courseMenu(course, current: current) }
        }
        .navigationBarTitleDisplayMode(.inline)
        #if DEBUG
        .task {
            try? await Task.sleep(for: .seconds(1.6))
            let nodes = course.allNodes
            if DebugSeed.action("popover") { withAnimation(.spring) { selected = current?.id } }
            if DebugSeed.action("locked"), let c = current, let next = course.node(after: c.id) {
                withAnimation(.spring) { selected = course.node(after: next.id)?.id ?? next.id }
            }
            if DebugSeed.action("guidebook") { guidebook = course.units.first }
            if DebugSeed.action("chest"), let n = nodes.first(where: { $0.kind == .chest }) { chest = ChestState(id: n.id, gems: 27) }
        }
        #endif
        .overlay {
            if let chest {
                ChestOpenOverlay(gems: chest.gems, tint: course.tint) {
                    withAnimation(.smooth) { self.chest = nil }
                }
                .transition(.opacity)
            }
        }
        .overlay(alignment: .bottom) {
            if let toast {
                Text(toast)
                    .font(.body(15, weight: .semibold))
                    .padding(.horizontal, 18).padding(.vertical, 12)
                    .glassEffect(.regular, in: .capsule)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(item: $guidebook) { unit in
            GuidebookSheet(course: course, unit: unit).presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showSources) {
            SourcesSheet(course: course).presentationDetents([.medium, .large])
        }
        .confirmationDialog("Delete \(course.title)?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete course", role: .destructive) {
                Haptics.shared.thud()
                router.homePath = []
                Task {
                    try? await Task.sleep(for: .milliseconds(400))
                    model.delete(course)
                }
            }
        } message: {
            Text("Your progress on this path will be lost.")
        }
    }

    // MARK: Nodes

    @ViewBuilder
    private func unitNodes(_ unit: CourseUnit, unitIndex: Int, course: Course, current: PathNode?) -> some View {
        let globalOffset = course.units.prefix(unitIndex).reduce(0) { $0 + $1.nodes.count }
        let offsets = unit.nodes.indices.map { i in
            CGFloat(sin(Double(i) * .pi / 4)) * 78 * (unitIndex.isMultiple(of: 2) ? 1 : -1)
        }
        Group {
            ForEach(Array(unit.nodes.enumerated()), id: \.element.id) { i, node in
                let state = model.state(of: node, in: course)
                let stars = model.progress[course.id]?.stars[node.id] ?? 0
                let look = NodeLook(state: state, tint: unit.tint, kind: node.kind, stars: stars)
                let x = offsets[i]
                let side: CGFloat = x > 0 ? -1 : 1
                ZStack {
                    // Decorations beside the node.
                    if state == .current {
                        BloubView(shape: model.player.bloubShape, color: model.player.bloubColor,
                                  expression: selected == node.id ? .excited : .happy,
                                  lookAt: CGPoint(x: -side, y: 0.2))
                            .frame(width: 66, height: 66)
                            .phaseAnimator([0.0, -6.0]) { v, y in v.offset(y: y) } animation: { _ in .easeInOut(duration: 0.9) }
                            .offset(x: x + side * 110, y: 6)
                            .transition(.scale.combined(with: .opacity))
                    } else if i == 2 || (i == unit.nodes.count - 2 && unit.nodes.count > 5) {
                        MascotDecoration(index: unitIndex * 10 + i, tint: unit.tint, done: state == .completed)
                            .offset(x: x + side * 128)
                    }

                    PathNodeView(node: node, look: look,
                                 isReady: model.lessons[node.id] != nil,
                                 isThinking: model.generating.contains(node.id),
                                 selected: selected == node.id) {
                        tap(node)
                    }
                    .accessibilityIdentifier("node-\(globalOffset + i)")
                    .accessibilityValue(state == .current ? "current" : (state == .completed ? "completed" : "locked"))
                    .anchorPreference(key: SelectedNodeAnchor.self, value: .bounds) { selected == node.id ? $0 : nil }
                    .overlay(alignment: .top) {
                        if state == .current && selected != node.id {
                            StartTooltip(tint: unit.tint, text: node.kind == .chest ? "OPEN" : (stars > 0 ? "AGAIN" : "START"))
                                .fixedSize()
                                .offset(y: node.kind == .boss ? -80 : -56)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .offset(x: x)
                }
                .frame(maxWidth: .infinity)
                .frame(height: look.diameter + 14)
                .padding(.top, node.kind == .boss ? 24 : 0)
                .padding(.vertical, 11)
                .padding(.top, i == 0 ? 26 : 0)
                .padding(.top, state == .current ? 26 : 0)
                .padding(.bottom, i == unit.nodes.count - 1 ? 24 : 0)
                .id(node.id)
                .scrollTransition(.animated(.spring)) { v, phase in
                    v.scaleEffect(phase.isIdentity ? 1 : 0.8).opacity(phase.isIdentity ? 1 : 0.4)
                }
            }
        }
    }

    // MARK: Actions

    private func tap(_ node: PathNode) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            selected = selected == node.id ? nil : node.id
        }
        if selected != nil { SoundFX.shared.play(.bubble) }
    }

    private func handle(_ action: NodePopover.Action, node: PathNode, course: Course) {
        switch action {
        case .start:
            withAnimation(.snappy) { selected = nil }
            router.play(node, in: course)
        case .openChest:
            withAnimation(.snappy) { selected = nil }
            let gems = model.openChest(node, in: course)
            Haptics.shared.celebrate()
            withAnimation(.spring) { chest = ChestState(id: node.id, gems: gems) }
        case .dismiss:
            withAnimation(.snappy) { selected = nil }
        }
    }

    private func courseMenu(_ course: Course, current: PathNode?) -> some View {
        Menu {
            if let current, current.kind != .chest {
                Button {
                    model.regenerate(current, in: course)
                    Haptics.shared.softTap()
                    show("ilo is rewriting “\(current.title)”")
                } label: { Label("Regenerate current lesson", systemImage: "arrow.clockwise") }
            }
            Button { showSources = true } label: { Label("Sources", systemImage: "books.vertical") }
            if let unit = current.flatMap({ course.unit(containing: $0.id) }) ?? course.units.first {
                Button { guidebook = unit } label: { Label("Guidebook", systemImage: "book.closed") }
            }
            Divider()
            Button(role: .destructive) { confirmDelete = true } label: { Label("Delete course", systemImage: "trash") }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Palette.ink)
        }
    }

    private func show(_ text: String) {
        withAnimation(.spring) { toast = text }
        Task {
            try? await Task.sleep(for: .seconds(2.2))
            withAnimation(.smooth) { toast = nil }
        }
    }
}

struct SelectedNodeAnchor: PreferenceKey {
    static let defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

// MARK: - Pieces

/// Course header at the top of the path.
private struct PathIntro: View {
    @Environment(AppModel.self) private var model
    let course: Course

    var body: some View {
        let pct = model.completion(of: course)
        HStack(spacing: 14) {
            Image(systemName: course.symbol)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(course.tint.deep)
                .frame(width: 58, height: 58)
                .background(course.tint.soft, in: .circle)
            VStack(alignment: .leading, spacing: 3) {
                Text(course.title).font(.display(24, weight: .heavy)).lineLimit(2)
                Text(course.tagline).font(.body(14)).foregroundStyle(Palette.muted).lineLimit(2)
            }
            Spacer(minLength: 0)
            ZStack {
                Circle().stroke(course.tint.soft, lineWidth: 5)
                Circle().trim(from: 0, to: pct)
                    .stroke(course.tint.deep, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(pct * 100))%").font(.display(12, weight: .heavy))
            }
            .frame(width: 48, height: 48)
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.top, 8)
    }
}

/// Sticky unit banner (tint, title, outcome, Guidebook).
struct UnitBanner: View {
    let unit: CourseUnit
    let index: Int
    var onGuidebook: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("UNIT \(index + 1)")
                    .font(.display(13, weight: .heavy))
                    .kerning(1)
                    .foregroundStyle(.white.opacity(0.85))
                Text(unit.title)
                    .font(.display(21, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(unit.outcome)
                    .font(.body(13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(2)
            }
            .shadow(color: unit.tint.deep.opacity(0.35), radius: 0, y: 1)
            Spacer(minLength: 4)
            Button(action: onGuidebook) {
                VStack(spacing: 3) {
                    Image(systemName: "book.pages.fill").font(.system(size: 18, weight: .bold))
                    Text("Guide").font(.display(11, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(width: 62, height: 62)
                .background(unit.tint.deep.opacity(0.55), in: .rect(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(.white.opacity(0.35), lineWidth: 1.5))
            }
            .buttonStyle(.squish)
        }
        .padding(.leading, 20).padding(.trailing, 12).padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous).fill(unit.tint.deep)
                .offset(y: 5)
            RoundedRectangle(cornerRadius: 24, style: .continuous).fill(unit.tint.base.gradient)
        }
        .padding(.bottom, 5)
    }
}

/// ilo bloub hanging out between nodes.
private struct MascotDecoration: View {
    let index: Int
    let tint: CourseTint
    let done: Bool
    @State private var poke = 0

    private var expression: BloubExpression {
        let pool: [BloubExpression] = done ? [.proud, .happy, .laughing] : [.curious, .attentive, .shy, .sleepy]
        return pool[index % pool.count]
    }

    var body: some View {
        Button {
            poke += 1
            Haptics.shared.softTap()
            SoundFX.shared.play(.bubble)
        } label: {
            ZStack(alignment: .bottom) {
                Ellipse().fill(tint.base.opacity(0.18)).frame(width: 64, height: 12).offset(y: 4)
                BloubView(shape: .circle, color: .ink, expression: poke % 2 == 1 ? .surprised : expression)
                    .frame(width: 62, height: 62)
                    .keyframeAnimator(initialValue: CGFloat(0), trigger: poke) { v, y in v.offset(y: y) } keyframes: { _ in
                        SpringKeyframe(-26, duration: 0.2)
                        SpringKeyframe(0, duration: 0.35, spring: .bouncy)
                    }
            }
        }
        .buttonStyle(.plain)
    }
}

/// End of the path.
private struct CourseFinishFlag: View {
    let done: Bool
    let tint: CourseTint

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(done ? AnyShapeStyle(Palette.gold.gradient) : AnyShapeStyle(Color(hex: 0xC9CEDB)))
                .frame(width: 104, height: 104)
                .background(done ? Palette.butter : Color(hex: 0xEDEFF5), in: .circle)
                .symbolEffect(.bounce, options: .repeat(.periodic(delay: 2)), isActive: done)
            Text(done ? "Path complete!" : "Finish line")
                .font(.display(18, weight: .bold))
                .foregroundStyle(done ? Palette.ink : Palette.faint)
        }
        .padding(.top, 10)
    }
}

/// Soft canvas with the unit tint faintly glowing.
private struct PathBackground: View {
    let tint: CourseTint
    var body: some View {
        ZStack {
            Palette.canvas
            LinearGradient(colors: [tint.soft.opacity(0.55), Palette.canvas, Palette.periwinkleMist.opacity(0.6)],
                           startPoint: .top, endPoint: .bottom)
        }
        .ignoresSafeArea()
    }
}
