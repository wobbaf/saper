import SpriteKit

/// Generates tile textures programmatically for different states and skins.
class TileRenderer {
    private var textures: [String: SKTexture] = [:]
    private var skin: SkinType = .space
    private let tileSize = Constants.tileSize

    func generateTextures(for skin: SkinType, in view: SKView) {
        self.skin = skin
        textures.removeAll()

        textures["hidden"] = renderTexture(in: view) { [self] size in
            createHiddenTile(size: size)
        }

        for i in 0...8 {
            textures["revealed_\(i)"] = renderTexture(in: view) { [self] size in
                createRevealedTile(number: i, size: size)
            }
        }

        textures["mine"] = renderTexture(in: view) { [self] size in
            createMineTile(size: size)
        }

        textures["flag"] = renderTexture(in: view) { [self] size in
            createFlagTile(size: size)
        }

        textures["question"] = renderTexture(in: view) { [self] size in
            createQuestionTile(size: size)
        }
    }

    func texture(for state: TileState, adjacentCount: Int = 0) -> SKTexture? {
        switch state {
        case .hidden:
            return textures["hidden"]
        case .revealed:
            return textures["revealed_\(adjacentCount)"]
        case .mine:
            return textures["mine"]
        case .flagged:
            return textures["flag"]
        case .question:
            return textures["question"]
        }
    }

    // MARK: - Tile Creation

    private func renderTexture(in view: SKView, builder: (CGSize) -> SKNode) -> SKTexture {
        let size = CGSize(width: tileSize, height: tileSize)
        let node = builder(size)
        return view.texture(from: node, crop: CGRect(origin: .zero, size: size)) ?? SKTexture()
    }

    private func createHiddenTile(size: CGSize) -> SKNode {
        let container = SKNode()
        let cr = skin.tileCornerRadius
        let center = CGPoint(x: size.width / 2, y: size.height / 2)

        let bg = SKShapeNode(rectOf: CGSize(width: size.width - 2, height: size.height - 2), cornerRadius: cr)
        bg.fillColor = skin.hiddenTileColor
        bg.strokeColor = skin.hiddenTileBorderColor
        bg.lineWidth = skin == .minecraft ? 2 : 1
        bg.position = center
        container.addChild(bg)

        if skin == .minecraft {
            // Grass strip across the top (~25% of tile height)
            let grassH: CGFloat = (size.height - 2) * 0.25
            let grass = SKShapeNode(rectOf: CGSize(width: size.width - 2, height: grassH), cornerRadius: 0)
            grass.fillColor = SKColor(red: 0.29, green: 0.60, blue: 0.05, alpha: 1)
            grass.strokeColor = .clear
            grass.position = CGPoint(x: center.x, y: size.height - 1 - grassH / 2)
            container.addChild(grass)
        } else {
            // Subtle inner highlight (non-Minecraft only)
            let highlight = SKShapeNode(rectOf: CGSize(width: size.width - 8, height: size.height - 8), cornerRadius: 2)
            highlight.fillColor = SKColor(white: 1.0, alpha: 0.03)
            highlight.strokeColor = .clear
            highlight.position = CGPoint(x: center.x, y: center.y + 1)
            container.addChild(highlight)
        }

        return container
    }

    private func createRevealedTile(number: Int, size: CGSize) -> SKNode {
        let container = SKNode()
        let cr = max(0, skin.tileCornerRadius - 2)

        let bg = SKShapeNode(rectOf: CGSize(width: size.width - 2, height: size.height - 2), cornerRadius: cr)
        bg.fillColor = skin.revealedTileColor
        bg.strokeColor = skin.gridLineColor
        bg.lineWidth = skin == .minecraft ? 1.5 : 0.5
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        container.addChild(bg)

        if number > 0 {
            let color = SKColor.numberColor(for: number)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)

            // Three-layer neon glow — intensity scales with number value
            let glowStrength = CGFloat(0.12 + Float(number) * 0.055)
            let glowLayers: [(CGFloat, CGFloat)] = [(42, 0.55), (56, 0.28), (70, 0.11)]
            for (fontSize, alphaScale) in glowLayers {
                let halo = SKLabelNode(text: "\(number)")
                halo.fontName = "Menlo-Bold"
                halo.fontSize = fontSize
                halo.fontColor = color.withAlphaComponent(glowStrength * alphaScale)
                halo.verticalAlignmentMode = .center
                halo.horizontalAlignmentMode = .center
                halo.position = center
                container.addChild(halo)
            }

            // Sharp foreground label
            let label = SKLabelNode(text: "\(number)")
            label.fontName = "Menlo-Bold"
            label.fontSize = 22
            label.fontColor = color
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.position = center
            container.addChild(label)
        }

        return container
    }

    private func createMineTile(size: CGSize) -> SKNode {
        let container = SKNode()

        let bg = SKShapeNode(rectOf: CGSize(width: size.width - 2, height: size.height - 2), cornerRadius: 2)
        bg.fillColor = SKColor(red: 0.3, green: 0.0, blue: 0.0, alpha: 1)
        bg.strokeColor = SKColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1)
        bg.lineWidth = 1
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        container.addChild(bg)

        // Mine symbol
        let mine = SKShapeNode(circleOfRadius: 8)
        mine.fillColor = SKColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1)
        mine.strokeColor = SKColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1)
        mine.lineWidth = 1.5
        mine.position = CGPoint(x: size.width / 2, y: size.height / 2)
        container.addChild(mine)

        // Spikes
        for angle in stride(from: 0.0, to: .pi * 2, by: .pi / 4) {
            let spike = SKShapeNode(rectOf: CGSize(width: 2, height: 10))
            spike.fillColor = SKColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1)
            spike.strokeColor = .clear
            spike.position = CGPoint(
                x: size.width / 2 + cos(CGFloat(angle)) * 10,
                y: size.height / 2 + sin(CGFloat(angle)) * 10
            )
            spike.zRotation = CGFloat(angle)
            container.addChild(spike)
        }

        return container
    }

    private func createFlagTile(size: CGSize) -> SKNode {
        let container = SKNode()

        let bg = SKShapeNode(rectOf: CGSize(width: size.width - 2, height: size.height - 2), cornerRadius: 4)
        bg.fillColor = skin.hiddenTileColor
        bg.strokeColor = SKColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 0.8)
        bg.lineWidth = 1.5
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        container.addChild(bg)

        // Flag pole
        let pole = SKShapeNode(rectOf: CGSize(width: 2, height: 18))
        pole.fillColor = .white
        pole.strokeColor = .clear
        pole.position = CGPoint(x: size.width / 2, y: size.height / 2 - 2)
        container.addChild(pole)

        // Flag triangle
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 10, y: -5))
        path.addLine(to: CGPoint(x: 0, y: -10))
        path.closeSubpath()
        let flag = SKShapeNode(path: path)
        flag.fillColor = SKColor(red: 1.0, green: 0.3, blue: 0.1, alpha: 1)
        flag.strokeColor = .clear
        flag.position = CGPoint(x: size.width / 2 + 1, y: size.height / 2 + 10)
        container.addChild(flag)

        return container
    }

    private func createQuestionTile(size: CGSize) -> SKNode {
        let container = SKNode()

        let bg = SKShapeNode(rectOf: CGSize(width: size.width - 2, height: size.height - 2), cornerRadius: 4)
        bg.fillColor = skin.hiddenTileColor
        bg.strokeColor = SKColor(red: 0.5, green: 0.5, blue: 1.0, alpha: 0.8)
        bg.lineWidth = 1.5
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        container.addChild(bg)

        let label = SKLabelNode(text: "?")
        label.fontName = "Menlo-Bold"
        label.fontSize = 24
        label.fontColor = SKColor(red: 0.5, green: 0.5, blue: 1.0, alpha: 1)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: size.width / 2, y: size.height / 2)
        container.addChild(label)

        return container
    }
}
