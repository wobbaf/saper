import SwiftUI

private struct ShopItem {
    let booster: BoosterType
    let price: Int
    let color: Color
}

private let shopItems: [ShopItem] = [
    ShopItem(booster: .solveSector,  price: 60,  color: .purple),
    ShopItem(booster: .undoMine,     price: 25,  color: .orange),
    ShopItem(booster: .mineShield,   price: 40,  color: .blue),
    ShopItem(booster: .refillHeart,  price: 50,  color: .pink),
]

/// Gem shop — buy boosters with gems. Purchases are permanent (added to base stock).
struct ShopView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss

    private var theme: SkinUITheme { gameState.profile.currentSkin.uiTheme }

    var body: some View {
        NavigationView {
            ZStack {
                theme.backgroundColors[0]
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Gem balance banner
                    HStack(spacing: 8) {
                        Image(systemName: "diamond.fill")
                            .foregroundColor(theme.accentColor)
                            .font(.system(size: 18))
                        Text("\(gameState.profile.gems) gems")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(theme.primaryTextColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(theme.cardBackground)

                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(shopItems, id: \.booster.rawValue) { item in
                                ShopRow(item: item, gameState: gameState, theme: theme)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Shop")
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

private struct ShopRow: View {
    let item: ShopItem
    @ObservedObject var gameState: GameState
    let theme: SkinUITheme

    /// During a run show the live run count; on the menu show the profile stock.
    private var count: Int {
        if gameState.isPlaying {
            return gameState.runBoosters[item.booster.rawValue] ?? 0
        }
        switch item.booster {
        case .solveSector:  return gameState.profile.solveSectorCount
        case .undoMine:     return gameState.profile.undoMineCount
        case .mineShield:   return gameState.profile.mineShieldCount
        case .refillHeart:  return gameState.profile.refillHeartCount
        }
    }

    private var canAfford: Bool { gameState.profile.gems >= item.price }
    private var atMax: Bool { count >= Constants.maxBoostersPerType }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(item.color.opacity(0.85))
                    .frame(width: 48, height: 48)
                Image(systemName: item.booster.iconName)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.booster.displayName)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(theme.primaryTextColor)
                Text(item.booster.description)
                    .font(.system(size: 12))
                    .foregroundColor(theme.secondaryTextColor)
                Text("Owned: \(count)/\(Constants.maxBoostersPerType)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(item.color.opacity(0.8))
            }

            Spacer()

            Button(action: buy) {
                HStack(spacing: 4) {
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 11))
                    Text("\(item.price)")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                }
                .foregroundColor(atMax ? .gray : (canAfford ? .white : .gray))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    atMax ? Color.gray.opacity(0.2) :
                    (canAfford ? item.color.opacity(0.3) : Color.gray.opacity(0.15))
                )
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(atMax ? Color.clear : (canAfford ? item.color.opacity(0.5) : Color.clear), lineWidth: 1)
                )
            }
            .disabled(atMax || !canAfford)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.cardBackground)
        )
    }

    private func buy() {
        guard canAfford && !atMax else { return }
        gameState.profile.gems -= item.price
        switch item.booster {
        case .solveSector:  gameState.profile.solveSectorCount += 1
        case .undoMine:     gameState.profile.undoMineCount += 1
        case .mineShield:   gameState.profile.mineShieldCount += 1
        case .refillHeart:  gameState.profile.refillHeartCount += 1
        }
        // If buying mid-run, also add to the live run stock so the HUD updates immediately
        if gameState.isPlaying {
            gameState.runBoosters[item.booster.rawValue, default: 0] += 1
        }
    }
}
