import SwiftUI

struct SplashScreenView: View {
    @State private var opacity: Double = 0
    @State private var scale: Double = 0.85
    @State private var glowPhase: Bool = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 28) {
                // App icon
                Image(uiImage: UIImage(named: "AppIcon") ?? UIImage())
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 110, height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .cyan.opacity(glowPhase ? 0.6 : 0.25), radius: glowPhase ? 24 : 12)

                VStack(spacing: 8) {
                    ZStack {
                        // Glow layer
                        Text("MINESWEEPER FOREVER")
                            .font(.system(size: 24, weight: .black, design: .monospaced))
                            .foregroundStyle(LinearGradient(colors: [.cyan, .purple], startPoint: .leading, endPoint: .trailing))
                            .blur(radius: glowPhase ? 12 : 6)
                            .opacity(glowPhase ? 0.6 : 0.3)

                        Text("MINESWEEPER FOREVER")
                            .font(.system(size: 24, weight: .black, design: .monospaced))
                            .foregroundStyle(LinearGradient(colors: [.cyan, .purple], startPoint: .leading, endPoint: .trailing))
                    }

                    Text("I N F I N I T Y")
                        .font(.system(size: 16, weight: .light, design: .monospaced))
                        .foregroundColor(.white.opacity(0.45))
                        .tracking(8)
                }
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                opacity = 1
                scale = 1
            }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                glowPhase = true
            }
        }
    }
}
