import SpriteKit

/// Container node for an 8x8 sector of tiles.
class SectorNode: SKNode {
    let coordinate: SectorCoordinate
    var tileNodes: [[TileNode]] = []
    private var overlayNode: SKShapeNode?
    private var borderNode: SKShapeNode?

    init(coordinate: SectorCoordinate, sector: Sector, renderer: TileRenderer) {
        self.coordinate = coordinate
        super.init()

        let size = Constants.sectorSize
        for row in 0..<size {
            var rowNodes: [TileNode] = []
            for col in 0..<size {
                let tileNode = TileNode(
                    localX: col,
                    localY: row,
                    sectorCoord: coordinate,
                    renderer: renderer
                )
                tileNode.updateAppearance(tile: sector.tiles[row][col])
                addChild(tileNode)
                rowNodes.append(tileNode)
            }
            tileNodes.append(rowNodes)
        }

        // Sector border
        let sectorPixelSize = Constants.sectorPixelSize
        let origin = CGPoint(
            x: CGFloat(coordinate.originTileX) * Constants.tileSize,
            y: CGFloat(coordinate.originTileY) * Constants.tileSize
        )
        let borderRect = CGRect(
            x: origin.x,
            y: origin.y,
            width: sectorPixelSize,
            height: sectorPixelSize
        )
        borderNode = SKShapeNode(rect: borderRect)
        borderNode?.strokeColor = SKColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.35)
        borderNode?.lineWidth = 1.5
        borderNode?.fillColor = .clear
        borderNode?.zPosition = -1
        if let border = borderNode {
            addChild(border)
            // Slow neon pulse on the grid line
            let dim = SKAction.customAction(withDuration: 2.0) { node, t in
                let alpha = 0.20 + 0.18 * abs(sin(Double(t) * .pi / 2.0))
                (node as? SKShapeNode)?.strokeColor = SKColor(red: 0.0, green: 0.8, blue: 1.0, alpha: alpha)
            }
            border.run(SKAction.repeatForever(dim))
        }

        updateOverlay(status: sector.status)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateTile(at localX: Int, localY: Int, with tile: Tile, animated: Bool = false) {
        guard localX >= 0, localX < Constants.sectorSize,
              localY >= 0, localY < Constants.sectorSize else { return }

        let tileNode = tileNodes[localY][localX]
        if animated {
            if tile.state == .mine {
                tileNode.animateMineReveal()
            } else {
                tileNode.animateReveal(tile: tile)
            }
        } else {
            tileNode.updateAppearance(tile: tile)
        }
    }

    func updateAllTiles(sector: Sector) {
        for row in 0..<Constants.sectorSize {
            for col in 0..<Constants.sectorSize {
                tileNodes[row][col].updateAppearance(tile: sector.tiles[row][col])
            }
        }
    }

    func updateOverlay(status: SectorStatus, animated: Bool = false) {
        overlayNode?.removeFromParent()
        overlayNode = nil

        let sectorPixelSize = Constants.sectorPixelSize
        let origin = CGPoint(
            x: CGFloat(coordinate.originTileX) * Constants.tileSize,
            y: CGFloat(coordinate.originTileY) * Constants.tileSize
        )
        let overlayRect = CGRect(
            x: origin.x,
            y: origin.y,
            width: sectorPixelSize,
            height: sectorPixelSize
        )
        let center = CGPoint(x: origin.x + sectorPixelSize / 2, y: origin.y + sectorPixelSize / 2)

        switch status {
        case .solved:
            let overlay = SKShapeNode(rect: overlayRect)
            overlay.fillColor = SKColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 0.06)
            overlay.strokeColor = SKColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 0.3)
            overlay.lineWidth = 2
            overlay.zPosition = 10
            overlayNode = overlay
            addChild(overlay)

            if animated {
                animateSectorSolved(center: center, rect: overlayRect)
            }

        case .locked:
            let overlay = SKShapeNode(rect: overlayRect)
            overlay.fillColor = SKColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.08)
            overlay.strokeColor = SKColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.5)
            overlay.lineWidth = 2
            overlay.zPosition = 10
            overlayNode = overlay
            addChild(overlay)

            // Pulsing animation
            let pulseOut = SKAction.fadeAlpha(to: 0.03, duration: 1.0)
            let pulseIn = SKAction.fadeAlpha(to: 0.12, duration: 1.0)
            overlay.run(SKAction.repeatForever(SKAction.sequence([pulseOut, pulseIn])))

            if animated {
                animateSectorFailed(center: center, rect: overlayRect)
            }

        case .active:
            break
        }
    }

    // MARK: - Sector Solved Animation

    private func animateSectorSolved(center: CGPoint, rect: CGRect) {
        // 1. Green particle burst from center
        let particleCount = 24
        for i in 0..<particleCount {
            let angle = CGFloat(i) / CGFloat(particleCount) * .pi * 2
            let particle = SKShapeNode(circleOfRadius: 3)
            particle.fillColor = SKColor(red: 0.0, green: 1.0, blue: 0.5, alpha: 1.0)
            particle.strokeColor = .clear
            particle.position = center
            particle.zPosition = 20
            particle.alpha = 0.9
            addChild(particle)

            let dist = Constants.sectorPixelSize * 0.6
            let target = CGPoint(x: center.x + cos(angle) * dist, y: center.y + sin(angle) * dist)
            let move = SKAction.move(to: target, duration: 0.5)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.5)
            let scale = SKAction.scale(to: 0.2, duration: 0.5)
            let group = SKAction.group([move, fade, scale])
            particle.run(SKAction.sequence([group, SKAction.removeFromParent()]))
        }

        // 2. Expanding ring
        let ring = SKShapeNode(circleOfRadius: 10)
        ring.strokeColor = SKColor(red: 0.0, green: 1.0, blue: 0.5, alpha: 0.8)
        ring.fillColor = .clear
        ring.lineWidth = 3
        ring.position = center
        ring.zPosition = 19
        addChild(ring)

        let expand = SKAction.scale(to: Constants.sectorPixelSize / 20, duration: 0.6)
        expand.timingMode = .easeOut
        let fadeRing = SKAction.fadeOut(withDuration: 0.6)
        ring.run(SKAction.sequence([SKAction.group([expand, fadeRing]), SKAction.removeFromParent()]))

        // 3. Flash overlay
        let flash = SKShapeNode(rect: rect)
        flash.fillColor = SKColor(red: 0.0, green: 1.0, blue: 0.5, alpha: 0.25)
        flash.strokeColor = .clear
        flash.zPosition = 18
        addChild(flash)
        flash.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.4), SKAction.removeFromParent()]))

        // 4. Border glow pulse
        if let overlay = overlayNode {
            let glowUp = SKAction.customAction(withDuration: 0.3) { node, t in
                (node as? SKShapeNode)?.strokeColor = SKColor(
                    red: 0.0, green: 1.0, blue: 0.0,
                    alpha: 0.3 + 0.7 * (1.0 - t / 0.3)
                )
            }
            let glowDown = SKAction.customAction(withDuration: 0.5) { node, t in
                (node as? SKShapeNode)?.strokeColor = SKColor(
                    red: 0.0, green: 1.0, blue: 0.0,
                    alpha: 0.3 + 0.7 * (t / 0.5)
                )
            }
            overlay.run(SKAction.sequence([
                glowUp,
                SKAction.customAction(withDuration: 0) { node, _ in
                    (node as? SKShapeNode)?.strokeColor = SKColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 0.3)
                }
            ]))
            _ = glowDown // suppress unused warning
        }
    }

    // MARK: - Sector Failed Animation

    private func animateSectorFailed(center: CGPoint, rect: CGRect) {
        // 1. Red flash
        let flash = SKShapeNode(rect: rect)
        flash.fillColor = SKColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.35)
        flash.strokeColor = .clear
        flash.zPosition = 18
        addChild(flash)
        flash.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.5), SKAction.removeFromParent()]))

        // 2. Shake the sector tiles
        let shakeRight = SKAction.moveBy(x: 6, y: 0, duration: 0.04)
        let shakeLeft = SKAction.moveBy(x: -12, y: 0, duration: 0.04)
        let shakeCenter = SKAction.moveBy(x: 6, y: 0, duration: 0.04)
        let shakeSequence = SKAction.sequence([shakeRight, shakeLeft, shakeCenter])
        for row in tileNodes {
            for tileNode in row {
                tileNode.run(SKAction.repeat(shakeSequence, count: 3))
            }
        }

        // 3. Red particles scattering outward
        let particleCount = 16
        for i in 0..<particleCount {
            let angle = CGFloat(i) / CGFloat(particleCount) * .pi * 2 + CGFloat.random(in: -0.2...0.2)
            let particle = SKShapeNode(circleOfRadius: 2.5)
            particle.fillColor = SKColor(red: 1.0, green: 0.2, blue: 0.1, alpha: 0.8)
            particle.strokeColor = .clear
            particle.position = center
            particle.zPosition = 20
            addChild(particle)

            let dist = Constants.sectorPixelSize * 0.45
            let target = CGPoint(x: center.x + cos(angle) * dist, y: center.y + sin(angle) * dist)
            let move = SKAction.move(to: target, duration: 0.4)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.4)
            particle.run(SKAction.sequence([SKAction.group([move, fade]), SKAction.removeFromParent()]))
        }

        // 4. Skull/X marker at center
        let xMark = SKLabelNode(text: "✕")
        xMark.fontName = "Helvetica-Bold"
        xMark.fontSize = 40
        xMark.fontColor = SKColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 0.9)
        xMark.position = center
        xMark.zPosition = 21
        xMark.setScale(0.1)
        addChild(xMark)

        let pop = SKAction.scale(to: 1.0, duration: 0.2)
        pop.timingMode = .easeOut
        let hold = SKAction.wait(forDuration: 0.8)
        let fadeX = SKAction.fadeOut(withDuration: 0.5)
        xMark.run(SKAction.sequence([pop, hold, fadeX, SKAction.removeFromParent()]))
    }

    /// Get the bounding rect in world coordinates.
    var worldBoundingRect: CGRect {
        CGRect(
            x: CGFloat(coordinate.originTileX) * Constants.tileSize,
            y: CGFloat(coordinate.originTileY) * Constants.tileSize,
            width: Constants.sectorPixelSize,
            height: Constants.sectorPixelSize
        )
    }
}
