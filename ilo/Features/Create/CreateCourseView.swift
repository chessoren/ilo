import SwiftUI

/// "What do you want to learn next?" — goal, level and daily minutes → PathBuildingView.
struct CreateCourseView: View {
    @Environment(AppModel.self) private var model
    @Environment(AppRouter.self) private var router

    @State private var goal = ""
    @State private var level: LearnerLevel = .zero
    @State private var minutes = 10
    @State private var building: BuildJob?
    @State private var shown = false
    @State private var suggestionSeed = 0
    @FocusState private var focused: Bool

    private static let allSuggestions: [(String, String)] = [
        ("figure.dance", "Salsa for a wedding"),
        ("chevron.left.forwardslash.chevron.right", "Code my first website"),
        ("book.fill", "Atomic Habits"),
        ("character.bubble.fill", "Italian for travel"),
        ("camera.fill", "Street photography"),
        ("brain.head.profile", "Stoic philosophy"),
        ("guitar", "Guitar chords"),
        ("chart.line.uptrend.xyaxis", "Investing basics"),
        ("fork.knife", "Cook Thai food"),
        ("mic.fill", "Public speaking"),
        ("paintpalette.fill", "Watercolor painting"),
        ("moon.stars.fill", "Sleep better"),
    ]

    private var suggestions: [(String, String)] {
        let all = Self.allSuggestions
        return (0..<6).map { all[($0 + suggestionSeed * 6) % all.count] }
    }

    private var canBuild: Bool { goal.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                header.appear(shown)
                goalField.appear(shown, delay: 0.08)
                suggestionsView.appear(shown, delay: 0.14)
                levelPicker.appear(shown, delay: 0.2)
                minutesPicker.appear(shown, delay: 0.26)
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.top, 8)
            .padding(.bottom, 140)
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollIndicators(.hidden)
        .demoScrollable()
        .background(IloBackground())
        .safeAreaInset(edge: .bottom) {
            Button {
                focused = false
                building = BuildJob(request: CourseRequest(goal: goal.trimmingCharacters(in: .whitespacesAndNewlines),
                                         motivation: nil, level: level, dailyMinutes: minutes, deadline: nil,
                                         styles: model.lastRequest?.styles ?? []))
            } label: {
                Label("Build my path", systemImage: "sparkles")
            }
            .buttonStyle(.pill(.ink))
            .accessibilityIdentifier("create-build")
            .disabled(!canBuild)
            .padding(.horizontal, Metrics.gutter)
            .padding(.top, 14)
            .padding(.bottom, 8)
            .background {
                LinearGradient(colors: [Palette.canvas.opacity(0), Palette.canvas.opacity(0.95)], startPoint: .top, endPoint: .center)
                    .ignoresSafeArea()
            }
            .animation(.spring, value: canBuild)
        }
        .onAppear { shown = true }
        .fullScreenCover(item: $building) { job in
            PathBuildingView(request: job.request) { course in
                building = nil
                goal = ""
                Haptics.shared.celebrate()
                Task {
                    try? await Task.sleep(for: .milliseconds(350))
                    router.openPath(course)
                }
            }
            .background(IloBackground(tint: Palette.lavender))
            // Building can take a while (on-device / cloud model): always leave a way back.
            .overlay(alignment: .topLeading) {
                GlassIconButton(systemImage: "xmark", size: 44) { building = nil }
                    .accessibilityIdentifier("create-build-close")
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                Text("New path").font(.body(15, weight: .semibold)).foregroundStyle(Palette.muted)
                Text("What do you want to \(Text("learn next?").foregroundStyle(Palette.periwinkleDeep))")
                    .font(.display(34, weight: .heavy))
                    .foregroundStyle(Palette.ink)
            }
            Spacer(minLength: 8)
            BloubView(shape: .circle, color: .ilo,
                      expression: canBuild ? .excited : (focused ? .attentive : .curious),
                      mode: focused && !goal.isEmpty && !canBuild ? .thinking : .face)
                .frame(width: 76)
        }
    }

    private var goalField: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("e.g. Salsa for my grandma's wedding", text: $goal, axis: .vertical)
                .font(.display(22, weight: .semibold))
                .lineLimit(2...4)
                .focused($focused)
                .submitLabel(.done)
                .accessibilityIdentifier("create-goal-field")
                .onSubmit { focused = false }
                .onChange(of: goal) { _, new in
                    // Vertical TextFields insert "\n" on Return instead of submitting: dismiss the keyboard instead.
                    if new.contains("\n") {
                        goal = new.replacingOccurrences(of: "\n", with: "")
                        focused = false
                    }
                }
            HStack {
                Image(systemName: "sparkles").foregroundStyle(Palette.periwinkleDeep)
                Text("Be specific: why, for when, what level.")
                    .font(.body(13)).foregroundStyle(Palette.muted)
                Spacer()
                if !goal.isEmpty {
                    Button { withAnimation(.snappy) { goal = "" } } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(Palette.faint)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .card(radius: 30, padding: 20)
        .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous)
            .stroke(focused ? Palette.periwinkle : .clear, lineWidth: 2))
        .animation(.snappy, value: focused)
    }

    private var suggestionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Need ideas?").font(.display(18, weight: .bold))
                Spacer()
                Button {
                    Haptics.shared.tick()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { suggestionSeed += 1 }
                } label: {
                    Image(systemName: "shuffle")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 36, height: 36)
                        .glassEffect(.regular.interactive(), in: .circle)
                }
                .buttonStyle(.plain)
            }
            FlowLayout(spacing: 8) {
                ForEach(suggestions, id: \.1) { symbol, text in
                    Button {
                        Haptics.shared.tap()
                        withAnimation(.snappy) { goal = text }
                    } label: {
                        Label(text, systemImage: symbol)
                            .font(.body(14, weight: .semibold))
                            .foregroundStyle(goal == text ? .white : Palette.ink)
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .background(goal == text ? Palette.ink : .white, in: .capsule)
                    }
                    .buttonStyle(.squish)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
            }
        }
    }

    private var levelPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your level").font(.display(18, weight: .bold))
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(LearnerLevel.allCases, id: \.self) { l in
                        choice(l.title, subtitle: l.detail, selected: level == l, tint: .lavender) { level = l }
                    }
                }
                .padding(.horizontal, Metrics.gutter)
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, -Metrics.gutter)
        }
    }

    private var minutesPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Minutes a day").font(.display(18, weight: .bold))
            HStack(spacing: 10) {
                ForEach([5, 10, 15, 20], id: \.self) { m in
                    Button {
                        Haptics.shared.tick()
                        withAnimation(.snappy) { minutes = m }
                    } label: {
                        VStack(spacing: 0) {
                            Text("\(m)").font(.display(24, weight: .heavy))
                            Text("min").font(.body(12, weight: .semibold)).opacity(0.7)
                        }
                        .foregroundStyle(minutes == m ? .white : Palette.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 70)
                        .background(minutes == m ? Palette.ink : .white, in: .rect(cornerRadius: 22, style: .continuous))
                    }
                    .buttonStyle(.squish)
                }
            }
        }
    }

    private func choice(_ title: String, subtitle: String, selected: Bool, tint: CourseTint, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.shared.tick()
            withAnimation(.snappy) { action() }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.display(15, weight: .bold))
                Text(subtitle).font(.body(12)).opacity(0.7).lineLimit(2)
            }
            .foregroundStyle(selected ? .white : Palette.ink)
            .frame(width: 150, alignment: .leading)
            .padding(14)
            .background(selected ? tint.deep : .white, in: .rect(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.squish)
    }
}

/// One "build my path" run.
struct BuildJob: Identifiable {
    let id = UUID()
    var request: CourseRequest
}

/// Simple wrapping layout for chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 360
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 { x = 0; y += rowH + spacing; rowH = 0 }
            x += size.width + spacing
            rowH = max(rowH, size.height)
        }
        return CGSize(width: width, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX { x = bounds.minX; y += rowH + spacing; rowH = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowH = max(rowH, size.height)
        }
    }
}
