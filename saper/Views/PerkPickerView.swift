import SwiftUI

/// Level-up overlay — presents 3 perk choices for the player to pick one.
struct PerkPickerView: View {
    let perks: [RunPerk]
    let level: Int
    let onPick: (RunPerk) -> Void

    @State private var scale: CGFloat = 0.85
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.75)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("LEVEL \(level)")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(4)

                    Text("Choose a Perk")
                        .font(.system(size: 26, weight: .black, design: .monospaced))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange, .yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }

                VStack(spacing: 12) {
                    ForEach(perks, id: \.rawValue) { perk in
                        PerkCard(perk: perk) {
                            onPick(perk)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

private struct PerkCard: View {
    let perk: RunPerk
    let onTap: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(perk.color.opacity(0.2))
                        .frame(width: 48, height: 48)
                    Image(systemName: perk.iconName)
                        .font(.system(size: 22))
                        .foregroundColor(perk.color)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(perk.displayName)
                        .font(.system(size: 17, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Text(perk.description)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.55))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(perk.color.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(perk.color.opacity(0.35), lineWidth: 1)
                    )
            )
            .scaleEffect(pressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeInOut(duration: 0.1)) { pressed = true } }
                .onEnded   { _ in withAnimation(.easeInOut(duration: 0.15)) { pressed = false } }
        )
    }
}
