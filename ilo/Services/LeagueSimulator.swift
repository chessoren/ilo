import Foundation

/// Offline league cohort. Used when the Supabase backend isn't configured (dev / demo mode);
/// with a backend, `LeaderboardService` returns the real cohort instead.
enum LeagueSimulator {
    private static let names = [
        "Maya", "Leo", "Inès", "Sam", "Noah", "Zoé", "Hugo", "Aya", "Jules", "Lina", "Omar", "Chloé",
        "Ethan", "Nora", "Yanis", "Emma", "Kai", "Lou", "Adam", "Sofia", "Milo", "Jade", "Rayan", "Alma",
    ]

    static func board(for player: Player, weekStart: Date, at now: Date = .now, size: Int = 20) -> [LeaderboardEntry] {
        var rng = Mulberry32(seed: UInt32(truncatingIfNeeded: Int(weekStart.timeIntervalSince1970 / 3600)) &+ UInt32(player.league.rawValue * 7919))
        let elapsed = min(max(now.timeIntervalSince(weekStart) / (7 * 86_400), 0), 1)
        let tierBoost = 1 + Double(player.league.rawValue) * 0.35
        // Unique rivals: a seeded shuffle of the name pool (never the learner's own name).
        var pool = names.filter { $0.caseInsensitiveCompare(player.name) != .orderedSame }
        for i in stride(from: pool.count - 1, to: 0, by: -1) {
            pool.swapAt(i, Int(rng.next() * Double(i + 1)) % (i + 1))
        }
        var entries: [LeaderboardEntry] = (0..<(size - 1)).map { i in
            let pace = rng.next()
            let weekly = Int((40 + pace * pace * 520) * tierBoost * elapsed)
            _ = rng.next()
            let name = pool[i % pool.count]
            return LeaderboardEntry(id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", i)) ?? UUID(),
                                    name: name,
                                    shape: BloubShape.allCases[Int(rng.next() * 8) % 8],
                                    color: BloubColor.allCases[Int(rng.next() * 11) % 11],
                                    xp: weekly,
                                    streak: Int(rng.next() * 60),
                                    isMe: false)
        }
        entries.append(LeaderboardEntry(id: player.id, name: player.name.isEmpty ? "You" : player.name,
                                        shape: player.bloubShape, color: player.bloubColor,
                                        xp: player.weeklyXP, streak: player.streak, isMe: true))
        return entries.sorted { $0.xp == $1.xp ? $0.isMe : $0.xp > $1.xp }
    }

    static func friends(for player: Player) -> [LeaderboardEntry] {
        var list = player.friends.map {
            LeaderboardEntry(id: $0.id, name: $0.name, shape: $0.shape, color: $0.color, xp: $0.weeklyXP, streak: $0.streak, isMe: false)
        }
        list.append(LeaderboardEntry(id: player.id, name: player.name.isEmpty ? "You" : player.name,
                                     shape: player.bloubShape, color: player.bloubColor,
                                     xp: player.weeklyXP, streak: player.streak, isMe: true))
        return list.sorted { $0.xp > $1.xp }
    }
}
