import SpriteKit

/// In-scene HUD overlay that moves with the camera (for elements that need
/// to be part of the SpriteKit render tree).
class HUDNode: SKNode {
    // Currently kept minimal since the main HUD is in SwiftUI.
    // This can be used for in-scene effects like floating "+50 XP" labels.

    override init() {
        super.init()
        self.name = "hud"
        self.zPosition = 1000
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Show a floating text animation at a world position.
    func showFloatingText(_ text: String, at worldPosition: CGPoint, color: SKColor = .white) {
        let label = SKLabelNode(text: text)
        label.fontName = "Menlo-Bold"
        label.fontSize = 14
        label.fontColor = color
        label.position = worldPosition
        label.zPosition = 1001
        addChild(label)

        let moveUp = SKAction.moveBy(x: 0, y: 40, duration: 1.0)
        let fadeOut = SKAction.fadeOut(withDuration: 1.0)
        let remove = SKAction.removeFromParent()
        label.run(SKAction.sequence([SKAction.group([moveUp, fadeOut]), remove]))
    }
}
