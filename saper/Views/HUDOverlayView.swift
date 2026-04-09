import SwiftUI

/// SwiftUI overlay showing game HUD elements.
/// The overlay passes through touches except for interactive elements.
struct HUDOverlayView: View {
    @ObservedObject var gameState: GameState

    var body: some View {
        VStack(spacing: 0) {
            // Top HUD bar
            topBar
                .padding(.horizontal, 16)
                .padding(.top, 8)

            // XP bar
            xpBar
                .padding(.horizontal, 16)
                .padding(.top, 4)

            Spacer()
        }
        .allowsHitTesting(false) // entire VStack is pass-through
        .overlay(alignment: .topTrailing) {
            // Re-overlay just the interactive buttons — aligned topTrailing
            // so there's no Spacer eating touches
            HStack(spacing: 8) {
                Button(action: useRevealOne) {
                    HStack(spacing: 2) {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 12))
                        Text("\(gameState.profile.revealOneCount)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }
                .disabled(gameState.profile.revealOneCount <= 0)

                Button(action: useSolveSector) {
                    HStack(spacing: 2) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                        Text("\(gameState.profile.solveSectorCount)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(.purple)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }
                .disabled(gameState.profile.solveSectorCount <= 0)

                Button(action: useUndoMine) {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 12))
                        Text("\(gameState.profile.undoMineCount)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }
                .disabled(gameState.profile.undoMineCount <= 0)

                Button(action: { gameState.pauseGame() }) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(.trailing, 16)
            .padding(.top, 8)
        }
        .overlay {
            if gameState.gameMode == .hardcore {
                Rectangle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [.clear, .red.opacity(0.15)]),
                            center: .center,
                            startRadius: 100,
                            endRadius: 400
                        )
                    )
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
    }

    private var topBar: some View {
        HStack {
            // Gem count
            HStack(spacing: 4) {
                Image(systemName: "diamond.fill")
                    .foregroundColor(.cyan)
                    .font(.system(size: 14))
                Text("\(gameState.profile.gems)")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)

            // Score
            HStack(spacing: 4) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 14))
                Text("\(gameState.sectorsSolvedThisSession)")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)

            if gameState.gameMode == .timed {
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .foregroundColor(.orange)
                        .font(.system(size: 14))
                    Text(gameState.timerManager.formattedTime)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(gameState.timerManager.remaining <= 30 ? .red : .white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }

            Spacer()
        }
    }

    private var xpBar: some View {
        HStack {
            Text("Lv.\(gameState.profile.level)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 4)
                        .cornerRadius(2)

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.cyan, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * gameState.profile.xpProgress, height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(height: 4)

            Text("\(gameState.profile.xp)/\(gameState.profile.xpForNextLevel)")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    private func useRevealOne() {
        let centerSector = SectorCoordinate(x: 0, y: 0)
        gameState.useRevealOne(sectorCoord: centerSector)
    }

    private func useSolveSector() {
        let centerSector = SectorCoordinate(x: 0, y: 0)
        gameState.useSolveSector(sectorCoord: centerSector)
    }

    private func useUndoMine() {
        // Find the nearest locked sector
        for radius in 0...5 {
            for dx in -radius...radius {
                for dy in -radius...radius {
                    if abs(dx) != radius && abs(dy) != radius { continue }
                    let coord = SectorCoordinate(x: dx, y: dy)
                    if let sector = gameState.boardManager.sector(at: coord),
                       sector.status == .locked {
                        gameState.useUndoMine(sectorCoord: coord)
                        return
                    }
                }
            }
        }
    }
}
