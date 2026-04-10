import SwiftUI

/// Game over / results screen.
struct GameOverView: View {
    @ObservedObject var gameState: GameState
    let onPlayAgain: () -> Void
    let onMainMenu: () -> Void
    @State private var showLeaderboard = false

    private var theme: SkinUITheme { gameState.profile.currentSkin.uiTheme }

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text(gameState.gameMode == .hardcore ? "GAME OVER" : "TIME'S UP")
                    .font(.system(size: 32, weight: .black, design: .monospaced))
                    .foregroundStyle(
                        gameState.gameMode == .hardcore
                        ? LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
                    )

                VStack(spacing: 12) {
                    ResultRow(icon: "checkmark.seal.fill", label: "Sectors Solved", value: "\(gameState.sectorsSolvedThisSession)", color: theme.accentColor)
                    ResultRow(icon: "square.grid.3x3.fill", label: "Tiles Revealed", value: "\(gameState.tilesRevealedThisSession)", color: .blue)
                    ResultRow(icon: "diamond.fill", label: "Gems Collected", value: "\(gameState.gemsCollectedThisSession)", color: theme.accentColor)

                    Divider().background(Color.white.opacity(0.2))

                    ResultRow(icon: "star.fill", label: "XP Gained", value: "\(gameState.tilesRevealedThisSession + gameState.sectorsSolvedThisSession * 50)", color: .yellow)

                    let highScore = currentHighScore()
                    ResultRow(icon: "trophy.fill", label: "Best", value: "\(highScore)", color: .orange)
                }
                .padding(20)
                .background(theme.cardBackground)
                .cornerRadius(12)

                VStack(spacing: 12) {
                    Button(action: onPlayAgain) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Play Again")
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [theme.accentColor.opacity(0.35), theme.secondaryColor.opacity(0.35)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(theme.accentColor.opacity(0.5), lineWidth: 1)
                        )
                    }

                    HStack(spacing: 20) {
                        Button(action: { showLeaderboard = true }) {
                            Text("Scores")
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(theme.accentColor.opacity(0.8))
                                .padding(.vertical, 12)
                        }

                        Button(action: onMainMenu) {
                            Text("Main Menu")
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.vertical, 12)
                        }
                    }
                }
            }
            .padding(30)
        }
        .sheet(isPresented: $showLeaderboard) {
            LeaderboardView(gameState: gameState)
        }
    }

    private func currentHighScore() -> Int {
        switch gameState.gameMode {
        case .endless: return gameState.profile.highScoreEndless
        case .hardcore: return gameState.profile.highScoreHardcore
        case .timed: return gameState.profile.highScoreTimed
        }
    }
}

struct ResultRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(label)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
    }
}
