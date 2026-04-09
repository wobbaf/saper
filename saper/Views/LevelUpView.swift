import SwiftUI

/// Level-up celebration overlay.
struct LevelUpView: View {
    let level: Int
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 16) {
                Text("LEVEL UP!")
                    .font(.system(size: 28, weight: .black, design: .monospaced))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange, .yellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("Level \(level)")
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)

                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "diamond.fill")
                            .foregroundColor(.cyan)
                        Text("+\(Constants.gemsPerLevelUp) Gems")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                        Text("+1 Booster")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.yellow)
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.08))
                .cornerRadius(12)

                Button(action: onDismiss) {
                    Text("Continue")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.cyan.opacity(0.3))
                        .cornerRadius(10)
                }
                .padding(.top, 8)
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}
