import Foundation

enum BoosterType: String, Codable, CaseIterable {
    case revealOne
    case solveSector
    case undoMine

    var displayName: String {
        switch self {
        case .revealOne: return "Reveal One"
        case .solveSector: return "Solve Sector"
        case .undoMine: return "Undo Mine"
        }
    }

    var description: String {
        switch self {
        case .revealOne: return "Reveals one random safe tile"
        case .solveSector: return "Solves the entire sector"
        case .undoMine: return "Reverts a failed sector"
        }
    }

    var iconName: String {
        switch self {
        case .revealOne: return "eye.fill"
        case .solveSector: return "checkmark.seal.fill"
        case .undoMine: return "arrow.uturn.backward"
        }
    }
}
