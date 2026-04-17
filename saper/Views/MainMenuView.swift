import SwiftUI

/// Main menu with animated starfield background and game mode selection.
struct MainMenuView: View {
    @ObservedObject var gameState: GameState
    var onClassicMode: () -> Void = {}
    @State private var showSettings = false
    @State private var showLeaderboard = false
    @State private var showShop = false
    @State private var showHowToPlay = false
    @State private var animateTitle = false
    @State private var titleGlowPhase = false
    private var theme: SkinUITheme { gameState.profile.currentSkin.uiTheme }

    var body: some View {
        ZStack {
            // Background — always driven by skin theme
            LinearGradient(
                colors: theme.backgroundColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if theme.showStarfield {
                StarFieldBackgroundView()
            }

            VStack(spacing: 0) {
                Spacer()

                // Title
                VStack(spacing: 8) {
                    ZStack {
                        // Glow layer — only for skins with dark, vibrant backgrounds
                        if theme.showStarfield {
                            Text("MINESWEEPER")
                                .font(.system(size: 36, weight: .black, design: .monospaced))
                                .foregroundStyle(LinearGradient(colors: theme.titleColors, startPoint: .leading, endPoint: .trailing))
                                .blur(radius: titleGlowPhase ? 14 : 8)
                                .opacity(titleGlowPhase ? 0.65 : 0.35)
                        }

                        Text("MINESWEEPER")
                            .font(.system(size: 36, weight: .black, design: .monospaced))
                            .foregroundStyle(LinearGradient(colors: theme.titleColors, startPoint: .leading, endPoint: .trailing))
                            .opacity(animateTitle ? 1.0 : 0.8)
                    }

                    Text("F O R E V E R")
                        .font(.system(size: 20, weight: .light, design: .monospaced))
                        .foregroundColor(theme.secondaryTextColor)
                        .tracking(8)
                }
                .padding(.bottom, 50)

                // Game mode buttons
                VStack(spacing: 16) {
                    ForEach(GameMode.allCases, id: \.self) { mode in
                        Button(action: { startGame(mode: mode) }) {
                            modeRow(
                                icon: iconForMode(mode),
                                title: mode.displayName,
                                borderColor: borderColorForMode(mode)
                            )
                        }
                    }

                    Button(action: onClassicMode) {
                        modeRow(
                            icon: "square.grid.3x3.topleft.filled",
                            title: "Classic",
                            borderColor: theme.secondaryTextColor.opacity(0.3)
                        )
                    }
                }
                .padding(.horizontal, 30)

                Spacer()

                // Stats bar
                HStack(spacing: 20) {
                    StatBadge(icon: "diamond.fill", value: "\(gameState.profile.gems)", color: theme.accentColor, cardBg: theme.cardBackground, textColor: theme.primaryTextColor)
                    StatBadge(icon: "star.fill", value: "Lv.\(gameState.profile.level)", color: .yellow, cardBg: theme.cardBackground, textColor: theme.primaryTextColor)
                    StatBadge(icon: "trophy.fill", value: "\(gameState.profile.totalSectorsSolved)", color: .orange, cardBg: theme.cardBackground, textColor: theme.primaryTextColor)
                }
                .padding(.bottom, 20)

                // Bottom buttons
                HStack(spacing: 28) {
                    iconButton(icon: "gearshape.fill", label: "Settings", action: { showSettings = true })
                    iconButton(icon: "trophy.fill", label: "Scores", action: { showLeaderboard = true })
                    iconButton(icon: "arrow.up.circle.fill", label: "Upgrades", action: { showShop = true }, accent: true)
                    iconButton(icon: "book.fill", label: "Guide", action: { showHowToPlay = true })
                }
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(gameState: gameState)
        }
        .sheet(isPresented: $showLeaderboard) {
            LeaderboardView(gameState: gameState)
        }
        .sheet(isPresented: $showShop) {
            PrestigeShopView(gameState: gameState)
        }
        .sheet(isPresented: $showHowToPlay) {
            HowToPlayView(gameState: gameState)
        }
        .onAppear {
            AnalyticsManager.screenView("main_menu")
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animateTitle = true
            }
            withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
                titleGlowPhase = true
            }
        }
    }

    private func startGame(mode: GameMode) {
        if mode != .endless && mode != .hardcore {
            gameState.startGame(mode: mode)
            return
        }
        if GamePersistence.hasMeaningfulSave(for: mode) && gameState.resumeFromSave(mode: mode) {
            // Auto-resume — player had actual progress
        } else {
            gameState.resetBoard(mode: mode)
        }
    }

    @ViewBuilder
    private func modeRow(icon: String, title: String, borderColor: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .frame(width: 30)

            Text(title)
                .font(.system(size: 18, weight: .bold, design: .monospaced))

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(theme.secondaryTextColor.opacity(0.6))
        }
        .foregroundColor(theme.primaryTextColor)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.buttonBackground)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1))
        )
    }

    @ViewBuilder
    private func iconButton(icon: String, label: String, action: @escaping () -> Void, accent: Bool = false) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 22))
                Text(label).font(.system(size: 10))
            }
            .foregroundColor(accent ? theme.accentColor : theme.secondaryTextColor)
        }
    }

    private func iconForMode(_ mode: GameMode) -> String {
        switch mode {
        case .endless:  return "infinity"
        case .hardcore: return "flame.fill"
        case .timed:    return "timer"
        case .practice: return "graduationcap.fill"
        }
    }

    private func borderColorForMode(_ mode: GameMode) -> Color {
        switch mode {
        case .endless:  return theme.accentColor.opacity(0.4)
        case .hardcore: return .red.opacity(0.35)
        case .timed:    return .orange.opacity(0.35)
        case .practice: return .green.opacity(0.35)
        }
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let color: Color
    var cardBg: Color = Color.white.opacity(0.08)
    var textColor: Color = .white

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 12))
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(textColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(cardBg)
        .cornerRadius(8)
    }
}

/// Simple SwiftUI animated star background for the menu.
struct StarFieldBackgroundView: View {
    @State private var stars: [(CGFloat, CGFloat, CGFloat, Double)] = []

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                for (x, y, radius, opacity) in stars {
                    let rect = CGRect(
                        x: x * size.width - radius,
                        y: y * size.height - radius,
                        width: radius * 2,
                        height: radius * 2
                    )
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(.white.opacity(opacity))
                    )
                }
            }
            .onAppear {
                stars = (0..<100).map { _ in
                    (
                        CGFloat.random(in: 0...1),
                        CGFloat.random(in: 0...1),
                        CGFloat.random(in: 0.5...2),
                        Double.random(in: 0.1...0.6)
                    )
                }
            }
        }
    }
}
