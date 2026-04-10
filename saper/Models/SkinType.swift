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

    /// Grass green top for Minecraft, base colour for other skins
    var hiddenTileColor: SKColor {
        switch self {
        case .space:     return SKColor(red: 0.12, green: 0.12, blue: 0.22, alpha: 1)
        case .neonGrid:  return SKColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1)
        case .minecraft: return SKColor(red: 0.40, green: 0.62, blue: 0.18, alpha: 1) // grass top
        }
    }

    var hiddenTileBorderColor: SKColor {
        switch self {
        case .space:     return SKColor(red: 0.25, green: 0.25, blue: 0.45, alpha: 1)
        case .neonGrid:  return SKColor(red: 0.0,  green: 0.8,  blue: 1.0,  alpha: 0.6)
        case .minecraft: return SKColor(red: 0.15, green: 0.35, blue: 0.05, alpha: 1) // dark grass edge
        }
    }

    var revealedTileColor: SKColor {
        switch self {
        case .space:     return SKColor(red: 0.06, green: 0.06, blue: 0.12, alpha: 1)
        case .neonGrid:  return SKColor(red: 0.03, green: 0.03, blue: 0.03, alpha: 1)
        case .minecraft: return SKColor(red: 0.64, green: 0.48, blue: 0.28, alpha: 1) // oak planks
        }
    }

    var gridLineColor: SKColor {
        switch self {
        case .space:     return SKColor(red: 0.15, green: 0.15, blue: 0.3,  alpha: 0.3)
        case .neonGrid:  return SKColor(red: 0.0,  green: 0.6,  blue: 0.8,  alpha: 0.4)
        case .minecraft: return SKColor(red: 0.42, green: 0.30, blue: 0.15, alpha: 1.0) // dark wood border
        }
    }

    /// Obsidian colour used for flagged tiles in Minecraft skin
    var obsidianColor: SKColor {
        return SKColor(red: 0.07, green: 0.03, blue: 0.10, alpha: 1)
    }
    var obsidianAccentColor: SKColor {
        return SKColor(red: 0.18, green: 0.08, blue: 0.26, alpha: 1)
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
