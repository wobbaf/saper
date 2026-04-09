import SpriteKit

/// Helper for creating glow effects on nodes.
struct GlowEffect {

    /// Add a glow effect around a node.
    static func addGlow(to node: SKNode, color: SKColor, radius: CGFloat = 10) {
        let effectNode = SKEffectNode()
        effectNode.shouldRasterize = true
        effectNode.filter = CIFilter(
            name: "CIGaussianBlur",
            parameters: ["inputRadius": radius]
        )

        let glowNode = node.copy() as! SKNode
        glowNode.alpha = 0.4
        effectNode.addChild(glowNode)
        effectNode.zPosition = node.zPosition - 1

        node.parent?.addChild(effectNode)
        effectNode.position = node.position
    }

    /// Create a pulsing glow animation.
    static func pulsingGlow(minAlpha: CGFloat = 0.3, maxAlpha: CGFloat = 0.8, duration: TimeInterval = 1.5) -> SKAction {
        let fadeOut = SKAction.fadeAlpha(to: minAlpha, duration: duration)
        fadeOut.timingMode = .easeInEaseOut
        let fadeIn = SKAction.fadeAlpha(to: maxAlpha, duration: duration)
        fadeIn.timingMode = .easeInEaseOut
        return SKAction.repeatForever(SKAction.sequence([fadeOut, fadeIn]))
    }

    /// Color for a specific mine count number.
    static func colorForNumber(_ number: Int) -> SKColor {
        SKColor.numberColor(for: number)
    }
}
