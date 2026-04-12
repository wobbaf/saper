import SpriteKit
import SwiftUI

extension View {
    /// Sets the navigation bar color scheme — uses toolbarColorScheme on iOS 16+,
    /// falls back to environment colorScheme on iOS 15.
    func navigationBarColorScheme(_ scheme: ColorScheme) -> some View {
        if #available(iOS 16.0, *) {
            return AnyView(self.toolbarColorScheme(scheme, for: .navigationBar))
        } else {
            return AnyView(self.environment(\.colorScheme, scheme))
        }
    }
}

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

