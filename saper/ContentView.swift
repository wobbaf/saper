import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameState: GameState
    @State private var showClassicMenu = false
    @State private var classicDifficulty: ClassicDifficulty?

    var body: some View {
        Group {
            if let difficulty = classicDifficulty {
                ClassicContainerView(difficulty: difficulty) {
                    classicDifficulty = nil
                }
            } else if showClassicMenu {
                ClassicMenuView(
                    onStartGame: { difficulty in
                        classicDifficulty = difficulty
                        showClassicMenu = false
                    },
                    onBack: {
                        showClassicMenu = false
                    }
                )
            } else if gameState.isPlaying {
                GameContainerView(gameState: gameState)
            } else {
                MainMenuView(gameState: gameState) {
                    showClassicMenu = true
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: gameState.isPlaying)
        .animation(.easeInOut(duration: 0.3), value: showClassicMenu)
        .animation(.easeInOut(duration: 0.3), value: classicDifficulty?.rawValue)
    }
}

