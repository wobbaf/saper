import Foundation

enum GameMode: String, Codable, CaseIterable {
    case endless
    case hardcore
    case timed

    var displayName: String {
        switch self {
        case .endless: return "Endless"
        case .hardcore: return "Hardcore"
        case .timed: return "Timed"
        }
    }

    var description: String {
        switch self {
        case .endless: return "Explore the infinite board. No game over."
        case .hardcore: return "One mine hit = game over."
        case .timed: return "3 minutes. Solve as many sectors as you can."
        }
    }
}
