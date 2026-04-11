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
    /// Primary text color appropriate for this skin's background.
    let primaryTextColor: Color
    /// Muted/secondary text color appropriate for this skin's background.
    let secondaryTextColor: Color
}

enum SkinType: String, Codable, CaseIterable {
    case classicLight
    case classicDark
    case space
    case neonGrid
    case minecraft

    var displayName: String {
        switch self {
        case .classicLight: return "Classic Light"
        case .classicDark:  return "Classic Dark"
        case .space:        return "Space"
        case .neonGrid:     return "Neon Grid"
        case .minecraft:    return "Minecraft"
        }
    }

    var backgroundColor: SKColor {
        switch self {
        case .classicLight: return SKColor(red: 0.78, green: 0.78, blue: 0.78, alpha: 1)
        case .classicDark:  return SKColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1)
        case .space:        return SKColor(red: 0.02, green: 0.02, blue: 0.08, alpha: 1)
        case .neonGrid:     return SKColor(red: 0.0,  green: 0.0,  blue: 0.0,  alpha: 1)
        case .minecraft:    return SKColor(red: 0.35, green: 0.22, blue: 0.08, alpha: 1)
        }
    }

    var hiddenTileColor: SKColor {
        switch self {
        case .classicLight: return SKColor(red: 0.86, green: 0.86, blue: 0.86, alpha: 1)
        case .classicDark:  return SKColor(red: 0.24, green: 0.24, blue: 0.24, alpha: 1)
        case .space:        return SKColor(red: 0.12, green: 0.12, blue: 0.22, alpha: 1)
        case .neonGrid:     return SKColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1)
        case .minecraft:    return SKColor(red: 0.40, green: 0.62, blue: 0.18, alpha: 1)
        }
    }

    var hiddenTileBorderColor: SKColor {
        switch self {
        case .classicLight: return SKColor(red: 0.55, green: 0.55, blue: 0.55, alpha: 1)
        case .classicDark:  return SKColor(red: 0.40, green: 0.40, blue: 0.40, alpha: 1)
        case .space:        return SKColor(red: 0.25, green: 0.25, blue: 0.45, alpha: 1)
        case .neonGrid:     return SKColor(red: 0.0,  green: 0.8,  blue: 1.0,  alpha: 0.6)
        case .minecraft:    return SKColor(red: 0.15, green: 0.35, blue: 0.05, alpha: 1)
        }
    }

    var revealedTileColor: SKColor {
        switch self {
        case .classicLight: return SKColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1)
        case .classicDark:  return SKColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1)
        case .space:        return SKColor(red: 0.06, green: 0.06, blue: 0.12, alpha: 1)
        case .neonGrid:     return SKColor(red: 0.03, green: 0.03, blue: 0.03, alpha: 1)
        case .minecraft:    return SKColor(red: 0.64, green: 0.48, blue: 0.28, alpha: 1)
        }
    }

    var gridLineColor: SKColor {
        switch self {
        case .classicLight: return SKColor(red: 0.50, green: 0.50, blue: 0.50, alpha: 0.9)
        case .classicDark:  return SKColor(red: 0.32, green: 0.32, blue: 0.32, alpha: 0.9)
        case .space:        return SKColor(red: 0.15, green: 0.15, blue: 0.3,  alpha: 0.3)
        case .neonGrid:     return SKColor(red: 0.0,  green: 0.6,  blue: 0.8,  alpha: 0.4)
        case .minecraft:    return SKColor(red: 0.42, green: 0.30, blue: 0.15, alpha: 1.0)
        }
    }

    /// Obsidian colour used for flagged tiles in Minecraft skin
    var obsidianColor: SKColor {
        return SKColor(red: 0.07, green: 0.03, blue: 0.10, alpha: 1)
    }
    var obsidianAccentColor: SKColor {
        return SKColor(red: 0.18, green: 0.08, blue: 0.26, alpha: 1)
    }

    /// Corner radius for tiles.
    var tileCornerRadius: CGFloat {
        switch self {
        case .minecraft:    return 0
        case .classicLight,
             .classicDark:  return 2
        default:            return 4
        }
    }

    /// Whether to render neon glow halos on tile numbers.
    var useNeonGlow: Bool {
        switch self {
        case .classicLight, .classicDark, .minecraft: return false
        default: return true
        }
    }

    /// Per-skin number colors. Classic skins use traditional Minesweeper palette.
    func numberColor(for count: Int) -> SKColor {
        switch self {
        case .classicLight:
            let colors: [SKColor] = [
                SKColor(red: 0.5,  green: 0.5,  blue: 0.5,  alpha: 1), // 0
                SKColor(red: 0.0,  green: 0.0,  blue: 0.8,  alpha: 1), // 1 blue
                SKColor(red: 0.0,  green: 0.45, blue: 0.0,  alpha: 1), // 2 dark green
                SKColor(red: 0.75, green: 0.0,  blue: 0.0,  alpha: 1), // 3 red
                SKColor(red: 0.0,  green: 0.0,  blue: 0.45, alpha: 1), // 4 navy
                SKColor(red: 0.45, green: 0.0,  blue: 0.0,  alpha: 1), // 5 maroon
                SKColor(red: 0.0,  green: 0.35, blue: 0.35, alpha: 1), // 6 teal
                SKColor(red: 0.0,  green: 0.0,  blue: 0.0,  alpha: 1), // 7 black
                SKColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1), // 8 gray
            ]
            return count >= 0 && count < colors.count ? colors[count] : .black
        case .classicDark:
            let colors: [SKColor] = [
                SKColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1), // 0
                SKColor(red: 0.25, green: 0.50, blue: 1.0,  alpha: 1), // 1 light blue
                SKColor(red: 0.15, green: 0.85, blue: 0.25, alpha: 1), // 2 green
                SKColor(red: 1.0,  green: 0.35, blue: 0.35, alpha: 1), // 3 red
                SKColor(red: 0.35, green: 0.35, blue: 1.0,  alpha: 1), // 4 purple-blue
                SKColor(red: 0.90, green: 0.20, blue: 0.20, alpha: 1), // 5 dark red
                SKColor(red: 0.15, green: 0.85, blue: 0.85, alpha: 1), // 6 cyan
                SKColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1), // 7 light gray
                SKColor(red: 0.55, green: 0.55, blue: 0.55, alpha: 1), // 8 mid gray
            ]
            return count >= 0 && count < colors.count ? colors[count] : .white
        default:
            return SKColor.numberColor(for: count)
        }
    }

    var gemCost: Int { return 50 }

    var isFree: Bool {
        switch self {
        case .classicLight, .classicDark: return true
        default: return false
        }
    }

    var uiTheme: SkinUITheme {
        switch self {
        case .classicLight:
            return SkinUITheme(
                backgroundColors: [
                    Color(red: 0.84, green: 0.84, blue: 0.84),
                    Color(red: 0.88, green: 0.88, blue: 0.88),
                    Color(red: 0.84, green: 0.84, blue: 0.84)
                ],
                titleColors: [Color(red: 0.0, green: 0.0, blue: 0.65), Color(red: 0.0, green: 0.0, blue: 0.5), Color(red: 0.0, green: 0.0, blue: 0.65)],
                accentColor: Color(red: 0.0, green: 0.0, blue: 0.65),
                secondaryColor: Color(red: 0.6, green: 0.0, blue: 0.0),
                showStarfield: false,
                cardBackground: Color.black.opacity(0.09),
                buttonBackground: Color.black.opacity(0.07),
                primaryTextColor: Color(red: 0.05, green: 0.05, blue: 0.05),
                secondaryTextColor: Color(red: 0.0, green: 0.0, blue: 0.0).opacity(0.5)
            )
        case .classicDark:
            return SkinUITheme(
                backgroundColors: [
                    Color(red: 0.11, green: 0.11, blue: 0.11),
                    Color(red: 0.16, green: 0.16, blue: 0.16),
                    Color(red: 0.11, green: 0.11, blue: 0.11)
                ],
                titleColors: [Color(red: 0.80, green: 0.80, blue: 0.80), .white, Color(red: 0.80, green: 0.80, blue: 0.80)],
                accentColor: Color(red: 0.80, green: 0.80, blue: 0.80),
                secondaryColor: Color(red: 0.58, green: 0.58, blue: 0.58),
                showStarfield: false,
                cardBackground: Color.white.opacity(0.08),
                buttonBackground: Color.white.opacity(0.06),
                primaryTextColor: Color.white,
                secondaryTextColor: Color.white.opacity(0.55)
            )
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
                buttonBackground: Color.white.opacity(0.06),
                primaryTextColor: Color.white,
                secondaryTextColor: Color.white.opacity(0.55)
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
                buttonBackground: Color.white.opacity(0.04),
                primaryTextColor: Color(red: 0.0, green: 0.9, blue: 0.4),
                secondaryTextColor: Color.white.opacity(0.55)
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
                buttonBackground: Color(red: 0.35, green: 0.22, blue: 0.08).opacity(0.5),
                primaryTextColor: Color(red: 0.90, green: 0.80, blue: 0.60),
                secondaryTextColor: Color(red: 0.90, green: 0.80, blue: 0.60).opacity(0.6)
            )
        }
    }
}
