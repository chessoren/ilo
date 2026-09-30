import Foundation
import UIKit

/// JSON shapes exchanged with the `ilo-ai` edge function (and produced by the on-device model).
/// Decoding is lenient: missing ids, unknown enum values and bad SF Symbols are repaired instead of failing.
enum Wire {
    struct CourseDTO: Decodable, Sendable {
        var title: String
        var tagline: String
        var symbol: String
        var tint: String
        var category: String
        var units: [UnitDTO]
        var sources: [SourceDTO]

        enum CodingKeys: String, CodingKey { case title, tagline, symbol, tint, category, units, sources }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            title = (try? c.decode(String.self, forKey: .title)) ?? "Your path"
            tagline = (try? c.decode(String.self, forKey: .tagline)) ?? "Built by ilo, just for you"
            symbol = (try? c.decode(String.self, forKey: .symbol)) ?? "sparkles"
            tint = (try? c.decode(String.self, forKey: .tint)) ?? "periwinkle"
            category = (try? c.decode(String.self, forKey: .category)) ?? "skill"
            units = (try? c.decode([UnitDTO].self, forKey: .units)) ?? []
            sources = (try? c.decode([SourceDTO].self, forKey: .sources)) ?? []
        }
    }

    struct UnitDTO: Decodable, Sendable {
        var title: String
        var outcome: String
        var tint: String?
        var nodes: [NodeDTO]

        enum CodingKeys: String, CodingKey { case title, outcome, tint, nodes }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            title = (try? c.decode(String.self, forKey: .title)) ?? "Unit"
            outcome = (try? c.decode(String.self, forKey: .outcome)) ?? ""
            tint = try? c.decode(String.self, forKey: .tint)
            nodes = (try? c.decode([NodeDTO].self, forKey: .nodes)) ?? []
        }
    }

    struct NodeDTO: Decodable, Sendable {
        var title: String
        var brief: String
        var kind: String
        var symbol: String?

        enum CodingKeys: String, CodingKey { case title, brief, kind, symbol }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            title = (try? c.decode(String.self, forKey: .title)) ?? "Lesson"
            brief = (try? c.decode(String.self, forKey: .brief)) ?? ""
            kind = (try? c.decode(String.self, forKey: .kind)) ?? "lesson"
            symbol = try? c.decode(String.self, forKey: .symbol)
        }
    }

    struct SourceDTO: Decodable, Sendable {
        var title: String
        var url: String
        enum CodingKeys: String, CodingKey { case title, url }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            url = (try? c.decode(String.self, forKey: .url)) ?? ""
            title = (try? c.decode(String.self, forKey: .title)) ?? url
        }
    }

    struct LessonDTO: Decodable, Sendable {
        var title: String?
        var intro: String?
        /// Each module decodes on its own so one bad module doesn't sink the lesson.
        var modules: [LessonModule]
        var takeaways: [String]

        enum CodingKeys: String, CodingKey { case title, intro, modules, takeaways }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            title = try? c.decode(String.self, forKey: .title)
            intro = try? c.decode(String.self, forKey: .intro)
            takeaways = (try? c.decode([String].self, forKey: .takeaways)) ?? []
            modules = ((try? c.decode([Lossy<LessonModule>].self, forKey: .modules)) ?? []).compactMap(\.value)
        }
    }

    /// Decodes a value or nil without throwing.
    struct Lossy<T: Decodable & Sendable>: Decodable, Sendable {
        var value: T?
        init(from decoder: Decoder) throws { value = try? T(from: decoder) }
    }

    struct GradeDTO: Decodable, Sendable {
        var score: Double
        var passed: Bool?
        var feedback: String?
        var improved: String?
    }

    struct ChatDTO: Decodable, Sendable { var reply: String }

    struct ErrorDTO: Decodable, Sendable { var error: String }

    struct StepDTO: Decodable, Sendable {
        var phase: String
        var text: String
        var detail: String?
    }
}

// MARK: - Conversion to app models

extension Wire.CourseDTO {
    func course(for request: CourseRequest) -> Course {
        let courseTint = CourseTint(rawValue: tint) ?? .periwinkle
        let units = units.enumerated().compactMap { index, unit -> CourseUnit? in
            let nodes = unit.nodes.map { node -> PathNode in
                let kind = NodeKind(rawValue: node.kind) ?? .lesson
                return PathNode(title: node.title, brief: node.brief, kind: kind,
                                symbol: Sanitize.symbol(node.symbol, fallback: kind.defaultSymbol))
            }
            guard !nodes.isEmpty else { return nil }
            let tint = unit.tint.flatMap(CourseTint.init(rawValue:)) ?? CourseTint.allCases[index % CourseTint.allCases.count]
            return CourseUnit(title: unit.title, outcome: unit.outcome, tint: tint, nodes: nodes)
        }
        return Course(goal: request.goal, title: title, tagline: tagline,
                      symbol: Sanitize.symbol(symbol, fallback: "sparkles"), tint: courseTint,
                      category: CourseCategory(rawValue: category) ?? .skill, level: request.level,
                      motivation: request.motivation, deadline: request.deadline, dailyMinutes: request.dailyMinutes,
                      units: units,
                      sources: sources.filter { $0.url.hasPrefix("http") }.map { CourseSource(title: $0.title, url: $0.url) })
    }
}

extension Wire.LessonDTO {
    /// Keeps only playable modules; throws if none survive.
    func lesson(for node: PathNode, by author: String) throws -> Lesson {
        let playable = modules.filter(\.isValid).map(Sanitize.module)
        guard !playable.isEmpty else { throw AIError.badResponse("the lesson had no playable modules") }
        return Lesson(nodeID: node.id, title: title?.nilIfBlank ?? node.title,
                      intro: intro?.nilIfBlank ?? "Let's go — one small step at a time.",
                      modules: playable, takeaways: Array(takeaways.prefix(3)), generatedBy: author)
    }
}

enum Sanitize {
    /// Returns `name` if it is a real SF Symbol, else `fallback`.
    static func symbol(_ name: String?, fallback: String) -> String {
        guard let name, !name.isEmpty, UIImage(systemName: name) != nil else { return fallback }
        return name
    }

    /// Small fixes the UI relies on (valid card symbols, sane numbers).
    static func module(_ module: LessonModule) -> LessonModule {
        var m = module
        if let cards = m.cards {
            m.cards = cards.map { card in
                var card = card
                if let symbol = card.symbol, UIImage(systemName: symbol) == nil { card.symbol = nil }
                return card
            }
        }
        if m.type == .practiceTimer {
            m.bpm = min(max(m.bpm ?? 100, 30), 260)
            if m.beatsPerBar == nil { m.beatsPerBar = m.countLabels?.count ?? 4 }
        }
        if m.type == .speedRound, m.seconds == nil { m.seconds = 30 }
        if let lo = m.minValue, let hi = m.maxValue, lo > hi { m.minValue = hi; m.maxValue = lo }
        return m
    }
}

extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
