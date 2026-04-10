import SwiftUI

/// Pause menu overlay.
struct PauseMenuView: View {
    @ObservedObject var gameState: GameState
    let onResume: () -> Void
    let onRestart: () -> Void
    let onShop: () -> Void
    let onMainMenu: () -> Void

    private var theme: SkinUITheme { gameState.profile.currentSkin.uiTheme }

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("PAUSED")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(LinearGradient(colors: theme.titleColors, startPoint: .leading, endPoint: .trailing))

                VStack(spacing: 8) {
                    StatRow(label: "Sectors Solved", value: "\(gameState.sectorsSolvedThisSession)")
                    StatRow(label: "Tiles Revealed", value: "\(gameState.tilesRevealedThisSession)")
                    StatRow(label: "Gems Found", value: "\(gameState.gemsCollectedThisSession)")
                    StatRow(label: "Mode", value: gameState.gameMode.displayName)
                }
                .padding(20)
                .background(theme.cardBackground)
                .cornerRadius(12)

                VStack(spacing: 12) {
                    MenuButton(title: "Resume", icon: "play.fill", color: theme.accentColor, action: onResume)
                    MenuButton(title: "Shop", icon: "bag.fill", color: theme.secondaryColor, action: onShop)
                    MenuButton(title: "Restart", icon: "arrow.counterclockwise", color: theme.accentColor.opacity(0.7), action: onRestart)
                    MenuButton(title: "Main Menu", icon: "house.fill", color: .white.opacity(0.4), action: onMainMenu)
                }
            }
            .padding(30)
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
    }
}

struct MenuButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24)
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color.opacity(0.3))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(color.opacity(0.5), lineWidth: 1)
            )
        }
    }
}
