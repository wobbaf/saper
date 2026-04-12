import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameState: GameState
    @State private var showClassicMenu = false
    @State private var classicDifficulty: ClassicDifficulty?
    @State private var splashDone = false
    @State private var splashOpacity: Double = 1

    var body: some View {
        ZStack {
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

            if !splashDone {
                SplashScreenView()
                    .opacity(splashOpacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(splashOpacity > 0.1)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    splashOpacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    splashDone = true
                }
            }
        }
    }
}

