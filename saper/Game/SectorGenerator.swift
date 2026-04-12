import GameplayKit

/// Generates a single sector's mine layout from a seed.
struct SectorGenerator {

    /// Generate a sector with mines placed according to density rules.
    static func generate(at coord: SectorCoordinate, globalSeed: UInt64, difficultyBonus: Double = 0.0, densityReduction: Double = 0.0) -> Sector {
        let rng = SeededRandom.rng(globalSeed: globalSeed, sector: coord)
        let distance = coord.distanceFromOrigin

        // Pre-roll the modifier before tile generation so cursed sectors get a real density boost
        var prerolledModifier: SectorModifier? = nil
        if distance > 2 {
            let modRoll = Double(rng.nextInt(upperBound: 10000)) / 10000.0
            if modRoll < 0.09 {
                let modIdx = rng.nextInt(upperBound: SectorModifier.allCases.count)
                prerolledModifier = SectorModifier.allCases[modIdx]
            }
        }

        let cursedBonus: Double = prerolledModifier == .cursed ? 0.12 : 0.0
        let density = max(0.05, min(Constants.baseDensity + Double(distance) * Constants.densityMultiplier + difficultyBonus + cursedBonus - densityReduction, Constants.maxDensity))

        let size = Constants.sectorSize
        var tiles = [[Tile]](repeating: [Tile](repeating: Tile(), count: size), count: size)

        for row in 0..<size {
            for col in 0..<size {
                let roll = Double(rng.nextInt(upperBound: 10000)) / 10000.0
                tiles[row][col].hasMine = roll < density
            }
        }

        // Gem reward: always 1 base gem, +5-10 bonus on ~15% of sectors
        let gemRoll = Double(rng.nextInt(upperBound: 10000)) / 10000.0
        let gemReward: Int
        if gemRoll < Constants.gemSectorChance {
            gemReward = 1 + 5 + rng.nextInt(upperBound: 6) // 6–11 gems
        } else {
            gemReward = 1
        }

        // Scatter tile gems: ~2.5% chance per non-mine tile
        for row in 0..<size {
            for col in 0..<size {
                if tiles[row][col].hasMine { continue }
                let gemRollTile = Double(rng.nextInt(upperBound: 10000)) / 10000.0
                if gemRollTile < 0.025 {
                    tiles[row][col].hasGem = true
                }
            }
        }

        let sector = Sector(coordinate: coord, tiles: tiles, gemReward: gemReward)
        sector.density = density

        // Piggy bank: 12% chance for one random non-mine tile to be a piggy bank
        let piggyRoll = Double(rng.nextInt(upperBound: 10000)) / 10000.0
        if piggyRoll < 0.12 {
            var nonMineTiles: [(Int, Int)] = []
            for row in 0..<size {
                for col in 0..<size {
                    if !tiles[row][col].hasMine {
                        nonMineTiles.append((col, row))
                    }
                }
            }
            if !nonMineTiles.isEmpty {
                let idx = rng.nextInt(upperBound: nonMineTiles.count)
                let (px, py) = nonMineTiles[idx]
                sector.tiles[py][px].isPiggyBank = true
            }
        }

        // Apply pre-rolled modifier
        sector.modifier = prerolledModifier
        if sector.modifier == .charged {
            sector.gemReward = max(1, sector.gemReward * 2 + 2)
        }

        return sector
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
