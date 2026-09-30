import Foundation
import Security

/// The learner's own Anthropic API key ("bring your own Claude"), stored in the Keychain on this device only.
/// ilo never sends it anywhere except api.anthropic.com.
enum AnthropicKeyStore {
    private static let service = "app.ilo.learn.anthropic"
    private static let account = "api-key"

    static var key: String? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: account,
                                    kSecReturnData as String: true,
                                    kSecMatchLimit as String: kSecMatchLimitOne]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data, let key = String(data: data, encoding: .utf8), !key.isEmpty else { return nil }
        return key
    }

    static var isConnected: Bool { key != nil }

    static func save(_ key: String) {
        remove()
        let item: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                   kSecAttrService as String: service,
                                   kSecAttrAccount as String: account,
                                   kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                                   kSecValueData as String: Data(key.utf8)]
        SecItemAdd(item as CFDictionary, nil)
    }

    static func remove() {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: account]
        SecItemDelete(query as CFDictionary)
    }

    /// "sk-ant-…a1B2" — safe to show in Settings.
    static var maskedKey: String? {
        guard let key else { return nil }
        return "\(key.prefix(7))…\(key.suffix(4))"
    }
}

/// Minimal Claude Messages API client over raw HTTP (Swift has no official Anthropic SDK).
struct AnthropicClient: Sendable {
    let apiKey: String
    static let model = "claude-opus-5-5"
    private static let base = URL(string: "https://api.anthropic.com/v1")!

    enum Failure: LocalizedError {
        case invalidKey
        case noCredit
        case rateLimited
        case refused
        case http(Int, String)
        case malformed

        var errorDescription: String? {
            switch self {
            case .invalidKey: "That key doesn't work. Check it on console.anthropic.com."
            case .noCredit: "Your Anthropic account is out of credit."
            case .rateLimited: "Claude is busy right now. Try again in a moment."
            case .refused: "Claude declined this request."
            case .http(let code, let message): "Claude error \(code): \(message)"
            case .malformed: "Claude sent something ilo couldn't read."
            }
        }
    }

    /// Checks the key with a free Models API call.
    static func validate(_ key: String) async throws {
        var request = URLRequest(url: base.appending(path: "models"))
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 20
        let (data, response) = try await URLSession.shared.data(for: request)
        try check(response, data)
    }

    /// Result of one (possibly multi-hop) Messages call.
    struct Reply: Sendable {
        var text: String
        var sources: [CourseSource]
    }

    /// Sends a Messages request. Handles `pause_turn` (server tools) by continuing the turn, and refusals.
    /// - Parameters:
    ///   - effort: output_config.effort (Claude Opus 5.5 defaults to medium; we always set it explicitly).
    ///   - schema: optional JSON schema for structured outputs (`output_config.format`).
    ///   - webSearch: enables Anthropic's server-side web search tool.
    func send(system: String, messages: [[String: Any]], effort: String, maxTokens: Int = 16000,
              schema: [String: Any]? = nil, webSearch: Int = 0, timeout: TimeInterval = 180) async throws -> Reply {
        var conversation = messages
        var texts: [String] = []
        var sources: [CourseSource] = []
        for _ in 0..<4 {
            var outputConfig: [String: Any] = ["effort": effort]
            if let schema { outputConfig["format"] = ["type": "json_schema", "schema": schema] }
            var body: [String: Any] = [
                "model": Self.model,
                "max_tokens": maxTokens,
                "system": system,
                "messages": conversation,
                "output_config": outputConfig,
                // Server-side refusal fallback, routed by category.
                "fallbacks": "default",
            ]
            if webSearch > 0 {
                body["tools"] = [["type": "web_search_20260209", "name": "web_search", "max_uses": webSearch]]
            }
            var request = URLRequest(url: Self.base.appending(path: "messages"))
            request.httpMethod = "POST"
            request.timeoutInterval = timeout
            request.setValue("application/json", forHTTPHeaderField: "content-type")
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            request.setValue("server-side-fallback-2026-07-01", forHTTPHeaderField: "anthropic-beta")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)
            try Self.check(response, data)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let content = json["content"] as? [[String: Any]] else { throw Failure.malformed }

            for block in content {
                switch block["type"] as? String {
                case "text":
                    if let text = block["text"] as? String { texts.append(text) }
                case "web_search_tool_result":
                    // Success → a list of results; error → a single object.
                    for result in block["content"] as? [[String: Any]] ?? [] {
                        if let url = result["url"] as? String, let title = result["title"] as? String,
                           !sources.contains(where: { $0.url == url }) {
                            sources.append(CourseSource(title: title, url: url))
                        }
                    }
                default:
                    break
                }
            }

            switch json["stop_reason"] as? String {
            case "refusal":
                throw Failure.refused
            case "pause_turn":
                // A long server-tool turn paused: send the partial assistant turn back to let Claude continue.
                conversation.append(["role": "assistant", "content": content])
                continue
            default:
                return Reply(text: texts.joined(separator: "\n"), sources: sources)
            }
        }
        return Reply(text: texts.joined(separator: "\n"), sources: sources)
    }

    private static func check(_ response: URLResponse, _ data: Data) throws {
        guard let http = response as? HTTPURLResponse else { throw Failure.malformed }
        guard !(200..<300).contains(http.statusCode) else { return }
        let message = ((try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? [String: Any])?["message"] as? String
        switch http.statusCode {
        case 401, 403: throw Failure.invalidKey
        case 429: throw Failure.rateLimited
        case 400 where (message ?? "").localizedCaseInsensitiveContains("credit"): throw Failure.noCredit
        default: throw Failure.http(http.statusCode, message ?? "unknown error")
        }
    }
}

extension String {
    /// The outermost JSON object in a model reply (tolerates stray prose or code fences).
    var jsonObjectSlice: Data? {
        guard let start = firstIndex(of: "{"), let end = lastIndex(of: "}"), start < end else { return nil }
        return String(self[start...end]).data(using: .utf8)
    }
}
