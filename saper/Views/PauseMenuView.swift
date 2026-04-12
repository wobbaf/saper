import SwiftUI

/// Pause menu overlay.
struct PauseMenuView: View {
    @ObservedObject var gameState: GameState
    let onResume: () -> Void
    let onRestart: () -> Void
    let onShop: () -> Void
    let onMainMenu: () -> Void

    private var theme: SkinUITheme { gameState.profile.currentSkin.uiTheme }

    @State private var showRestartConfirm = false
    @State private var showMainMenuConfirm = false
    @State private var showQuitConfirm = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("PAUSED")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(LinearGradient(colors: theme.titleColors, startPoint: .leading, endPoint: .trailing))

                VStack(spacing: 8) {
                    StatRow(label: "Sectors Solved", value: "\(gameState.sectorsSolvedThisSession)", theme: theme)
                    StatRow(label: "Tiles Revealed", value: "\(gameState.tilesRevealedThisSession)", theme: theme)
                    StatRow(label: "Gems Found",     value: "\(gameState.gemsCollectedThisSession)", theme: theme)
                    StatRow(label: "Mode",           value: gameState.gameMode.displayName,          theme: theme)
                }
                .padding(20)
                .background(theme.cardBackground)
                .cornerRadius(12)

                VStack(spacing: 12) {
                    MenuButton(title: "Resume",    icon: "play.fill",             tint: theme.accentColor,    background: theme.buttonBackground, textColor: theme.primaryTextColor, action: onResume)
                    MenuButton(title: "Shop",      icon: "bag.fill",               tint: theme.secondaryColor, background: theme.buttonBackground, textColor: theme.primaryTextColor, action: onShop)
                    MenuButton(title: "Restart",   icon: "arrow.counterclockwise", tint: theme.accentColor,    background: theme.buttonBackground, textColor: theme.primaryTextColor, action: { showRestartConfirm = true })
                    MenuButton(title: "Main Menu", icon: "house.fill",             tint: theme.accentColor.opacity(0.5), background: theme.buttonBackground, textColor: theme.primaryTextColor.opacity(0.6), action: { showMainMenuConfirm = true })
                    if gameState.gameMode == .endless || gameState.gameMode == .hardcore {
                        MenuButton(title: "Quit Run", icon: "xmark.circle.fill", tint: .red, background: theme.buttonBackground, textColor: .red, action: { showQuitConfirm = true })
                    }
                }
            }
            .padding(30)
        }
        .confirmationDialog("Restart game?", isPresented: $showRestartConfirm, titleVisibility: .visible) {
            Button("Restart", role: .destructive, action: onRestart)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your current progress will be lost.")
        }
        .confirmationDialog("Quit to main menu?", isPresented: $showMainMenuConfirm, titleVisibility: .visible) {
            Button("Quit", role: .destructive, action: onMainMenu)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(gameState.gameMode == .endless || gameState.gameMode == .hardcore
                 ? "Your run will be saved. You can resume it later."
                 : "Your current session will end.")
        }
        .confirmationDialog("End this run?", isPresented: $showQuitConfirm, titleVisibility: .visible) {
            Button("Quit Run", role: .destructive) {
                GamePersistence.clearSave(for: gameState.gameMode)
                gameState.isPlaying = false
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This run will be deleted and cannot be resumed.")
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    let theme: SkinUITheme

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(theme.primaryTextColor.opacity(0.6))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(theme.primaryTextColor)
        }
    }
}

struct MenuButton: View {
    let title: String
    let icon: String
    let tint: Color
    let background: Color
    let textColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24)
                    .foregroundColor(tint)
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(textColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(background)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(tint.opacity(0.6), lineWidth: 1)
            )
        }
    }
}
