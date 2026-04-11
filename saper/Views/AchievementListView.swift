import SwiftUI

struct AchievementListView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }
    private var theme: SkinUITheme { gameState.profile.currentSkin.uiTheme }

    var body: some View {
        NavigationView {
            ZStack {
                (isDark ? theme.backgroundColors[0] : Color(red: 0.95, green: 0.95, blue: 0.98))
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        let unlocked = gameState.profile.unlockedAchievements
                        ForEach(Achievement.all) { achievement in
                            let isUnlocked = unlocked.contains(achievement.id)
                            AchievementRow(achievement: achievement, isUnlocked: isUnlocked, isDark: isDark, theme: theme)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarLeading) {
                    let count = gameState.profile.unlockedAchievements.count
                    Text("\(count)/\(Achievement.all.count)")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(theme.accentColor)
                }
            }
        }
    }
}

private struct AchievementRow: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let isDark: Bool
    let theme: SkinUITheme

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 52, height: 52)
                Image(systemName: achievement.iconName)
                    .font(.system(size: 22))
                    .foregroundColor(isUnlocked ? .yellow : .gray.opacity(0.4))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(achievement.displayName)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(isUnlocked ? (isDark ? .white : .primary) : .gray)
                Text(achievement.description)
                    .font(.system(size: 12))
                    .foregroundColor(isUnlocked ? (isDark ? .white.opacity(0.55) : .secondary) : .gray.opacity(0.5))
            }

            Spacer()

            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 20))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDark ? theme.cardBackground : Color.white.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isUnlocked ? Color.yellow.opacity(0.4) : Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
        .opacity(isUnlocked ? 1.0 : 0.65)
    }
}
