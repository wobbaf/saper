import SwiftUI

/// Level-up overlay — presents 3 perk choices for the player to pick one.
struct PerkPickerView: View {
    let perks: [RunPerk]
    let level: Int
    let onPick: (RunPerk) -> Void

    @State private var scale: CGFloat = 0.85
    @State private var opacity: Double = 0
    @State private var titleGlow = false

    var body: some View {
        ZStack {
            // Deep blur backdrop
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                VStack(spacing: 6) {
                    Text("LEVEL \(level)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.45))
                        .tracking(6)

                    ZStack {
                        // Glow bloom
                        Text("Choose a Perk")
                            .font(.system(size: 28, weight: .black, design: .monospaced))
                            .foregroundStyle(
                                LinearGradient(colors: [.yellow, .orange, .yellow],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                            .blur(radius: titleGlow ? 12 : 6)
                            .opacity(titleGlow ? 0.6 : 0.3)

                        Text("Choose a Perk")
                            .font(.system(size: 28, weight: .black, design: .monospaced))
                            .foregroundStyle(
                                LinearGradient(colors: [.yellow, .orange, .yellow],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                    }
                }

                VStack(spacing: 14) {
                    ForEach(perks, id: \.rawValue) { perk in
                        PerkCard(perk: perk) { onPick(perk) }
                    }
                }
                .padding(.horizontal, 20)
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                titleGlow = true
            }
        }
    }
}

private struct PerkCard: View {
    let perk: RunPerk
    let onTap: () -> Void

    @State private var pressed = false
    @State private var borderGlow = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon with layered glow
                ZStack {
                    Circle()
                        .fill(perk.color.opacity(0.55))
                        .frame(width: 56, height: 56)
                        .blur(radius: 8)
                    Circle()
                        .fill(perk.color.opacity(0.30))
                        .frame(width: 56, height: 56)
                    Image(systemName: perk.iconName)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(perk.color)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(perk.displayName)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Text(perk.description)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(perk.color)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .background(
                ZStack {
                    // Soft colour fill
                    RoundedRectangle(cornerRadius: 16)
                        .fill(perk.color.opacity(0.22))
                    // Neon border — pulses
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(perk.color.opacity(borderGlow ? 0.9 : 0.5), lineWidth: 1.5)
                    // Outer glow
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(perk.color.opacity(borderGlow ? 0.5 : 0.25), lineWidth: 6)
                        .blur(radius: 6)
                }
            )
            .scaleEffect(pressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                borderGlow = true
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeInOut(duration: 0.1)) { pressed = true } }
                .onEnded   { _ in withAnimation(.easeInOut(duration: 0.15)) { pressed = false } }
        )
    }
}
