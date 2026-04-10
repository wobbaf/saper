import SpriteKit

enum SkinType: String, Codable, CaseIterable {
    case space
    case neonGrid
    case minecraft

    var displayName: String {
        switch self {
        case .space:     return "Space"
        case .neonGrid:  return "Neon Grid"
        case .minecraft: return "Minecraft"
        }
    }

    var backgroundColor: SKColor {
        switch self {
        case .space:     return SKColor(red: 0.02, green: 0.02, blue: 0.08, alpha: 1)
        case .neonGrid:  return SKColor(red: 0.0,  green: 0.0,  blue: 0.0,  alpha: 1)
        case .minecraft: return SKColor(red: 0.35, green: 0.22, blue: 0.08, alpha: 1) // dirt
        }
    }

    /// Dirt body colour (grass stripe rendered separately in TileRenderer)
    var hiddenTileColor: SKColor {
        switch self {
        case .space:     return SKColor(red: 0.12, green: 0.12, blue: 0.22, alpha: 1)
        case .neonGrid:  return SKColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1)
        case .minecraft: return SKColor(red: 0.53, green: 0.35, blue: 0.14, alpha: 1) // dirt
        }
    }

    var hiddenTileBorderColor: SKColor {
        switch self {
        case .space:     return SKColor(red: 0.25, green: 0.25, blue: 0.45, alpha: 1)
        case .neonGrid:  return SKColor(red: 0.0,  green: 0.8,  blue: 1.0,  alpha: 0.6)
        case .minecraft: return SKColor(red: 0.28, green: 0.17, blue: 0.05, alpha: 1) // dark dirt
        }
    }

    var revealedTileColor: SKColor {
        switch self {
        case .space:     return SKColor(red: 0.06, green: 0.06, blue: 0.12, alpha: 1)
        case .neonGrid:  return SKColor(red: 0.03, green: 0.03, blue: 0.03, alpha: 1)
        case .minecraft: return SKColor(red: 0.44, green: 0.44, blue: 0.44, alpha: 1) // stone
        }
    }

    var gridLineColor: SKColor {
        switch self {
        case .space:     return SKColor(red: 0.15, green: 0.15, blue: 0.3,  alpha: 0.3)
        case .neonGrid:  return SKColor(red: 0.0,  green: 0.6,  blue: 0.8,  alpha: 0.4)
        case .minecraft: return SKColor(red: 0.28, green: 0.28, blue: 0.28, alpha: 1.0) // cobblestone line
        }
    }

    /// Corner radius for tiles — Minecraft uses 0 for blocky look.
    var tileCornerRadius: CGFloat {
        switch self {
        case .minecraft: return 0
        default:         return 4
        }
    }

    var gemCost: Int { return 50 }

    var isFree: Bool {
        switch self {
        case .space, .neonGrid: return true
        case .minecraft:        return false
        }
    }
}
