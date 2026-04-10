import SwiftUI

private struct ShopItem {
    let booster: BoosterType
    let price: Int
    let color: Color
}

private let shopItems: [ShopItem] = [
    ShopItem(booster: .revealOne,    price: 8,  color: .yellow),
    ShopItem(booster: .solveSector,  price: 15, color: .purple),
    ShopItem(booster: .undoMine,     price: 6,  color: .orange),
]

/// Gem shop — buy boosters with gems. Purchases are permanent (added to base stock).
struct ShopView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        NavigationView {
            ZStack {
                (isDark ? Color(red: 0.07, green: 0.07, blue: 0.12) : Color(red: 0.95, green: 0.95, blue: 0.98))
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

                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(shopItems, id: \.booster.rawValue) { item in
                                ShopRow(item: item, gameState: gameState, isDark: isDark)
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct ShopRow: View {
    let item: ShopItem
    @ObservedObject var gameState: GameState
    let isDark: Bool

    private var count: Int {
        switch item.booster {
        case .revealOne:   return gameState.profile.revealOneCount
        case .solveSector: return gameState.profile.solveSectorCount
        case .undoMine:    return gameState.profile.undoMineCount
        }
    }

    private var canAfford: Bool { gameState.profile.gems >= item.price }
    private var atMax: Bool { count >= Constants.maxBoostersPerType }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(item.color.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: item.booster.iconName)
                    .font(.system(size: 20))
                    .foregroundColor(item.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.booster.displayName)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(isDark ? .white : .primary)
                Text(item.booster.description)
                    .font(.system(size: 12))
                    .foregroundColor(isDark ? .white.opacity(0.5) : .secondary)
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
                .fill(isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.03))
        )
    }

    private func buy() {
        guard canAfford && !atMax else { return }
        gameState.profile.gems -= item.price
        switch item.booster {
        case .revealOne:   gameState.profile.revealOneCount += 1
        case .solveSector: gameState.profile.solveSectorCount += 1
        case .undoMine:    gameState.profile.undoMineCount += 1
        }
    }
}
