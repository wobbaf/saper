import Foundation

/// A special property that can be assigned to a sector, giving it unique behavior.
enum SectorModifier: String, Codable, CaseIterable {
    /// UndoMine booster cannot reverse a mine hit here.
    case cursed
    /// Gem reward is doubled when this sector is solved.
    case charged
    /// Unlock cost is doubled for this sector.
    case sealed

    var displayName: String {
        switch self {
        case .cursed:  return "Cursed"
        case .charged: return "Charged"
        case .sealed:  return "Sealed"
        }
    }

    var badge: String {
        switch self {
        case .cursed:  return "💀"
        case .charged: return "⚡"
        case .sealed:  return "🔒"
        }
    }

    var flavorText: String {
        switch self {
        case .cursed:  return "Undo Mine won't work here"
        case .charged: return "Gem reward doubled"
        case .sealed:  return "Costs double gems to unlock"
        }
    }

    var badgeColor: (CGFloat, CGFloat, CGFloat) {
        switch self {
        case .cursed:  return (1.0, 0.2, 0.2)
        case .charged: return (0.2, 0.9, 1.0)
        case .sealed:  return (0.7, 0.3, 1.0)
        }
    }
}
