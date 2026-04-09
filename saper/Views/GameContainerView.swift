import SwiftUI
import SpriteKit

/// Hosts the SpriteKit game scene with a SwiftUI HUD overlay.
struct GameContainerView: View {
    @ObservedObject var gameState: GameState
    @State private var scene: GameScene?
    @State private var sceneID = UUID()
    @State private var showResetConfirmation = false
    @State private var showShop = false

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
                    showResetConfirmation = true
                } onShop: {
                    showShop = true
                } onMainMenu: {
                    gameState.recordLeaderboardEntry()
                    if gameState.gameMode == .endless || gameState.gameMode == .hardcore {
                        GamePersistence.saveBoard(
                            boardManager: gameState.boardManager,
                            gameMode: gameState.gameMode,
                            sectorsSolved: gameState.sectorsSolvedThisSession,
                            tilesRevealed: gameState.tilesRevealedThisSession,
                            gemsCollected: gameState.gemsCollectedThisSession
                        )
                    }
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

            if !gameState.pendingPerkOffer.isEmpty {
                PerkPickerView(
                    perks: gameState.pendingPerkOffer,
                    level: gameState.profile.level
                ) { perk in
                    gameState.applyPerk(perk)
                }
            }
        }
        .sheet(isPresented: $showShop) {
            ShopView(gameState: gameState)
        }
        .onAppear {
            createScene()
        }
        .alert("Start New Game?", isPresented: $showResetConfirmation) {
            Button("New Game", role: .destructive) { restartGame() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your current progress will be lost.")
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
