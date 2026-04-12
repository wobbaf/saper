import SwiftUI

/// Skin selection view.
struct SkinPickerView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss

    private var theme: SkinUITheme { gameState.profile.currentSkin.uiTheme }

    var body: some View {
        NavigationView {
            List {
                ForEach(SkinType.allCases, id: \.self) { skin in
                    Button(action: { selectSkin(skin) }) {
                        HStack {
                            // Color preview
                            RoundedRectangle(cornerRadius: 8)
                                .fill(skinPreviewColor(skin))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(skinBorderColor(skin), lineWidth: 2)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(skin.displayName)
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                                    .foregroundColor(.primary)

                                if skin.isFree {
                                    Text("Free")
                                        .font(.system(size: 12))
                                        .foregroundColor(.green)
                                } else if gameState.profile.unlockedSkins.contains(skin) {
                                    Text("Unlocked")
                                        .font(.system(size: 12))
                                        .foregroundColor(.blue)
                                } else {
                                    HStack(spacing: 2) {
                                        Image(systemName: "diamond.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(.cyan)
                                        Text("\(skin.gemCost)")
                                            .font(.system(size: 12))
                                            .foregroundColor(.cyan)
                                    }
                                }
                            }

                            Spacer()

                            if gameState.profile.currentSkin == skin {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .disabled(!skin.isFree && !gameState.profile.unlockedSkins.contains(skin) && gameState.profile.gems < skin.gemCost)
                }
            }
            .navigationTitle("Skins")
            .navigationBarColorScheme(theme.isDark ? .dark : .light)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(theme.accentColor)
                }
            }
        }
    }

    private func skinPreviewColor(_ skin: SkinType) -> Color {
        switch skin {
        case .classicLight: return Color(red: 0.86, green: 0.86, blue: 0.86)
        case .classicDark:  return Color(red: 0.24, green: 0.24, blue: 0.24)
        case .space:        return Color(red: 0.12, green: 0.12, blue: 0.22)
        case .neonGrid:     return Color(red: 0.08, green: 0.08, blue: 0.08)
        case .minecraft:    return Color(red: 0.40, green: 0.62, blue: 0.18)
        }
    }

    private func skinBorderColor(_ skin: SkinType) -> Color {
        switch skin {
        case .classicLight: return Color(red: 0.55, green: 0.55, blue: 0.55)
        case .classicDark:  return Color(red: 0.40, green: 0.40, blue: 0.40)
        case .space:        return Color(red: 0.25, green: 0.25, blue: 0.45)
        case .neonGrid:     return Color(red: 0.0,  green: 0.8,  blue: 1.0)
        case .minecraft:    return Color(red: 0.29, green: 0.60, blue: 0.05)
        }
    }

    private func selectSkin(_ skin: SkinType) {
        if skin.isFree || gameState.profile.unlockedSkins.contains(skin) {
            applySkin(skin)
        } else if gameState.profile.gems >= skin.gemCost {
            gameState.profile.gems -= skin.gemCost
            gameState.profile.unlockedSkins.append(skin)
            applySkin(skin)
        }
    }

    private func applySkin(_ skin: SkinType) {
        gameState.profile.currentSkin = skin
        gameState.profile.appearanceMode = skin.definition.isDark ? 2 : 1
    }
}
