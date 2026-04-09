import SwiftUI

/// App-wide color definitions for SwiftUI views.
enum ColorPalette {
    static let background = Color(red: 0.02, green: 0.02, blue: 0.08)
    static let backgroundLight = Color(red: 0.05, green: 0.05, blue: 0.15)

    static let cyan = Color(red: 0.0, green: 1.0, blue: 1.0)
    static let neonGreen = Color(red: 0.0, green: 1.0, blue: 0.0)
    static let neonYellow = Color(red: 1.0, green: 1.0, blue: 0.0)
    static let neonOrange = Color(red: 1.0, green: 0.6, blue: 0.0)
    static let neonRed = Color(red: 1.0, green: 0.0, blue: 0.0)
    static let neonPink = Color(red: 1.0, green: 0.4, blue: 0.7)
    static let neonPurple = Color(red: 0.6, green: 0.0, blue: 1.0)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let textMuted = Color.white.opacity(0.3)

    static let cardBackground = Color.white.opacity(0.08)
    static let cardBorder = Color.white.opacity(0.15)
}
