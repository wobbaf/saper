import SwiftUI
import SpriteKit

/// Hosts the classic minesweeper SpriteKit scene with a retro HUD.
struct ClassicContainerView: View {
    @StateObject private var classicGameState: ClassicGameState
    @State private var scene: ClassicGameScene?
    @State private var sceneID = UUID()

    let onMainMenu: () -> Void

    init(difficulty: ClassicDifficulty, onMainMenu: @escaping () -> Void) {
        _classicGameState = StateObject(wrappedValue: ClassicGameState(difficulty: difficulty))
        self.onMainMenu = onMainMenu
    }

    var body: some View {
        VStack(spacing: 0) {
            // Back button row
            HStack {
                Button(action: onMainMenu) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                        Text("Menu")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(retroRaisedBackground)
                }

                Spacer()

                Text(classicGameState.difficulty.displayName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)

                Spacer()

                // Invisible spacer to balance
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                    Text("Menu")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.clear)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .padding(.horizontal, 6)
            .padding(.top, 4)
            .background(Color(red: 192/255, green: 192/255, blue: 192/255))

            // Retro HUD
            ClassicHUDView(
                classicGameState: classicGameState,
                onRestart: { restartGame() },
                onBack: onMainMenu
            )

            // Game board
            ZStack {
                if let scene = scene {
                    SpriteView(
                        scene: scene,
                        preferredFramesPerSecond: 60,
                        options: [.ignoresSiblingOrder]
                    )
                    .id(sceneID)
                } else {
                    Color(red: 192/255, green: 192/255, blue: 192/255)
                }

                // Undo overlay on mine hit
                if classicGameState.canUndo {
                    VStack {
                        Spacer()
                        Button(action: {
                            classicGameState.undoMineHit()
                            createScene()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.uturn.backward")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Undo")
                                    .font(.system(size: 16, weight: .bold))
                                Text("(\(classicGameState.undoCount))")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.black.opacity(0.5))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(retroRaisedBackground)
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .background(Color(red: 192/255, green: 192/255, blue: 192/255))
        .onAppear { createScene() }
        .statusBarHidden()
    }

    private var retroRaisedBackground: some View {
        Rectangle()
            .fill(Color(red: 192/255, green: 192/255, blue: 192/255))
            .overlay(
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height

                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: w, y: 0))
                        path.addLine(to: CGPoint(x: w - 1, y: 1))
                        path.addLine(to: CGPoint(x: 1, y: 1))
                        path.closeSubpath()
                    }
                    .fill(Color.white)

                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: 0, y: h))
                        path.addLine(to: CGPoint(x: 1, y: h - 1))
                        path.addLine(to: CGPoint(x: 1, y: 1))
                        path.closeSubpath()
                    }
                    .fill(Color.white)

                    Path { path in
                        path.move(to: CGPoint(x: 0, y: h))
                        path.addLine(to: CGPoint(x: w, y: h))
                        path.addLine(to: CGPoint(x: w - 1, y: h - 1))
                        path.addLine(to: CGPoint(x: 1, y: h - 1))
                        path.closeSubpath()
                    }
                    .fill(Color(red: 128/255, green: 128/255, blue: 128/255))

                    Path { path in
                        path.move(to: CGPoint(x: w, y: 0))
                        path.addLine(to: CGPoint(x: w, y: h))
                        path.addLine(to: CGPoint(x: w - 1, y: h - 1))
                        path.addLine(to: CGPoint(x: w - 1, y: 1))
                        path.closeSubpath()
                    }
                    .fill(Color(red: 128/255, green: 128/255, blue: 128/255))
                }
            )
    }

    private func createScene() {
        let newScene = ClassicGameScene()
        newScene.classicGameState = classicGameState
        newScene.scaleMode = .resizeFill
        scene = newScene
        sceneID = UUID()
    }

    private func restartGame() {
        classicGameState.restartGame()
        createScene()
    }
}
