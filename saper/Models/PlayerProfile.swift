import Foundation

struct PlayerProfile: Codable {
    var gems: Int = 0
    var xp: Int = 0
    var level: Int = 1
    var revealOneCount: Int = 1
    var solveSectorCount: Int = 1
    var undoMineCount: Int = 3
    var unlockedSkins: [SkinType] = []
    var currentSkin: SkinType = .classicLight
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

    // Prestige upgrades (permanent, affect every run)
    var headstartLevel: Int = 0       // 0–3: +1 starting booster per level
    var scholarLevel: Int = 0         // 0–2: +25% XP per level
    var prospectorLevel: Int = 0      // 0–3: +1 gem from gem sectors per level
    var densityShieldLevel: Int = 0   // 0–3: −3% mine density per level
    var extraChoiceUnlocked: Bool = false  // perk offers show 4 options
    var extraHeartsLevel: Int = 0     // 0–2: +1 max heart in endless per level

    func prestigeLevel(for upgrade: PrestigeUpgrade) -> Int {
        switch upgrade {
        case .headstart:     return headstartLevel
        case .scholar:       return scholarLevel
        case .prospector:    return prospectorLevel
        case .densityShield: return densityShieldLevel
        case .extraChoice:   return extraChoiceUnlocked ? 1 : 0
        case .extraHearts:   return extraHeartsLevel
        }
    }

    mutating func applyPrestige(_ upgrade: PrestigeUpgrade) {
        switch upgrade {
        case .headstart:     headstartLevel += 1
        case .scholar:       scholarLevel += 1
        case .prospector:    prospectorLevel += 1
        case .densityShield: densityShieldLevel += 1
        case .extraChoice:   extraChoiceUnlocked = true
        case .extraHearts:   extraHeartsLevel += 1
        }
    }

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
