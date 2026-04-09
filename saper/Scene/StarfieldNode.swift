import SpriteKit

/// Creates a lightweight parallax starfield background.
class StarfieldNode: SKNode {

    private var starLayers: [SKNode] = []
    private static var starTexture: SKTexture?

    override init() {
        super.init()
        self.name = "starfield"
        self.zPosition = -100
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(for screenSize: CGSize) {
        removeAllChildren()
        starLayers.removeAll()

        // Create a tiny reusable texture for all stars
        if StarfieldNode.starTexture == nil {
            let shape = SKShapeNode(circleOfRadius: 4)
            shape.fillColor = .white
            shape.strokeColor = .clear
            // We can't use SKView.texture here easily, so just use colored sprites
            StarfieldNode.starTexture = nil // will use color sprites
        }

        // 2 parallax layers with fewer stars, using SKSpriteNode (batched by SpriteKit)
        let configs: [(count: Int, sizeRange: ClosedRange<CGFloat>, alphaRange: ClosedRange<CGFloat>)] = [
            (60, 1.0...2.0, 0.1...0.3),    // Far
            (30, 1.5...3.0, 0.25...0.55),   // Near
        ]

        let spread = max(screenSize.width, screenSize.height) * 4

        for (index, config) in configs.enumerated() {
            let layerNode = SKNode()
            layerNode.name = "starLayer_\(index)"

            for _ in 0..<config.count {
                let radius = CGFloat.random(in: config.sizeRange)
                let star = SKSpriteNode(color: randomStarColor(), size: CGSize(width: radius * 2, height: radius * 2))
                star.alpha = CGFloat.random(in: config.alphaRange)
                star.position = CGPoint(
                    x: CGFloat.random(in: -spread...spread),
                    y: CGFloat.random(in: -spread...spread)
                )
                layerNode.addChild(star)
            }

            starLayers.append(layerNode)
            addChild(layerNode)
        }
    }

    /// Update star positions based on camera movement for parallax effect.
    func updateParallax(cameraPosition: CGPoint, cameraScale: CGFloat) {
        for (index, layer) in starLayers.enumerated() {
            let parallaxFactor: CGFloat = index == 0 ? 0.95 : 0.8
            layer.position = CGPoint(
                x: cameraPosition.x * (1 - parallaxFactor),
                y: cameraPosition.y * (1 - parallaxFactor)
            )
        }
    }

    private func randomStarColor() -> SKColor {
        let colors: [SKColor] = [
            .white,
            SKColor(red: 0.8, green: 0.85, blue: 1.0, alpha: 1),
            SKColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 1),
        ]
        return colors.randomElement() ?? .white
    }
}
