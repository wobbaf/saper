import Foundation

/// Encapsulates all game actions: reveal, flag, chord, boosters.
struct GameActions {

    enum RevealResult {
        case safe(revealed: [FloodFill.TilePosition])
        case mine(sectorCoord: SectorCoordinate)
        case alreadyRevealed
        case sectorLocked
    }

    /// Reveal a tile at global coordinates.
    static func revealTile(
        globalX: Int,
        globalY: Int,
        gameState: GameState
    ) -> RevealResult {
        let sectorCoord = SectorCoordinate(fromTileX: globalX, tileY: globalY)
        let sector = gameState.boardManager.ensureSector(at: sectorCoord)

        if sector.status == .locked || sector.status == .inactive { return .sectorLocked }

        let localX = globalX - sectorCoord.originTileX
        let localY = globalY - sectorCoord.originTileY

        guard localX >= 0, localX < Constants.sectorSize,
              localY >= 0, localY < Constants.sectorSize else { return .alreadyRevealed }

        let tile = sector.tiles[localY][localX]
        if tile.state == .revealed || tile.state == .flagged || tile.state == .question {
            return .alreadyRevealed
        }

        // Safe first tap
        if !sector.firstTapDone {
            sector.firstTapDone = true
            SectorGenerator.ensureSafeFirstTap(
                sector: sector,
                localX: localX,
                localY: localY,
                globalSeed: gameState.boardManager.globalSeed
            )
            // Recompute adjacent counts since mines may have moved
            gameState.boardManager.computeAdjacentCounts(for: sector)
        }

        // Check for mine
        if sector.tiles[localY][localX].hasMine {
            sector.tiles[localY][localX].state = .mine
            sector.status = .locked
            sector.isModified = true
            return .mine(sectorCoord: sectorCoord)
        }

        // Compute adjacent count
        let count = gameState.boardManager.adjacentMineCount(
            globalTileX: globalX,
            globalTileY: globalY
        )
        sector.tiles[localY][localX].adjacentMineCount = count

        // Flood fill if 0 (handles revealing the starting tile + all connected 0-tiles)
        if count == 0 {
            let floodRevealed = FloodFill.execute(
                startX: globalX,
                startY: globalY,
                boardManager: gameState.boardManager
            )
            return .safe(revealed: floodRevealed)
        }

        // Non-zero count: just reveal this single tile
        sector.tiles[localY][localX].state = .revealed
        sector.isModified = true
        return .safe(revealed: [FloodFill.TilePosition(globalX: globalX, globalY: globalY)])
    }

    /// Toggle flag on a tile: hidden → flagged, flagged → question, question → hidden.
    static func toggleFlag(
        globalX: Int,
        globalY: Int,
        gameState: GameState
    ) -> TileState? {
        let sectorCoord = SectorCoordinate(fromTileX: globalX, tileY: globalY)
        guard let sector = gameState.boardManager.sector(at: sectorCoord),
              sector.status != .locked else { return nil }

        let localX = globalX - sectorCoord.originTileX
        let localY = globalY - sectorCoord.originTileY

        guard localX >= 0, localX < Constants.sectorSize,
              localY >= 0, localY < Constants.sectorSize else { return nil }

        let currentState = sector.tiles[localY][localX].state

        let newState: TileState
        switch currentState {
        case .hidden:
            newState = .flagged
        case .flagged:
            newState = .question
        case .question:
            newState = .hidden
        default:
            return nil
        }

        sector.tiles[localY][localX].state = newState
        sector.isModified = true
        return newState
    }

    /// Chord reveal: when tapping a revealed number, if adjacent flags == number,
    /// reveal all non-flagged adjacent hidden tiles.
    static func chordReveal(
        globalX: Int,
        globalY: Int,
        gameState: GameState
    ) -> RevealResult {
        let sectorCoord = SectorCoordinate(fromTileX: globalX, tileY: globalY)
        guard let sector = gameState.boardManager.sector(at: sectorCoord),
              sector.status != .locked else { return .sectorLocked }

        let localX = globalX - sectorCoord.originTileX
        let localY = globalY - sectorCoord.originTileY

        guard localX >= 0, localX < Constants.sectorSize,
              localY >= 0, localY < Constants.sectorSize else { return .alreadyRevealed }

        let tile = sector.tiles[localY][localX]
        guard tile.state == .revealed, tile.adjacentMineCount > 0 else { return .alreadyRevealed }

        // Count adjacent flags
        var flagCount = 0
        var hiddenNeighbors: [(Int, Int)] = []

        for dx in -1...1 {
            for dy in -1...1 {
                if dx == 0 && dy == 0 { continue }
                let nx = globalX + dx
                let ny = globalY + dy
                let nSectorCoord = SectorCoordinate(fromTileX: nx, tileY: ny)
                guard let nSector = gameState.boardManager.sector(at: nSectorCoord) else { continue }
                let nlx = nx - nSectorCoord.originTileX
                let nly = ny - nSectorCoord.originTileY
                guard nlx >= 0, nlx < Constants.sectorSize,
                      nly >= 0, nly < Constants.sectorSize else { continue }
                let nTile = nSector.tiles[nly][nlx]
                if nTile.state == .flagged {
                    flagCount += 1
                } else if nTile.state == .hidden || nTile.state == .question {
                    hiddenNeighbors.append((nx, ny))
                }
            }
        }

        guard flagCount == tile.adjacentMineCount else { return .alreadyRevealed }

        // Reveal all hidden neighbors
        var allRevealed: [FloodFill.TilePosition] = []
        for (nx, ny) in hiddenNeighbors {
            let result = revealTile(globalX: nx, globalY: ny, gameState: gameState)
            switch result {
            case .mine(let coord):
                return .mine(sectorCoord: coord)
            case .safe(let revealed):
                allRevealed.append(contentsOf: revealed)
            default:
                break
            }
        }

        return .safe(revealed: allRevealed)
    }

    /// Check if a sector is now solved and update its status.
    static func checkSectorCompletion(
        _ coord: SectorCoordinate,
        gameState: GameState
    ) -> Bool {
        guard let sector = gameState.boardManager.sector(at: coord),
              sector.status == .active else { return false }

        if sector.isSolved {
            sector.status = .solved
            sector.isModified = true

            for neighbor in coord.neighbors {
                guard let nSector = gameState.boardManager.sector(at: neighbor) else { continue }

                // Solving a sector unlocks all adjacent inactive sectors for free
                if nSector.status == .inactive {
                    nSector.status = .active
                    nSector.isModified = true
                    gameState.onSectorStatusChanged?(neighbor, .active)
                }

                // Mine-hit locked sectors auto-unlock if every one of their neighbours is solved
                if nSector.status == .locked,
                   gameState.boardManager.allNeighborsSolved(of: neighbor) {
                    nSector.status = .active
                    nSector.isModified = true
                    gameState.onSectorStatusChanged?(neighbor, .active)
                }
            }

            return true
        }
        return false
    }

    /// Use the Reveal One booster: reveal one random safe hidden tile in the sector.
    static func useRevealOneBooster(
        sectorCoord: SectorCoordinate,
        gameState: GameState
    ) -> FloodFill.TilePosition? {
        guard gameState.revealOneAvailable > 0 else { return nil }
        guard let sector = gameState.boardManager.sector(at: sectorCoord),
              sector.status == .active else { return nil }

        var candidates: [(Int, Int)] = []
        for row in 0..<Constants.sectorSize {
            for col in 0..<Constants.sectorSize {
                let tile = sector.tiles[row][col]
                if !tile.hasMine && tile.state == .hidden {
                    candidates.append((col, row))
                }
            }
        }

        guard !candidates.isEmpty else { return nil }

        let (col, row) = candidates.randomElement()!
        let gx = sectorCoord.originTileX + col
        let gy = sectorCoord.originTileY + row

        _ = revealTile(globalX: gx, globalY: gy, gameState: gameState)
        gameState.runBoosters[BoosterType.revealOne.rawValue, default: 0] -= 1

        return FloodFill.TilePosition(globalX: gx, globalY: gy)
    }

    /// Use the Solve Sector booster: reveal all safe tiles in the sector.
    static func useSolveSectorBooster(
        sectorCoord: SectorCoordinate,
        gameState: GameState
    ) -> [FloodFill.TilePosition] {
        guard gameState.solveSectorAvailable > 0 else { return [] }
        guard let sector = gameState.boardManager.sector(at: sectorCoord),
              sector.status == .active else { return [] }

        var revealed: [FloodFill.TilePosition] = []

        // Ensure first tap is done and counts are computed
        if !sector.firstTapDone {
            sector.firstTapDone = true
            gameState.boardManager.computeAdjacentCounts(for: sector)
        }

        for row in 0..<Constants.sectorSize {
            for col in 0..<Constants.sectorSize {
                let tile = sector.tiles[row][col]
                if !tile.hasMine && tile.state != .revealed {
                    let gx = sectorCoord.originTileX + col
                    let gy = sectorCoord.originTileY + row
                    sector.tiles[row][col].state = .revealed
                    if sector.tiles[row][col].adjacentMineCount == 0 {
                        let count = gameState.boardManager.adjacentMineCount(globalTileX: gx, globalTileY: gy)
                        sector.tiles[row][col].adjacentMineCount = count
                    }
                    revealed.append(FloodFill.TilePosition(globalX: gx, globalY: gy))
                }
            }
        }

        sector.isModified = true
        gameState.runBoosters[BoosterType.solveSector.rawValue, default: 0] -= 1

        return revealed
    }

    /// Unlock a locked sector using gems.
    static func unlockSectorWithGems(
        sectorCoord: SectorCoordinate,
        gameState: GameState
    ) -> Bool {
        guard let sector = gameState.boardManager.sector(at: sectorCoord) else { return false }
        guard sector.status == .locked || sector.status == .inactive else { return false }

        let cost = gameState.unlockCost(for: sectorCoord)
        guard gameState.profile.gems >= cost else { return false }

        let wasLocked = sector.status == .locked
        gameState.profile.gems -= cost
        sector.status = .active
        sector.isModified = true

        if wasLocked {
            // Mine-hit: reset the revealed mine tile so the player can retry
            for row in 0..<Constants.sectorSize {
                for col in 0..<Constants.sectorSize {
                    if sector.tiles[row][col].state == .mine {
                        sector.tiles[row][col].state = .hidden
                    }
                }
            }
        }

        return true
    }

    /// Use the Undo Mine booster: revert a locked sector back to active, hiding all revealed mines.
    static func useUndoMineBooster(
        sectorCoord: SectorCoordinate,
        gameState: GameState
    ) -> Bool {
        guard gameState.undoMineAvailable > 0 else { return false }
        guard let sector = gameState.boardManager.sector(at: sectorCoord),
              sector.status == .locked else { return false }

        gameState.runBoosters[BoosterType.undoMine.rawValue, default: 0] -= 1
        sector.status = .active

        // Reset all mine-state tiles back to hidden
        for row in 0..<Constants.sectorSize {
            for col in 0..<Constants.sectorSize {
                if sector.tiles[row][col].state == .mine {
                    sector.tiles[row][col].state = .hidden
                }
            }
        }
        sector.isModified = true
        return true
    }
}
