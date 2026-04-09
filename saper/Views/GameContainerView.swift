import SwiftUI
import SpriteKit

/// Hosts the SpriteKit game scene with a SwiftUI HUD overlay.
struct GameContainerView: View {
    @ObservedObject var gameState: GameState
    @State private var scene: GameScene?
    @State private var sceneID = UUID()

    var body: some View {
        ZStack {
            if let scene = scene {
                SpriteView(
                    scene: scene,
                    preferredFramesPerSecond: 60,
                    options: [.ignoresSiblingOrder]
                )
                .ignoresSafeArea()
                .id(sceneID)
            } else {
                Color.black
                    .ignoresSafeArea()
            }

            HUDOverlayView(gameState: gameState)

            if gameState.isPaused {
                PauseMenuView(gameState: gameState) {
                    gameState.resumeGame()
                } onRestart: {
                    restartGame()
                } onMainMenu: {
                    gameState.recordLeaderboardEntry()
                    GamePersistence.clearSave()
                    gameState.isPlaying = false
                }
            }

            if gameState.isGameOver {
                GameOverView(gameState: gameState) {
                    restartGame()
                } onMainMenu: {
                    gameState.isPlaying = false
                }
            }

            if gameState.showLevelUp {
                LevelUpView(level: gameState.profile.level) {
                    gameState.showLevelUp = false
                }
            }
        }
        .onAppear {
            createScene()
        }
        .statusBarHidden()
    }

    private func createScene() {
        let newScene = GameScene()
        newScene.gameState = gameState
        newScene.scaleMode = .resizeFill
        scene = newScene
        sceneID = UUID()
    }

    private func restartGame() {
        gameState.restartGame()
        createScene()
    }
}
