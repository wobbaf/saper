import SwiftUI

private struct LeaderboardTab: Identifiable {
    let id: String
    let label: String
    let icon: String
}

private let leaderboardTabs: [LeaderboardTab] = [
    LeaderboardTab(id: "endless", label: "Endless", icon: "infinity"),
    LeaderboardTab(id: "hardcore", label: "Hardcore", icon: "flame.fill"),
    LeaderboardTab(id: "timed", label: "Timed", icon: "timer"),
    LeaderboardTab(id: "classic_beginner", label: "Classic B", icon: "square.grid.3x3"),
    LeaderboardTab(id: "classic_intermediate", label: "Classic I", icon: "square.grid.3x3"),
    LeaderboardTab(id: "classic_expert", label: "Classic E", icon: "square.grid.3x3"),
]

/// Local leaderboard view showing scores across all modes, plus achievements.
struct LeaderboardView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: String = "endless"
    @State private var showAchievements = false

    private var theme: SkinUITheme { gameState.profile.currentSkin.uiTheme }

    var body: some View {
        NavigationView {
            ZStack {
                theme.backgroundColors[0]
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Tab picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(leaderboardTabs) { tab in
                                tabButton(tab: tab)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }

                    Divider()
                        .background(theme.secondaryTextColor.opacity(0.2))

                    // Entries list
                    let entries = LeaderboardPersistence.entries(forMode: selectedTab)

                    if entries.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "trophy")
                                .font(.system(size: 40))
                                .foregroundColor(theme.secondaryTextColor.opacity(0.4))
                            Text("No scores yet")
                                .font(.system(size: 16, design: .monospaced))
                                .foregroundColor(theme.secondaryTextColor)
                            Text(emptyHint)
                                .font(.system(size: 12))
                                .foregroundColor(theme.secondaryTextColor.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                                LeaderboardRowView(rank: index + 1, entry: entry, theme: theme)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparatorTint(theme.secondaryTextColor.opacity(0.12))
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("Scores")
            .navigationBarColorScheme(theme.isDark ? .dark : .light)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showAchievements = true
                    } label: {
                        Label("Medals", systemImage: "medal.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.yellow)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(theme.accentColor)
                }
            }
            .sheet(isPresented: $showAchievements) {
                AchievementListView(gameState: gameState)
            }
        }
        .onAppear { AnalyticsManager.screenView("leaderboard") }
    }

    @ViewBuilder
    private func tabButton(tab: LeaderboardTab) -> some View {
        let isSelected = selectedTab == tab.id
        let fillColor: Color = isSelected
            ? theme.accentColor.opacity(0.25)
            : theme.primaryTextColor.opacity(0.06)
        let strokeColor: Color = isSelected
            ? theme.accentColor.opacity(0.5)
            : Color.clear
        let textColor: Color = isSelected
            ? theme.accentColor
            : theme.secondaryTextColor

        Button(action: { selectedTab = tab.id }) {
            HStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 10))
                Text(tab.label)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8).fill(fillColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8).stroke(strokeColor, lineWidth: 1)
            )
            .foregroundColor(textColor)
        }
    }

    private var emptyHint: String {
        if selectedTab.hasPrefix("classic") {
            return "Win a classic game to appear here"
        }
        return "Play a game to appear here"
    }
}

struct LeaderboardRowView: View {
    let rank: Int
    let entry: LeaderboardEntry
    let theme: SkinUITheme

    var body: some View {
        HStack(spacing: 12) {
            // Rank
            Text("#\(rank)")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(rankColor)
                .frame(width: 40, alignment: .leading)

            // Score
            VStack(alignment: .leading, spacing: 2) {
                Text(scoreText)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(theme.primaryTextColor)
                Text(entry.detail)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(theme.secondaryTextColor)
            }

            Spacer()

            // Date
            Text(formattedDate)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(theme.secondaryTextColor.opacity(0.7))
        }
        .padding(.vertical, 4)
    }

    private var scoreText: String {
        if entry.lowerIsBetter {
            let minutes = entry.score / 60
            let seconds = entry.score % 60
            return minutes > 0 ? "\(minutes)m \(seconds)s" : "\(seconds)s"
        }
        return "\(entry.score) sectors"
    }

    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.78) // silver
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2) // bronze
        default: return theme.secondaryTextColor
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: entry.date)
    }
}
