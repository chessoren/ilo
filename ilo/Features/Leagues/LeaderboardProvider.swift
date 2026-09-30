import Foundation
import Observation

/// Single call site for leaderboard data. `LeaderboardService` reads the Supabase cohort,
/// and falls back to the offline `LeagueSimulator` when no backend is configured.
@Observable
@MainActor
final class LeaderboardProvider {
    private(set) var league: [LeaderboardEntry] = []
    private(set) var friends: [LeaderboardEntry] = []
    private(set) var isLoading = false

    func refresh(for player: Player) async {
        isLoading = league.isEmpty
        league = await fetchLeague(for: player)
        friends = await fetchFriends(for: player)
        isLoading = false
    }

    private func fetchLeague(for player: Player) async -> [LeaderboardEntry] {
        await LeaderboardService.league(for: player)
    }

    private func fetchFriends(for player: Player) async -> [LeaderboardEntry] {
        await LeaderboardService.friends(for: player)
    }
}
