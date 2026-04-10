import SwiftUI

/// SwiftUI overlay showing game HUD elements.
struct HUDOverlayView: View {
    @ObservedObject var gameState: GameState
    var onShopTapped: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            topPill
                .padding(.horizontal, 12)
                .padding(.top, 8)

            xpBar
                .padding(.horizontal, 16)
                .padding(.top, 5)

            Spacer()
        }
        .allowsHitTesting(false)
        // Re-enable hit testing only on the interactive pill
        .overlay(alignment: .top) {
            interactivePill
                .padding(.horizontal, 12)
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

    // MARK: - Non-interactive pill (stats only, for layout/background)

    private var topPill: some View {
        pillBackground {
            HStack(spacing: 0) {
                statsSection
                pillDivider
                boosterSection
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Interactive overlay (same shape, all buttons active)

    private var interactivePill: some View {
        pillBackground {
            HStack(spacing: 0) {
                statsSection.allowsHitTesting(false)
                pillDivider.allowsHitTesting(false)
                boosterSection
            }
        }
    }

    @ViewBuilder
    private func pillBackground<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.55))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
    }

    // MARK: - Stats section (gems · sectors · timer)

    private var statsSection: some View {
        HStack(spacing: 14) {
            statItem(icon: "diamond.fill", value: "\(gameState.profile.gems)", color: .cyan)

            statItem(icon: "checkmark.seal.fill", value: "\(gameState.sectorsSolvedThisSession)", color: .green)

            if gameState.gameMode == .endless {
                statItem(
                    icon: "heart.fill",
                    value: "\(gameState.livesRemaining)",
                    color: gameState.livesRemaining <= 1 ? .red : .pink
                )
            }

            if gameState.gameMode == .timed {
                statItem(
                    icon: "timer",
                    value: gameState.timerManager.formattedTime,
                    color: gameState.timerManager.remaining <= 30 ? .red : .orange
                )
            }
        }
    }

    private func statItem(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
    }

    private var pillDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.15))
            .frame(width: 1, height: 22)
            .padding(.horizontal, 10)
    }

    // MARK: - Booster + action section

    private var boosterSection: some View {
        HStack(spacing: 0) {
            boosterButton(icon: "eye.fill",              count: gameState.revealOneAvailable,    color: .yellow, action: useRevealOne)
            boosterButton(icon: "checkmark.seal.fill",   count: gameState.solveSectorAvailable,  color: .purple, action: useSolveSector)
            boosterButton(icon: "arrow.uturn.backward",  count: gameState.undoMineAvailable,     color: .orange, action: useUndoMine)

            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 1, height: 22)
                .padding(.horizontal, 8)

            actionButton(icon: "bag.fill",   color: .cyan,  action: onShopTapped)
            actionButton(icon: "pause.fill", color: .white, action: { gameState.pauseGame() })
        }
    }

    private func boosterButton(icon: String, count: Int, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                Text("\(count)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
            }
            .foregroundColor(count > 0 ? color : color.opacity(0.35))
            .frame(minWidth: 44, minHeight: 36)
        }
        .disabled(count <= 0)
        .buttonStyle(.plain)
    }

    private func actionButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
    }

    // MARK: - XP bar

    private var xpBar: some View {
        HStack(spacing: 6) {
            Text("Lv.\(gameState.profile.level)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 4)

                    Capsule()
                        .fill(LinearGradient(
                            colors: [.cyan, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geometry.size.width * gameState.profile.xpProgress, height: 4)
                }
            }
            .frame(height: 4)

            Text("\(gameState.profile.xp)/\(gameState.profile.xpForNextLevel)")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))
        }
        .allowsHitTesting(false)
    }

    // MARK: - Actions

    private func useRevealOne() {
        gameState.useRevealOne(sectorCoord: gameState.focusedSector)
    }

    private func useSolveSector() {
        gameState.useSolveSector(sectorCoord: gameState.focusedSector)
    }

    private func useUndoMine() {
        let center = gameState.focusedSector
        for radius in 0...5 {
            for dx in -radius...radius {
                for dy in -radius...radius {
                    if abs(dx) != radius && abs(dy) != radius { continue }
                    let coord = SectorCoordinate(x: center.x + dx, y: center.y + dy)
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
