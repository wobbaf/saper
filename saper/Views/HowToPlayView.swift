import SwiftUI

struct HowToPlayView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss

    private var theme: SkinUITheme { gameState.profile.currentSkin.uiTheme }

    var body: some View {
        NavigationView {
            theBody
                .navigationTitle("How to Play")
                .navigationBarColorScheme(theme.isDark ? .dark : .light)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                            .foregroundColor(theme.accentColor)
                    }
                }
        }
        .onAppear { AnalyticsManager.screenView("how_to_play") }
    }

    @ViewBuilder
    private var theBody: some View {
        if #available(iOS 16, *) {
            ZStack {
                LinearGradient(colors: theme.backgroundColors, startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                scrollContent
                    .scrollContentBackground(.hidden)
            }
            .toolbarBackground(theme.backgroundColors.first ?? .clear, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        } else {
            ZStack {
                LinearGradient(colors: theme.backgroundColors, startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                scrollContent
            }
        }
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                section("The Basics") {
                    rule(icon: "hand.tap.fill", color: .cyan,
                         title: "Tap to reveal",
                         body: "Tap any hidden tile to uncover it. Numbers show how many mines are directly adjacent (including diagonals). A blank tile means zero — it auto-expands to reveal surrounding safe tiles.")
                    rule(icon: "hand.point.up.left.fill", color: .orange,
                         title: "Long-press to flag",
                         body: "Long-press a hidden tile to place a flag marking a suspected mine. Long-press again to remove it.")
                    rule(icon: "arrow.triangle.2.circlepath", color: .purple,
                         title: "Chord reveal",
                         body: "Tap a revealed number whose adjacent flag count matches it — all remaining hidden neighbors are instantly revealed. Great for speeding up safe areas.")
                }

                section("Sectors") {
                    rule(icon: "square.grid.3x3.fill", color: .green,
                         title: "Solving a sector",
                         body: "The board is divided into sectors. Reveal all safe tiles in a sector to solve it and earn XP, gems, and a streak bonus.")
                    rule(icon: "lock.fill", color: .red,
                         title: "Locked sectors",
                         body: "Hit a mine and the sector locks. Tap the locked sector to pay gems and unlock it, or use an Undo Mine booster to restore it for free.")
                    rule(icon: "moon.fill", color: .gray,
                         title: "Inactive sectors",
                         body: "Sectors far from your current area start inactive. Tap one to activate it for a small gem cost — the cost scales with difficulty.")
                }

                section("Game Modes") {
                    rule(icon: "infinity", color: .cyan,
                         title: "Endless",
                         body: "Explore forever with 3 lives. Lose a life each time you hit a mine. Run ends at 0 lives.")
                    rule(icon: "bolt.fill", color: .red,
                         title: "Hardcore",
                         body: "One mine hit = game over. No lives, no second chances. Mine shields are your only protection.")
                    rule(icon: "timer", color: .orange,
                         title: "Timed",
                         body: "3 minutes to solve as many sectors as possible. No lives — but the clock never stops.")
                    rule(icon: "figure.play", color: .green,
                         title: "Practice",
                         body: "Infinite lives, no score tracking. Great for learning the board and experimenting.")
                    rule(icon: "square.grid.3x3.topleft.filled", color: theme.accentColor,
                         title: "Classic",
                         body: "Fixed-size boards (Beginner, Intermediate, Expert) — traditional minesweeper with a single grid, no infinite scroll.")
                }

                section("Boosters") {
                    rule(icon: "checkmark.seal.fill", color: .purple,
                         title: "Solve Sector",
                         body: "Instantly reveals all safe tiles in the focused sector. Remaining hidden tiles (mines) are auto-flagged if Auto-Flag is on.")
                    rule(icon: "arrow.uturn.backward", color: .orange,
                         title: "Undo Mine",
                         body: "Finds the nearest locked sector and resets it to active, as if the mine was never hit. Also refunds a life in Endless mode.")
                    rule(icon: "shield.fill", color: .blue,
                         title: "Mine Shield",
                         body: "Passively absorbs the next mine hit — the sector stays active and no life is lost. Consumed automatically on hit.")
                    rule(icon: "heart.fill", color: .pink,
                         title: "Refill Heart",
                         body: "Restores one lost life in Endless mode. Has no effect in other modes.")
                }

                section("Progression") {
                    rule(icon: "star.fill", color: .yellow,
                         title: "XP and levels",
                         body: "Reveal tiles and solve sectors to earn XP. Each level-up offers a choice of 3 run perks that boost your current game.")
                    rule(icon: "flame.fill", color: .orange,
                         title: "Solve streak",
                         body: "Solve sectors back-to-back without dying to build a streak. A streak multiplies XP gained — up to 2×.")
                    rule(icon: "diamond.fill", color: .cyan,
                         title: "Gems",
                         body: "Collected from gem tiles and sector rewards. Spend them in the Shop to buy boosters or unlock skins, and in-game to activate inactive sectors.")
                }

                section("Tips") {
                    rule(icon: "lightbulb.fill", color: .yellow,
                         title: "Start in the middle",
                         body: "The 3×3 cluster around (0,0) is always pre-activated. Tap somewhere there first for a safe opening.")
                    rule(icon: "shield.lefthalf.filled", color: .cyan,
                         title: "Island Immunity",
                         body: "With Island Immunity on (Settings), mine hits are absorbed without locking your sector until you uncover your first flood-fill island. The mine stays in place — flag it and work around it. Resume never grants this.")
                    rule(icon: "flag.fill", color: .green,
                         title: "Flag-Only Mode",
                         body: "Enable in Settings to swap controls: tap places a flag, long-press reveals. Chord still works the same.")
                }

            }
            .padding(20)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(theme.accentColor)
                .tracking(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            content()
        }
        .frame(maxWidth: .infinity)
    }

    private func rule(icon: String, color: Color, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 28)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(theme.primaryTextColor)
                Text(body)
                    .font(.system(size: 13))
                    .foregroundColor(theme.primaryTextColor.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.cardBackground)
        .cornerRadius(10)
    }
}
