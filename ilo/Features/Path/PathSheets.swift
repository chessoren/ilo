import SwiftUI

/// Unit guidebook: outcome + every node's brief.
struct GuidebookSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let course: Course
    let unit: CourseUnit
    @State private var shown = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Guidebook").font(.body(13, weight: .bold)).foregroundStyle(.white.opacity(0.85))
                        Text(unit.title).font(.display(28, weight: .heavy)).foregroundStyle(.white)
                        Label(unit.outcome, systemImage: "target")
                            .font(.body(15, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(22)
                    .background(unit.tint.base.gradient, in: .rect(cornerRadius: 30, style: .continuous))
                    .appear(shown)

                    ForEach(Array(unit.nodes.enumerated()), id: \.element.id) { i, node in
                        let state = model.state(of: node, in: course)
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: state == .completed ? "checkmark" : node.kind.defaultSymbol)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(state == .locked ? Palette.faint : .white)
                                .frame(width: 40, height: 40)
                                .background(state == .locked ? Palette.canvasDeep : unit.tint.base, in: .circle)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(node.title).font(.display(16, weight: .bold))
                                    Spacer()
                                    Text(node.kind.label).font(.body(11, weight: .bold)).foregroundStyle(unit.tint.deep)
                                }
                                Text(node.brief).font(.body(14)).foregroundStyle(Palette.ink2.opacity(0.8))
                            }
                        }
                        .card(radius: 22, padding: 14)
                        .appear(shown, delay: 0.05 + Double(i) * 0.04)
                    }
                }
                .padding(Metrics.gutter)
            }
            .background(Palette.canvas)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                }
            }
        }
        .onAppear { shown = true }
    }
}

/// Where ilo's research came from.
struct SourcesSheet: View {
    @Environment(\.dismiss) private var dismiss
    let course: Course

    var body: some View {
        NavigationStack {
            Group {
                if course.sources.isEmpty {
                    VStack(spacing: 14) {
                        BloubView(shape: .circle, color: .ilo, expression: .shy).frame(width: 100)
                        Text("No sources for this path").font(.display(20, weight: .bold))
                        Text("ilo built it from its own knowledge.").font(.body(15)).foregroundStyle(Palette.muted)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(course.sources) { source in
                        if let url = URL(string: source.url) {
                            Link(destination: url) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(source.title).font(.body(15, weight: .semibold)).foregroundStyle(Palette.ink)
                                    Text(url.host() ?? source.url).font(.body(12)).foregroundStyle(Palette.muted)
                                }
                            }
                        } else {
                            Text(source.title)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Palette.canvas)
            .navigationTitle("Sources")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                }
            }
        }
    }
}
