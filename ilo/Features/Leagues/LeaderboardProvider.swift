import Foundation
import Observation

/// Single call site for leaderboard data. Today it reads the offline `LeagueSimulator`;
/// swap the two `fetch` bodies for `LeaderboardService` when the backend lands.
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
        LeagueSimulator.board(for: player, weekStart: Calendar.current.startOfWeek(for: .now))
    }

    private func fetchFriends(for player: Player) async -> [LeaderboardEntry] {
        LeagueSimulator.friends(for: player)
    }
}
