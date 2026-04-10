import Foundation
import Combine
import SpriteKit

/// Central game state shared between SpriteKit and SwiftUI.
class GameState: ObservableObject {
    @Published var profile: PlayerProfile
    @Published var gameMode: GameMode = .endless
    @Published var isPaused: Bool = false
    @Published var isGameOver: Bool = false
    @Published var showLevelUp: Bool = false
    @Published var sectorsSolvedThisSession: Int = 0
    @Published var tilesRevealedThisSession: Int = 0
    @Published var gemsCollectedThisSession: Int = 0
    @Published var isPlaying: Bool = false

    let boardManager: BoardManager
    let timerManager = TimerManager()

    // Callbacks for scene to react to
    var onSectorStatusChanged: ((SectorCoordinate, SectorStatus) -> Void)?
    var onTilesRevealed: (([FloodFill.TilePosition]) -> Void)?
    var onTileStateChanged: ((Int, Int, TileState) -> Void)?
    var onGemCollected: ((Int) -> Void)?
    var onMineHit: ((SectorCoordinate) -> Void)?
    var onSectorSolved: ((SectorCoordinate) -> Void)?
    var onSectorReset: ((SectorCoordinate) -> Void)?

    init(profile: PlayerProfile, seed: UInt64) {
        self.profile = profile
        self.boardManager = BoardManager(globalSeed: seed)
    }

    // MARK: - Game Actions

    func revealTile(globalX: Int, globalY: Int) {
        if isGameOver || isPaused { return }

        let sectorCoord = SectorCoordinate(fromTileX: globalX, tileY: globalY)

        // Check if sector needs adjacent counts computed
        if let sector = boardManager.sector(at: sectorCoord), !sector.firstTapDone {
            boardManager.computeAdjacentCounts(for: sector)
        }

        let result = GameActions.revealTile(
            globalX: globalX,
            globalY: globalY,
            gameState: self
        )

        switch result {
        case .safe(let revealed):
            let xpGained = revealed.count * Constants.xpPerTileReveal
            tilesRevealedThisSession += revealed.count
            let leveledUp = profile.addXP(xpGained)
            if leveledUp {
                showLevelUp = true
                AudioManager.shared.playCompound(SoundEffect.levelUpFanfare)
                HapticsManager.shared.play(.levelUp)
            }

            // Audio/haptic feedback for reveals
            if revealed.count == 1 {
                let sc = SectorCoordinate(fromTileX: globalX, tileY: globalY)
                let lx = globalX - sc.originTileX
                let ly = globalY - sc.originTileY
                let num = boardManager.sector(at: sc)?.tiles[ly][lx].adjacentMineCount ?? 0
                AudioManager.shared.play(.tileReveal(number: num))
                HapticsManager.shared.play(.tileReveal(number: num))
            } else if revealed.count > 1 {
                AudioManager.shared.play(.floodFill)
                HapticsManager.shared.play(.floodFillTap)
            }

            onTilesRevealed?(revealed)

            // Check sector completion for all affected sectors
            var checkedSectors: Set<SectorCoordinate> = []
            for pos in revealed {
                let sc = SectorCoordinate(fromTileX: pos.globalX, tileY: pos.globalY)
                if checkedSectors.contains(sc) { continue }
                checkedSectors.insert(sc)
                if GameActions.checkSectorCompletion(sc, gameState: self) {
                    handleSectorSolved(sc)
                }
            }

        case .mine(let coord):
            AudioManager.shared.play(.mineExplosion)
            HapticsManager.shared.play(.mineHit)
            onMineHit?(coord)
            onSectorStatusChanged?(coord, .locked)

            if gameMode == .hardcore {
                isGameOver = true
            }

        case .alreadyRevealed:
            break
        case .sectorLocked:
            AudioManager.shared.play(.lockedSectorTap)
            HapticsManager.shared.play(.lockedSectorTap)
        }

        objectWillChange.send()
    }

    func toggleFlag(globalX: Int, globalY: Int) {
        if isGameOver || isPaused { return }
        if let newState = GameActions.toggleFlag(globalX: globalX, globalY: globalY, gameState: self) {
            switch newState {
            case .flagged:
                AudioManager.shared.play(.flagPlace)
                HapticsManager.shared.play(.flagPlaced)
            case .hidden:
                AudioManager.shared.play(.flagRemove)
                HapticsManager.shared.play(.flagRemoved)
            default:
                break
            }
            onTileStateChanged?(globalX, globalY, newState)
            objectWillChange.send()
        }
    }

    func chordReveal(globalX: Int, globalY: Int) {
        if isGameOver || isPaused { return }

        let result = GameActions.chordReveal(
            globalX: globalX,
            globalY: globalY,
            gameState: self
        )

        switch result {
        case .safe(let revealed):
            if !revealed.isEmpty {
                AudioManager.shared.play(.chordReveal)
                HapticsManager.shared.play(.chordReveal)
                let xpGained = revealed.count * Constants.xpPerTileReveal
                tilesRevealedThisSession += revealed.count
                let leveledUp = profile.addXP(xpGained)
                if leveledUp { showLevelUp = true }
                onTilesRevealed?(revealed)

                var checkedSectors: Set<SectorCoordinate> = []
                for pos in revealed {
                    let sc = SectorCoordinate(fromTileX: pos.globalX, tileY: pos.globalY)
                    if checkedSectors.contains(sc) { continue }
                    checkedSectors.insert(sc)
                    if GameActions.checkSectorCompletion(sc, gameState: self) {
                        handleSectorSolved(sc)
                    }
                }
            }

        case .mine(let coord):
            onMineHit?(coord)
            onSectorStatusChanged?(coord, .locked)
            if gameMode == .hardcore { isGameOver = true }

        default:
            break
        }

        objectWillChange.send()
    }

    func useRevealOne(sectorCoord: SectorCoordinate) {
        if isGameOver || isPaused { return }
        if let pos = GameActions.useRevealOneBooster(sectorCoord: sectorCoord, gameState: self) {
            AudioManager.shared.play(.boosterUsed)
            HapticsManager.shared.play(.boosterRevealOne)
            tilesRevealedThisSession += 1
            onTilesRevealed?([pos])
            if GameActions.checkSectorCompletion(sectorCoord, gameState: self) {
                handleSectorSolved(sectorCoord)
            }
            objectWillChange.send()
        }
    }

    func useSolveSector(sectorCoord: SectorCoordinate) {
        if isGameOver || isPaused { return }
        let revealed = GameActions.useSolveSectorBooster(sectorCoord: sectorCoord, gameState: self)
        if !revealed.isEmpty {
            AudioManager.shared.play(.boosterUsed)
            HapticsManager.shared.play(.boosterSolveSector)
            tilesRevealedThisSession += revealed.count
            onTilesRevealed?(revealed)
            if GameActions.checkSectorCompletion(sectorCoord, gameState: self) {
                handleSectorSolved(sectorCoord)
            }
            objectWillChange.send()
        }
    }

    func unlockSector(_ coord: SectorCoordinate) {
        if GameActions.unlockSectorWithGems(sectorCoord: coord, gameState: self) {
            onSectorStatusChanged?(coord, .active)
            objectWillChange.send()
        }
    }

    func useUndoMine(sectorCoord: SectorCoordinate) {
        if isGameOver || isPaused { return }
        if GameActions.useUndoMineBooster(sectorCoord: sectorCoord, gameState: self) {
            AudioManager.shared.play(.boosterUsed)
            HapticsManager.shared.play(.boosterRevealOne)
            onSectorReset?(sectorCoord)
            onSectorStatusChanged?(sectorCoord, .active)
            objectWillChange.send()
        }
    }

    // MARK: - Private

    private func handleSectorSolved(_ coord: SectorCoordinate) {
        sectorsSolvedThisSession += 1

        AudioManager.shared.playCompound(SoundEffect.sectorSolvedChord)
        HapticsManager.shared.play(.sectorSolved)

        let leveledUp = profile.addXP(Constants.xpPerSectorSolve)
        if leveledUp {
            showLevelUp = true
            AudioManager.shared.playCompound(SoundEffect.levelUpFanfare)
            HapticsManager.shared.play(.levelUp)
        }

        // Collect gems
        if let sector = boardManager.sector(at: coord),
           sector.gemReward > 0 && !sector.gemCollected {
            sector.gemCollected = true
            profile.gems += sector.gemReward
            gemsCollectedThisSession += sector.gemReward
            let _ = profile.addXP(sector.gemReward * Constants.xpPerGemFind)
            AudioManager.shared.playCompound(SoundEffect.gemChime)
            HapticsManager.shared.play(.gemCollected)
            onGemCollected?(sector.gemReward)
        }

        // Update high scores
        switch gameMode {
        case .endless:
            profile.highScoreEndless = max(profile.highScoreEndless, sectorsSolvedThisSession)
        case .hardcore:
            profile.highScoreHardcore = max(profile.highScoreHardcore, sectorsSolvedThisSession)
        case .timed:
            profile.highScoreTimed = max(profile.highScoreTimed, sectorsSolvedThisSession)
        }
        profile.totalSectorsSolved += 1

        onSectorSolved?(coord)
        onSectorStatusChanged?(coord, .solved)
    }

    // MARK: - Game Lifecycle

    func startGame(mode: GameMode) {
        gameMode = mode
        isGameOver = false
        isPaused = false
        sectorsSolvedThisSession = 0
        tilesRevealedThisSession = 0
        gemsCollectedThisSession = 0
        isPlaying = true
        boardManager.reset()

        syncAudioHaptics()
        MusicEngine.shared.start()

        if mode == .timed {
            timerManager.start()
        }
    }

    /// Explicitly resets the board and clears any saved game. The only way to discard a save.
    func resetBoard(mode: GameMode) {
        GamePersistence.clearSave()
        startGame(mode: mode)
    }

    /// Resumes an endless or hardcore game from a saved board state.
    /// Returns true if a matching save was found and restored.
    func resumeFromSave() -> Bool {
        guard GamePersistence.hasSave() else { return false }

        boardManager.reset()
        guard let saveData = GamePersistence.loadBoard(into: boardManager) else { return false }
        guard saveData.gameMode == .endless || saveData.gameMode == .hardcore else {
            GamePersistence.clearSave()
            return false
        }

        gameMode = saveData.gameMode
        isGameOver = false
        isPaused = false
        sectorsSolvedThisSession = saveData.sectorsSolved
        tilesRevealedThisSession = saveData.tilesRevealed
        gemsCollectedThisSession = saveData.gemsCollected
        isPlaying = true

        syncAudioHaptics()
        MusicEngine.shared.start()
        return true
    }

    private func syncAudioHaptics() {
        AudioManager.shared.isEnabled = profile.soundEnabled
        AudioManager.shared.sfxVolume = profile.sfxVolume
        AudioManager.shared.ambienceVolume = profile.ambienceVolume
        HapticsManager.shared.isEnabled = profile.hapticsEnabled
        MusicEngine.shared.isEnabled = profile.soundEnabled
        MusicEngine.shared.outputVolume = profile.ambienceVolume * 0.35
    }

    func pauseGame() {
        isPaused = true
        MusicEngine.shared.pause()
        if gameMode == .timed {
            timerManager.pause()
        }
    }

    func resumeGame() {
        isPaused = false
        MusicEngine.shared.resume()
        if gameMode == .timed {
            timerManager.resume()
        }
    }

    func endGame() {
        isGameOver = true
        isPlaying = false
        MusicEngine.shared.stop()
        if gameMode == .timed {
            timerManager.stop()
        }
        recordLeaderboardEntry()
    }

    /// Records a leaderboard entry for the current session (called on game over or quit).
    func recordLeaderboardEntry() {
        let sectors = sectorsSolvedThisSession
        guard sectors > 0 else { return }

        let detail = "\(sectors) sector\(sectors == 1 ? "" : "s")"
        let entry = LeaderboardEntry(
            score: sectors,
            mode: gameMode.rawValue,
            detail: detail,
            tilesRevealed: tilesRevealedThisSession,
            gemsCollected: gemsCollectedThisSession
        )
        LeaderboardPersistence.addEntry(entry)
    }

    func restartGame() {
        resetBoard(mode: gameMode)
    }
}
