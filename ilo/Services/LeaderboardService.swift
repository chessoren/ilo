import Foundation

/// Weekly league + friends leaderboards.
/// With a Supabase backend: real cohorts (see `supabase/migrations/0001_init.sql`). Without one (or offline): `LeagueSimulator`.
enum LeaderboardService {
    /// Minimum rows shown in a league. Young cohorts are topped up with simulated learners so the board never looks empty.
    static let minimumCohort = 20

    private struct Row: Decodable {
        var user_id: UUID
        var name: String
        var bloub_shape: String
        var bloub_color: String
        var xp: Int
        var streak: Int
        var is_me: Bool
    }

    private struct ProfileParams: Encodable, Sendable {
        var p_name: String
        var p_shape: String
        var p_color: String
        var p_league: Int
        var p_total_xp: Int
        var p_streak: Int
    }

    private struct XPParams: Encodable, Sendable {
        var p_xp: Int
        var p_streak: Int
    }

    private struct Empty: Encodable, Sendable {}

    private struct CodeParams: Encodable, Sendable { var p_code: String }

    /// This week's league cohort, ranked (the player is flagged `isMe`).
    static func league(for player: Player) async -> [LeaderboardEntry] {
        guard AppConfig.hasBackend else { return LeagueSimulator.board(for: player, weekStart: player.weekStart) }
        do {
            await syncProfile(player)
            let data = try await SupabaseClient.shared.rpc("leaderboard", params: Empty())
            var rows = try JSONDecoder().decode([Row].self, from: data).map { entry(from: $0, player: player) }
            if rows.count < minimumCohort {
                let bots = LeagueSimulator.board(for: player, weekStart: player.weekStart, size: minimumCohort - rows.count + 1)
                    .filter { !$0.isMe }
                rows += bots
            }
            return rows.sorted { $0.xp == $1.xp ? $0.isMe : $0.xp > $1.xp }
        } catch {
            return LeagueSimulator.board(for: player, weekStart: player.weekStart)
        }
    }

    /// Friends (and the player), ranked by weekly XP.
    static func friends(for player: Player) async -> [LeaderboardEntry] {
        guard AppConfig.hasBackend else { return LeagueSimulator.friends(for: player) }
        do {
            let data = try await SupabaseClient.shared.rpc("friends_board", params: Empty())
            let remote = try JSONDecoder().decode([Row].self, from: data).map { entry(from: $0, player: player) }
            // Local friends (added offline) stay visible alongside real ones.
            let local = LeagueSimulator.friends(for: player).filter { !$0.isMe && !remote.map(\.name).contains($0.name) }
            return (remote + local).sorted { $0.xp > $1.xp }
        } catch {
            return LeagueSimulator.friends(for: player)
        }
    }

    /// Reports XP just earned (call after each lesson). Fire-and-forget; silently no-ops offline.
    static func reportXP(_ xp: Int, player: Player) async {
        guard AppConfig.hasBackend, xp > 0 else { return }
        _ = try? await SupabaseClient.shared.rpc("add_xp", params: XPParams(p_xp: xp, p_streak: player.streak))
    }

    /// Pushes name, bloub and league to the backend profile.
    static func syncProfile(_ player: Player) async {
        guard AppConfig.hasBackend else { return }
        _ = try? await SupabaseClient.shared.rpc("upsert_profile", params: ProfileParams(
            p_name: player.name.isEmpty ? "Learner" : player.name,
            p_shape: player.bloubShape.rawValue, p_color: player.bloubColor.rawValue,
            p_league: player.league.rawValue, p_total_xp: player.totalXP, p_streak: player.streak))
    }

    /// The player's 6-letter friend code (nil offline).
    static func friendCode(for player: Player) async -> String? {
        guard AppConfig.hasBackend else { return nil }
        struct Profile: Decodable { var friend_code: String }
        guard let data = try? await SupabaseClient.shared.rpc("upsert_profile", params: ProfileParams(
            p_name: player.name.isEmpty ? "Learner" : player.name,
            p_shape: player.bloubShape.rawValue, p_color: player.bloubColor.rawValue,
            p_league: player.league.rawValue, p_total_xp: player.totalXP, p_streak: player.streak)) else { return nil }
        return try? JSONDecoder().decode(Profile.self, from: data).friend_code
    }

    /// Adds a friend by code; returns their name.
    static func addFriend(code: String) async throws -> String {
        guard AppConfig.hasBackend else { throw AIError.notConfigured }
        let data = try await SupabaseClient.shared.rpc("add_friend", params: CodeParams(p_code: code))
        return (try? JSONDecoder().decode(String.self, from: data)) ?? code
    }

    private static func entry(from row: Row, player: Player) -> LeaderboardEntry {
        if row.is_me {
            // Local numbers are always the freshest for "me".
            return LeaderboardEntry(id: player.id, name: player.name.isEmpty ? "You" : player.name,
                                    shape: player.bloubShape, color: player.bloubColor,
                                    xp: max(row.xp, player.weeklyXP), streak: player.streak, isMe: true)
        }
        return LeaderboardEntry(id: row.user_id, name: row.name.isEmpty ? "Learner" : row.name,
                                shape: BloubShape(rawValue: row.bloub_shape) ?? .circle,
                                color: BloubColor(rawValue: row.bloub_color) ?? .blue,
                                xp: row.xp, streak: row.streak, isMe: false)
    }
}
