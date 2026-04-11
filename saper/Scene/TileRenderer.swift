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
        bg.lineWidth = skin == .minecraft ? 1 : 1
        bg.position = center
        container.addChild(bg)

        if skin == .minecraft {
            // Top-down grass block: scatter darker green pixel marks across surface
            let dark = SKColor(red: 0.22, green: 0.50, blue: 0.04, alpha: 1)
            let px: CGFloat = 5
            // Fixed pattern mimicking Minecraft grass texture pixel clusters
            let offsets: [(CGFloat, CGFloat)] = [
                (6, 6), (14, 10), (28, 7), (36, 14),
                (8, 26), (20, 32), (32, 28), (38, 36),
                (12, 18), (24, 22), (16, 38), (34, 20)
            ]
            for (ox, oy) in offsets {
                let dot = SKShapeNode(rectOf: CGSize(width: px, height: px))
                dot.fillColor = dark
                dot.strokeColor = .clear
                dot.position = CGPoint(x: ox + px / 2, y: oy + px / 2)
                container.addChild(dot)
            }
        } else {
            // Subtle inner highlight
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

        if skin == .minecraft {
            // Oak plank grain: three horizontal darker stripes
            let grain = SKColor(red: 0.42, green: 0.30, blue: 0.15, alpha: 0.55)
            let stripeYs: [CGFloat] = [size.height * 0.28, size.height * 0.52, size.height * 0.76]
            for sy in stripeYs {
                let stripe = SKShapeNode(rectOf: CGSize(width: size.width - 4, height: 2))
                stripe.fillColor = grain
                stripe.strokeColor = .clear
                stripe.position = CGPoint(x: size.width / 2, y: sy)
                container.addChild(stripe)
            }
        }

        if number > 0 {
            let color = skin.numberColor(for: number)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)

            if skin.useNeonGlow {
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

        if skin == .minecraft {
            return createCreeperTile(size: size)
        }

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

    /// Creeper face tile for Minecraft skin mine.
    private func createCreeperTile(size: CGSize) -> SKNode {
        let container = SKNode()

        // Background: Minecraft creeper green
        let bg = SKShapeNode(rectOf: CGSize(width: size.width - 2, height: size.height - 2), cornerRadius: 0)
        bg.fillColor = SKColor(red: 0.40, green: 0.62, blue: 0.18, alpha: 1)
        bg.strokeColor = SKColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1)
        bg.lineWidth = 1
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        container.addChild(bg)

        let black = SKColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1)
        let px: CGFloat = 7  // pixel size

        // Helper: add a pixel square
        func pixel(x: CGFloat, y: CGFloat) {
            let sq = SKShapeNode(rectOf: CGSize(width: px, height: px))
            sq.fillColor = black
            sq.strokeColor = .clear
            // y is from top: convert to SpriteKit bottom-origin coords
            sq.position = CGPoint(x: x + px / 2, y: size.height - y - px / 2)
            container.addChild(sq)
        }

        // Eyes: two 2×2 pixel squares side by side in upper half
        // Left eye at col 1-2, row 1-2  (pixel grid offset from edge ~6px)
        let ex1: CGFloat = 7,  ex2: CGFloat = 22  // left/right eye x
        let ey: CGFloat = 8                         // eye row y (from top)
        pixel(x: ex1,      y: ey);      pixel(x: ex1 + px,  y: ey)
        pixel(x: ex1,      y: ey + px); pixel(x: ex1 + px,  y: ey + px)
        pixel(x: ex2,      y: ey);      pixel(x: ex2 + px,  y: ey)
        pixel(x: ex2,      y: ey + px); pixel(x: ex2 + px,  y: ey + px)

        // Nose: 2×1 center below eyes
        let nx: CGFloat = 17, ny: CGFloat = 22
        pixel(x: nx, y: ny); pixel(x: nx + px, y: ny)

        // Mouth: classic creeper jagged mouth
        //  ██████
        //  ██  ██
        //    ████
        let my: CGFloat = 29
        pixel(x: 7,  y: my);     pixel(x: 14, y: my);
        pixel(x: 21, y: my);     pixel(x: 28, y: my)
        pixel(x: 7,  y: my + px);                     pixel(x: 28, y: my + px)
        pixel(x: 14, y: my + px * 2); pixel(x: 21, y: my + px * 2)

        return container
    }

    private func createFlagTile(size: CGSize) -> SKNode {
        if skin == .minecraft {
            return createObsidianTile(size: size)
        }

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

    /// Obsidian block tile for Minecraft flagged state.
    private func createObsidianTile(size: CGSize) -> SKNode {
        let container = SKNode()

        let bg = SKShapeNode(rectOf: CGSize(width: size.width - 2, height: size.height - 2), cornerRadius: 0)
        bg.fillColor = skin.obsidianColor
        bg.strokeColor = SKColor(red: 0.25, green: 0.10, blue: 0.35, alpha: 1)
        bg.lineWidth = 1
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        container.addChild(bg)

        // Scattered purple-tinted pixel highlights — obsidian's characteristic shimmer
        let accent = skin.obsidianAccentColor
        let px: CGFloat = 5
        let offsets: [(CGFloat, CGFloat)] = [
            (5, 5), (16, 9), (30, 5), (38, 14),
            (8, 22), (22, 18), (34, 25),
            (6, 34), (18, 30), (32, 36), (38, 28)
        ]
        for (ox, oy) in offsets {
            let dot = SKShapeNode(rectOf: CGSize(width: px, height: px))
            dot.fillColor = accent
            dot.strokeColor = .clear
            dot.position = CGPoint(x: ox + px / 2, y: oy + px / 2)
            container.addChild(dot)
        }

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
