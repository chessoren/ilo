import SwiftUI

/// Mini code lab for html / css / js: highlighted editor, live preview, requirement checklist.
struct CodeLabModule: View {
    let session: ModuleSession

    enum Pane: String, CaseIterable { case code = "Code", preview = "Preview" }

    @State private var code = ""
    @State private var pane: Pane = .code
    @State private var results: [Int: Bool] = [:]
    @State private var revealed = 0
    @State private var attempts = 0
    @State private var usedSolution = false
    @State private var shake: CGFloat = 0
    @State private var visible = false
    @State private var checking = false
    @Namespace private var paneNS

    private var module: LessonModule { session.module }
    private var language: String { (module.language ?? "html").lowercased() }
    private var requirements: [String] { module.mustContain ?? [] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RealHeader(type: module.type, title: module.title, tint: session.tint)

                taskCard.appear(visible, delay: 0.06)

                paneSwitcher.appear(visible, delay: 0.12)

                // Both panes stay alive so the web preview is already rendered when you switch.
                ZStack {
                    editorCard
                        .opacity(pane == .code ? 1 : 0)
                        .offset(x: pane == .code ? 0 : -40)
                        .scaleEffect(pane == .code ? 1 : 0.96)
                        .allowsHitTesting(pane == .code)
                    previewCard
                        .opacity(pane == .preview ? 1 : 0)
                        .offset(x: pane == .preview ? 0 : 40)
                        .scaleEffect(pane == .preview ? 1 : 0.96)
                        .allowsHitTesting(pane == .preview)
                }
                .modifier(RealShake(animatableData: shake))
                .appear(visible, delay: 0.18)

                if attempts > 0 && !usedSolution && !session.isResolved, let solution = module.solution {
                    Button {
                        Haptics.shared.tap()
                        SoundFX.shared.play(.whoosh)
                        withAnimation(.spring) {
                            code = solution
                            usedSolution = true
                            results = [:]
                            revealed = 0
                        }
                        session.mood = .happy
                    } label: {
                        Label("Show solution", systemImage: "lightbulb.max.fill")
                    }
                    .buttonStyle(.pill(.white, height: 50))
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.top, 8)
            .padding(.bottom, 120)
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear(perform: setup)
        .onChange(of: code) {
            if !checking && !results.isEmpty { withAnimation(.smooth) { results = [:]; revealed = 0 } }
            session.canCheck = !code.realTrimmed.isEmpty && !checking
        }
        .realDemoAuto {
            await realPause(1.2)
            for chunk in ["<h1>Hello</h1>\n", "<button>Go</button>\n"] {
                code += chunk
                await realPause(0.5)
            }
            session.check()
            await realPause(2.4)
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { pane = .preview }
            await realPause(1.5)
            code = code.replacingOccurrences(of: "Go", with: "Start")
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { pane = .code }
            await realPause(0.8)
            session.check()
        }
    }

    // MARK: Task

    private var taskCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text(language.uppercased())
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(languageColor, in: .capsule)
                Text("Your task")
                    .font(.body(13, weight: .heavy))
                    .foregroundStyle(Palette.muted)
            }
            Text(module.prompt ?? "Make the code work!")
                .font(.display(19, weight: .bold))
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                Text("Your code must include")
                    .font(.body(12, weight: .bold))
                    .foregroundStyle(Palette.faint)
                RealFlowRows(spacing: 8) {
                    ForEach(Array(requirements.enumerated()), id: \.offset) { i, req in
                        requirementChip(i, req)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(radius: 28, padding: 18)
    }

    private func requirementChip(_ i: Int, _ req: String) -> some View {
        let shown = i < revealed
        let ok = results[i]
        let color: Color = !shown || ok == nil ? Palette.ink2 : (ok! ? Palette.success : Palette.danger)
        return HStack(spacing: 6) {
            ZStack {
                Circle().fill(!shown || ok == nil ? Palette.canvasDeep : (ok! ? Palette.success : Palette.danger))
                    .frame(width: 20, height: 20)
                if shown, let ok {
                    Image(systemName: ok ? "checkmark" : "xmark")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            Text(req)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(color)
        }
        .padding(.leading, 6)
        .padding(.trailing, 11)
        .padding(.vertical, 6)
        .background((shown && ok != nil ? (ok! ? Palette.successSoft : Palette.dangerSoft) : Palette.canvas), in: .capsule)
        .scaleEffect(shown && ok != nil ? 1.0 : 0.98)
        .animation(.spring(response: 0.35, dampingFraction: 0.55), value: shown)
    }

    private var languageColor: Color {
        switch language {
        case "css": Color(hex: 0x2F8FE0)
        case "js", "javascript": Color(hex: 0xC99A17)
        default: Palette.orange
        }
    }

    // MARK: Panes

    private var paneSwitcher: some View {
        HStack(spacing: 4) {
            ForEach(Pane.allCases, id: \.self) { p in
                Button {
                    Haptics.shared.tick()
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { pane = p }
                } label: {
                    Label(p.rawValue, systemImage: p == .code ? "chevron.left.forwardslash.chevron.right" : "safari")
                        .font(.body(15, weight: .bold))
                        .foregroundStyle(pane == p ? .white : Palette.ink2)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background {
                            if pane == p {
                                Capsule().fill(Palette.ink).matchedGeometryEffect(id: "pane", in: paneNS)
                            }
                        }
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .glassEffect(.regular, in: .capsule)
    }

    private var editorCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                ForEach([Palette.danger, Palette.gold, Palette.success], id: \.self) { c in
                    Circle().fill(c).frame(width: 10, height: 10)
                }
                Text("index.\(language == "javascript" ? "js" : language)")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.leading, 8)
                Spacer()
                Button {
                    Haptics.shared.tap()
                    code = module.starterCode ?? ""
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Reset code")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(Color.white.opacity(0.05))

            RealCodeEditor(code: $code, language: language, editable: !session.isResolved)
                .frame(height: 280)
        }
        .background(Color(uiColor: RealSyntax.background), in: .rect(cornerRadius: 26, style: .continuous))
        .clipShape(.rect(cornerRadius: 26, style: .continuous))
        .shadow(color: Color(hex: 0x1A1D2E, alpha: 0.25), radius: 20, y: 10)
    }

    private var previewCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill").font(.system(size: 10, weight: .bold))
                Text("my-first-page.ilo")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Image(systemName: "arrow.clockwise").font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(Palette.muted)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Palette.canvas, in: .capsule)
            .padding(10)

            RealWebPreview(code: code, language: language)
                .frame(height: 262)
        }
        .background(.white, in: .rect(cornerRadius: 26, style: .continuous))
        .clipShape(.rect(cornerRadius: 26, style: .continuous))
        .shadow(color: Color(hex: 0x3A4470, alpha: 0.1), radius: 20, y: 10)
    }

    // MARK: Checking

    private func setup() {
        visible = true
        if code.isEmpty { code = module.starterCode ?? "" }
        session.hidesCheckBar = false
        session.checkTitle = "Run & check"
        session.mood = .attentive
        session.canCheck = !code.realTrimmed.isEmpty
        session.onCheck = { Task { await check() } }
    }

    private func check() async {
        guard !checking else { return }
        checking = true
        session.canCheck = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        let lower = code.lowercased()
        var newResults: [Int: Bool] = [:]
        for (i, req) in requirements.enumerated() {
            newResults[i] = lower.contains(req.lowercased())
        }
        results = newResults
        revealed = 0
        session.mood = .curious
        for i in requirements.indices {
            try? await Task.sleep(for: .seconds(0.22))
            withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) { revealed = i + 1 }
            if newResults[i] == true { Haptics.shared.tick(); SoundFX.shared.play(.pop) } else { Haptics.shared.softTap() }
        }
        try? await Task.sleep(for: .seconds(0.3))
        let allPass = newResults.values.allSatisfy { $0 } && !requirements.isEmpty
        checking = false

        if allPass {
            if usedSolution {
                session.resolve(correct: false, feedback: "You used the solution this time — read it line by line, then try it from memory next time.",
                                correctAnswer: nil)
            } else {
                withAnimation(.spring) { pane = .preview }
                session.resolve(correct: true, feedback: module.explanation ?? "Your code works — look at it run!")
            }
        } else {
            attempts += 1
            withAnimation(.linear(duration: 0.45)) { shake += 1 }
            let missing = requirements.enumerated().filter { newResults[$0.offset] == false }.map(\.element)
            if attempts >= 3 {
                session.resolve(correct: false, feedback: "Missing: \(missing.joined(separator: ", ")).", correctAnswer: module.solution)
            } else {
                Haptics.shared.wrong()
                SoundFX.shared.play(.wrong)
                session.mood = .confused
                session.canCheck = true
            }
        }
    }
}

/// Simple wrapping layout for chips.
struct RealFlowRows: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0, maxX: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > width { x = 0; y += rowH + spacing; rowH = 0 }
            x += size.width + spacing
            rowH = max(rowH, size.height)
            maxX = max(maxX, x - spacing)
        }
        return CGSize(width: min(width, maxX), height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX { x = bounds.minX; y += rowH + spacing; rowH = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowH = max(rowH, size.height)
        }
    }
}
