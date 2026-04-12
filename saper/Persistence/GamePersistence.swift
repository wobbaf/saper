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
        let runBoosters: [String: Int]?
        let runPerks: [String: Int]?
        let startingDifficultyBonus: Double?
    }

    private static var saveURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("board_state.json")
    }

    static func saveBoard(boardManager: BoardManager, gameMode: GameMode, sectorsSolved: Int, tilesRevealed: Int, gemsCollected: Int, runBoosters: [String: Int] = [:], runPerks: [String: Int] = [:], startingDifficultyBonus: Double = 0) {
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
            runBoosters: runBoosters,
            runPerks: runPerks,
            startingDifficultyBonus: startingDifficultyBonus
        )

        do {
            let data = try JSONEncoder().encode(boardData)
            try data.write(to: saveURL)
        } catch {
            print("Failed to save board: \(error)")
        }
    }

    static func loadBoard(into boardManager: BoardManager) -> BoardSaveData? {
        guard let data = try? Data(contentsOf: saveURL),
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

    static func clearSave() {
        try? FileManager.default.removeItem(at: saveURL)
    }

    static func hasSave() -> Bool {
        FileManager.default.fileExists(atPath: saveURL.path)
    }

    /// Returns the game mode of the saved game without loading the full board.
    static func savedGameMode() -> GameMode? {
        guard let data = try? Data(contentsOf: saveURL) else { return nil }
        struct ModePeek: Decodable { let gameMode: GameMode }
        return (try? JSONDecoder().decode(ModePeek.self, from: data))?.gameMode
    }

    /// Returns true only when the save has a matching mode AND the player has revealed at least one tile.
    static func hasMeaningfulSave(for mode: GameMode) -> Bool {
        guard let data = try? Data(contentsOf: saveURL) else { return false }
        struct Peek: Decodable { let gameMode: GameMode; let tilesRevealed: Int }
        guard let peek = try? JSONDecoder().decode(Peek.self, from: data) else { return false }
        return peek.gameMode == mode && peek.tilesRevealed > 0
    }
}
