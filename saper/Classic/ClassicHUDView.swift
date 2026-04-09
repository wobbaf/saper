import SwiftUI

/// Windows 95-style HUD bar with mine counter, smiley button, and timer.
struct ClassicHUDView: View {
    @ObservedObject var classicGameState: ClassicGameState
    let onRestart: () -> Void
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Mine counter (left)
            RetroDigitDisplay(value: classicGameState.minesRemaining)

            Spacer()

            // Smiley button (center)
            SmileyButton(state: classicGameState.smileyState) {
                onRestart()
            }

            Spacer()

            // Timer (right)
            RetroDigitDisplay(value: min(classicGameState.elapsedSeconds, 999))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(retroInsetBorder)
        .padding(6)
        .background(Color(red: 192/255, green: 192/255, blue: 192/255))
    }

    private var retroInsetBorder: some View {
        RoundedRectangle(cornerRadius: 0)
            .fill(Color(red: 192/255, green: 192/255, blue: 192/255))
            .overlay(
                // Inset bevel: dark on top/left, light on bottom/right
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height
                    Path { path in
                        // Top dark edge
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: w, y: 0))
                        path.addLine(to: CGPoint(x: w - 2, y: 2))
                        path.addLine(to: CGPoint(x: 2, y: 2))
                        path.closeSubpath()
                    }
                    .fill(Color(red: 128/255, green: 128/255, blue: 128/255))

                    Path { path in
                        // Left dark edge
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: 0, y: h))
                        path.addLine(to: CGPoint(x: 2, y: h - 2))
                        path.addLine(to: CGPoint(x: 2, y: 2))
                        path.closeSubpath()
                    }
                    .fill(Color(red: 128/255, green: 128/255, blue: 128/255))

                    Path { path in
                        // Bottom light edge
                        path.move(to: CGPoint(x: 0, y: h))
                        path.addLine(to: CGPoint(x: w, y: h))
                        path.addLine(to: CGPoint(x: w - 2, y: h - 2))
                        path.addLine(to: CGPoint(x: 2, y: h - 2))
                        path.closeSubpath()
                    }
                    .fill(Color.white)

                    Path { path in
                        // Right light edge
                        path.move(to: CGPoint(x: w, y: 0))
                        path.addLine(to: CGPoint(x: w, y: h))
                        path.addLine(to: CGPoint(x: w - 2, y: h - 2))
                        path.addLine(to: CGPoint(x: w - 2, y: 2))
                        path.closeSubpath()
                    }
                    .fill(Color.white)
                }
            )
    }
}

// MARK: - Retro LED Digit Display

/// Red LED-style 3-digit counter like classic Minesweeper.
struct RetroDigitDisplay: View {
    let value: Int

    private var displayText: String {
        let clamped = max(-99, min(999, value))
        if clamped < 0 {
            return String(format: "-%02d", abs(clamped))
        }
        return String(format: "%03d", clamped)
    }

    var body: some View {
        Text(displayText)
            .font(.system(size: 28, weight: .bold, design: .monospaced))
            .foregroundColor(Color(red: 1, green: 0, blue: 0))
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(Color(red: 48/255, green: 0, blue: 0))
            .overlay(
                Rectangle()
                    .stroke(Color(red: 128/255, green: 128/255, blue: 128/255), lineWidth: 1)
            )
    }
}

// MARK: - Smiley Button

/// Clickable smiley face that changes with game state.
struct SmileyButton: View {
    let state: ClassicGameState.SmileyState
    let action: () -> Void

    private var faceText: String {
        switch state {
        case .happy:    return "🙂"
        case .surprised: return "😮"
        case .cool:     return "😎"
        case .dead:     return "😵"
        }
    }

    var body: some View {
        Button(action: action) {
            Text(faceText)
                .font(.system(size: 28))
                .frame(width: 44, height: 44)
                .background(
                    // Raised bevel for the button
                    ZStack {
                        Color(red: 192/255, green: 192/255, blue: 192/255)

                        GeometryReader { geo in
                            let w = geo.size.width
                            let h = geo.size.height

                            // Top/left highlight
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

                            // Bottom/right shadow
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
                    }
                )
        }
    }
}
