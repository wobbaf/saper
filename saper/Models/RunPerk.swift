import SwiftUI

/// A per-run perk offered on level up. All effects last only for the current run.
enum RunPerk: String, Codable, CaseIterable {
    case solveSectorBooster
    case undoMineBooster
    case gemMagnet
    case sectorDiscount
    case xpRush

    var displayName: String {
        switch self {
        case .solveSectorBooster: return "+1 Solver"
        case .undoMineBooster:   return "+1 Undo"
        case .gemMagnet:         return "Gem Magnet"
        case .sectorDiscount:    return "Discount"
        case .xpRush:            return "XP Rush"
        }
    }

    var description: String {
        switch self {
        case .solveSectorBooster: return "Gain 1 extra Solve Sector booster for this run."
        case .undoMineBooster:   return "Gain 1 extra Undo Mine booster for this run."
        case .gemMagnet:         return "+1 gem every time you solve a sector. Stackable."
        case .sectorDiscount:    return "Unlock locked sectors for 3 gems instead of 5."
        case .xpRush:            return "Gain 50% more XP for the rest of this run."
        }
    }

    var iconName: String {
        switch self {
        case .solveSectorBooster: return "checkmark.seal.fill"
        case .undoMineBooster:   return "arrow.uturn.backward"
        case .gemMagnet:         return "diamond.fill"
        case .sectorDiscount:    return "tag.fill"
        case .xpRush:            return "bolt.fill"
        }
    }

    var color: Color {
        switch self {
        case .solveSectorBooster: return .purple
        case .undoMineBooster:   return .orange
        case .gemMagnet:         return .cyan
        case .sectorDiscount:    return .green
        case .xpRush:            return Color(red: 1, green: 0.85, blue: 0)
        }
    }

    static func generateOffer(count: Int = 3, gameMode: GameMode = .endless, livesRemaining: Int = 3, maxLives: Int = 3) -> [RunPerk] {
        var pool = allCases
        pool.shuffle()
        return Array(pool.prefix(count))
    }
}
