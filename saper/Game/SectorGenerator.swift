import GameplayKit

/// Generates a single sector's mine layout from a seed.
struct SectorGenerator {

    /// Generate a sector with mines placed according to density rules.
    static func generate(at coord: SectorCoordinate, globalSeed: UInt64, difficultyBonus: Double = 0.0) -> Sector {
        let rng = SeededRandom.rng(globalSeed: globalSeed, sector: coord)
        let distance = coord.distanceFromOrigin
        let density = min(Constants.baseDensity + Double(distance) * Constants.densityMultiplier + difficultyBonus, Constants.maxDensity)

        let size = Constants.sectorSize
        var tiles = [[Tile]](repeating: [Tile](repeating: Tile(), count: size), count: size)

        for row in 0..<size {
            for col in 0..<size {
                let roll = Double(rng.nextInt(upperBound: 10000)) / 10000.0
                tiles[row][col].hasMine = roll < density
            }
        }

        // Gem reward (~15% chance)
        let gemRoll = Double(rng.nextInt(upperBound: 10000)) / 10000.0
        let gemReward: Int
        if gemRoll < Constants.gemSectorChance {
            gemReward = Constants.gemMinPerSector + rng.nextInt(upperBound: Constants.gemMaxPerSector - Constants.gemMinPerSector + 1)
        } else {
            gemReward = 0
        }

        return Sector(coordinate: coord, tiles: tiles, gemReward: gemReward)
    }

    /// Ensure the tile at (localX, localY) is safe by relocating any mine there.
    static func ensureSafeFirstTap(sector: Sector, localX: Int, localY: Int, globalSeed: UInt64) {
        guard sector.tiles[localY][localX].hasMine else { return }

        sector.tiles[localY][localX].hasMine = false

        // Try to relocate the mine to the first available non-mine tile
        let size = Constants.sectorSize
        var candidates: [(Int, Int)] = []
        for row in 0..<size {
            for col in 0..<size {
                if row == localY && col == localX { continue }
                if !sector.tiles[row][col].hasMine {
                    candidates.append((col, row))
                }
            }
        }

        if !candidates.isEmpty {
            let shuffled = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: candidates) as! [(Int, Int)]
            let (rx, ry) = shuffled[0]
            sector.tiles[ry][rx].hasMine = true
        }
        // If no candidates, the sector is fully mined (extremely rare) — just remove the mine
    }
}
