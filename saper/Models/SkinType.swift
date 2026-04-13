import SpriteKit
import SwiftUI

// MARK: - Skin Definition
// All per-skin configuration lives here. To add a new skin:
//   1. Add a case to SkinType
//   2. Add one SkinDefinition block in SkinType.definition

struct SkinDefinition {
    // MARK: Meta
    let displayName: String
    let isFree: Bool
    let gemCost: Int

    // MARK: Tile base colors
    let backgroundColor: SKColor
    let hiddenTileColor: SKColor
    let hiddenTileBorderColor: SKColor
    /// Subtle inner highlight drawn on hidden tiles (non-minecraft).
    let hiddenTileHighlightColor: SKColor
    let revealedTileColor: SKColor
    let gridLineColor: SKColor
    let tileCornerRadius: CGFloat
    let useNeonGlow: Bool
    /// Number label colors for mine counts 0–8.
    let numberColors: [SKColor]

    // MARK: Mine tile
    let mineBackgroundColor: SKColor
    let mineBorderColor: SKColor
    let mineCircleColor: SKColor
    let mineCircleBorderColor: SKColor
    let mineSpikeColor: SKColor

    // MARK: Flag tile
    let flagBorderColor: SKColor
    let flagPoleColor: SKColor
    let flagTriangleColor: SKColor

    // MARK: Question tile
    let questionBorderColor: SKColor
    let questionMarkColor: SKColor

    // MARK: Special tile (Minecraft: obsidian/creeper)
    let specialTileColor: SKColor
    let specialTileBorderColor: SKColor
    let specialTileAccentColor: SKColor
    /// Dot color scattered on hidden tiles (e.g. grass on Minecraft, unused otherwise).
    let hiddenTileDotColor: SKColor?

    // MARK: Sector overlays
    let solvedOverlayFill: SKColor
    let solvedOverlayBorder: SKColor
    let lockedOverlayFill: SKColor
    let lockedOverlayBorder: SKColor
    let inactiveOverlayFill: SKColor
    let inactiveOverlayBorder: SKColor
    let inactiveCostLabelColor: SKColor

    // MARK: Sector animations
    let solvedParticleColor: SKColor
    let solvedRingColor: SKColor
    let solvedFlashColor: SKColor
    let failedFlashColor: SKColor
    let failedParticleColor: SKColor
    let failedXMarkColor: SKColor

    // MARK: Difficulty tint
    /// Background color at max difficulty tier (lerped from backgroundColor).
    let difficultyMaxColor: SKColor

    // MARK: Floating text colors
    let floatingGemColor: SKColor
    let floatingXPColor: SKColor
    let floatingWarningColor: SKColor
    let floatingGoldColor: SKColor

    // MARK: SwiftUI theme
    let backgroundColors: [Color]
    let titleColors: [Color]
    let accentColor: Color
    let secondaryColor: Color
    let showStarfield: Bool
    let cardBackground: Color
    let buttonBackground: Color
    let primaryTextColor: Color
    let secondaryTextColor: Color
    /// True for dark-background skins — controls nav bar color scheme.
    let isDark: Bool
}

// MARK: - SkinType

enum SkinType: String, Codable, CaseIterable {
    case classicLight
    case classicDark
    case space
    case neonGrid
    case minecraft

    // MARK: Single definition per skin — the only place to edit per-skin values

    var definition: SkinDefinition {
        switch self {

        case .classicLight:
            return SkinDefinition(
                displayName: "Classic Light",
                isFree: true,
                gemCost: 0,
                // Tiles
                backgroundColor:         SKColor(red: 0.78, green: 0.78, blue: 0.78, alpha: 1),
                hiddenTileColor:         SKColor(red: 0.86, green: 0.86, blue: 0.86, alpha: 1),
                hiddenTileBorderColor:   SKColor(red: 0.55, green: 0.55, blue: 0.55, alpha: 1),
                hiddenTileHighlightColor:SKColor(white: 1.0, alpha: 0.03),
                revealedTileColor:       SKColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1),
                gridLineColor:           SKColor(red: 0.50, green: 0.50, blue: 0.50, alpha: 0.9),
                tileCornerRadius:        4,
                useNeonGlow:             false,
                numberColors: [
                    SKColor(red: 0.5,  green: 0.5,  blue: 0.5,  alpha: 1), // 0
                    SKColor(red: 0.0,  green: 0.0,  blue: 0.8,  alpha: 1), // 1 blue
                    SKColor(red: 0.0,  green: 0.45, blue: 0.0,  alpha: 1), // 2 dark green
                    SKColor(red: 0.75, green: 0.0,  blue: 0.0,  alpha: 1), // 3 red
                    SKColor(red: 0.0,  green: 0.0,  blue: 0.45, alpha: 1), // 4 navy
                    SKColor(red: 0.45, green: 0.0,  blue: 0.0,  alpha: 1), // 5 maroon
                    SKColor(red: 0.0,  green: 0.35, blue: 0.35, alpha: 1), // 6 teal
                    SKColor(red: 0.0,  green: 0.0,  blue: 0.0,  alpha: 1), // 7 black
                    SKColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1), // 8 gray
                ],
                // Mine
                mineBackgroundColor:  SKColor(red: 0.55, green: 0.15, blue: 0.15, alpha: 1),
                mineBorderColor:      SKColor(red: 0.75, green: 0.10, blue: 0.10, alpha: 1),
                mineCircleColor:      SKColor(red: 0.85, green: 0.20, blue: 0.20, alpha: 1),
                mineCircleBorderColor:SKColor(red: 0.95, green: 0.40, blue: 0.40, alpha: 1),
                mineSpikeColor:       SKColor(red: 0.80, green: 0.20, blue: 0.20, alpha: 1),
                // Flag
                flagBorderColor:    SKColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 0.8),
                flagPoleColor:      SKColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1),
                flagTriangleColor:  SKColor(red: 0.9, green: 0.15, blue: 0.05, alpha: 1),
                // Question
                questionBorderColor:SKColor(red: 0.3, green: 0.3, blue: 0.9, alpha: 0.8),
                questionMarkColor:  SKColor(red: 0.2, green: 0.2, blue: 0.85, alpha: 1),
                // Special
                specialTileColor:        SKColor(red: 0.78, green: 0.78, blue: 0.78, alpha: 1),
                specialTileBorderColor:  SKColor(red: 0.55, green: 0.55, blue: 0.55, alpha: 1),
                specialTileAccentColor:  SKColor(red: 0.65, green: 0.65, blue: 0.65, alpha: 1),
                hiddenTileDotColor:      nil,
                // Sector overlays
                solvedOverlayFill:    SKColor(red: 0.0, green: 0.6, blue: 0.0, alpha: 0.06),
                solvedOverlayBorder:  SKColor(red: 0.0, green: 0.6, blue: 0.0, alpha: 0.35),
                lockedOverlayFill:    SKColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 0.08),
                lockedOverlayBorder:  SKColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 0.50),
                inactiveOverlayFill:  SKColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.55),
                inactiveOverlayBorder:SKColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 0.4),
                inactiveCostLabelColor:SKColor(red: 0.0, green: 0.0, blue: 0.65, alpha: 1),
                // Animations
                solvedParticleColor:  SKColor(red: 0.0, green: 0.7, blue: 0.0, alpha: 1),
                solvedRingColor:      SKColor(red: 0.0, green: 0.7, blue: 0.0, alpha: 0.8),
                solvedFlashColor:     SKColor(red: 0.0, green: 0.7, blue: 0.0, alpha: 0.2),
                failedFlashColor:     SKColor(red: 0.9, green: 0.0, blue: 0.0, alpha: 0.3),
                failedParticleColor:  SKColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 0.8),
                failedXMarkColor:     SKColor(red: 0.85, green: 0.1, blue: 0.1, alpha: 0.9),
                // Difficulty
                difficultyMaxColor:   SKColor(red: 0.60, green: 0.58, blue: 0.55, alpha: 1),
                // Floating text
                floatingGemColor:     SKColor(red: 0.0, green: 0.2, blue: 0.8, alpha: 1),
                floatingXPColor:      SKColor(red: 0.0, green: 0.55, blue: 0.0, alpha: 1),
                floatingWarningColor: SKColor(red: 0.85, green: 0.1, blue: 0.1, alpha: 1),
                floatingGoldColor:    SKColor(red: 0.7, green: 0.5, blue: 0.0, alpha: 1),
                // UI
                backgroundColors: [
                    Color(red: 0.84, green: 0.84, blue: 0.84),
                    Color(red: 0.88, green: 0.88, blue: 0.88),
                    Color(red: 0.84, green: 0.84, blue: 0.84),
                ],
                titleColors: [
                    Color(red: 0.0, green: 0.0, blue: 0.65),
                    Color(red: 0.0, green: 0.0, blue: 0.5),
                    Color(red: 0.0, green: 0.0, blue: 0.65),
                ],
                accentColor:       Color(red: 0.0, green: 0.0, blue: 0.65),
                secondaryColor:    Color(red: 0.6, green: 0.0, blue: 0.0),
                showStarfield:     false,
                cardBackground:    Color(white: 0.91),
                buttonBackground:  Color(white: 0.82),
                primaryTextColor:  Color(red: 0.05, green: 0.05, blue: 0.05),
                secondaryTextColor:Color.black.opacity(0.5),
                isDark:            false
            )

        case .classicDark:
            return SkinDefinition(
                displayName: "Classic Dark",
                isFree: true,
                gemCost: 0,
                backgroundColor:         SKColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1),
                hiddenTileColor:         SKColor(red: 0.24, green: 0.24, blue: 0.24, alpha: 1),
                hiddenTileBorderColor:   SKColor(red: 0.40, green: 0.40, blue: 0.40, alpha: 1),
                hiddenTileHighlightColor:SKColor(white: 1.0, alpha: 0.03),
                revealedTileColor:       SKColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1),
                gridLineColor:           SKColor(red: 0.32, green: 0.32, blue: 0.32, alpha: 0.9),
                tileCornerRadius:        4,
                useNeonGlow:             false,
                numberColors: [
                    SKColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1), // 0
                    SKColor(red: 0.25, green: 0.50, blue: 1.0,  alpha: 1), // 1 light blue
                    SKColor(red: 0.15, green: 0.85, blue: 0.25, alpha: 1), // 2 green
                    SKColor(red: 1.0,  green: 0.35, blue: 0.35, alpha: 1), // 3 red
                    SKColor(red: 0.35, green: 0.35, blue: 1.0,  alpha: 1), // 4 purple-blue
                    SKColor(red: 0.90, green: 0.20, blue: 0.20, alpha: 1), // 5 dark red
                    SKColor(red: 0.15, green: 0.85, blue: 0.85, alpha: 1), // 6 cyan
                    SKColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1), // 7 light gray
                    SKColor(red: 0.55, green: 0.55, blue: 0.55, alpha: 1), // 8 mid gray
                ],
                mineBackgroundColor:  SKColor(red: 0.30, green: 0.0,  blue: 0.0,  alpha: 1),
                mineBorderColor:      SKColor(red: 0.80, green: 0.0,  blue: 0.0,  alpha: 1),
                mineCircleColor:      SKColor(red: 1.0,  green: 0.2,  blue: 0.2,  alpha: 1),
                mineCircleBorderColor:SKColor(red: 1.0,  green: 0.4,  blue: 0.4,  alpha: 1),
                mineSpikeColor:       SKColor(red: 1.0,  green: 0.3,  blue: 0.3,  alpha: 1),
                flagBorderColor:    SKColor(red: 1.0,  green: 0.5,  blue: 0.0,  alpha: 0.8),
                flagPoleColor:      .white,
                flagTriangleColor:  SKColor(red: 1.0,  green: 0.3,  blue: 0.1,  alpha: 1),
                questionBorderColor:SKColor(red: 0.5,  green: 0.5,  blue: 1.0,  alpha: 0.8),
                questionMarkColor:  SKColor(red: 0.5,  green: 0.5,  blue: 1.0,  alpha: 1),
                specialTileColor:        SKColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1),
                specialTileBorderColor:  SKColor(red: 0.40, green: 0.40, blue: 0.40, alpha: 1),
                specialTileAccentColor:  SKColor(red: 0.30, green: 0.30, blue: 0.30, alpha: 1),
                hiddenTileDotColor:      nil,
                solvedOverlayFill:    SKColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 0.06),
                solvedOverlayBorder:  SKColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 0.30),
                lockedOverlayFill:    SKColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.08),
                lockedOverlayBorder:  SKColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.50),
                inactiveOverlayFill:  SKColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.70),
                inactiveOverlayBorder:SKColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 0.50),
                inactiveCostLabelColor:SKColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 1),
                solvedParticleColor:  SKColor(red: 0.0, green: 1.0, blue: 0.5, alpha: 1),
                solvedRingColor:      SKColor(red: 0.0, green: 1.0, blue: 0.5, alpha: 0.8),
                solvedFlashColor:     SKColor(red: 0.0, green: 1.0, blue: 0.5, alpha: 0.25),
                failedFlashColor:     SKColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.35),
                failedParticleColor:  SKColor(red: 1.0, green: 0.2, blue: 0.1, alpha: 0.8),
                failedXMarkColor:     SKColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 0.9),
                difficultyMaxColor:   SKColor(red: 0.22, green: 0.04, blue: 0.04, alpha: 1),
                floatingGemColor:     SKColor(red: 0.3, green: 0.8, blue: 1.0, alpha: 1),
                floatingXPColor:      SKColor(red: 0.5, green: 1.0, blue: 0.5, alpha: 1),
                floatingWarningColor: SKColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1),
                floatingGoldColor:    SKColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1),
                backgroundColors: [
                    Color(red: 0.11, green: 0.11, blue: 0.11),
                    Color(red: 0.16, green: 0.16, blue: 0.16),
                    Color(red: 0.11, green: 0.11, blue: 0.11),
                ],
                titleColors: [
                    Color(red: 0.80, green: 0.80, blue: 0.80),
                    .white,
                    Color(red: 0.80, green: 0.80, blue: 0.80),
                ],
                accentColor:       Color(red: 0.80, green: 0.80, blue: 0.80),
                secondaryColor:    Color(red: 0.58, green: 0.58, blue: 0.58),
                showStarfield:     false,
                cardBackground:    Color.white.opacity(0.16),
                buttonBackground:  Color.white.opacity(0.12),
                primaryTextColor:  .white,
                secondaryTextColor:Color.white.opacity(0.55),
                isDark:            true
            )

        case .space:
            return SkinDefinition(
                displayName: "Space",
                isFree: false,
                gemCost: 50,
                backgroundColor:         SKColor(red: 0.02, green: 0.02, blue: 0.08, alpha: 1),
                hiddenTileColor:         SKColor(red: 0.12, green: 0.12, blue: 0.22, alpha: 1),
                hiddenTileBorderColor:   SKColor(red: 0.25, green: 0.25, blue: 0.45, alpha: 1),
                hiddenTileHighlightColor:SKColor(white: 1.0, alpha: 0.04),
                revealedTileColor:       SKColor(red: 0.06, green: 0.06, blue: 0.12, alpha: 1),
                gridLineColor:           SKColor(red: 0.15, green: 0.15, blue: 0.30, alpha: 0.3),
                tileCornerRadius:        4,
                useNeonGlow:             true,
                numberColors:            SKColor.defaultNeonNumberColors,
                mineBackgroundColor:  SKColor(red: 0.20, green: 0.0,  blue: 0.30, alpha: 1),
                mineBorderColor:      SKColor(red: 0.70, green: 0.0,  blue: 0.90, alpha: 1),
                mineCircleColor:      SKColor(red: 0.90, green: 0.2,  blue: 1.0,  alpha: 1),
                mineCircleBorderColor:SKColor(red: 1.0,  green: 0.5,  blue: 1.0,  alpha: 1),
                mineSpikeColor:       SKColor(red: 0.85, green: 0.3,  blue: 1.0,  alpha: 1),
                flagBorderColor:    SKColor(red: 0.0,  green: 0.8,  blue: 1.0,  alpha: 0.9),
                flagPoleColor:      SKColor(red: 0.7,  green: 0.7,  blue: 1.0,  alpha: 1),
                flagTriangleColor:  SKColor(red: 0.0,  green: 0.7,  blue: 1.0,  alpha: 1),
                questionBorderColor:SKColor(red: 0.3,  green: 0.5,  blue: 1.0,  alpha: 0.9),
                questionMarkColor:  SKColor(red: 0.4,  green: 0.6,  blue: 1.0,  alpha: 1),
                specialTileColor:        SKColor(red: 0.02, green: 0.02, blue: 0.08, alpha: 1),
                specialTileBorderColor:  SKColor(red: 0.25, green: 0.25, blue: 0.45, alpha: 1),
                specialTileAccentColor:  SKColor(red: 0.20, green: 0.20, blue: 0.50, alpha: 1),
                hiddenTileDotColor:      nil,
                solvedOverlayFill:    SKColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 0.07),
                solvedOverlayBorder:  SKColor(red: 0.0, green: 0.7, blue: 1.0, alpha: 0.4),
                lockedOverlayFill:    SKColor(red: 0.8, green: 0.0, blue: 1.0, alpha: 0.08),
                lockedOverlayBorder:  SKColor(red: 0.8, green: 0.0, blue: 1.0, alpha: 0.55),
                inactiveOverlayFill:  SKColor(red: 0.0, green: 0.0, blue: 0.05, alpha: 0.80),
                inactiveOverlayBorder:SKColor(red: 0.2, green: 0.3, blue: 0.8,  alpha: 0.5),
                inactiveCostLabelColor:SKColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 1),
                solvedParticleColor:  SKColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1),
                solvedRingColor:      SKColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.8),
                solvedFlashColor:     SKColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.2),
                failedFlashColor:     SKColor(red: 0.8, green: 0.0, blue: 1.0, alpha: 0.35),
                failedParticleColor:  SKColor(red: 0.8, green: 0.1, blue: 1.0, alpha: 0.8),
                failedXMarkColor:     SKColor(red: 0.9, green: 0.2, blue: 1.0, alpha: 0.9),
                difficultyMaxColor:   SKColor(red: 0.22, green: 0.01, blue: 0.04, alpha: 1),
                floatingGemColor:     SKColor(red: 0.3, green: 0.8, blue: 1.0, alpha: 1),
                floatingXPColor:      SKColor(red: 0.5, green: 1.0, blue: 0.5, alpha: 1),
                floatingWarningColor: SKColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1),
                floatingGoldColor:    SKColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1),
                backgroundColors: [
                    Color(red: 0.02, green: 0.02, blue: 0.08),
                    Color(red: 0.05, green: 0.02, blue: 0.15),
                    Color(red: 0.02, green: 0.02, blue: 0.08),
                ],
                titleColors:       [.cyan, .purple, .cyan],
                accentColor:       .cyan,
                secondaryColor:    .purple,
                showStarfield:     true,
                cardBackground:    Color.white.opacity(0.16),
                buttonBackground:  Color.white.opacity(0.12),
                primaryTextColor:  .white,
                secondaryTextColor:Color.white.opacity(0.55),
                isDark:            true
            )

        case .neonGrid:
            return SkinDefinition(
                displayName: "Neon Grid",
                isFree: false,
                gemCost: 50,
                backgroundColor:         SKColor(red: 0.0,  green: 0.0,  blue: 0.0,  alpha: 1),
                hiddenTileColor:         SKColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1),
                hiddenTileBorderColor:   SKColor(red: 0.0,  green: 0.8,  blue: 1.0,  alpha: 0.6),
                hiddenTileHighlightColor:SKColor(white: 1.0, alpha: 0.02),
                revealedTileColor:       SKColor(red: 0.03, green: 0.03, blue: 0.03, alpha: 1),
                gridLineColor:           SKColor(red: 0.0,  green: 0.6,  blue: 0.8,  alpha: 0.4),
                tileCornerRadius:        4,
                useNeonGlow:             true,
                numberColors:            SKColor.defaultNeonNumberColors,
                mineBackgroundColor:  SKColor(red: 0.10, green: 0.0,  blue: 0.0,  alpha: 1),
                mineBorderColor:      SKColor(red: 1.0,  green: 0.0,  blue: 0.3,  alpha: 1),
                mineCircleColor:      SKColor(red: 1.0,  green: 0.0,  blue: 0.4,  alpha: 1),
                mineCircleBorderColor:SKColor(red: 1.0,  green: 0.4,  blue: 0.6,  alpha: 1),
                mineSpikeColor:       SKColor(red: 1.0,  green: 0.1,  blue: 0.4,  alpha: 1),
                flagBorderColor:    SKColor(red: 0.0,  green: 0.9,  blue: 0.4,  alpha: 0.9),
                flagPoleColor:      SKColor(red: 0.0,  green: 0.9,  blue: 0.4,  alpha: 1),
                flagTriangleColor:  SKColor(red: 0.0,  green: 0.9,  blue: 0.4,  alpha: 1),
                questionBorderColor:SKColor(red: 0.0,  green: 0.8,  blue: 1.0,  alpha: 0.9),
                questionMarkColor:  SKColor(red: 0.0,  green: 0.8,  blue: 1.0,  alpha: 1),
                specialTileColor:        SKColor(red: 0.0,  green: 0.0,  blue: 0.0,  alpha: 1),
                specialTileBorderColor:  SKColor(red: 0.0,  green: 0.8,  blue: 1.0,  alpha: 0.6),
                specialTileAccentColor:  SKColor(red: 0.0,  green: 0.8,  blue: 1.0,  alpha: 0.3),
                hiddenTileDotColor:      nil,
                solvedOverlayFill:    SKColor(red: 0.0, green: 0.9, blue: 0.4, alpha: 0.06),
                solvedOverlayBorder:  SKColor(red: 0.0, green: 0.9, blue: 0.4, alpha: 0.5),
                lockedOverlayFill:    SKColor(red: 1.0, green: 0.0, blue: 0.3, alpha: 0.08),
                lockedOverlayBorder:  SKColor(red: 1.0, green: 0.0, blue: 0.3, alpha: 0.6),
                inactiveOverlayFill:  SKColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.80),
                inactiveOverlayBorder:SKColor(red: 0.0, green: 0.6, blue: 0.8, alpha: 0.5),
                inactiveCostLabelColor:SKColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1),
                solvedParticleColor:  SKColor(red: 0.0, green: 0.9, blue: 0.4, alpha: 1),
                solvedRingColor:      SKColor(red: 0.0, green: 0.9, blue: 0.4, alpha: 0.8),
                solvedFlashColor:     SKColor(red: 0.0, green: 0.9, blue: 0.4, alpha: 0.2),
                failedFlashColor:     SKColor(red: 1.0, green: 0.0, blue: 0.3, alpha: 0.35),
                failedParticleColor:  SKColor(red: 1.0, green: 0.0, blue: 0.3, alpha: 0.8),
                failedXMarkColor:     SKColor(red: 1.0, green: 0.1, blue: 0.3, alpha: 0.9),
                difficultyMaxColor:   SKColor(red: 0.12, green: 0.0, blue: 0.0, alpha: 1),
                floatingGemColor:     SKColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1),
                floatingXPColor:      SKColor(red: 0.0, green: 0.9, blue: 0.4, alpha: 1),
                floatingWarningColor: SKColor(red: 1.0, green: 0.1, blue: 0.3, alpha: 1),
                floatingGoldColor:    SKColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1),
                backgroundColors: [
                    Color(red: 0.00, green: 0.00, blue: 0.00),
                    Color(red: 0.01, green: 0.03, blue: 0.02),
                    Color(red: 0.00, green: 0.00, blue: 0.00),
                ],
                titleColors: [
                    Color(red: 0.0, green: 0.9, blue: 0.4),
                    Color(red: 0.0, green: 0.7, blue: 1.0),
                    Color(red: 0.0, green: 0.9, blue: 0.4),
                ],
                accentColor:       Color(red: 0.0, green: 0.8, blue: 1.0),
                secondaryColor:    Color(red: 0.0, green: 0.9, blue: 0.4),
                showStarfield:     false,
                cardBackground:    Color.white.opacity(0.14),
                buttonBackground:  Color.white.opacity(0.10),
                primaryTextColor:  Color(red: 0.0, green: 0.9, blue: 0.4),
                secondaryTextColor:Color.white.opacity(0.55),
                isDark:            true
            )

        case .minecraft:
            return SkinDefinition(
                displayName: "Minecraft",
                isFree: false,
                gemCost: 50,
                backgroundColor:         SKColor(red: 0.35, green: 0.22, blue: 0.08, alpha: 1),
                hiddenTileColor:         SKColor(red: 0.40, green: 0.62, blue: 0.18, alpha: 1),
                hiddenTileBorderColor:   SKColor(red: 0.15, green: 0.35, blue: 0.05, alpha: 1),
                hiddenTileHighlightColor:SKColor(white: 1.0, alpha: 0.0),
                revealedTileColor:       SKColor(red: 0.64, green: 0.48, blue: 0.28, alpha: 1),
                gridLineColor:           SKColor(red: 0.42, green: 0.30, blue: 0.15, alpha: 1),
                tileCornerRadius:        0,
                useNeonGlow:             false,
                numberColors:            SKColor.defaultNeonNumberColors,
                mineBackgroundColor:  SKColor(red: 0.40, green: 0.62, blue: 0.18, alpha: 1),
                mineBorderColor:      SKColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1),
                mineCircleColor:      SKColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1),
                mineCircleBorderColor:SKColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1),
                mineSpikeColor:       SKColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1),
                flagBorderColor:    SKColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1),
                flagPoleColor:      SKColor(red: 0.90, green: 0.90, blue: 0.90, alpha: 1),
                flagTriangleColor:  SKColor(red: 0.9,  green: 0.1,  blue: 0.05, alpha: 1),
                questionBorderColor:SKColor(red: 0.42, green: 0.30, blue: 0.15, alpha: 1),
                questionMarkColor:  SKColor(red: 0.90, green: 0.80, blue: 0.60, alpha: 1),
                specialTileColor:        SKColor(red: 0.07, green: 0.03, blue: 0.10, alpha: 1),
                specialTileBorderColor:  SKColor(red: 0.25, green: 0.10, blue: 0.35, alpha: 1),
                specialTileAccentColor:  SKColor(red: 0.18, green: 0.08, blue: 0.26, alpha: 1),
                hiddenTileDotColor:      SKColor(red: 0.22, green: 0.50, blue: 0.04, alpha: 1),
                solvedOverlayFill:    SKColor(red: 0.40, green: 0.72, blue: 0.18, alpha: 0.12),
                solvedOverlayBorder:  SKColor(red: 0.40, green: 0.72, blue: 0.18, alpha: 0.6),
                lockedOverlayFill:    SKColor(red: 0.8,  green: 0.1,  blue: 0.1,  alpha: 0.12),
                lockedOverlayBorder:  SKColor(red: 0.8,  green: 0.1,  blue: 0.1,  alpha: 0.6),
                inactiveOverlayFill:  SKColor(red: 0.10, green: 0.06, blue: 0.02, alpha: 0.75),
                inactiveOverlayBorder:SKColor(red: 0.42, green: 0.30, blue: 0.15, alpha: 0.6),
                inactiveCostLabelColor:SKColor(red: 0.85, green: 0.65, blue: 0.20, alpha: 1),
                solvedParticleColor:  SKColor(red: 0.40, green: 0.72, blue: 0.18, alpha: 1),
                solvedRingColor:      SKColor(red: 0.40, green: 0.72, blue: 0.18, alpha: 0.8),
                solvedFlashColor:     SKColor(red: 0.40, green: 0.72, blue: 0.18, alpha: 0.2),
                failedFlashColor:     SKColor(red: 0.8,  green: 0.1,  blue: 0.1,  alpha: 0.35),
                failedParticleColor:  SKColor(red: 0.8,  green: 0.15, blue: 0.05, alpha: 0.8),
                failedXMarkColor:     SKColor(red: 0.9,  green: 0.1,  blue: 0.1,  alpha: 0.9),
                difficultyMaxColor:   SKColor(red: 0.40, green: 0.12, blue: 0.03, alpha: 1),
                floatingGemColor:     SKColor(red: 0.85, green: 0.65, blue: 0.20, alpha: 1),
                floatingXPColor:      SKColor(red: 0.40, green: 0.72, blue: 0.18, alpha: 1),
                floatingWarningColor: SKColor(red: 0.9,  green: 0.1,  blue: 0.1,  alpha: 1),
                floatingGoldColor:    SKColor(red: 0.85, green: 0.65, blue: 0.20, alpha: 1),
                backgroundColors: [
                    Color(red: 0.20, green: 0.13, blue: 0.05),
                    Color(red: 0.28, green: 0.18, blue: 0.07),
                    Color(red: 0.18, green: 0.11, blue: 0.04),
                ],
                titleColors: [
                    Color(red: 0.85, green: 0.65, blue: 0.20),
                    Color(red: 0.40, green: 0.72, blue: 0.18),
                    Color(red: 0.85, green: 0.65, blue: 0.20),
                ],
                accentColor:       Color(red: 0.40, green: 0.72, blue: 0.18),
                secondaryColor:    Color(red: 0.85, green: 0.65, blue: 0.20),
                showStarfield:     false,
                cardBackground:    Color(red: 0.15, green: 0.09, blue: 0.03).opacity(0.8),
                buttonBackground:  Color(red: 0.35, green: 0.22, blue: 0.08).opacity(0.5),
                primaryTextColor:  Color(red: 0.90, green: 0.80, blue: 0.60),
                secondaryTextColor:Color(red: 0.90, green: 0.80, blue: 0.60).opacity(0.6),
                isDark:            true
            )
        }
    }

    // MARK: Convenience forwarding — existing call sites unchanged

    var displayName: String  { definition.displayName }
    var isFree: Bool         { definition.isFree }
    var gemCost: Int         { definition.gemCost }

    var backgroundColor: SKColor        { definition.backgroundColor }
    var hiddenTileColor: SKColor        { definition.hiddenTileColor }
    var hiddenTileBorderColor: SKColor  { definition.hiddenTileBorderColor }
    var revealedTileColor: SKColor      { definition.revealedTileColor }
    var gridLineColor: SKColor          { definition.gridLineColor }
    var tileCornerRadius: CGFloat       { definition.tileCornerRadius }
    var useNeonGlow: Bool               { definition.useNeonGlow }

    var obsidianColor: SKColor       { definition.specialTileColor }
    var obsidianAccentColor: SKColor { definition.specialTileAccentColor }

    func numberColor(for count: Int) -> SKColor {
        let colors = definition.numberColors
        return count >= 0 && count < colors.count ? colors[count] : colors.last ?? .white
    }

    var uiTheme: SkinUITheme { SkinUITheme(definition: definition) }
}

// MARK: - SkinUITheme (view-facing subset, kept for backward compatibility)

struct SkinUITheme {
    let backgroundColors: [Color]
    let titleColors: [Color]
    let accentColor: Color
    let secondaryColor: Color
    let showStarfield: Bool
    let cardBackground: Color
    let buttonBackground: Color
    let primaryTextColor: Color
    let secondaryTextColor: Color
    let isDark: Bool

    init(definition d: SkinDefinition) {
        backgroundColors   = d.backgroundColors
        titleColors        = d.titleColors
        accentColor        = d.accentColor
        secondaryColor     = d.secondaryColor
        showStarfield      = d.showStarfield
        cardBackground     = d.cardBackground
        buttonBackground   = d.buttonBackground
        primaryTextColor   = d.primaryTextColor
        secondaryTextColor = d.secondaryTextColor
        isDark             = d.isDark
    }
}

// MARK: - SKColor helpers

extension SKColor {
    static func numberColor(for count: Int) -> SKColor {
        guard count >= 0 && count < Constants.numberColors.count else { return .white }
        let (r, g, b) = Constants.numberColors[count]
        return SKColor(red: r, green: g, blue: b, alpha: 1)
    }

    static let defaultNeonNumberColors: [SKColor] = (0..<9).map { SKColor.numberColor(for: $0) }
}
