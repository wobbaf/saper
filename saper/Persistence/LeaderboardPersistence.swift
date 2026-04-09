import Foundation

/// A single leaderboard entry.
struct LeaderboardEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let score: Int               // sectors solved (endless/hardcore/timed) or elapsed seconds (classic)
    let mode: String             // "endless", "hardcore", "timed", or "classic_beginner", "classic_intermediate", "classic_expert"
    let detail: String           // e.g. "14 sectors" or "42s"
    let tilesRevealed: Int
    let gemsCollected: Int

    /// Whether lower scores are better (true for classic time-based).
    var lowerIsBetter: Bool { mode.hasPrefix("classic") }

    init(date: Date = Date(), score: Int, mode: String, detail: String, tilesRevealed: Int = 0, gemsCollected: Int = 0) {
        self.id = UUID()
        self.date = date
        self.score = score
        self.mode = mode
        self.detail = detail
        self.tilesRevealed = tilesRevealed
        self.gemsCollected = gemsCollected
    }
}

/// Persists leaderboard entries to the Documents directory.
struct LeaderboardPersistence {
    private static var saveURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("leaderboard.json")
    }

    static func loadEntries() -> [LeaderboardEntry] {
        guard let data = try? Data(contentsOf: saveURL),
              let entries = try? JSONDecoder().decode([LeaderboardEntry].self, from: data) else {
            return []
        }
        return entries
    }

    static func saveEntries(_ entries: [LeaderboardEntry]) {
        do {
            let data = try JSONEncoder().encode(entries)
            try data.write(to: saveURL)
        } catch {
            print("Failed to save leaderboard: \(error)")
        }
    }

    /// Adds a new entry, keeping at most 50 per mode, sorted by best first.
    static func addEntry(_ entry: LeaderboardEntry) {
        var entries = loadEntries()
        entries.append(entry)

        let grouped = Dictionary(grouping: entries, by: { $0.mode })
        var trimmed: [LeaderboardEntry] = []
        for (_, modeEntries) in grouped {
            let lowerBetter = modeEntries.first?.lowerIsBetter ?? false
            let sorted = modeEntries.sorted {
                lowerBetter ? $0.score < $1.score : $0.score > $1.score
            }
            trimmed.append(contentsOf: sorted.prefix(50))
        }

        saveEntries(trimmed)
    }

    /// Returns entries for the given mode, sorted best-first.
    static func entries(forMode mode: String) -> [LeaderboardEntry] {
        let filtered = loadEntries().filter { $0.mode == mode }
        let lowerBetter = filtered.first?.lowerIsBetter ?? false
        return filtered.sorted {
            lowerBetter ? $0.score < $1.score : $0.score > $1.score
        }
    }

    static func clearAll() {
        try? FileManager.default.removeItem(at: saveURL)
    }
}
