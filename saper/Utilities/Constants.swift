import Foundation
import CoreGraphics

enum Constants {
    static let tileSize: CGFloat = 44
    static let sectorSize: Int = 8
    static let sectorPixelSize: CGFloat = CGFloat(sectorSize) * tileSize

    // Mine density
    static let baseDensity: Double = 0.15
    static let densityMultiplier: Double = 0.005
    static let maxDensity: Double = 0.65

    // Difficulty scaling — one tier every N sectors solved, +densityPerTier per tier
    static let sectorsPerDifficultyTier: Int = 10
    static let densityBonusPerTier: Double = 0.025
    static let maxDifficultyTier: Int = 6   // caps at +0.15 density bonus

    // Sector loading
    static let loadRadius: Int = 3
    static let unloadRadius: Int = 8

    // Gems
    static let gemSectorChance: Double = 0.15
    static let gemMinPerSector: Int = 1
    static let gemMaxPerSector: Int = 3
    static let sectorUnlockCost: Int = 5

    // XP
    static let xpPerTileReveal: Int = 1
    static let xpPerSectorSolve: Int = 50
    static let xpPerGemFind: Int = 10
    static let xpPerLevel: Int = 500
    static let gemsPerLevelUp: Int = 3

    // Boosters
    static let maxBoostersPerType: Int = 10

    // Timed mode
    static let timedModeDuration: TimeInterval = 180

    // Camera
    static let minCameraScale: CGFloat = 0.05
    static let maxCameraScale: CGFloat = 3.5
    static let defaultCameraScale: CGFloat = 1.0

    // Number glow colors (RGB)
    static let numberColors: [(CGFloat, CGFloat, CGFloat)] = [
        (0.5, 0.5, 0.5),   // 0: dim gray (not shown)
        (0.0, 1.0, 1.0),   // 1: cyan
        (0.0, 1.0, 0.0),   // 2: green
        (1.0, 1.0, 0.0),   // 3: yellow
        (1.0, 0.6, 0.0),   // 4: orange
        (1.0, 0.0, 0.0),   // 5: red
        (1.0, 0.4, 0.7),   // 6: pink
        (0.6, 0.0, 1.0),   // 7: purple
        (1.0, 1.0, 1.0),   // 8: white
    ]
}
