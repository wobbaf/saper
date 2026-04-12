import SwiftUI

struct AchievementListView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss

    private var theme: SkinUITheme { gameState.profile.currentSkin.uiTheme }

    var body: some View {
        NavigationView {
            ZStack {
                theme.backgroundColors[0]
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        let unlocked = gameState.profile.unlockedAchievements
                        ForEach(Achievement.all) { achievement in
                            let isUnlocked = unlocked.contains(achievement.id)
                            AchievementRow(achievement: achievement, isUnlocked: isUnlocked, theme: theme)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarColorScheme(theme.isDark ? .dark : .light)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(theme.accentColor)
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
    let theme: SkinUITheme

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color.yellow.opacity(0.2) : theme.primaryTextColor.opacity(0.06))
                    .frame(width: 52, height: 52)
                Image(systemName: achievement.iconName)
                    .font(.system(size: 22))
                    .foregroundColor(isUnlocked ? .yellow : theme.secondaryTextColor.opacity(0.4))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(achievement.displayName)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(isUnlocked ? theme.primaryTextColor : theme.secondaryTextColor)
                Text(achievement.description)
                    .font(.system(size: 12))
                    .foregroundColor(isUnlocked ? theme.secondaryTextColor : theme.secondaryTextColor.opacity(0.5))
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
                .fill(theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isUnlocked ? Color.yellow.opacity(0.4) : theme.secondaryTextColor.opacity(0.1), lineWidth: 1)
                )
        )
        .opacity(isUnlocked ? 1.0 : 0.65)
    }
}
