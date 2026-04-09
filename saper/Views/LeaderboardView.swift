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

/// Local leaderboard view showing scores across all modes.
struct LeaderboardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab: String = "endless"

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        NavigationView {
            ZStack {
                (isDark ? Color(red: 0.05, green: 0.05, blue: 0.12) : Color(red: 0.94, green: 0.94, blue: 0.97))
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
                        .background(isDark ? Color.white.opacity(0.1) : Color.black.opacity(0.1))

                    // Entries list
                    let entries = LeaderboardPersistence.entries(forMode: selectedTab)

                    if entries.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "trophy")
                                .font(.system(size: 40))
                                .foregroundColor(isDark ? .white.opacity(0.2) : .secondary.opacity(0.3))
                            Text("No scores yet")
                                .font(.system(size: 16, design: .monospaced))
                                .foregroundColor(isDark ? .white.opacity(0.4) : .secondary)
                            Text(emptyHint)
                                .font(.system(size: 12))
                                .foregroundColor(isDark ? .white.opacity(0.3) : .secondary.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                                LeaderboardRowView(rank: index + 1, entry: entry, isDark: isDark)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparatorTint(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(isDark ? .cyan : .blue)
                }
            }
        }
    }

    @ViewBuilder
    private func tabButton(tab: LeaderboardTab) -> some View {
        let isSelected = selectedTab == tab.id
        let fillColor: Color = isSelected
            ? (isDark ? Color.cyan.opacity(0.25) : Color.blue.opacity(0.15))
            : (isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
        let strokeColor: Color = isSelected
            ? (isDark ? Color.cyan.opacity(0.5) : Color.blue.opacity(0.3))
            : Color.clear
        let textColor: Color = isSelected
            ? (isDark ? .cyan : .blue)
            : (isDark ? .white.opacity(0.5) : .secondary)

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
    let isDark: Bool

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
                    .foregroundColor(isDark ? .white : .primary)
                Text(entry.detail)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(isDark ? .white.opacity(0.5) : .secondary)
            }

            Spacer()

            // Date
            Text(formattedDate)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(isDark ? .white.opacity(0.3) : .secondary.opacity(0.6))
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
        default: return isDark ? .white.opacity(0.4) : .secondary
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: entry.date)
    }
}
