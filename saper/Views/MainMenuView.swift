import SwiftUI

/// Main menu with animated starfield background and game mode selection.
struct MainMenuView: View {
    @ObservedObject var gameState: GameState
    var onClassicMode: () -> Void = {}
    @Environment(\.colorScheme) private var colorScheme
    @State private var showSettings = false
    @State private var showSkinPicker = false
    @State private var showLeaderboard = false
    @State private var showShop = false
    @State private var animateTitle = false
    @State private var titleGlowPhase = false
    @State private var pendingMode: GameMode? = nil
    @State private var showResumeAlert = false

    private var isDark: Bool { colorScheme == .dark }

    private var theme: SkinUITheme { gameState.profile.currentSkin.uiTheme }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: isDark ? theme.backgroundColors : [
                    Color(red: 0.92, green: 0.93, blue: 0.96),
                    Color(red: 0.85, green: 0.87, blue: 0.95),
                    Color(red: 0.92, green: 0.93, blue: 0.96)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if isDark && theme.showStarfield {
                StarFieldBackgroundView()
            }

            VStack(spacing: 0) {
                Spacer()

                // Title
                VStack(spacing: 8) {
                    ZStack {
                        if isDark {
                            Text("MINESWEEPER")
                                .font(.system(size: 36, weight: .black, design: .monospaced))
                                .foregroundStyle(LinearGradient(colors: theme.titleColors, startPoint: .leading, endPoint: .trailing))
                                .blur(radius: titleGlowPhase ? 14 : 8)
                                .opacity(titleGlowPhase ? 0.65 : 0.35)
                        }

                        Text("MINESWEEPER")
                            .font(.system(size: 36, weight: .black, design: .monospaced))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: isDark ? theme.titleColors : [.blue, .purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .opacity(animateTitle ? 1.0 : 0.7)
                    }

                    Text("I N F I N I T Y")
                        .font(.system(size: 20, weight: .light, design: .monospaced))
                        .foregroundColor(isDark ? .white.opacity(0.6) : .secondary)
                        .tracking(8)
                }
                .padding(.bottom, 50)

                // Game mode buttons
                VStack(spacing: 16) {
                    Button(action: onClassicMode) {
                        modeRow(
                            icon: "square.grid.3x3.topleft.filled",
                            title: "Classic",
                            subtitle: "Windows-style Minesweeper",
                            borderColor: Color.gray.opacity(0.3)
                        )
                    }

                    ForEach(GameMode.allCases, id: \.self) { mode in
                        Button(action: { startGame(mode: mode) }) {
                            modeRow(
                                icon: iconForMode(mode),
                                title: mode.displayName,
                                subtitle: mode.description,
                                borderColor: borderColorForMode(mode)
                            )
                        }
                    }
                }
                .padding(.horizontal, 30)

                Spacer()

                // Stats bar
                HStack(spacing: 20) {
                    StatBadge(icon: "diamond.fill", value: "\(gameState.profile.gems)", color: theme.accentColor, cardBg: theme.cardBackground)
                    StatBadge(icon: "star.fill", value: "Lv.\(gameState.profile.level)", color: .yellow, cardBg: theme.cardBackground)
                    StatBadge(icon: "trophy.fill", value: "\(gameState.profile.totalSectorsSolved)", color: .orange, cardBg: theme.cardBackground)
                }
                .padding(.bottom, 20)

                // Bottom buttons
                HStack(spacing: 30) {
                    iconButton(icon: "gearshape.fill", label: "Settings", action: { showSettings = true })
                    iconButton(icon: "trophy.fill", label: "Scores", action: { showLeaderboard = true })
                    iconButton(icon: "paintbrush.fill", label: "Skins", action: { showSkinPicker = true })
                    iconButton(icon: "arrow.up.circle.fill", label: "Upgrades", action: { showShop = true }, accent: true)
                }
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(gameState: gameState)
        }
        .sheet(isPresented: $showSkinPicker) {
            SkinPickerView(gameState: gameState)
        }
        .sheet(isPresented: $showLeaderboard) {
            LeaderboardView()
        }
        .sheet(isPresented: $showShop) {
            PrestigeShopView(gameState: gameState)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animateTitle = true
            }
            withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
                titleGlowPhase = true
            }
        }
        .alert("Resume Game?", isPresented: $showResumeAlert, presenting: pendingMode) { mode in
            Button("Resume") {
                if !gameState.resumeFromSave() { gameState.startGame(mode: mode) }
            }
            Button("New Game", role: .destructive) { gameState.resetBoard(mode: mode) }
            Button("Cancel", role: .cancel) { pendingMode = nil }
        } message: { mode in
            Text("You have a saved \(mode.displayName) game in progress.")
        }
    }

    private func startGame(mode: GameMode) {
        if (mode == .endless || mode == .hardcore),
           GamePersistence.savedGameMode() == mode {
            pendingMode = mode
            showResumeAlert = true
        } else {
            gameState.startGame(mode: mode)
        }
    }

    @ViewBuilder
    private func modeRow(icon: String, title: String, subtitle: String, borderColor: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(isDark ? .white.opacity(0.5) : .secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(isDark ? .white.opacity(0.3) : .secondary.opacity(0.5))
        }
        .foregroundColor(isDark ? .white : .primary)
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
            .foregroundColor(accent ? theme.accentColor : (isDark ? .white.opacity(0.6) : .secondary))
        }
    }

    private func iconForMode(_ mode: GameMode) -> String {
        switch mode {
        case .endless: return "infinity"
        case .hardcore: return "flame.fill"
        case .timed: return "timer"
        }
    }

    private func borderColorForMode(_ mode: GameMode) -> Color {
        switch mode {
        case .endless: return theme.accentColor.opacity(0.4)
        case .hardcore: return .red.opacity(0.35)
        case .timed: return .orange.opacity(0.35)
        }
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let color: Color
    var cardBg: Color = Color.white.opacity(0.08)
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 12))
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(colorScheme == .dark ? .white : .primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(colorScheme == .dark ? cardBg : Color.black.opacity(0.06))
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
