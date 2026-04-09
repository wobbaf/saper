import Foundation

struct PlayerProfile: Codable {
    var gems: Int = 0
    var xp: Int = 0
    var level: Int = 1
    var revealOneCount: Int = 1
    var solveSectorCount: Int = 1
    var undoMineCount: Int = 3
    var unlockedSkins: [SkinType] = [.space, .neonGrid]
    var currentSkin: SkinType = .space
    var highScoreEndless: Int = 0
    var highScoreHardcore: Int = 0
    var highScoreTimed: Int = 0
    var totalSectorsSolved: Int = 0
    var totalGemsCollected: Int = 0
    var hapticsEnabled: Bool = true
    var soundEnabled: Bool = true
    var sfxVolume: Float = 0.7
    var ambienceVolume: Float = 0.3
    var autoFlagEnabled: Bool = false
    var appearanceMode: Int = 0 // 0 = system, 1 = light, 2 = dark

    var xpForNextLevel: Int { level * Constants.xpPerLevel }
    var xpProgress: Double { Double(xp) / Double(xpForNextLevel) }

    /// Add XP and return true if leveled up.
    /// The caller is responsible for offering a perk pick on level up.
    mutating func addXP(_ amount: Int) -> Bool {
        xp += amount
        if xp >= xpForNextLevel {
            xp -= xpForNextLevel
            level += 1
            return true
        }
        return false
    }
}
