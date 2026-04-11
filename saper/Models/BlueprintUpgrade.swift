import SwiftUI

/// Strategic/QOL upgrades that change gameplay mechanics rather than raw stats.
/// Purchased from the Blueprint Shop with gems.
enum BlueprintUpgrade: String, CaseIterable {
    case quickStart    // +1 revealOne booster per level at run start
    case lastStand     // Once per run: survive a mine hit at 1 life (endless/hardcore)
    case streakSavant  // Streak XP multiplier cap raised from 2× to 3×

    var displayName: String {
        switch self {
        case .quickStart:   return "Quick Start"
        case .lastStand:    return "Last Stand"
        case .streakSavant: return "Streak Savant"
        }
    }

    var description: String {
        switch self {
        case .quickStart:
            return "Start every run with +1 Reveal One booster per level."
        case .lastStand:
            return "Once per run: automatically survive a lethal mine hit."
        case .streakSavant:
            return "Streak bonus XP cap raised from 2× to 3×."
        }
    }

    var iconName: String {
        switch self {
        case .quickStart:   return "hare.fill"
        case .lastStand:    return "shield.lefthalf.filled"
        case .streakSavant: return "flame.fill"
        }
    }

    var color: Color {
        switch self {
        case .quickStart:   return .orange
        case .lastStand:    return .red
        case .streakSavant: return Color(red: 1.0, green: 0.6, blue: 0.1)
        }
    }

    var maxLevel: Int {
        switch self {
        case .quickStart:   return 3
        case .lastStand:    return 1
        case .streakSavant: return 1
        }
    }

    var levelCosts: [Int] {
        switch self {
        case .quickStart:   return [15, 30, 50]
        case .lastStand:    return [40]
        case .streakSavant: return [35]
        }
    }

    func costForNextLevel(current: Int) -> Int? {
        guard current < maxLevel else { return nil }
        return levelCosts[current]
    }
}
