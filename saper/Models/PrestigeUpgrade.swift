import SwiftUI

/// Permanent upgrades purchased in the main-menu shop with gems.
/// Each upgrade persists across all runs and stacks up to its max level.
enum PrestigeUpgrade: String, CaseIterable {
    case headstart      // +1 starting booster count (all types) per stack
    case scholar        // +25% XP gain per stack
    case prospector     // +1 gem from gem-bearing sectors per stack
    case densityShield  // −3% global mine density per stack
    case extraChoice    // perk offer shows 4 options instead of 3 (one-time)
    case extraHearts    // +1 max heart in endless mode per stack

    var displayName: String {
        switch self {
        case .headstart:     return "Headstart"
        case .scholar:       return "Scholar"
        case .prospector:    return "Prospector"
        case .densityShield: return "Density Shield"
        case .extraChoice:   return "Extra Choice"
        case .extraHearts:   return "Extra Hearts"
        }
    }

    var description: String {
        switch self {
        case .headstart:     return "Start every run with +1 of each booster."
        case .scholar:       return "+25% XP from all sources, every run."
        case .prospector:    return "+1 gem from every gem sector, every run."
        case .densityShield: return "Reduce global mine density by 3%."
        case .extraChoice:   return "Level-up perk offers show 4 choices instead of 3."
        case .extraHearts:   return "+1 starting heart in Endless mode. Max 5 hearts."
        }
    }

    var iconName: String {
        switch self {
        case .headstart:     return "backpack.fill"
        case .scholar:       return "graduationcap.fill"
        case .prospector:    return "sparkles"
        case .densityShield: return "shield.lefthalf.filled"
        case .extraChoice:   return "square.grid.2x2.fill"
        case .extraHearts:   return "heart.fill"
        }
    }

    var color: Color {
        switch self {
        case .headstart:     return .yellow
        case .scholar:       return .cyan
        case .prospector:    return Color(red: 0.3, green: 1.0, blue: 0.6)
        case .densityShield: return .blue
        case .extraChoice:   return .purple
        case .extraHearts:   return .pink
        }
    }

    var maxLevel: Int {
        switch self {
        case .headstart:     return 3
        case .scholar:       return 2
        case .prospector:    return 3
        case .densityShield: return 3
        case .extraChoice:   return 1
        case .extraHearts:   return 2
        }
    }

    /// Gem cost for each level (index 0 = buying level 1, etc.)
    var levelCosts: [Int] {
        switch self {
        case .headstart:     return [75, 150, 250]
        case .scholar:       return [200, 400]
        case .prospector:    return [100, 200, 350]
        case .densityShield: return [150, 300, 500]
        case .extraChoice:   return [300]
        case .extraHearts:   return [250, 500]
        }
    }

    func costForNextLevel(current: Int) -> Int? {
        guard current < maxLevel else { return nil }
        return levelCosts[current]
    }
}
