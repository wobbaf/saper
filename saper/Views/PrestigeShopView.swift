import SwiftUI
import Combine

/// Permanent upgrade shop — available from the main menu.
/// Upgrades persist across all runs and compound over time.
struct PrestigeShopView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        NavigationView {
            ZStack {
                (isDark ? Color(red: 0.05, green: 0.03, blue: 0.12)
                        : Color(red: 0.95, green: 0.95, blue: 0.98))
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Gem balance banner
                    HStack(spacing: 8) {
                        Image(systemName: "diamond.fill")
                            .foregroundColor(.cyan)
                            .font(.system(size: 18))
                        Text("\(gameState.profile.gems) gems")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(isDark ? .white : .primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))

                    Text("Upgrades are permanent and apply to every run.")
                        .font(.system(size: 12))
                        .foregroundColor(isDark ? .white.opacity(0.4) : .secondary)
                        .padding(.top, 12)
                        .padding(.bottom, 4)

                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(PrestigeUpgrade.allCases, id: \.rawValue) { upgrade in
                                PrestigeRow(upgrade: upgrade, gameState: gameState, isDark: isDark)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Upgrades")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct PrestigeRow: View {
    let upgrade: PrestigeUpgrade
    @ObservedObject var gameState: GameState
    let isDark: Bool

    private var currentLevel: Int { gameState.profile.prestigeLevel(for: upgrade) }
    private var nextCost: Int? { upgrade.costForNextLevel(current: currentLevel) }
    private var isMaxed: Bool { currentLevel >= upgrade.maxLevel }
    private var canAfford: Bool { gameState.profile.gems >= (nextCost ?? Int.max) }

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(upgrade.color.opacity(isMaxed ? 0.25 : 0.15))
                    .frame(width: 52, height: 52)
                if isMaxed {
                    Circle()
                        .stroke(upgrade.color.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 52, height: 52)
                }
                Image(systemName: upgrade.iconName)
                    .font(.system(size: 22))
                    .foregroundColor(upgrade.color.opacity(isMaxed ? 1.0 : 0.85))
            }

            // Text
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(upgrade.displayName)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(isDark ? .white : .primary)
                    if upgrade.maxLevel > 1 {
                        levelPips
                    }
                }
                Text(upgrade.description)
                    .font(.system(size: 12))
                    .foregroundColor(isDark ? .white.opacity(0.55) : .secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            // Buy button
            Button(action: buy) {
                if isMaxed {
                    Text("MAX")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(upgrade.color)
                        .frame(width: 56)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 10))
                        Text("\(nextCost!)")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(canAfford ? .white : .gray)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(canAfford ? upgrade.color.opacity(0.3) : Color.gray.opacity(0.15))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(canAfford ? upgrade.color.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
                }
            }
            .disabled(isMaxed || !canAfford)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isDark
                      ? upgrade.color.opacity(isMaxed ? 0.08 : 0.04)
                      : Color.black.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(upgrade.color.opacity(isMaxed ? 0.4 : 0.15), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private var levelPips: some View {
        HStack(spacing: 3) {
            ForEach(0..<upgrade.maxLevel, id: \.self) { i in
                Circle()
                    .fill(i < currentLevel ? upgrade.color : upgrade.color.opacity(0.2))
                    .frame(width: 7, height: 7)
            }
        }
    }

    private func buy() {
        guard let cost = nextCost, canAfford else { return }
        gameState.profile.gems -= cost
        gameState.profile.applyPrestige(upgrade)
        gameState.objectWillChange.send()
    }
}
