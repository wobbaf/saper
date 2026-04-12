import SwiftUI
import Combine

/// Blueprint shop — strategic/QOL upgrades that change how you play.
struct BlueprintShopView: View {
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

                VStack(spacing: 0) {
                    // Gem balance banner
                    HStack(spacing: 8) {
                        Image(systemName: "diamond.fill")
                            .foregroundColor(theme.accentColor)
                            .font(.system(size: 18))
                        Text("\(gameState.profile.gems) gems")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(isDark ? .white : .primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isDark ? theme.cardBackground : Color.black.opacity(0.04))

                    Text("Blueprints change how you play — permanently.")
                        .font(.system(size: 12))
                        .foregroundColor(isDark ? .white.opacity(0.4) : .secondary)
                        .padding(.top, 12)
                        .padding(.bottom, 4)

                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(BlueprintUpgrade.allCases, id: \.rawValue) { upgrade in
                                BlueprintRow(upgrade: upgrade, gameState: gameState, isDark: isDark, theme: theme)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Blueprints")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarColorScheme(theme.isDark ? .dark : .light)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(theme.accentColor)
                }
            }
        }
    }
}

private struct BlueprintRow: View {
    let upgrade: BlueprintUpgrade
    @ObservedObject var gameState: GameState
    let isDark: Bool
    let theme: SkinUITheme

    private var currentLevel: Int { gameState.profile.blueprintLevel(for: upgrade) }
    private var nextCost: Int? { upgrade.costForNextLevel(current: currentLevel) }
    private var isMaxed: Bool { currentLevel >= upgrade.maxLevel }
    private var canAfford: Bool { gameState.profile.gems >= (nextCost ?? Int.max) }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(upgrade.color.opacity(isMaxed ? 0.25 : 0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: upgrade.iconName)
                    .font(.system(size: 22))
                    .foregroundColor(upgrade.color.opacity(isMaxed ? 1.0 : 0.8))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(upgrade.displayName)
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(isDark ? .white : .primary)
                    if upgrade.maxLevel > 1 {
                        Text("Lv.\(currentLevel)/\(upgrade.maxLevel)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                Text(upgrade.description)
                    .font(.system(size: 12))
                    .foregroundColor(isDark ? .white.opacity(0.55) : .secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            if isMaxed {
                Text("MAX")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(upgrade.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(upgrade.color.opacity(0.15))
                    .cornerRadius(8)
            } else {
                Button(action: purchaseUpgrade) {
                    VStack(spacing: 2) {
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 11))
                        Text("\(nextCost ?? 0)")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(canAfford ? .cyan : .gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background((canAfford ? Color.cyan : Color.gray).opacity(0.15))
                    .cornerRadius(10)
                }
                .disabled(!canAfford)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isDark ? theme.cardBackground : Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(upgrade.color.opacity(isMaxed ? 0.4 : 0.15), lineWidth: 1)
                )
        )
    }

    private func purchaseUpgrade() {
        guard let cost = nextCost, gameState.profile.gems >= cost else { return }
        gameState.profile.gems -= cost
        gameState.profile.applyBlueprint(upgrade)
        gameState.objectWillChange.send()
    }
}
