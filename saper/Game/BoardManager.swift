import Foundation

/// Manages sector lifecycle: generation, loading, unloading, and mine counting.
class BoardManager {
    var sectors: [SectorCoordinate: Sector] = [:]
    let globalSeed: UInt64
    /// Extra density added on top of the distance-based formula — bumped each difficulty tier.
    var difficultyBonus: Double = 0.0

    init(globalSeed: UInt64) {
        self.globalSeed = globalSeed
    }

    /// Get or generate a sector at the given coordinate.
    @discardableResult
    func ensureSector(at coord: SectorCoordinate) -> Sector {
        if let existing = sectors[coord] {
            return existing
        }
        let sector = SectorGenerator.generate(at: coord, globalSeed: globalSeed, difficultyBonus: difficultyBonus)
        sectors[coord] = sector
        return sector
    }

    /// Load all sectors within a radius of the given center sector.
    func loadSectorsAround(_ center: SectorCoordinate, radius: Int) {
        for dx in -radius...radius {
            for dy in -radius...radius {
                let coord = SectorCoordinate(x: center.x + dx, y: center.y + dy)
                ensureSector(at: coord)
            }
        }
    }

    /// Unload sectors beyond a radius from the center (keep modified ones).
    func unloadSectorsBeyond(_ center: SectorCoordinate, radius: Int) -> [SectorCoordinate] {
        var unloaded: [SectorCoordinate] = []
        for (coord, sector) in sectors {
            if coord.chebyshevDistance(to: center) > radius {
                if !sector.isModified {
                    sectors[coord] = nil
                    unloaded.append(coord)
                }
            }
        }
        return unloaded
    }

    /// Count adjacent mines for a tile at global coordinates, loading neighbors as needed.
    func adjacentMineCount(globalTileX gx: Int, globalTileY gy: Int) -> Int {
        var count = 0
        for dx in -1...1 {
            for dy in -1...1 {
                if dx == 0 && dy == 0 { continue }
                let nx = gx + dx
                let ny = gy + dy
                let sectorCoord = SectorCoordinate(fromTileX: nx, tileY: ny)
                let sector = ensureSector(at: sectorCoord)
                let localX = nx - sectorCoord.originTileX
                let localY = ny - sectorCoord.originTileY
                if sector.tiles[localY][localX].hasMine {
                    count += 1
                }
            }
        }
        return count
    }

    /// Compute adjacent mine counts for all tiles in a sector.
    func computeAdjacentCounts(for sector: Sector) {
        let ox = sector.coordinate.originTileX
        let oy = sector.coordinate.originTileY
        let size = Constants.sectorSize

        // Ensure all neighbor sectors exist for border counting
        for neighbor in sector.coordinate.neighbors {
            ensureSector(at: neighbor)
        }

        for row in 0..<size {
            for col in 0..<size {
                if sector.tiles[row][col].hasMine { continue }
                sector.tiles[row][col].adjacentMineCount = adjacentMineCount(
                    globalTileX: ox + col,
                    globalTileY: oy + row
                )
            }
        }
    }

    /// Get a sector if it exists (no generation).
    func sector(at coord: SectorCoordinate) -> Sector? {
        sectors[coord]
    }

    /// Check if all 8 neighbors of a sector are solved.
    func allNeighborsSolved(of coord: SectorCoordinate) -> Bool {
        for neighbor in coord.neighbors {
            guard let sector = sectors[neighbor], sector.status == .solved else {
                return false
            }
        }
        return true
    }

    /// Reset the entire board.
    func reset() {
        sectors.removeAll()
    }
}
