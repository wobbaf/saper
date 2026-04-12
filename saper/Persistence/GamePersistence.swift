import Foundation

/// Manages saving and loading board state to the Documents directory.
struct GamePersistence {

    struct SectorSaveData: Codable {
        let coordinate: SectorCoordinate
        let tiles: [[Tile]]
        let status: SectorStatus
        let firstTapDone: Bool
        let gemCollected: Bool
        let gemReward: Int
    }

    struct BoardSaveData: Codable {
        let sectors: [SectorSaveData]
        let gameMode: GameMode
        let sectorsSolved: Int
        let tilesRevealed: Int
        let gemsCollected: Int
        let livesRemaining: Int?
        let runBoosters: [String: Int]?
        let runPerks: [String: Int]?
        let startingDifficultyBonus: Double?
    }

    // Each saveable mode gets its own file — modes never overwrite each other.
    private static func saveURL(for mode: GameMode) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("board_state_\(mode.rawValue).json")
    }

    // Legacy single-file URL — checked once on first launch then migrated.
    private static var legacySaveURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("board_state.json")
    }

    static func saveBoard(boardManager: BoardManager, gameMode: GameMode, sectorsSolved: Int, tilesRevealed: Int, gemsCollected: Int, livesRemaining: Int = 0, runBoosters: [String: Int] = [:], runPerks: [String: Int] = [:], startingDifficultyBonus: Double = 0) {
        var sectorDataList: [SectorSaveData] = []

        for (coord, sector) in boardManager.sectors where sector.isModified {
            let data = SectorSaveData(
                coordinate: coord,
                tiles: sector.tiles,
                status: sector.status,
                firstTapDone: sector.firstTapDone,
                gemCollected: sector.gemCollected,
                gemReward: sector.gemReward
            )
            sectorDataList.append(data)
        }

        let boardData = BoardSaveData(
            sectors: sectorDataList,
            gameMode: gameMode,
            sectorsSolved: sectorsSolved,
            tilesRevealed: tilesRevealed,
            gemsCollected: gemsCollected,
            livesRemaining: livesRemaining,
            runBoosters: runBoosters,
            runPerks: runPerks,
            startingDifficultyBonus: startingDifficultyBonus
        )

        do {
            let data = try JSONEncoder().encode(boardData)
            try data.write(to: saveURL(for: gameMode))
        } catch {
            print("Failed to save board: \(error)")
        }
    }

    static func loadBoard(into boardManager: BoardManager, mode: GameMode) -> BoardSaveData? {
        // Migrate legacy single-file save on first access
        migrateLegacySaveIfNeeded()

        guard let data = try? Data(contentsOf: saveURL(for: mode)),
              let boardData = try? JSONDecoder().decode(BoardSaveData.self, from: data) else {
            return nil
        }

        for sectorData in boardData.sectors {
            let sector = Sector(
                coordinate: sectorData.coordinate,
                tiles: sectorData.tiles,
                gemReward: sectorData.gemReward
            )
            sector.status = sectorData.status
            sector.firstTapDone = sectorData.firstTapDone
            sector.gemCollected = sectorData.gemCollected
            sector.isModified = true
            boardManager.sectors[sectorData.coordinate] = sector
        }

        return boardData
    }

    static func clearSave(for mode: GameMode) {
        try? FileManager.default.removeItem(at: saveURL(for: mode))
    }

    static func hasSave(for mode: GameMode) -> Bool {
        migrateLegacySaveIfNeeded()
        return FileManager.default.fileExists(atPath: saveURL(for: mode).path)
    }

    /// Returns true only when the save has a matching mode AND the player has revealed at least one tile.
    static func hasMeaningfulSave(for mode: GameMode) -> Bool {
        migrateLegacySaveIfNeeded()
        guard let data = try? Data(contentsOf: saveURL(for: mode)) else { return false }
        struct Peek: Decodable { let gameMode: GameMode; let tilesRevealed: Int }
        guard let peek = try? JSONDecoder().decode(Peek.self, from: data) else { return false }
        return peek.gameMode == mode && peek.tilesRevealed > 0
    }

    // MARK: - Legacy migration

    /// Moves the old single board_state.json into the per-mode file once, then deletes it.
    private static func migrateLegacySaveIfNeeded() {
        let legacy = legacySaveURL
        guard FileManager.default.fileExists(atPath: legacy.path),
              let data = try? Data(contentsOf: legacy),
              let mode = (try? JSONDecoder().decode(_ModePeek.self, from: data))?.gameMode else {
            try? FileManager.default.removeItem(at: legacy)
            return
        }
        let dest = saveURL(for: mode)
        if !FileManager.default.fileExists(atPath: dest.path) {
            try? FileManager.default.copyItem(at: legacy, to: dest)
        }
        try? FileManager.default.removeItem(at: legacy)
    }

    private struct _ModePeek: Decodable { let gameMode: GameMode }
}
