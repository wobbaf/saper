import SpriteKit
import SwiftUI

// MARK: - UI Theme

struct SkinUITheme {
    let backgroundColors: [Color]
    let titleColors: [Color]
    let accentColor: Color
    let secondaryColor: Color
    let showStarfield: Bool
    let cardBackground: Color
    let buttonBackground: Color
}

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

    var uiTheme: SkinUITheme {
        switch self {
        case .space:
            return SkinUITheme(
                backgroundColors: [
                    Color(red: 0.02, green: 0.02, blue: 0.08),
                    Color(red: 0.05, green: 0.02, blue: 0.15),
                    Color(red: 0.02, green: 0.02, blue: 0.08)
                ],
                titleColors: [.cyan, .purple, .cyan],
                accentColor: .cyan,
                secondaryColor: .purple,
                showStarfield: true,
                cardBackground: Color.white.opacity(0.08),
                buttonBackground: Color.white.opacity(0.06)
            )
        case .neonGrid:
            return SkinUITheme(
                backgroundColors: [
                    Color(red: 0.00, green: 0.00, blue: 0.00),
                    Color(red: 0.01, green: 0.03, blue: 0.02),
                    Color(red: 0.00, green: 0.00, blue: 0.00)
                ],
                titleColors: [Color(red: 0.0, green: 0.9, blue: 0.4), Color(red: 0.0, green: 0.7, blue: 1.0), Color(red: 0.0, green: 0.9, blue: 0.4)],
                accentColor: Color(red: 0.0, green: 0.8, blue: 1.0),
                secondaryColor: Color(red: 0.0, green: 0.9, blue: 0.4),
                showStarfield: false,
                cardBackground: Color.white.opacity(0.05),
                buttonBackground: Color.white.opacity(0.04)
            )
        case .minecraft:
            return SkinUITheme(
                backgroundColors: [
                    Color(red: 0.20, green: 0.13, blue: 0.05),
                    Color(red: 0.28, green: 0.18, blue: 0.07),
                    Color(red: 0.18, green: 0.11, blue: 0.04)
                ],
                titleColors: [Color(red: 0.85, green: 0.65, blue: 0.20), Color(red: 0.40, green: 0.72, blue: 0.18), Color(red: 0.85, green: 0.65, blue: 0.20)],
                accentColor: Color(red: 0.40, green: 0.72, blue: 0.18),
                secondaryColor: Color(red: 0.85, green: 0.65, blue: 0.20),
                showStarfield: false,
                cardBackground: Color(red: 0.15, green: 0.09, blue: 0.03).opacity(0.8),
                buttonBackground: Color(red: 0.35, green: 0.22, blue: 0.08).opacity(0.5)
            )
        }
    }
}
