import SwiftUI
import UIKit
import WebKit

// MARK: - Syntax highlighting

/// Tiny regex highlighter for html / css / js (dark editor theme).
enum RealSyntax {
    static let background = UIColor(red: 0.08, green: 0.085, blue: 0.11, alpha: 1)
    static let plain = UIColor(red: 0.91, green: 0.92, blue: 0.95, alpha: 1)
    static let tag = UIColor(red: 0.56, green: 0.66, blue: 0.97, alpha: 1)      // periwinkle
    static let attribute = UIColor(red: 0.96, green: 0.70, blue: 0.48, alpha: 1) // peach
    static let string = UIColor(red: 0.49, green: 0.88, blue: 0.66, alpha: 1)    // mint
    static let keyword = UIColor(red: 0.88, green: 0.61, blue: 0.94, alpha: 1)   // orchid
    static let number = UIColor(red: 1.0, green: 0.80, blue: 0.35, alpha: 1)     // gold
    static let comment = UIColor(red: 0.45, green: 0.47, blue: 0.56, alpha: 1)

    static let font = UIFont.monospacedSystemFont(ofSize: 15, weight: .medium)

    private struct Rule { let regex: NSRegularExpression; let color: UIColor; let group: Int }

    private static func rule(_ pattern: String, _ color: UIColor, group: Int = 0, options: NSRegularExpression.Options = []) -> Rule {
        Rule(regex: try! NSRegularExpression(pattern: pattern, options: options), color: color, group: group)
    }

    private static let htmlRules: [Rule] = [
        rule(#"</?[a-zA-Z][\w-]*|/?>"#, tag),
        rule(#"\s([a-zA-Z_:][\w:.-]*)\s*="#, attribute, group: 1),
        rule(#""[^"\n]*"|'[^'\n]*'"#, string),
        rule(#"<!--[\s\S]*?-->"#, comment),
    ]

    private static let cssRules: [Rule] = [
        rule(#"(^|\})\s*([^{}]+?)\s*(?=\{)"#, tag, group: 2, options: [.anchorsMatchLines]),
        rule(#"([a-zA-Z-]+)\s*:"#, attribute, group: 1),
        rule(#"#[0-9a-fA-F]{3,8}\b|\b\d+(\.\d+)?(px|rem|em|%|s|vh|vw)?\b"#, number),
        rule(#""[^"\n]*"|'[^'\n]*'"#, string),
        rule(#"/\*[\s\S]*?\*/"#, comment),
    ]

    private static let jsRules: [Rule] = [
        rule(#"\b(const|let|var|function|return|if|else|for|while|of|in|new|class|true|false|null|undefined|await|async|=>)\b"#, keyword),
        rule(#"\b(document|console|window|Math|JSON)\b"#, tag),
        rule(#"\b\d+(\.\d+)?\b"#, number),
        rule(#""[^"\n]*"|'[^'\n]*'|`[^`]*`"#, string),
        rule(#"//[^\n]*|/\*[\s\S]*?\*/"#, comment),
    ]

    static func rules(for language: String) -> [(NSRegularExpression, UIColor, Int)] {
        let list: [Rule]
        switch language.lowercased() {
        case "css": list = cssRules
        case "js", "javascript": list = jsRules
        default: list = htmlRules
        }
        return list.map { ($0.regex, $0.color, $0.group) }
    }

    static func highlight(_ storage: NSTextStorage, language: String) {
        let full = NSRange(location: 0, length: storage.length)
        storage.beginEditing()
        storage.setAttributes([.font: font, .foregroundColor: plain], range: full)
        let text = storage.string
        for (regex, color, group) in rules(for: language) {
            regex.enumerateMatches(in: text, range: full) { match, _, _ in
                guard let match else { return }
                let r = match.range(at: group)
                if r.location != NSNotFound { storage.addAttribute(.foregroundColor, value: color, range: r) }
            }
        }
        storage.endEditing()
    }
}

// MARK: - Editor

/// Monospaced code editor (UITextView) with live highlighting and a symbol accessory row.
struct RealCodeEditor: UIViewRepresentable {
    @Binding var code: String
    var language: String
    var editable = true

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.backgroundColor = .clear
        tv.font = RealSyntax.font
        tv.textColor = RealSyntax.plain
        tv.tintColor = RealSyntax.tag
        tv.autocorrectionType = .no
        tv.autocapitalizationType = .none
        tv.smartQuotesType = .no
        tv.smartDashesType = .no
        tv.smartInsertDeleteType = .no
        tv.spellCheckingType = .no
        tv.keyboardAppearance = .dark
        tv.keyboardType = .asciiCapable
        tv.textContainerInset = UIEdgeInsets(top: 14, left: 10, bottom: 14, right: 10)
        tv.alwaysBounceVertical = true
        tv.delegate = context.coordinator
        tv.text = code
        RealSyntax.highlight(tv.textStorage, language: language)
        context.coordinator.textView = tv

        let host = UIHostingController(rootView: RealSymbolRow { symbol in context.coordinator.insert(symbol) })
        host.view.backgroundColor = .clear
        host.view.frame = CGRect(x: 0, y: 0, width: 400, height: 52)
        host.view.autoresizingMask = [.flexibleWidth]
        host.sizingOptions = []
        tv.inputAccessoryView = host.view
        context.coordinator.accessoryHost = host
        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        context.coordinator.parent = self
        tv.isEditable = editable
        if tv.text != code {
            tv.text = code
            RealSyntax.highlight(tv.textStorage, language: language)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    @MainActor
    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: RealCodeEditor
        weak var textView: UITextView?
        var accessoryHost: UIHostingController<RealSymbolRow>?

        init(parent: RealCodeEditor) { self.parent = parent }

        func textViewDidChange(_ tv: UITextView) {
            let selected = tv.selectedRange
            RealSyntax.highlight(tv.textStorage, language: parent.language)
            tv.selectedRange = selected
            tv.typingAttributes = [.font: RealSyntax.font, .foregroundColor: RealSyntax.plain]
            parent.code = tv.text
        }

        func textView(_ tv: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            // Keep indentation on new lines.
            guard text == "\n" else { return true }
            let ns = tv.text as NSString
            let lineStart = ns.lineRange(for: NSRange(location: range.location, length: 0)).location
            let line = ns.substring(with: NSRange(location: lineStart, length: range.location - lineStart))
            let indent = String(line.prefix { $0 == " " || $0 == "\t" })
            tv.insertText("\n" + indent)
            return false
        }

        func insert(_ symbol: String) {
            guard let tv = textView else { return }
            Haptics.shared.tick()
            tv.insertText(symbol)
        }
    }
}

/// Keyboard accessory row with the symbols that are painful to type on iOS.
struct RealSymbolRow: View {
    var onInsert: (String) -> Void
    private let symbols = ["<", ">", "/", "=", "\"", "{", "}", ";", ":", "(", ")", "'", "#", "."]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(symbols, id: \.self) { s in
                    Button { onInsert(s) } label: {
                        Text(s)
                            .font(.system(size: 18, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Palette.ink)
                            .frame(minWidth: 38, minHeight: 38)
                            .background(.white, in: .rect(cornerRadius: 10, style: .continuous))
                            .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
                    }
                    .buttonStyle(.squish(0.9))
                }
                Button { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) } label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                        .frame(width: 44, height: 38)
                        .background(Palette.periwinkleSoft, in: .rect(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
        }
        .background(Color(hex: 0xD6D9E2))
    }
}

// MARK: - Preview

/// Live WKWebView preview of the learner's code.
struct RealWebPreview: UIViewRepresentable {
    var code: String
    var language: String

    func makeUIView(context: Context) -> WKWebView {
        let web = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        web.isOpaque = false
        web.backgroundColor = .white
        web.scrollView.backgroundColor = .white
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {
        let html = Self.document(code: code, language: language)
        guard context.coordinator.lastHTML != html else { return }
        context.coordinator.lastHTML = html
        web.loadHTMLString(html, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator { var lastHTML = "" }

    static func document(code: String, language: String) -> String {
        let head = """
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
        body { font-family: -apple-system, system-ui; margin: 18px; color: #0A0A0C; }
        button { font: inherit; }
        #ilo-console { font-family: ui-monospace, Menlo; font-size: 14px; background: #F3F4F8; border-radius: 12px; padding: 12px; white-space: pre-wrap; margin-top: 14px; }
        #ilo-console:empty::before { content: 'Console output appears here'; color: #A6AABB; }
        </style>
        """
        switch language.lowercased() {
        case "css":
            return """
            <html><head>\(head)<style>\(code)</style></head><body>
            <h1>Hello, ilo!</h1>
            <p>This is a paragraph with a <a href="#">link</a>.</p>
            <div class="box card">A box</div>
            <button class="button btn">Button</button>
            <ul><li>One</li><li>Two</li></ul>
            </body></html>
            """
        case "js", "javascript":
            return """
            <html><head>\(head)</head><body>
            <div id="app"></div>
            <div id="ilo-console"></div>
            <script>
            (function(){ const out = document.getElementById('ilo-console');
              const log = (...a) => { out.textContent += a.map(x => typeof x === 'object' ? JSON.stringify(x) : String(x)).join(' ') + '\\n'; };
              console.log = log; console.error = log;
              window.onerror = (m) => { log('⚠️ ' + m); };
            })();
            </script>
            <script>\(code)</script>
            </body></html>
            """
        case "html", "htm", "":
            return "<html><head>\(head)</head><body>\(code)</body></html>"
        default:
            // Python / Swift / … can't run in a web view: show the code plus what its literal prints would output,
            // instead of dumping the source into an HTML body as if it were markup.
            let output = printedLines(in: code).map(escape).joined(separator: "\n")
            return """
            <html><head>\(head)</head><body>
            <pre style="font-family: ui-monospace, Menlo; font-size: 14px; white-space: pre-wrap; margin: 0;">\(escape(code))</pre>
            <div id="ilo-console">\(output)</div>
            </body></html>
            """
        }
    }

    private static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    /// String literals passed to print(…) / console.log(…) — a friendly stand-in for running the program.
    private static func printedLines(in code: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: #"(?:print|console\.log|println)\s*\(\s*f?(["'])(.*?)\1\s*\)"#) else { return [] }
        let ns = code as NSString
        return regex.matches(in: code, range: NSRange(location: 0, length: ns.length)).compactMap { match in
            match.numberOfRanges > 2 ? ns.substring(with: match.range(at: 2)) : nil
        }
    }
}
