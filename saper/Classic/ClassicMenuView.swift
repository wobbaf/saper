import SwiftUI

/// Difficulty selection screen for classic minesweeper mode with retro styling.
struct ClassicMenuView: View {
    let onStartGame: (ClassicDifficulty) -> Void
    let onBack: () -> Void

    var body: some View {
        ZStack {
            // Retro gray background
            Color(red: 192/255, green: 192/255, blue: 192/255)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Title bar
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .bold))
                            Text("Back")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.black)
                    }

                    Spacer()

                    Text("Classic Minesweeper")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)

                    Spacer()

                    // Balance spacer
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.clear)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Spacer()

                // Mine icon
                Image(systemName: "circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.black)
                    .padding(.bottom, 8)

                Text("Select Difficulty")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black.opacity(0.6))
                    .padding(.bottom, 30)

                // Difficulty buttons
                VStack(spacing: 16) {
                    ForEach(ClassicDifficulty.allCases) { difficulty in
                        Button(action: { onStartGame(difficulty) }) {
                            VStack(spacing: 4) {
                                Text(difficulty.displayName)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.black)

                                Text(difficulty.description)
                                    .font(.system(size: 13))
                                    .foregroundColor(.black.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(retroRaisedButton)
                        }
                    }
                }
                .padding(.horizontal, 40)

                Spacer()
                Spacer()
            }
        }
    }

    private var retroRaisedButton: some View {
        Rectangle()
            .fill(Color(red: 192/255, green: 192/255, blue: 192/255))
            .overlay(
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height

                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: w, y: 0))
                        path.addLine(to: CGPoint(x: w - 2, y: 2))
                        path.addLine(to: CGPoint(x: 2, y: 2))
                        path.closeSubpath()
                    }
                    .fill(Color.white)

                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: 0, y: h))
                        path.addLine(to: CGPoint(x: 2, y: h - 2))
                        path.addLine(to: CGPoint(x: 2, y: 2))
                        path.closeSubpath()
                    }
                    .fill(Color.white)

                    Path { path in
                        path.move(to: CGPoint(x: 0, y: h))
                        path.addLine(to: CGPoint(x: w, y: h))
                        path.addLine(to: CGPoint(x: w - 2, y: h - 2))
                        path.addLine(to: CGPoint(x: 2, y: h - 2))
                        path.closeSubpath()
                    }
                    .fill(Color(red: 128/255, green: 128/255, blue: 128/255))

                    Path { path in
                        path.move(to: CGPoint(x: w, y: 0))
                        path.addLine(to: CGPoint(x: w, y: h))
                        path.addLine(to: CGPoint(x: w - 2, y: h - 2))
                        path.addLine(to: CGPoint(x: w - 2, y: 2))
                        path.closeSubpath()
                    }
                    .fill(Color(red: 128/255, green: 128/255, blue: 128/255))
                }
            )
    }
}
