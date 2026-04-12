import Foundation

enum BoosterType: String, Codable, CaseIterable {
    case solveSector
    case undoMine
    case mineShield
    case refillHeart

    var displayName: String {
        switch self {
        case .solveSector:  return "Solve Sector"
        case .undoMine:     return "Undo Mine"
        case .mineShield:   return "Mine Shield"
        case .refillHeart:  return "Refill Heart"
        }
    }

    var description: String {
        switch self {
        case .solveSector:  return "Reveals all safe tiles in the sector"
        case .undoMine:     return "Reverts a failed sector"
        case .mineShield:   return "Auto-absorbs the next mine hit"
        case .refillHeart:  return "Restores 1 lost heart (endless only)"
        }
    }

    var iconName: String {
        switch self {
        case .solveSector:  return "checkmark.seal.fill"
        case .undoMine:     return "arrow.uturn.backward"
        case .mineShield:   return "shield.fill"
        case .refillHeart:  return "heart.fill"
        }
    }
}
