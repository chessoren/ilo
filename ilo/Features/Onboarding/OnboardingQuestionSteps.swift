import SwiftUI

/// Shared feedback for a selection.
@MainActor
private func selectFeedback(_ answers: OnboardingAnswers) {
    Haptics.shared.tick()
    SoundFX.shared.play(.pop)
    answers.react()
}

// MARK: - Goal

struct OBGoalStep: View {
    @Bindable var answers: OnboardingAnswers
    var onSubmit: () -> Void

    @FocusState private var focused: Bool
    @State private var placeholder = ""
    @State private var visible = false
    @State private var filling: Task<Void, Never>?

    private struct Suggestion: Identifiable {
        var id: String { text }
        var text: String
        var symbol: String
    }

    private let suggestions: [Suggestion] = [
        .init(text: "Salsa for my grandma's wedding", symbol: "figure.dance"),
        .init(text: "Code my first website", symbol: "chevron.left.forwardslash.chevron.right"),
        .init(text: "Atomic Habits", symbol: "books.vertical.fill"),
        .init(text: "Chess openings", symbol: "crown.fill"),
        .init(text: "Public speaking", symbol: "music.mic"),
        .init(text: "Japanese for my trip", symbol: "airplane"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                field
                    .appear(visible, delay: 0.05)
                Text("Need a spark?")
                    .font(.body(14, weight: .semibold))
                    .foregroundStyle(Palette.muted)
                    .appear(visible, delay: 0.12)
                OBFlowLayout(spacing: 8, lineSpacing: 10) {
                    ForEach(Array(suggestions.enumerated()), id: \.element.id) { i, s in
                        OBChip(title: s.text, symbol: s.symbol, selected: answers.trimmedGoal == s.text) { fill(s.text) }
                            .appear(visible, delay: 0.15 + Double(i) * 0.05)
                    }
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.top, 20)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .onAppear { visible = true }
        .task { await runPlaceholder() }
        .onChange(of: answers.goal) { old, new in
            // A vertical-axis TextField inserts "\n" on Return instead of calling onSubmit: treat it as submit.
            if new.contains("\n") {
                answers.goal = new.replacingOccurrences(of: "\n", with: "")
                focused = false
                onSubmit()
                return
            }
            if new.count > old.count, new.count % 3 == 0 { Haptics.shared.tick() }
            if old.isEmpty != new.isEmpty { answers.react() }
        }
    }

    private var field: some View {
        ZStack(alignment: .topLeading) {
            if answers.goal.isEmpty {
                HStack(spacing: 0) {
                    Text(placeholder)
                    Rectangle().frame(width: 2.5, height: 26).opacity(focused ? 0 : 0.5)
                }
                .font(.display(24, weight: .bold))
                .foregroundStyle(Palette.faint)
                .allowsHitTesting(false)
            }
            TextField("", text: $answers.goal, axis: .vertical)
                .font(.display(24, weight: .bold))
                .foregroundStyle(Palette.ink)
                .lineLimit(1...3)
                .focused($focused)
                .submitLabel(.done)
                .onSubmit { focused = false; onSubmit() }
                .textInputAutocapitalization(.sentences)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
        .glassEffect(.regular.tint(.white.opacity(0.55)).interactive(), in: .rect(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(focused ? Palette.periwinkleDeep : .clear, lineWidth: 2)
        }
        .overlay(alignment: .bottomTrailing) {
            if !answers.goal.isEmpty {
                Button {
                    Haptics.shared.tap()
                    answers.goal = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Palette.faint)
                }
                .padding(14)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.smooth, value: focused)
        .animation(.spring, value: answers.goal.isEmpty)
        .onTapGesture { focused = true }
    }

    private func fill(_ text: String) {
        filling?.cancel()
        selectFeedback(answers)
        focused = false
        filling = Task {
            answers.goal = ""
            for ch in text {
                try? await Task.sleep(for: .milliseconds(18))
                if Task.isCancelled { return }
                answers.goal.append(ch)
            }
        }
    }

    private func runPlaceholder() async {
        var i = 0
        while !Task.isCancelled {
            let target = "e.g. " + suggestions[i % suggestions.count].text.lowercased()
            for ch in target {
                try? await Task.sleep(for: .milliseconds(45))
                placeholder.append(ch)
            }
            try? await Task.sleep(for: .seconds(1.4))
            while !placeholder.isEmpty && !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(18))
                placeholder.removeLast()
            }
            i += 1
        }
    }
}

// MARK: - Why

struct OBWhyStep: View {
    @Bindable var answers: OnboardingAnswers
    @State private var visible = false

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(Array(OnboardingMotivation.all.enumerated()), id: \.element.id) { i, m in
                    tile(m).appear(visible, delay: 0.05 + Double(i) * 0.05)
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.vertical, 20)
        }
        .scrollIndicators(.hidden)
        .onAppear { visible = true }
    }

    private func tile(_ m: OnboardingMotivation) -> some View {
        let selected = answers.motivation == m
        return Button {
            answers.motivation = m
            selectFeedback(answers)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Image(systemName: m.symbol)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(selected ? .white : m.tint.deep)
                    .frame(width: 48, height: 48)
                    .background(selected ? m.tint.deep : .white, in: .circle)
                    .symbolEffect(.bounce, value: selected)
                Spacer(minLength: 16)
                Text(m.title)
                    .font(.display(18, weight: .bold))
                    .foregroundStyle(Palette.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 138, alignment: .topLeading)
            .background(m.tint.soft, in: .rect(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(selected ? Palette.ink : .clear, lineWidth: 2.5)
            }
            .overlay(alignment: .topTrailing) {
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Palette.ink, .white)
                        .padding(12)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .scaleEffect(selected ? 1.02 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selected)
        }
        .buttonStyle(.squish(0.95))
    }
}

// MARK: - Deadline

struct OBDeadlineStep: View {
    @Bindable var answers: OnboardingAnswers
    @State private var visible = false

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(Array(OnboardingDeadline.allCases.enumerated()), id: \.element) { i, option in
                    OBChoiceCard(title: option.title, detail: option.detail, symbol: option.symbol,
                                 tint: [.sky, .periwinkle, .mint, .butter, .orchid][i],
                                 selected: answers.deadline == option) {
                        answers.deadline = option
                        selectFeedback(answers)
                    } accessory: {
                        EmptyView()
                    }
                    .appear(visible, delay: 0.05 + Double(i) * 0.05)
                }
                if answers.deadline == .date {
                    HStack {
                        Image(systemName: "calendar.badge.clock").foregroundStyle(CourseTint.orchid.deep)
                        Text("The big day").font(.display(17, weight: .bold))
                        Spacer()
                        DatePicker("", selection: $answers.eventDate, in: Date.now.addingTimeInterval(86_400)..., displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                    }
                    .card(CourseTint.orchid.soft, radius: 24, padding: 14)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onChange(of: answers.eventDate) { Haptics.shared.tick(); answers.react() }
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.vertical, 20)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: answers.deadline)
        }
        .scrollIndicators(.hidden)
        .onAppear { visible = true }
    }
}

// MARK: - Level

struct OBLevelStep: View {
    @Bindable var answers: OnboardingAnswers
    @State private var visible = false

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(Array(LearnerLevel.allCases.enumerated()), id: \.element) { i, level in
                    OBChoiceCard(title: level.title, detail: level.detail, symbol: "cellularbars",
                                 tint: [.mint, .sky, .periwinkle, .orchid][i],
                                 variable: Double(i + 1) / 4,
                                 selected: answers.level == level) {
                        answers.level = level
                        selectFeedback(answers)
                    }
                    .appear(visible, delay: 0.05 + Double(i) * 0.06)
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.vertical, 20)
        }
        .scrollIndicators(.hidden)
        .onAppear { visible = true }
    }
}

// MARK: - Styles

struct OBStylesStep: View {
    @Bindable var answers: OnboardingAnswers
    @State private var visible = false

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(Array(OnboardingStyle.all.enumerated()), id: \.element.id) { i, style in
                    tile(style).appear(visible, delay: 0.04 + Double(i) * 0.04)
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.vertical, 20)
        }
        .scrollIndicators(.hidden)
        .onAppear { visible = true }
    }

    private func tile(_ style: OnboardingStyle) -> some View {
        let selected = answers.styles.contains(style.id)
        return Button {
            if selected { answers.styles.remove(style.id) } else { answers.styles.insert(style.id) }
            selectFeedback(answers)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: style.symbol)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(selected ? .white : style.tint.deep)
                    .frame(width: 38, height: 38)
                    .background(selected ? style.tint.deep : style.tint.soft, in: .rect(cornerRadius: 12, style: .continuous))
                    .symbolEffect(.bounce, value: selected)
                Text(style.title)
                    .font(.display(15.5, weight: .bold))
                    .foregroundStyle(Palette.ink)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
            .background(selected ? style.tint.soft : .white, in: .rect(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(selected ? Palette.ink : Palette.hairline, lineWidth: selected ? 2 : 1)
            }
            .shadow(color: Color(hex: 0x3A4470, alpha: 0.05), radius: 8, y: 4)
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: selected)
        }
        .buttonStyle(.squish(0.95))
    }
}

// MARK: - Minutes

struct OBMinutesStep: View {
    @Bindable var answers: OnboardingAnswers
    @State private var visible = false

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(Array(OnboardingPace.all.enumerated()), id: \.element) { i, pace in
                    OBChoiceCard(title: "\(pace.minutes) min a day", detail: pace.title,
                                 symbol: ["cup.and.saucer.fill", "figure.walk", "figure.run", "flame.fill"][i],
                                 tint: [.mint, .sky, .periwinkle, .orange][i],
                                 selected: answers.pace == pace) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { answers.pace = pace }
                        selectFeedback(answers)
                    } accessory: {
                        Text("+\(pace.xp) XP")
                            .font(.display(13, weight: .bold))
                            .foregroundStyle(Palette.muted)
                    }
                    .appear(visible, delay: 0.05 + Double(i) * 0.05)
                }
                projection
                    .padding(.top, 6)
                    .appear(visible, delay: 0.3)
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.vertical, 20)
        }
        .scrollIndicators(.hidden)
        .onAppear { visible = true }
    }

    private var projection: some View {
        let minutes = answers.pace?.minutes ?? 10
        let date = answers.projectedDate(minutes: minutes)
        let deadline = answers.deadlineDate
        let onTrack = deadline.map { date <= $0 } ?? true
        return HStack(spacing: 14) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(Palette.ink, in: .rect(cornerRadius: 17, style: .continuous))
                .symbolEffect(.bounce, value: minutes)
            VStack(alignment: .leading, spacing: 3) {
                Text(answers.pace == nil ? "At 10 min a day" : "At \(minutes) min a day")
                    .font(.body(13, weight: .semibold))
                    .foregroundStyle(Palette.muted)
                    .contentTransition(.numericText())
                Text("Ready by \(date.formatted(.dateTime.month(.abbreviated).day()))")
                    .font(.display(24, weight: .heavy))
                    .foregroundStyle(Palette.ink)
                    .contentTransition(.numericText())
                if let deadline {
                    Text(onTrack ? "Right on time for \(deadline.formatted(.dateTime.month(.abbreviated).day()))"
                                 : "Tight! I'll focus on the essentials for \(deadline.formatted(.dateTime.month(.abbreviated).day())).")
                        .font(.body(13, weight: .medium))
                        .foregroundStyle(onTrack ? Palette.success : Palette.orange)
                        .contentTransition(.opacity)
                }
            }
            Spacer(minLength: 0)
        }
        .card(.white, radius: 26, padding: 16)
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: minutes)
    }
}

// MARK: - Name

struct OBNameStep: View {
    @Bindable var answers: OnboardingAnswers
    var onSubmit: () -> Void
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 14) {
            TextField("", text: $answers.name, prompt: Text("Your name").foregroundStyle(Palette.faint))
                .font(.display(38, weight: .heavy))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
                .textContentType(.givenName)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.continue)
                .focused($focused)
                .onSubmit(onSubmit)
                .padding(.vertical, 22)
                .padding(.horizontal, 18)
                .glassEffect(.regular.tint(.white.opacity(0.55)).interactive(), in: .rect(cornerRadius: 30, style: .continuous))
            Text("This is how ilo will cheer for you.")
                .font(.body(14, weight: .medium))
                .foregroundStyle(Palette.muted)
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.top, 28)
        .onChange(of: answers.name) { old, new in
            if new.count > old.count { Haptics.shared.tick(); SoundFX.shared.play(.tick) }
            if old.isEmpty != new.isEmpty { answers.react() }
        }
        .task {
            try? await Task.sleep(for: .milliseconds(450))
            focused = true
        }
    }
}
