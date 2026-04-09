import SpriteKit

/// Generates Windows 95-style beveled tile textures for classic minesweeper mode.
class ClassicTileRenderer {
    private var textures: [String: SKTexture] = [:]
    private var tileSize: CGFloat = 0

    // Classic Windows Minesweeper colors
    static let faceColor    = SKColor(red: 192/255, green: 192/255, blue: 192/255, alpha: 1) // #C0C0C0
    static let highlight    = SKColor.white
    static let shadow       = SKColor(red: 128/255, green: 128/255, blue: 128/255, alpha: 1) // #808080
    static let darkShadow   = SKColor(red: 64/255, green: 64/255, blue: 64/255, alpha: 1)
    static let bgColor      = SKColor(red: 192/255, green: 192/255, blue: 192/255, alpha: 1)

    // Classic number colors — exact Windows Minesweeper palette
    static let numberColors: [Int: SKColor] = [
        1: SKColor(red: 0, green: 0, blue: 1, alpha: 1),           // blue
        2: SKColor(red: 0, green: 128/255, blue: 0, alpha: 1),     // dark green
        3: SKColor(red: 1, green: 0, blue: 0, alpha: 1),           // red
        4: SKColor(red: 0, green: 0, blue: 128/255, alpha: 1),     // dark blue / navy
        5: SKColor(red: 128/255, green: 0, blue: 0, alpha: 1),     // maroon
        6: SKColor(red: 0, green: 128/255, blue: 128/255, alpha: 1), // teal
        7: SKColor(red: 0, green: 0, blue: 0, alpha: 1),           // black
        8: SKColor(red: 128/255, green: 128/255, blue: 128/255, alpha: 1), // gray
    ]

    func generateTextures(tileSize: CGFloat, in view: SKView) {
        self.tileSize = tileSize
        textures.removeAll()

        let bevel = max(2, floor(tileSize * 0.08))

        textures["hidden"] = renderTexture(in: view) { [self] size in
            createBeveledTile(size: size, bevel: bevel, raised: true)
        }

        for i in 0...8 {
            textures["revealed_\(i)"] = renderTexture(in: view) { [self] size in
                createRevealedTile(number: i, size: size)
            }
        }

        textures["mine"] = renderTexture(in: view) { [self] size in
            createMineTile(size: size)
        }

        textures["mine_hit"] = renderTexture(in: view) { [self] size in
            createMineTile(size: size, isHitMine: true)
        }

        textures["flag"] = renderTexture(in: view) { [self] size in
            createFlagTile(size: size, bevel: bevel)
        }
    }

    func texture(for state: TileState, adjacentCount: Int = 0, isHitMine: Bool = false) -> SKTexture? {
        switch state {
        case .hidden:
            return textures["hidden"]
        case .revealed:
            return textures["revealed_\(adjacentCount)"]
        case .mine:
            return isHitMine ? textures["mine_hit"] : textures["mine"]
        case .flagged:
            return textures["flag"]
        case .question:
            return textures["hidden"]
        }
    }

    // MARK: - Texture Rendering

    private func renderTexture(in view: SKView, builder: (CGSize) -> SKNode) -> SKTexture {
        let size = CGSize(width: tileSize, height: tileSize)
        let node = builder(size)
        return view.texture(from: node, crop: CGRect(origin: .zero, size: size)) ?? SKTexture()
    }

    // MARK: - Beveled (Hidden) Tile

    private func createBeveledTile(size: CGSize, bevel: CGFloat, raised: Bool) -> SKNode {
        let container = SKNode()
        let w = size.width
        let h = size.height

        // Base face
        let base = SKShapeNode(rectOf: CGSize(width: w, height: h))
        base.fillColor = Self.faceColor
        base.strokeColor = .clear
        base.position = CGPoint(x: w / 2, y: h / 2)
        container.addChild(base)

        let lightColor = raised ? Self.highlight : Self.shadow
        let darkColor = raised ? Self.shadow : Self.highlight

        // Top highlight edge
        let top = SKShapeNode(rectOf: CGSize(width: w, height: bevel))
        top.fillColor = lightColor
        top.strokeColor = .clear
        top.position = CGPoint(x: w / 2, y: h - bevel / 2)
        container.addChild(top)

        // Left highlight edge
        let left = SKShapeNode(rectOf: CGSize(width: bevel, height: h))
        left.fillColor = lightColor
        left.strokeColor = .clear
        left.position = CGPoint(x: bevel / 2, y: h / 2)
        container.addChild(left)

        // Bottom shadow edge
        let bottom = SKShapeNode(rectOf: CGSize(width: w, height: bevel))
        bottom.fillColor = darkColor
        bottom.strokeColor = .clear
        bottom.position = CGPoint(x: w / 2, y: bevel / 2)
        container.addChild(bottom)

        // Right shadow edge
        let right = SKShapeNode(rectOf: CGSize(width: bevel, height: h))
        right.fillColor = darkColor
        right.strokeColor = .clear
        right.position = CGPoint(x: w - bevel / 2, y: h / 2)
        container.addChild(right)

        return container
    }

    // MARK: - Revealed Tile

    private func createRevealedTile(number: Int, size: CGSize) -> SKNode {
        let container = SKNode()
        let w = size.width
        let h = size.height

        // Flat background
        let bg = SKShapeNode(rectOf: CGSize(width: w, height: h))
        bg.fillColor = Self.faceColor
        bg.strokeColor = .clear
        bg.position = CGPoint(x: w / 2, y: h / 2)
        container.addChild(bg)

        // Inset border — thin dark lines on all edges
        let borderWidth: CGFloat = 1
        let topLine = SKShapeNode(rectOf: CGSize(width: w, height: borderWidth))
        topLine.fillColor = Self.shadow
        topLine.strokeColor = .clear
        topLine.position = CGPoint(x: w / 2, y: h - borderWidth / 2)
        container.addChild(topLine)

        let leftLine = SKShapeNode(rectOf: CGSize(width: borderWidth, height: h))
        leftLine.fillColor = Self.shadow
        leftLine.strokeColor = .clear
        leftLine.position = CGPoint(x: borderWidth / 2, y: h / 2)
        container.addChild(leftLine)

        // Number label
        if number > 0 {
            let color = Self.numberColors[number] ?? .black
            let fontSize = max(12, floor(tileSize * 0.6))
            let label = SKLabelNode(text: "\(number)")
            label.fontName = "Helvetica-Bold"
            label.fontSize = fontSize
            label.fontColor = color
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.position = CGPoint(x: w / 2, y: h / 2)
            container.addChild(label)
        }

        return container
    }

    // MARK: - Mine Tile

    private func createMineTile(size: CGSize, isHitMine: Bool = false) -> SKNode {
        let container = SKNode()
        let w = size.width
        let h = size.height

        // Background
        let bg = SKShapeNode(rectOf: CGSize(width: w, height: h))
        bg.fillColor = isHitMine ? SKColor(red: 1, green: 0, blue: 0, alpha: 1) : Self.faceColor
        bg.strokeColor = .clear
        bg.position = CGPoint(x: w / 2, y: h / 2)
        container.addChild(bg)

        // Inset border
        let borderWidth: CGFloat = 1
        let topLine = SKShapeNode(rectOf: CGSize(width: w, height: borderWidth))
        topLine.fillColor = Self.shadow
        topLine.strokeColor = .clear
        topLine.position = CGPoint(x: w / 2, y: h - borderWidth / 2)
        container.addChild(topLine)

        let leftLine = SKShapeNode(rectOf: CGSize(width: borderWidth, height: h))
        leftLine.fillColor = Self.shadow
        leftLine.strokeColor = .clear
        leftLine.position = CGPoint(x: borderWidth / 2, y: h / 2)
        container.addChild(leftLine)

        // Mine body — black circle
        let mineRadius = max(4, floor(tileSize * 0.22))
        let mine = SKShapeNode(circleOfRadius: mineRadius)
        mine.fillColor = .black
        mine.strokeColor = .clear
        mine.position = CGPoint(x: w / 2, y: h / 2)
        container.addChild(mine)

        // Spikes
        let spikeLen = max(3, floor(tileSize * 0.15))
        let spikeWidth: CGFloat = max(1.5, floor(tileSize * 0.05))
        for angle in stride(from: 0.0, to: .pi * 2, by: .pi / 4) {
            let spike = SKShapeNode(rectOf: CGSize(width: spikeWidth, height: spikeLen))
            spike.fillColor = .black
            spike.strokeColor = .clear
            spike.position = CGPoint(
                x: w / 2 + cos(CGFloat(angle)) * mineRadius * 0.9,
                y: h / 2 + sin(CGFloat(angle)) * mineRadius * 0.9
            )
            spike.zRotation = CGFloat(angle)
            container.addChild(spike)
        }

        // Highlight dot
        let dot = SKShapeNode(circleOfRadius: max(1.5, floor(tileSize * 0.06)))
        dot.fillColor = .white
        dot.strokeColor = .clear
        dot.position = CGPoint(x: w / 2 - mineRadius * 0.3, y: h / 2 + mineRadius * 0.3)
        container.addChild(dot)

        return container
    }

    // MARK: - Flag Tile

    private func createFlagTile(size: CGSize, bevel: CGFloat) -> SKNode {
        let container = SKNode()
        let w = size.width
        let h = size.height

        // Beveled base
        let base = createBeveledTile(size: size, bevel: bevel, raised: true)
        container.addChild(base)

        // Flag pole
        let poleHeight = max(8, floor(tileSize * 0.45))
        let poleWidth: CGFloat = max(1.5, floor(tileSize * 0.05))
        let poleX = w / 2
        let poleBottom = h / 2 - poleHeight * 0.35

        let pole = SKShapeNode(rectOf: CGSize(width: poleWidth, height: poleHeight))
        pole.fillColor = .black
        pole.strokeColor = .clear
        pole.position = CGPoint(x: poleX, y: poleBottom + poleHeight / 2)
        container.addChild(pole)

        // Red flag triangle
        let flagH = max(5, floor(tileSize * 0.25))
        let flagW = max(5, floor(tileSize * 0.22))
        let flagTop = poleBottom + poleHeight

        let path = CGMutablePath()
        path.move(to: CGPoint(x: poleX, y: flagTop))
        path.addLine(to: CGPoint(x: poleX + flagW, y: flagTop - flagH / 2))
        path.addLine(to: CGPoint(x: poleX, y: flagTop - flagH))
        path.closeSubpath()

        let flag = SKShapeNode(path: path)
        flag.fillColor = SKColor(red: 1, green: 0, blue: 0, alpha: 1)
        flag.strokeColor = .clear
        container.addChild(flag)

        // Base platform
        let baseW = max(6, floor(tileSize * 0.3))
        let baseLine = SKShapeNode(rectOf: CGSize(width: baseW, height: max(1.5, floor(tileSize * 0.04))))
        baseLine.fillColor = .black
        baseLine.strokeColor = .clear
        baseLine.position = CGPoint(x: poleX, y: poleBottom)
        container.addChild(baseLine)

        return container
    }
}
