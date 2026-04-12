import SwiftUI

/// SwiftUI overlay showing game HUD elements.
struct HUDOverlayView: View {
    @ObservedObject var gameState: GameState
    var onShopTapped: () -> Void = {}

    // Booster bounce animation state
    @State private var revealOneBounce: Bool = false
    @State private var solveSectorBounce: Bool = false
    @State private var undoMineBounce: Bool = false
    @State private var prevRevealOne: Int = 0
    @State private var prevSolveSector: Int = 0
    @State private var prevUndoMine: Int = 0

    // XP bar level-up glow
    @State private var xpBarGlowing: Bool = false

    var body: some View {
        Group {
            if gameState.gameMode == .practice {
                // Practice mode: minimal HUD — just a pause button
                ZStack(alignment: .top) {
                    VStack(spacing: 0) {
                        pillBackground {
                            actionButton(icon: "pause.fill", color: .white, action: { gameState.pauseGame() })
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                        Spacer()
                    }
                }
            } else {
                ZStack(alignment: .top) {
                    // Non-interactive background shapes for layout
                    VStack(spacing: 0) {
                        xpBar
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                        topPillBackground
                            .padding(.horizontal, 12)
                            .padding(.top, 5)

                        Spacer()
                    }
                    .allowsHitTesting(false)

                    // Interactive top pill
                    VStack(spacing: 0) {
                        Spacer().frame(height: 8 + 16 + 5) // xpBar height offset
                        interactiveTopPill
                            .padding(.horizontal, 12)
                        Spacer()
                    }

                    // Hardcore vignette
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
                // Bottom booster pill pinned to safe area bottom
                .overlay(alignment: .bottom) {
                    interactiveBottomPill
                        .padding(.horizontal, 12)
                        .padding(.bottom, 12)
                }
            }
        }
        .onAppear {
            prevRevealOne = gameState.revealOneAvailable
            prevSolveSector = gameState.solveSectorAvailable
            prevUndoMine = gameState.undoMineAvailable
        }
    }

    // MARK: - Top pill

    private var topPillBackground: some View {
        pillBackground {
            HStack(spacing: 0) {
                statsSection
                pillDivider
                actionSection
            }
        }
        .allowsHitTesting(false)
    }

    private var interactiveTopPill: some View {
        pillBackground {
            HStack(spacing: 0) {
                statsSection.allowsHitTesting(false)
                pillDivider.allowsHitTesting(false)
                actionSection
            }
        }
    }

    // MARK: - Bottom booster pill

    private var interactiveBottomPill: some View {
        pillBackground {
            HStack(spacing: 0) {
                boosterButton(icon: "eye.fill",             count: gameState.revealOneAvailable,   color: .yellow, action: useRevealOne)
                    .scaleEffect(revealOneBounce ? 1.3 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.4), value: revealOneBounce)
                boosterButton(icon: "checkmark.seal.fill",  count: gameState.solveSectorAvailable, color: .purple, action: useSolveSector)
                    .scaleEffect(solveSectorBounce ? 1.3 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.4), value: solveSectorBounce)
                boosterButton(icon: "arrow.uturn.backward", count: gameState.undoMineAvailable,    color: .orange, action: useUndoMine)
                    .scaleEffect(undoMineBounce ? 1.3 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.4), value: undoMineBounce)

                let shields = gameState.perkStacks(.mineShield)
                if shields > 0 {
                    pillDivider
                    shieldIndicator(count: shields)
                }
            }
            .onChange(of: gameState.revealOneAvailable) { newVal in
                if newVal > prevRevealOne {
                    revealOneBounce = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { revealOneBounce = false }
                }
                prevRevealOne = newVal
            }
            .onChange(of: gameState.solveSectorAvailable) { newVal in
                if newVal > prevSolveSector {
                    solveSectorBounce = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { solveSectorBounce = false }
                }
                prevSolveSector = newVal
            }
            .onChange(of: gameState.undoMineAvailable) { newVal in
                if newVal > prevUndoMine {
                    undoMineBounce = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { undoMineBounce = false }
                }
                prevUndoMine = newVal
            }
        }
    }

    // MARK: - Shared pill background

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

    // MARK: - Stats section (gems · sectors · streak · lives/timer)

    private var statsSection: some View {
        HStack(spacing: 14) {
            statItem(icon: "diamond.fill", value: "\(gameState.profile.gems)", color: .cyan)
            statItem(icon: "checkmark.seal.fill", value: "\(gameState.sectorsSolvedThisSession)", color: .green)

            if gameState.solveStreak >= 2 {
                statItem(
                    icon: "flame.fill",
                    value: "×\(String(format: "%.1f", gameState.streakXpMultiplier))",
                    color: streakColor
                )
            }

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

    private var streakColor: Color {
        let t = min(Double(gameState.solveStreak) / 10.0, 1.0)
        return t < 0.5 ? .orange : .red
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

    // MARK: - Action section (shop · pause)

    private var actionSection: some View {
        HStack(spacing: 0) {
            actionButton(icon: "bag.fill",   color: .cyan,  action: onShopTapped)
            actionButton(icon: "pause.fill", color: .white, action: { gameState.pauseGame() })
        }
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

    // MARK: - Booster button

    private func boosterButton(icon: String, count: Int, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                Text("\(count)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
            }
            .foregroundColor(count > 0 ? color : color.opacity(0.35))
            .frame(minWidth: 52, minHeight: 36)
        }
        .disabled(count <= 0)
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
                        .shadow(color: xpBarGlowing ? .cyan.opacity(0.9) : .clear, radius: 5)
                }
            }
            .frame(height: 4)
            .onChange(of: gameState.profile.level) { _ in
                withAnimation(.easeIn(duration: 0.1)) { xpBarGlowing = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.easeOut(duration: 0.4)) { xpBarGlowing = false }
                }
            }

            Text("\(gameState.profile.xp)/\(gameState.profile.xpForNextLevel)")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))
        }
        .allowsHitTesting(false)
    }

    // MARK: - Shield indicator

    private func shieldIndicator(count: Int) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "shield.fill")
                .font(.system(size: 13))
            Text("\(count)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
        }
        .foregroundColor(.blue)
        .frame(minWidth: 44, minHeight: 36)
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
