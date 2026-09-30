import Foundation
import Security

/// Tiny Supabase client (URLSession, no SDK): anonymous auth via GoTrue, edge-function calls (JSON + SSE) and PostgREST RPCs.
/// The session is stored in the Keychain and refreshed automatically.
actor SupabaseClient {
    static let shared = SupabaseClient()

    struct Session: Codable, Sendable {
        var accessToken: String
        var refreshToken: String
        var expiresAt: Date
        var userID: String
    }

    enum ClientError: LocalizedError {
        case notConfigured
        case http(Int, String)
        case auth(String)

        var errorDescription: String? {
            switch self {
            case .notConfigured: "The backend isn't configured."
            case .http(let code, let body): "Server error \(code): \(body.prefix(200))"
            case .auth(let why): "Sign-in failed: \(why)"
            }
        }

        var status: Int? { if case .http(let code, _) = self { code } else { nil } }
    }

    /// One server-sent event.
    struct Event: Sendable {
        var name: String
        var data: Data
    }

    private let baseURL: URL?
    private let anonKey: String?
    private let urlSession: URLSession
    private var session: Session?
    private var signingIn: Task<Session, Error>?

    init(baseURL: URL? = AppConfig.supabaseURL, anonKey: String? = AppConfig.supabaseAnonKey) {
        self.baseURL = baseURL
        self.anonKey = anonKey
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 180
        config.timeoutIntervalForResource = 240
        config.waitsForConnectivity = false
        self.urlSession = URLSession(configuration: config)
        self.session = Keychain.load(Session.self, account: Self.keychainAccount)
    }

    nonisolated var isConfigured: Bool { baseURL != nil && anonKey != nil }

    /// Supabase user id of this device's learner (use it as the RevenueCat app user id).
    var userID: String? { session?.userID }

    // MARK: - Auth

    /// Returns a valid access token, signing in anonymously or refreshing as needed.
    func accessToken() async throws -> String {
        try await validSession().accessToken
    }

    @discardableResult
    func validSession() async throws -> Session {
        if let session, session.expiresAt.timeIntervalSinceNow > 60 { return session }
        if let signingIn { return try await signingIn.value }
        let task = Task { () throws -> Session in
            if let current = self.session, let refreshed = try? await self.refresh(current) { return refreshed }
            return try await self.signInAnonymously()
        }
        signingIn = task
        defer { signingIn = nil }
        let fresh = try await task.value
        store(fresh)
        return fresh
    }

    private func signInAnonymously() async throws -> Session {
        // GoTrue: POST /auth/v1/signup with no email/phone creates an anonymous user (enable it in the dashboard).
        try await authRequest(path: "auth/v1/signup", body: ["data": [String: String]()])
    }

    private func refresh(_ current: Session) async throws -> Session {
        try await authRequest(path: "auth/v1/token", query: [URLQueryItem(name: "grant_type", value: "refresh_token")],
                              body: ["refresh_token": current.refreshToken])
    }

    private func authRequest(path: String, query: [URLQueryItem] = [], body: some Encodable) async throws -> Session {
        guard let baseURL, let anonKey else { throw ClientError.notConfigured }
        var components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: false)
        if !query.isEmpty { components?.queryItems = query }
        guard let url = components?.url else { throw ClientError.notConfigured }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await urlSession.data(for: request)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else {
            throw ClientError.auth("\(code) \(String(data: data, encoding: .utf8) ?? "")")
        }
        let wire = try JSONDecoder().decode(AuthWire.self, from: data)
        let expiry = wire.expires_at.map { Date(timeIntervalSince1970: $0) } ?? Date(timeIntervalSinceNow: wire.expires_in ?? 3600)
        let uid = wire.user?.id ?? Self.subject(fromJWT: wire.access_token) ?? ""
        return Session(accessToken: wire.access_token, refreshToken: wire.refresh_token, expiresAt: expiry, userID: uid)
    }

    private struct AuthWire: Decodable {
        struct User: Decodable { let id: String }
        let access_token: String
        let refresh_token: String
        let expires_in: Double?
        let expires_at: Double?
        let user: User?
    }

    private func store(_ session: Session) {
        self.session = session
        Keychain.save(session, account: Self.keychainAccount)
    }

    /// Forgets the session (Settings → Reset).
    func signOut() {
        session = nil
        Keychain.delete(account: Self.keychainAccount)
    }

    // MARK: - Edge functions

    /// POST /functions/v1/<name> with a JSON body; returns the raw response body.
    func invoke(function: String, body: some Encodable & Sendable, timeout: TimeInterval = 120) async throws -> Data {
        try await authorized { token in
            var request = try self.request(path: "functions/v1/\(function)", token: token, timeout: timeout)
            request.httpBody = try JSONEncoder.ilo.encode(body)
            return request
        } perform: { request in
            let (data, response) = try await self.urlSession.data(for: request)
            try Self.check(response, data)
            return data
        }
    }

    /// POST /functions/v1/<name> and read the reply as server-sent events.
    func stream(function: String, body: some Encodable & Sendable, onEvent: @escaping @Sendable (Event) async throws -> Void) async throws {
        try await authorized { token in
            var request = try self.request(path: "functions/v1/\(function)", token: token, timeout: 200)
            request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
            request.httpBody = try JSONEncoder.ilo.encode(body)
            return request
        } perform: { request in
            let (bytes, response) = try await self.urlSession.bytes(for: request)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                var body = Data()
                for try await byte in bytes.prefix(4000) { body.append(byte) }
                throw ClientError.http(http.statusCode, String(data: body, encoding: .utf8) ?? "")
            }
            var name = "message"
            var dataLines: [String] = []
            for try await line in bytes.lines {
                if line.hasPrefix("event:") {
                    name = line.dropFirst(6).trimmingCharacters(in: .whitespaces)
                } else if line.hasPrefix("data:") {
                    dataLines.append(String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces))
                    // `bytes.lines` drops blank separators, so dispatch on each complete data line.
                    try await onEvent(Event(name: name, data: Data(dataLines.joined(separator: "\n").utf8)))
                    dataLines = []
                    name = "message"
                }
            }
        }
    }

    // MARK: - PostgREST

    /// POST /rest/v1/rpc/<name>.
    func rpc(_ name: String, params: some Encodable & Sendable) async throws -> Data {
        try await authorized { token in
            var request = try self.request(path: "rest/v1/rpc/\(name)", token: token, timeout: 20)
            request.httpBody = try JSONEncoder.ilo.encode(params)
            return request
        } perform: { request in
            let (data, response) = try await self.urlSession.data(for: request)
            try Self.check(response, data)
            return data
        }
    }

    // MARK: - Plumbing

    nonisolated private func request(path: String, token: String, timeout: TimeInterval) throws -> URLRequest {
        guard let baseURL, let anonKey else { throw ClientError.notConfigured }
        var request = URLRequest(url: baseURL.appending(path: path), timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    /// Runs a request with a fresh token; on 401 it re-authenticates once and retries.
    private func authorized<T: Sendable>(_ build: @escaping @Sendable (String) async throws -> URLRequest,
                                         perform: @escaping @Sendable (URLRequest) async throws -> T) async throws -> T {
        guard isConfigured else { throw ClientError.notConfigured }
        let token = try await accessToken()
        do {
            return try await perform(try await build(token))
        } catch ClientError.http(401, _) {
            if var expired = session { expired.expiresAt = .distantPast; session = expired }
            let fresh = try await accessToken()
            return try await perform(try await build(fresh))
        }
    }

    private static func check(_ response: URLResponse, _ data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            throw ClientError.http(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
    }

    private static let keychainAccount = "supabase.session"

    private static func subject(fromJWT jwt: String) -> String? {
        let parts = jwt.split(separator: ".")
        guard parts.count > 1 else { return nil }
        var base64 = String(parts[1]).replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64 += "=" }
        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return json["sub"] as? String
    }
}

extension JSONEncoder {
    /// ISO-8601 dates so the edge function (and Postgres) can read them.
    static var ilo: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

/// Minimal Keychain wrapper for small Codable values.
enum Keychain {
    private static let service = "app.ilo.learn"

    static func save(_ value: some Encodable, account: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: account]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(add as CFDictionary, nil)
    }

    static func load<T: Decodable>(_ type: T.Type, account: String) -> T? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: account,
                                    kSecReturnData as String: true,
                                    kSecMatchLimit as String: kSecMatchLimitOne]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess, let data = result as? Data else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    static func delete(account: String) {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: account]
        SecItemDelete(query as CFDictionary)
    }
}
