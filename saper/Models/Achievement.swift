import Foundation

struct Achievement: Identifiable {
    let id: String
    let displayName: String
    let description: String
    let iconName: String
    let condition: (PlayerProfile) -> Bool

    static let all: [Achievement] = [
        Achievement(
            id: "first_sector",
            displayName: "Sector Clear",
            description: "Solve your first sector",
            iconName: "checkmark.square.fill",
            condition: { $0.totalSectorsSolved >= 1 }
        ),
        Achievement(
            id: "sectors_25",
            displayName: "Veteran",
            description: "Solve 25 sectors total",
            iconName: "star.fill",
            condition: { $0.totalSectorsSolved >= 25 }
        ),
        Achievement(
            id: "sectors_100",
            displayName: "Legend",
            description: "Solve 100 sectors total",
            iconName: "star.circle.fill",
            condition: { $0.totalSectorsSolved >= 100 }
        ),
        Achievement(
            id: "gems_10",
            displayName: "Shiny Things",
            description: "Collect 10 gems",
            iconName: "diamond.fill",
            condition: { $0.totalGemsCollected >= 10 }
        ),
        Achievement(
            id: "gems_100",
            displayName: "Gem Hoarder",
            description: "Collect 100 gems total",
            iconName: "diamond.circle.fill",
            condition: { $0.totalGemsCollected >= 100 }
        ),
        Achievement(
            id: "level_5",
            displayName: "Rising Fast",
            description: "Reach level 5 in a run",
            iconName: "bolt.fill",
            condition: { $0.highestLevelReached >= 5 }
        ),
        Achievement(
            id: "level_10",
            displayName: "Seasoned",
            description: "Reach level 10 in a run",
            iconName: "bolt.circle.fill",
            condition: { $0.highestLevelReached >= 10 }
        ),
        Achievement(
            id: "streak_5",
            displayName: "On Fire",
            description: "Achieve a 5-sector solve streak",
            iconName: "flame.fill",
            condition: { $0.maxSolveStreak >= 5 }
        ),
        Achievement(
            id: "streak_10",
            displayName: "Unstoppable",
            description: "Achieve a 10-sector solve streak",
            iconName: "flame.circle.fill",
            condition: { $0.maxSolveStreak >= 10 }
        ),
        Achievement(
            id: "piggy_bank",
            displayName: "Lucky Find",
            description: "Discover a piggy bank tile",
            iconName: "banknote.fill",
            condition: { $0.totalPiggyBanksFound >= 1 }
        ),
    ]
}
