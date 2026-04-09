import Foundation

enum ClassicDifficulty: String, CaseIterable, Identifiable {
    case beginner
    case intermediate
    case expert

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .beginner:     return "Beginner"
        case .intermediate: return "Intermediate"
        case .expert:       return "Expert"
        }
    }

    var columns: Int {
        switch self {
        case .beginner:     return 9
        case .intermediate: return 16
        case .expert:       return 30
        }
    }

    var rows: Int {
        switch self {
        case .beginner:     return 9
        case .intermediate: return 16
        case .expert:       return 16
        }
    }

    var mineCount: Int {
        switch self {
        case .beginner:     return 10
        case .intermediate: return 40
        case .expert:       return 99
        }
    }

    var description: String {
        switch self {
        case .beginner:     return "9×9 · 10 mines"
        case .intermediate: return "16×16 · 40 mines"
        case .expert:       return "30×16 · 99 mines"
        }
    }
}
