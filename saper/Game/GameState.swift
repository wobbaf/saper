import Foundation
import Combine
import SpriteKit

/// Central game state shared between SpriteKit and SwiftUI.
class GameState: ObservableObject {
    @Published var profile: PlayerProfile
    @Published var gameMode: GameMode = .endless
    @Published var isPaused: Bool = false
    @Published var isGameOver: Bool = false
    @Published var pendingPerkOffer: [RunPerk] = []
    @Published var sectorsSolvedThisSession: Int = 0
    @Published var tilesRevealedThisSession: Int = 0
    @Published var gemsCollectedThisSession: Int = 0
    @Published var isPlaying: Bool = false
    /// The sector currently centered in the camera — updated by GameScene.
    var focusedSector: SectorCoordinate = SectorCoordinate(x: 0, y: 0)
    /// Current difficulty tier (0 = base). Increments every sectorsPerDifficultyTier sectors solved.
    @Published var difficultyTier: Int = 0
    /// Consecutive sectors solved without hitting a mine. Resets on mine hit.
    @Published var solveStreak: Int = 0
    /// Set to show gem-unlock confirmation dialog before spending gems.
    @Published var pendingUnlockCoord: SectorCoordinate? = nil

    // Per-run state — reset at the start of every run
    @Published var runBoosters: [String: Int] = [:]  // BoosterType.rawValue → count
    @Published var runPerks: [String: Int] = [:]     // RunPerk.rawValue → stacks
    @Published var livesRemaining: Int = 3           // Endless mode only

    let boardManager: BoardManager
    let timerManager = TimerManager()

    // Callbacks for scene to react to
    var onSectorStatusChanged: ((SectorCoordinate, SectorStatus) -> Void)?
    var onTilesRevealed: (([FloodFill.TilePosition]) -> Void)?
    var onTileStateChanged: ((Int, Int, TileState) -> Void)?
    var onGemCollected: ((Int, SectorCoordinate) -> Void)?
    var onMineHit: ((SectorCoordinate) -> Void)?
    var onSectorSolved: ((SectorCoordinate) -> Void)?
    var onSectorReset: ((SectorCoordinate) -> Void)?
    var onDifficultyTierChanged: ((Int) -> Void)?
    var onSectorUnlocked: ((SectorCoordinate, Int) -> Void)?
    var onTileGemCollected: ((Int, Int, Int) -> Void)?  // globalX, globalY, amount
    var onPiggyBankFound: ((Int, Int, Int) -> Void)?    // globalX, globalY, gems
    var onAchievementUnlocked: ((Achievement) -> Void)?

    init(profile: PlayerProfile, seed: UInt64) {
        self.profile = profile
        self.boardManager = BoardManager(globalSeed: seed)
    }

    // MARK: - Run perk helpers

    var revealOneAvailable: Int { runBoosters[BoosterType.revealOne.rawValue] ?? 0 }
    var solveSectorAvailable: Int { runBoosters[BoosterType.solveSector.rawValue] ?? 0 }
    var undoMineAvailable: Int { runBoosters[BoosterType.undoMine.rawValue] ?? 0 }

    func perkStacks(_ perk: RunPerk) -> Int { runPerks[perk.rawValue] ?? 0 }
    func hasPerk(_ perk: RunPerk) -> Bool { perkStacks(perk) > 0 }

    var maxLives: Int { 3 + profile.extraHeartsLevel }

    var xpMultiplier: Double {
        let runBonus = hasPerk(.xpRush) ? 1.5 : 1.0
        let prestigeBonus = 1.0 + Double(profile.scholarLevel) * 0.25
        return runBonus * prestigeBonus
    }

    /// Streak bonus: +10% XP per sector in current streak, capped at 2× (3× with Streak Savant blueprint).
    var streakXpMultiplier: Double {
        let cap = profile.streakSavantUnlocked ? 3.0 : 2.0
        return min(1.0 + Double(max(0, solveStreak - 1)) * 0.1, cap)
    }
    var sectorUnlockCost: Int { hasPerk(.sectorDiscount) ? 3 : Constants.sectorUnlockCost }

    /// Gem cost to unlock a sector. Mine-hit (locked) sectors have a fixed cost;
    /// inactive sectors scale with BFS distance to the nearest solved sector.
    func unlockCost(for coord: SectorCoordinate) -> Int {
        guard let sector = boardManager.sector(at: coord) else { return Constants.sectorUnlockCost }
        let sealedMultiplier = sector.modifier == .sealed ? 2 : 1
        switch sector.status {
        case .locked:
            let base = hasPerk(.sectorDiscount) ? 3 : Constants.sectorUnlockCost
            return base * sealedMultiplier
        case .inactive:
            let dist = boardManager.distanceToNearestSolved(from: coord)
            let base = max(2, dist * 4)
            let discounted = hasPerk(.sectorDiscount) ? max(1, base / 2) : base
            return discounted * sealedMultiplier
        default:
            return 0
        }
    }

    func applyPerk(_ perk: RunPerk) {
        switch perk {
        case .revealOneBooster:
            runBoosters[BoosterType.revealOne.rawValue, default: 0] += 1
        case .solveSectorBooster:
            runBoosters[BoosterType.solveSector.rawValue, default: 0] += 1
        case .undoMineBooster:
            runBoosters[BoosterType.undoMine.rawValue, default: 0] += 1
        case .refillHeart:
            livesRemaining = min(livesRemaining + 1, maxLives)
        default:
            runPerks[perk.rawValue, default: 0] += 1
        }
        pendingPerkOffer = []
        objectWillChange.send()
    }

    // MARK: - Game Actions

    func revealTile(globalX: Int, globalY: Int) {
        if isGameOver || isPaused { return }

        let sectorCoord = SectorCoordinate(fromTileX: globalX, tileY: globalY)

        // Capture whether this is the sector's first tap before GameActions sets firstTapDone.
        // If it is, ensureSafeFirstTap may relocate a mine, making neighbour border counts stale.
        let wasFirstTap = boardManager.sector(at: sectorCoord)?.firstTapDone == false

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
            tilesRevealedThisSession += revealed.count
            if gameMode != .practice {
                let xpGained = Int(Double(revealed.count * Constants.xpPerTileReveal) * xpMultiplier)
                let leveledUp = profile.addXP(xpGained)
                if leveledUp && pendingPerkOffer.isEmpty {
                    pendingPerkOffer = RunPerk.generateOffer(gameMode: gameMode, livesRemaining: livesRemaining, maxLives: maxLives)
                    AudioManager.shared.playCompound(SoundEffect.levelUpFanfare)
                    HapticsManager.shared.play(.levelUp)
                    MusicEngine.shared.triggerLevelUp()
                }
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

            if gameMode != .practice {
                // Tile gems + piggy bank tiles
                for pos in revealed {
                    let sc = SectorCoordinate(fromTileX: pos.globalX, tileY: pos.globalY)
                    guard let sector = boardManager.sector(at: sc) else { continue }
                    let lx = pos.globalX - sc.originTileX
                    let ly = pos.globalY - sc.originTileY
                    guard lx >= 0, lx < Constants.sectorSize, ly >= 0, ly < Constants.sectorSize else { continue }
                    // Tile gem
                    if sector.tiles[ly][lx].hasGem && !sector.tiles[ly][lx].gemCollected {
                        sector.tiles[ly][lx].gemCollected = true
                        let amount = 1
                        profile.gems += amount
                        profile.totalGemsCollected += amount
                        gemsCollectedThisSession += amount
                        let _ = profile.addXP(Int(Double(Constants.xpPerGemFind) * xpMultiplier))
                        AudioManager.shared.playCompound(SoundEffect.gemChime)
                        HapticsManager.shared.play(.gemCollected)
                        onTileGemCollected?(pos.globalX, pos.globalY, amount)
                    }
                    // Piggy bank
                    if sector.tiles[ly][lx].isPiggyBank && !sector.tiles[ly][lx].piggyBankCollected {
                        var tile = sector.tiles[ly][lx]
                        tile.piggyBankCollected = true
                        sector.setTile(tile, atLocalX: lx, localY: ly)
                        let amount = 5 + Int.random(in: 0...5)
                        profile.gems += amount
                        profile.totalGemsCollected += amount
                        profile.totalPiggyBanksFound += 1
                        gemsCollectedThisSession += amount
                        onPiggyBankFound?(pos.globalX, pos.globalY, amount)
                        checkAchievements()
                    }
                }
            }

            // If this was the sector's first tap, ensureSafeFirstTap may have relocated a
            // mine — refresh any already-revealed border tiles in neighbouring sectors.
            if wasFirstTap {
                let staleTiles = boardManager.recomputeRevealedBorderTiles(around: sectorCoord)
                if !staleTiles.isEmpty {
                    onTilesRevealed?(staleTiles)
                }
            }

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

        case .mine(let coord, let gx, let gy):
            solveStreak = 0
            AudioManager.shared.play(.mineExplosion)
            HapticsManager.shared.play(.mineHit)
            MusicEngine.shared.triggerMineHit()

            let absorbed: Bool
            if gameMode == .practice {
                // Practice mode: mine hits are always absorbed, no consequences
                absorbed = true
            } else if gameMode == .hardcore {
                let shields = perkStacks(.mineShield)
                if shields > 0 {
                    runPerks[RunPerk.mineShield.rawValue] = shields - 1
                    absorbed = true
                } else if profile.lastStandUnlocked && !profile.lastStandUsedThisRun {
                    profile.lastStandUsedThisRun = true
                    absorbed = true
                } else {
                    isGameOver = true
                    absorbed = false
                }
            } else if gameMode == .endless {
                if profile.lastStandUnlocked && !profile.lastStandUsedThisRun && livesRemaining <= 1 {
                    profile.lastStandUsedThisRun = true
                    absorbed = true
                } else {
                    livesRemaining -= 1
                    if livesRemaining <= 0 {
                        livesRemaining = 0
                        isGameOver = true
                    }
                    absorbed = livesRemaining > 0
                }
            } else {
                absorbed = false
            }

            if !absorbed {
                if let sector = boardManager.sector(at: coord) {
                    sector.status = .locked
                    sector.isModified = true
                }
                onMineHit?(coord)
                onSectorStatusChanged?(coord, .locked)
            } else {
                // Show the hit mine briefly, then reset the tile so the player can continue
                onTileStateChanged?(gx, gy, .mine)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                    guard let self = self else { return }
                    let sc = SectorCoordinate(fromTileX: gx, tileY: gy)
                    if let sector = self.boardManager.sector(at: sc) {
                        let lx = gx - sc.originTileX
                        let ly = gy - sc.originTileY
                        if lx >= 0, lx < Constants.sectorSize, ly >= 0, ly < Constants.sectorSize {
                            sector.tiles[ly][lx].state = .hidden
                            sector.isModified = true
                        }
                    }
                    self.onTileStateChanged?(gx, gy, .hidden)
                }
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
                let xpGained = Int(Double(revealed.count * Constants.xpPerTileReveal) * xpMultiplier)
                tilesRevealedThisSession += revealed.count
                let leveledUp = profile.addXP(xpGained)
                if leveledUp && pendingPerkOffer.isEmpty {
                    pendingPerkOffer = RunPerk.generateOffer(gameMode: gameMode, livesRemaining: livesRemaining, maxLives: maxLives)
                    AudioManager.shared.playCompound(SoundEffect.levelUpFanfare)
                    HapticsManager.shared.play(.levelUp)
                }
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

        case .mine(let coord, _, _):
            solveStreak = 0
            onMineHit?(coord)
            onSectorStatusChanged?(coord, .locked)
            if gameMode == .hardcore {
                let shields = perkStacks(.mineShield)
                if shields > 0 {
                    runPerks[RunPerk.mineShield.rawValue] = shields - 1
                } else {
                    isGameOver = true
                }
            }

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
        let cost = unlockCost(for: coord)
        if GameActions.unlockSectorWithGems(sectorCoord: coord, gameState: self) {
            AudioManager.shared.play(.boosterUsed)
            HapticsManager.shared.play(.lockedSectorTap)
            onSectorStatusChanged?(coord, .active)
            onSectorUnlocked?(coord, cost)
            objectWillChange.send()
        }
    }

    func confirmUnlockSector() {
        guard let coord = pendingUnlockCoord else { return }
        pendingUnlockCoord = nil
        unlockSector(coord)
    }

    func useUndoMine(sectorCoord: SectorCoordinate) {
        if isGameOver || isPaused { return }
        // Cursed sectors block the undoMine booster
        if let sector = boardManager.sector(at: sectorCoord), sector.modifier == .cursed { return }
        if GameActions.useUndoMineBooster(sectorCoord: sectorCoord, gameState: self) {
            AudioManager.shared.play(.boosterUsed)
            HapticsManager.shared.play(.boosterRevealOne)
            onSectorReset?(sectorCoord)
            onSectorStatusChanged?(sectorCoord, .active)
            objectWillChange.send()
        }
    }

    // MARK: - Achievements

    func checkAchievements() {
        for achievement in Achievement.all {
            guard !profile.unlockedAchievements.contains(achievement.id) else { continue }
            if achievement.condition(profile) {
                profile.unlockedAchievements.append(achievement.id)
                onAchievementUnlocked?(achievement)
            }
        }
    }

    // MARK: - Private

    private func handleSectorSolved(_ coord: SectorCoordinate) {
        sectorsSolvedThisSession += 1
        solveStreak += 1

        AudioManager.shared.playCompound(SoundEffect.sectorSolvedChord)
        HapticsManager.shared.play(.sectorSolved)
        MusicEngine.shared.triggerSectorSolved()
        MusicEngine.shared.sectorsCompleted = sectorsSolvedThisSession

        if gameMode != .practice {
            // Difficulty tier bump
            let newTier = min(sectorsSolvedThisSession / Constants.sectorsPerDifficultyTier,
                             Constants.maxDifficultyTier)
            if newTier > difficultyTier {
                difficultyTier = newTier
                boardManager.difficultyBonus = Double(newTier) * Constants.densityBonusPerTier
                onDifficultyTierChanged?(newTier)
            }

            let xpGained = Int(Double(Constants.xpPerSectorSolve) * xpMultiplier * streakXpMultiplier)
            let leveledUp = profile.addXP(xpGained)
            if leveledUp && pendingPerkOffer.isEmpty {
                let offerCount = profile.extraChoiceUnlocked ? 4 : 3
                pendingPerkOffer = RunPerk.generateOffer(count: offerCount, gameMode: gameMode, livesRemaining: livesRemaining, maxLives: maxLives)
                AudioManager.shared.playCompound(SoundEffect.levelUpFanfare)
                HapticsManager.shared.play(.levelUp)
                MusicEngine.shared.triggerLevelUp()
            }

            // Collect sector gem reward
            if let sector = boardManager.sector(at: coord),
               sector.gemReward > 0 && !sector.gemCollected {
                sector.gemCollected = true
                let baseReward = sector.gemReward
                let prospectorBonus = profile.prospectorLevel
                let gemMagnetBonus = perkStacks(.gemMagnet)
                let reward = baseReward + prospectorBonus + gemMagnetBonus
                profile.gems += reward
                profile.totalGemsCollected += reward
                gemsCollectedThisSession += reward
                let _ = profile.addXP(Int(Double(reward * Constants.xpPerGemFind) * xpMultiplier))
                AudioManager.shared.playCompound(SoundEffect.gemChime)
                HapticsManager.shared.play(.gemCollected)
                onGemCollected?(reward, coord)
            }

            // Update high scores
            switch gameMode {
            case .endless:
                profile.highScoreEndless = max(profile.highScoreEndless, sectorsSolvedThisSession)
            case .hardcore:
                profile.highScoreHardcore = max(profile.highScoreHardcore, sectorsSolvedThisSession)
            case .timed:
                profile.highScoreTimed = max(profile.highScoreTimed, sectorsSolvedThisSession)
            case .practice:
                break
            }
            profile.totalSectorsSolved += 1

            if solveStreak > profile.maxSolveStreak {
                profile.maxSolveStreak = solveStreak
            }
            if profile.level > profile.highestLevelReached {
                profile.highestLevelReached = profile.level
            }

            checkAchievements()
        }

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
        solveStreak = 0
        pendingUnlockCoord = nil
        isPlaying = true
        pendingPerkOffer = []

        // Per-run state reset
        profile.xp = 0
        profile.level = 1
        difficultyTier = 0
        boardManager.difficultyBonus = 0.0

        // Per-run boosters: base stock + headstart prestige bonus + quick start blueprint
        // Practice mode has no boosters — it's pure minesweeper
        if mode == .practice {
            runBoosters = [:]
        } else {
            let headstart = profile.headstartLevel
            runBoosters = [
                BoosterType.revealOne.rawValue:   profile.revealOneCount + headstart + profile.quickStartLevel,
                BoosterType.solveSector.rawValue: profile.solveSectorCount + headstart,
                BoosterType.undoMine.rawValue:    profile.undoMineCount + headstart
            ]
        }
        runPerks = [:]
        livesRemaining = maxLives
        profile.lastStandUsedThisRun = false
        focusedSector = SectorCoordinate(x: 0, y: 0)

        // Apply density shield prestige
        boardManager.densityReduction = Double(profile.densityShieldLevel) * 0.03

        boardManager.reset()

        // Pre-generate and activate the 3×3 starting cluster so the player
        // has an immediate foothold. Everything else generates as .inactive.
        for dx in -1...1 {
            for dy in -1...1 {
                boardManager.ensureSector(at: SectorCoordinate(x: dx, y: dy)).status = .active
            }
        }

        syncAudioHaptics()
        MusicEngine.shared.sectorsCompleted = 0
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
        runBoosters = saveData.runBoosters ?? [
            BoosterType.revealOne.rawValue:   profile.revealOneCount,
            BoosterType.solveSector.rawValue: profile.solveSectorCount,
            BoosterType.undoMine.rawValue:    profile.undoMineCount
        ]
        runPerks = saveData.runPerks ?? [:]
        pendingPerkOffer = []
        isPlaying = true

        // Restore difficulty tier from saved sector count
        let tier = min(sectorsSolvedThisSession / Constants.sectorsPerDifficultyTier,
                      Constants.maxDifficultyTier)
        difficultyTier = tier
        boardManager.difficultyBonus = Double(tier) * Constants.densityBonusPerTier
        boardManager.densityReduction = Double(profile.densityShieldLevel) * 0.03

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
