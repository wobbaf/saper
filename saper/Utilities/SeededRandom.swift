import GameplayKit

/// Provides deterministic random number generation based on a global seed
/// and sector coordinates.
struct SeededRandom {

    /// Derive a per-sector seed from the global seed and sector coordinates.
    static func sectorSeed(globalSeed: UInt64, sector: SectorCoordinate) -> UInt64 {
        var hash = globalSeed
        hash ^= UInt64(bitPattern: Int64(sector.x)) &* 0x9E3779B97F4A7C15
        hash ^= UInt64(bitPattern: Int64(sector.y)) &* 0x517CC1B727220A95
        hash ^= (hash >> 30) &* 0xBF58476D1CE4E5B9
        hash ^= (hash >> 27) &* 0x94D049BB133111EB
        hash ^= (hash >> 31)
        return hash
    }

    /// Create a deterministic RNG for a given sector.
    static func rng(globalSeed: UInt64, sector: SectorCoordinate) -> GKLinearCongruentialRandomSource {
        let seed = sectorSeed(globalSeed: globalSeed, sector: sector)
        return GKLinearCongruentialRandomSource(seed: seed)
    }

    /// Generate a new random global seed.
    static func newGlobalSeed() -> UInt64 {
        UInt64.random(in: 0...UInt64.max)
    }
}
