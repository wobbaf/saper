import SpriteKit

extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        hypot(x - other.x, y - other.y)
    }

    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }
}

extension SKColor {
    static func numberColor(for count: Int) -> SKColor {
        guard count >= 0 && count < Constants.numberColors.count else {
            return .white
        }
        let (r, g, b) = Constants.numberColors[count]
        return SKColor(red: r, green: g, blue: b, alpha: 1)
    }
}
