import Foundation

enum GameMode: String, Codable, CaseIterable {
    case endless
    case practice
    case hardcore
    case timed

    var displayName: String {
        switch self {
        case .endless:  return "Play"
        case .hardcore: return "Hardcore"
        case .timed:    return "Timed"
        case .practice: return "Practice"
        }
    }

    var description: String {
        switch self {
        case .endless:  return "Explore the infinite board. No game over."
        case .hardcore: return "One mine hit = game over."
        case .timed:    return "3 minutes. Solve as many sectors as you can."
        case .practice: return "Infinite lives. No score tracking. Just explore."
        }
    }
}
