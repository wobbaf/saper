import FirebaseAnalytics

enum AnalyticsManager {

    // MARK: - Session

    static func gameSessionStart(mode: GameMode, resumed: Bool) {
        Analytics.logEvent("game_session_start", parameters: [
            "mode": mode.rawValue,
            "resumed": resumed
        ])
    }

    static func gameSessionEnd(mode: GameMode, sectors: Int, tiles: Int, gems: Int, durationSeconds: Int, quit: Bool) {
        Analytics.logEvent("game_session_end", parameters: [
            "mode": mode.rawValue,
            "sectors_solved": sectors,
            "tiles_revealed": tiles,
            "gems_collected": gems,
            "duration_seconds": durationSeconds,
            "quit": quit
        ])
    }

    // MARK: - Gameplay

    static func sectorSolved(mode: GameMode, streak: Int, gemReward: Int) {
        Analytics.logEvent("sector_solved", parameters: [
            "mode": mode.rawValue,
            "streak": streak,
            "gem_reward": gemReward
        ])
    }

    static func mineHit(mode: GameMode, absorber: String, livesRemaining: Int) {
        Analytics.logEvent("mine_hit", parameters: [
            "mode": mode.rawValue,
            "absorber": absorber,
            "lives_remaining": livesRemaining
        ])
    }

    static func levelUp(level: Int, mode: GameMode) {
        Analytics.logEvent("level_up", parameters: [
            "level": level,
            "mode": mode.rawValue
        ])
    }

    static func sectorUnlocked(cost: Int, gemsAfter: Int, mode: GameMode) {
        Analytics.logEvent("sector_unlocked", parameters: [
            "cost": cost,
            "gems_after": gemsAfter,
            "mode": mode.rawValue
        ])
    }

    // MARK: - Perks & Boosters

    static func perkSelected(perk: RunPerk, level: Int, mode: GameMode) {
        Analytics.logEvent("perk_selected", parameters: [
            "perk": perk.rawValue,
            "level": level,
            "mode": mode.rawValue
        ])
    }

    static func boosterUsed(type: BoosterType, remaining: Int, mode: GameMode) {
        Analytics.logEvent("booster_used", parameters: [
            "type": type.rawValue,
            "remaining": remaining,
            "mode": mode.rawValue
        ])
    }

    static func boosterPurchased(type: BoosterType, cost: Int, gemsAfter: Int) {
        Analytics.logEvent("booster_purchased", parameters: [
            "type": type.rawValue,
            "cost": cost,
            "gems_after": gemsAfter
        ])
    }

    // MARK: - Prestige

    static func prestigeUpgradePurchased(upgrade: PrestigeUpgrade, newLevel: Int, cost: Int, gemsAfter: Int) {
        Analytics.logEvent("prestige_upgrade_purchased", parameters: [
            "upgrade": upgrade.rawValue,
            "new_level": newLevel,
            "cost": cost,
            "gems_after": gemsAfter
        ])
    }

    // MARK: - Skin

    static func skinSelected(skin: SkinType, purchased: Bool, cost: Int) {
        Analytics.logEvent("skin_selected", parameters: [
            "skin": skin.rawValue,
            "purchased": purchased,
            "cost": cost
        ])
    }

    // MARK: - Achievements

    static func achievementUnlocked(id: String, name: String) {
        Analytics.logEvent(AnalyticsEventUnlockAchievement, parameters: [
            AnalyticsParameterAchievementID: id,
            "achievement_name": name
        ])
    }

    // MARK: - Screen Views

    static func screenView(_ name: String) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: name
        ])
    }
}
