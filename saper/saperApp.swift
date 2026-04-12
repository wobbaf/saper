import SwiftUI

@main
struct saperApp: App {
    @StateObject private var gameState: GameState
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let profile = ProfilePersistence.loadProfile()
        let seed = ProfilePersistence.loadOrCreateSeed()
        _gameState = StateObject(wrappedValue: GameState(profile: profile, seed: seed))

        AudioManager.shared.setup()
        HapticsManager.shared.setup()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameState)
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .background || newPhase == .inactive {
                        saveState()
                    }
                }
                .preferredColorScheme(colorScheme)
        }
    }

    private var colorScheme: ColorScheme? {
        switch gameState.profile.appearanceMode {
        case 1: return .light
        case 2: return .dark
        default: return nil // system
        }
    }

    private func saveState() {
        ProfilePersistence.saveProfile(gameState.profile)
        if gameState.isPlaying && !gameState.isGameOver {
            GamePersistence.saveBoard(
                boardManager: gameState.boardManager,
                gameMode: gameState.gameMode,
                sectorsSolved: gameState.sectorsSolvedThisSession,
                tilesRevealed: gameState.tilesRevealedThisSession,
                gemsCollected: gameState.gemsCollectedThisSession,
                livesRemaining: gameState.livesRemaining,
                runBoosters: gameState.runBoosters,
                runPerks: gameState.runPerks,
                startingDifficultyBonus: gameState.startingDifficultyBonus
            )
        }
    }
}
